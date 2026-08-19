#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import time
import uuid
from pathlib import Path

BUNDLE_ID = "de.kamilunavo.keepmeter"
SCREENSHOT_DIR = Path("/tmp/keepmeter-runtime")
DEFAULT_APP_PATH = Path("/tmp/keepmeter-debug-derived/Build/Products/Debug-iphonesimulator/KeepMeter.app")
PERSISTENCE_SENTINEL = "keepmeter-runtime-persistence-ok.txt"
LAUNCH_SENTINEL = "keepmeter-runtime-launch-ok.txt"
LAUNCH_PROBE_ARGUMENT = "--keepMeterRuntimeLaunchProbe"
LAUNCH_TOKEN_PREFIX = "--keepMeterRuntimeLaunchToken="


class RuntimeSmokeError(RuntimeError):
    pass


def command(
    args: list[str],
    *,
    timeout: int = 30,
    check: bool = True,
    quiet: bool = False,
) -> subprocess.CompletedProcess[str]:
    printable = " ".join(args)
    if not quiet:
        print(f"$ {printable}", flush=True)
    try:
        completed = subprocess.run(
            args,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeSmokeError(f"Command timed out after {timeout}s: {printable}") from exc

    if completed.stdout and not quiet:
        print(completed.stdout.rstrip(), flush=True)
    if completed.stderr and not quiet:
        print(completed.stderr.rstrip(), file=sys.stderr, flush=True)

    if check and completed.returncode != 0:
        raise RuntimeSmokeError(
            f"Command failed with exit {completed.returncode}: {printable}\n"
            f"stdout: {completed.stdout}\nstderr: {completed.stderr}"
        )
    return completed


def simctl(args: list[str], *, timeout: int = 30, check: bool = True, quiet: bool = False):
    return command(["xcrun", "simctl", *args], timeout=timeout, check=check, quiet=quiet)


def best_effort_simctl(args: list[str], *, timeout: int) -> None:
    try:
        simctl(args, timeout=timeout, check=False, quiet=True)
    except RuntimeSmokeError as exc:
        print(f"Runtime cleanup warning: {exc}", flush=True)


def available_devices() -> dict:
    completed = simctl(["list", "devices", "available", "-j"], timeout=8, quiet=True)
    return json.loads(completed.stdout)


def select_simulator() -> tuple[str, str, tuple[int, int]]:
    candidates: list[tuple[tuple[int, int], int, str, str]] = []
    for runtime, devices in available_devices().get("devices", {}).items():
        match = re.search(r"iOS-(\d+)-(\d+)", runtime)
        if not match:
            continue
        version = (int(match.group(1)), int(match.group(2)))
        for device in devices:
            if not device.get("isAvailable", True):
                continue
            name = device.get("name", "")
            if not name.startswith("iPhone"):
                continue
            pro_score = 2 if "Pro" in name else 1 if ("Plus" in name or "Max" in name) else 0
            candidates.append((version, pro_score, name, device["udid"]))

    if not candidates:
        raise RuntimeSmokeError("No available iPhone simulator found on the runner")

    candidates.sort()
    version, _, name, udid = candidates[-1]
    return udid, name, version


def device_state(udid: str) -> str:
    for devices in available_devices().get("devices", {}).values():
        for device in devices:
            if device.get("udid") == udid:
                return device.get("state", "Unknown")
    return "Missing"


def wait_for_boot(udid: str) -> None:
    try:
        simctl(["boot", udid], timeout=12, check=False)
    except RuntimeSmokeError as exc:
        print(f"Boot command did not return promptly; continuing with state polling: {exc}", flush=True)

    last_state = "Unknown"
    for attempt in range(1, 46):
        try:
            last_state = device_state(udid)
        except RuntimeSmokeError as exc:
            print(f"Simulator state poll [{attempt}/45] transient error: {exc}", flush=True)
            time.sleep(2)
            continue

        print(f"Simulator state [{attempt}/45]: {last_state}", flush=True)
        if last_state == "Booted":
            print("✓ Simulator reached Booted state", flush=True)
            break
        time.sleep(2)
    else:
        raise RuntimeSmokeError(
            f"Simulator did not reach Booted state inside the bounded boot window; last state: {last_state}"
        )

    try:
        simctl(["bootstatus", udid, "-b"], timeout=90)
        print("✓ Simulator boot services report ready", flush=True)
    except RuntimeSmokeError as exc:
        print(f"bootstatus did not complete; using a final bounded settle fallback: {exc}", flush=True)
        time.sleep(15)


def app_container(udid: str, kind: str = "app") -> Path | None:
    try:
        result = simctl(
            ["get_app_container", udid, BUNDLE_ID, kind],
            timeout=4,
            check=False,
            quiet=True,
        )
    except RuntimeSmokeError:
        return None

    if result.returncode != 0:
        return None

    raw_path = result.stdout.strip()
    if not raw_path:
        return None

    path = Path(raw_path)
    return path if path.exists() else None


def ensure_installed(udid: str, app_path: Path) -> Path:
    print("Installing KeepMeter into the booted simulator…", flush=True)
    try:
        simctl(["install", udid, str(app_path)], timeout=90)
        print("✓ simctl install returned successfully", flush=True)
    except RuntimeSmokeError as exc:
        print(f"Install command did not return cleanly; polling installation state: {exc}", flush=True)

    for attempt in range(1, 21):
        container = app_container(udid)
        if container is not None:
            print(f"✓ App installation resolved on poll {attempt}/20", flush=True)
            return container
        print(f"Install state [{attempt}/20]: not visible yet", flush=True)
        time.sleep(2)

    raise RuntimeSmokeError(
        "KeepMeter never became installed after the bounded simctl install + container polling window"
    )


def simulator_data_applications_root(udid: str) -> Path:
    return (
        Path.home()
        / "Library"
        / "Developer"
        / "CoreSimulator"
        / "Devices"
        / udid
        / "data"
        / "Containers"
        / "Data"
        / "Application"
    )


def sentinel_candidates(udid: str, filename: str) -> list[Path]:
    root = simulator_data_applications_root(udid)
    if not root.is_dir():
        return []
    return list(root.glob(f"*/Documents/{filename}"))


def remove_host_sentinels(udid: str, filename: str) -> None:
    for path in sentinel_candidates(udid, filename):
        try:
            path.unlink()
        except FileNotFoundError:
            pass


def wait_for_host_sentinel(
    udid: str,
    filename: str,
    expected_content: str,
    *,
    attempts: int,
    interval: float,
    label: str,
) -> Path:
    for attempt in range(1, attempts + 1):
        for path in sentinel_candidates(udid, filename):
            try:
                content = path.read_text(encoding="utf-8").strip()
            except (FileNotFoundError, OSError, UnicodeError):
                continue
            if content == expected_content:
                print(f"✓ {label} verified on poll {attempt}/{attempts}", flush=True)
                return path
        print(f"{label} [{attempt}/{attempts}]: not ready yet", flush=True)
        time.sleep(interval)

    raise RuntimeSmokeError(f"{label} did not appear inside the bounded verification window")


def launch(
    udid: str,
    language: str,
    locale: str,
    onboarding: bool,
    terminate: bool,
    extra_arguments: list[str] | None = None,
) -> str:
    launch_token = uuid.uuid4().hex
    remove_host_sentinels(udid, LAUNCH_SENTINEL)

    args = ["launch"]
    if terminate:
        args.append("--terminate-running-process")
    args.extend([
        udid,
        BUNDLE_ID,
        "-AppleLanguages",
        f"({language})",
        "-AppleLocale",
        locale,
        "-hasCompletedOnboarding",
        "YES" if onboarding else "NO",
        LAUNCH_PROBE_ARGUMENT,
        f"{LAUNCH_TOKEN_PREFIX}{launch_token}",
    ])
    if extra_arguments:
        args.extend(extra_arguments)

    command_error: RuntimeSmokeError | None = None
    output = ""
    try:
        result = simctl(args, timeout=45)
        output = result.stdout.strip()
        if f"{BUNDLE_ID}:" not in output:
            print(f"Launch returned unexpected output; using Swift launch probe as authority: {output!r}", flush=True)
    except RuntimeSmokeError as exc:
        command_error = exc
        print(f"Launch command did not return cleanly; verifying actual app execution: {exc}", flush=True)

    try:
        wait_for_host_sentinel(
            udid,
            LAUNCH_SENTINEL,
            launch_token,
            attempts=45,
            interval=1,
            label="SwiftUI launch sentinel",
        )
    except RuntimeSmokeError as exc:
        if command_error is not None:
            raise RuntimeSmokeError(f"{command_error}; additionally, {exc}") from exc
        raise

    return output or f"{BUNDLE_ID}: verified-by-runtime-sentinel"


def screenshot(udid: str, filename: str) -> Path:
    path = SCREENSHOT_DIR / filename
    simctl(["io", udid, "screenshot", str(path)], timeout=45)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeSmokeError(f"Runtime screenshot is missing or empty: {path}")
    command(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], timeout=15)
    return path


