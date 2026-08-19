#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUNDLE_ID = "de.kamilunavo.keepmeter"
SCREENSHOT_DIR = Path("/tmp/keepmeter-runtime")
DEFAULT_APP_PATH = Path("/tmp/keepmeter-debug-derived/Build/Products/Debug-iphonesimulator/KeepMeter.app")
PERSISTENCE_SENTINEL = "keepmeter-runtime-persistence-ok.txt"


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


def launch(
    udid: str,
    language: str,
    locale: str,
    onboarding: bool,
    terminate: bool,
    extra_arguments: list[str] | None = None,
) -> str:
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
    ])
    if extra_arguments:
        args.extend(extra_arguments)

    result = simctl(args, timeout=45)
    output = result.stdout.strip()
    if f"{BUNDLE_ID}:" not in output:
        raise RuntimeSmokeError(f"Unexpected simctl launch output: {output!r}")
    return output


def screenshot(udid: str, filename: str) -> Path:
    path = SCREENSHOT_DIR / filename
    simctl(["io", udid, "screenshot", str(path)], timeout=45)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeSmokeError(f"Runtime screenshot is missing or empty: {path}")
    command(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], timeout=15)
    return path


def require_persistence_sentinel(udid: str) -> Path:
    for attempt in range(1, 16):
        data_container = app_container(udid, "data")
        if data_container is not None:
            sentinel = data_container / "Documents" / PERSISTENCE_SENTINEL
            if sentinel.is_file() and sentinel.read_text(encoding="utf-8").strip() == "ok":
                print(f"✓ Runtime SwiftData persistence sentinel found on poll {attempt}/15", flush=True)
                return sentinel
        print(f"Persistence sentinel [{attempt}/15]: not ready yet", flush=True)
        time.sleep(1)

    raise RuntimeSmokeError(
        "Debug persistence probe did not verify the seeded SwiftData purchases after terminate/relaunch"
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
        best_effort_simctl(["terminate", udid, BUNDLE_ID], timeout=15)

        # 2) DEBUG-only seed: render a realistic populated dashboard with both a
        # KEEP candidate and an urgent RETURN? candidate.
        launch(
            udid,
            "en",
            "en_US",
            onboarding=True,
            terminate=False,
            extra_arguments=["--keepMeterRuntimeSeed"],
        )
        time.sleep(4)
        screenshot(udid, "dashboard-populated-en-light.png")
        best_effort_simctl(["terminate", udid, BUNDLE_ID], timeout=15)

        # 3) Relaunch WITHOUT the seed flag. The DEBUG probe only reads SwiftData and
        # writes a sentinel when the expected persisted records/usage/statuses survived.
        simctl(["ui", udid, "appearance", "dark"], timeout=20)
        launch(
            udid,
            "de",
            "de_DE",
            onboarding=True,
            terminate=False,
            extra_arguments=["--keepMeterRuntimeProbe"],
        )
        time.sleep(4)
        require_persistence_sentinel(udid)
        screenshot(udid, "dashboard-persisted-de-dark.png")

        best_effort_simctl(["terminate", udid, BUNDLE_ID], timeout=15)

        # 4) Final clean relaunch: no seed/probe arguments. This proves the ordinary
        # app still starts from the now-populated persisted store.
        launch(udid, "de", "de_DE", onboarding=True, terminate=False)
        time.sleep(2)

        if app_container(udid, "data") is None:
            raise RuntimeSmokeError("App data container is unavailable after successful populated relaunch")

        print("✓ Fresh-install Light/English onboarding rendered", flush=True)
        print("✓ DEBUG-only realistic purchase data seeded into SwiftData", flush=True)
        print("✓ Populated Light/English dashboard rendered", flush=True)
        print("✓ Seeded purchases survived terminate/relaunch without reseeding", flush=True)
        print("✓ Persisted Dark/German dashboard rendered", flush=True)
        print("✓ Final clean relaunch succeeded without QA arguments", flush=True)
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