def require_persistence_sentinel(udid: str) -> Path:
    return wait_for_host_sentinel(
        udid,
        PERSISTENCE_SENTINEL,
        "ok",
        attempts=20,
        interval=1,
        label="Runtime SwiftData persistence sentinel",
    )


def main() -> int:
    app_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_APP_PATH
    if not app_path.is_dir():
        raise RuntimeSmokeError(f"Debug app bundle not found at {app_path}")

    if SCREENSHOT_DIR.exists():
        shutil.rmtree(SCREENSHOT_DIR)
    SCREENSHOT_DIR.mkdir(parents=True)

    udid, name, version = select_simulator()
    print(f"Using simulator: {name}, iOS {version[0]}.{version[1]}, {udid}", flush=True)

    try:
        wait_for_boot(udid)
        installed_app = ensure_installed(udid, app_path)
        print(f"✓ App installed at {installed_app}", flush=True)

        best_effort_simctl(
            [
                "status_bar", udid, "override",
                "--time", "09:41",
                "--batteryState", "charged",
                "--batteryLevel", "100",
                "--wifiBars", "3",
                "--cellularBars", "4",
            ],
            timeout=10,
        )

        # 1) Fresh install onboarding: no QA seed data yet.
        simctl(["ui", udid, "appearance", "light"], timeout=20)
        launch(udid, "en", "en_US", onboarding=False, terminate=True)
        time.sleep(3)
        screenshot(udid, "onboarding-en-light.png")

        # 2) DEBUG-only seed: render a realistic populated dashboard with both a
        # KEEP candidate and an urgent RETURN? candidate. Each launch carries a unique
        # DEBUG token; the host-side sentinel proves Swift code actually executed even
        # when the hosted runner's simctl client does not return promptly.
        launch(
            udid,
            "en",
            "en_US",
            onboarding=True,
            terminate=True,
            extra_arguments=["--keepMeterRuntimeSeed"],
        )
        time.sleep(4)
        screenshot(udid, "dashboard-populated-en-light.png")

        # 3) Relaunch WITHOUT the seed flag. The DEBUG persistence probe only reads
        # SwiftData and writes a sentinel when the expected records/usage/statuses survived.
        simctl(["ui", udid, "appearance", "dark"], timeout=20)
        remove_host_sentinels(udid, PERSISTENCE_SENTINEL)
        launch(
            udid,
            "de",
            "de_DE",
            onboarding=True,
            terminate=True,
            extra_arguments=["--keepMeterRuntimeProbe"],
        )
        require_persistence_sentinel(udid)
        time.sleep(2)
        screenshot(udid, "dashboard-persisted-de-dark.png")

        # 4) Final clean relaunch: only the generic DEBUG launch probe remains; there
        # are no seed/persistence-probe arguments. A new token proves a new app launch.
        launch(udid, "de", "de_DE", onboarding=True, terminate=True)
        time.sleep(2)

        print("✓ Fresh-install Light/English onboarding rendered", flush=True)
        print("✓ DEBUG-only realistic purchase data seeded into SwiftData", flush=True)
        print("✓ Populated Light/English dashboard rendered", flush=True)
        print("✓ Seeded purchases survived terminate/relaunch without reseeding", flush=True)
        print("✓ Persisted Dark/German dashboard rendered", flush=True)
        print("✓ Final clean relaunch executed Swift code without seed/probe arguments", flush=True)
        print("✓ Populated runtime screenshots captured", flush=True)
        print("KeepMeter populated simulator runtime smoke passed", flush=True)
        return 0
    finally:
        best_effort_simctl(["terminate", udid, BUNDLE_ID], timeout=8)
        best_effort_simctl(["shutdown", udid], timeout=15)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeSmokeError as exc:
        print(f"::error title=Runtime smoke::{exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
