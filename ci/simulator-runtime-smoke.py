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
SCREENSHOT_VALIDATOR = Path("/tmp/keepmeter-runtime-screenshot-signal")
DEFAULT_APP_PATH = Path("/tmp/keepmeter-debug-derived/Build/Products/Debug-iphonesimulator/KeepMeter.app")
PERSISTENCE_SENTINEL = "keepmeter-runtime-persistence-ok.txt"
LAUNCH_SENTINEL = "keepmeter-runtime-launch-ok.txt"
LAUNCH_PROBE_ARGUMENT = "--keepMeterRuntimeLaunchProbe"
LAUNCH_TOKEN_PREFIX = "--keepMeterRuntimeLaunchToken="
MAX_SIMULATOR_SETUP_ATTEMPTS = 2


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


def simulator_candidates() -> list[tuple[str, str, tuple[int, int]]]:
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

    candidates.sort(reverse=True)
    return [(udid, name, version) for version, _, name, udid in candidates]


def device_state(udid: str) -> str:
    for devices in available_devices().get("devices", {}).values():
        for device in devices:
            if device.get("udid") == udid:
                return device.get("state", "Unknown")
    return "Missing"


def installation_services_responsive(udid: str) -> bool:
    try:
        result = simctl(["listapps", udid], timeout=12, check=False, quiet=True)
    except RuntimeSmokeError as exc:
        print(f"Simulator app-service health probe timed out: {exc}", flush=True)
        return False

    if result.returncode != 0:
        print("Simulator app-service health probe returned a failure", flush=True)
        return False

    print("✓ Simulator app installation services respond", flush=True)
    return True


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
        print(f"bootstatus did not complete; checking app installation services directly: {exc}", flush=True)
        if not installation_services_responsive(udid):
            raise RuntimeSmokeError(
                "Simulator reached Booted state but CoreSimulator app installation services never became responsive"
            ) from exc
        time.sleep(3)


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


def prepare_runtime_simulator(app_path: Path) -> tuple[str, str, tuple[int, int], Path]:
    candidates = simulator_candidates()
    if not candidates:
        raise RuntimeSmokeError("No available iPhone simulator found on the runner")

    attempt_count = min(MAX_SIMULATOR_SETUP_ATTEMPTS, len(candidates))
    failures: list[str] = []

    for index, (udid, name, version) in enumerate(candidates[:attempt_count], start=1):
        print(
            f"Runtime environment attempt {index}/{attempt_count}: "
            f"{name}, iOS {version[0]}.{version[1]}, {udid}",
            flush=True,
        )
        try:
            wait_for_boot(udid)
            installed_app = ensure_installed(udid, app_path)
            print(f"✓ App installed at {installed_app}", flush=True)
            return udid, name, version, installed_app
        except RuntimeSmokeError as exc:
            failures.append(f"{name} iOS {version[0]}.{version[1]}: {exc}")
            print(f"Runtime environment attempt {index} failed before app execution: {exc}", flush=True)
            best_effort_simctl(["terminate", udid, BUNDLE_ID], timeout=5)
            best_effort_simctl(["shutdown", udid], timeout=8)

            if index < attempt_count:
                print("Retrying setup once on a different available iPhone simulator…", flush=True)

    detail = " | ".join(failures)
    raise RuntimeSmokeError(
        f"No healthy simulator environment could install KeepMeter after {attempt_count} bounded attempts: {detail}"
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


def matching_host_sentinel(udid: str, filename: str, expected_content: str) -> Path | None:
    for path in sentinel_candidates(udid, filename):
        try:
            content = path.read_text(encoding="utf-8").strip()
        except (FileNotFoundError, OSError, UnicodeError):
            continue
        if content == expected_content:
            return path
    return None


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
        path = matching_host_sentinel(udid, filename, expected_content)
        if path is not None:
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
        result = simctl(args, timeout=15)
        output = result.stdout.strip()
        if f"{BUNDLE_ID}:" not in output:
            print(f"Launch returned unexpected output; using active-scene probe as authority: {output!r}", flush=True)
    except RuntimeSmokeError as exc:
        command_error = exc
        print(f"Launch command did not return cleanly; verifying foreground execution: {exc}", flush=True)

    for attempt in range(1, 11):
        if matching_host_sentinel(udid, LAUNCH_SENTINEL, launch_token) is not None:
            print(f"✓ Active SwiftUI scene verified on poll {attempt}/10", flush=True)
            return output or f"{BUNDLE_ID}: verified-by-active-scene-sentinel"
        time.sleep(1)

    print("Active scene not visible yet; nudging KeepMeter to the foreground", flush=True)
    try:
        simctl(["launch", udid, BUNDLE_ID], timeout=10, check=False)
    except RuntimeSmokeError as exc:
        print(f"Foreground nudge did not return promptly: {exc}", flush=True)

    try:
        wait_for_host_sentinel(
            udid,
            LAUNCH_SENTINEL,
            launch_token,
            attempts=35,
            interval=1,
            label="Active SwiftUI scene sentinel",
        )
    except RuntimeSmokeError as exc:
        if command_error is not None:
            raise RuntimeSmokeError(f"{command_error}; additionally, {exc}") from exc
        raise

    return output or f"{BUNDLE_ID}: verified-by-active-scene-sentinel"


def screenshot(udid: str, filename: str) -> Path:
    path = SCREENSHOT_DIR / filename
    simctl(["io", udid, "screenshot", str(path)], timeout=45)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeSmokeError(f"Runtime screenshot is missing or empty: {path}")
    command(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], timeout=15)
    command([str(SCREENSHOT_VALIDATOR), str(path)], timeout=20)
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

    command(
        ["xcrun", "swiftc", "ci/RuntimeScreenshotSignal.swift", "-o", str(SCREENSHOT_VALIDATOR)],
        timeout=90,
    )

    udid, name, version, _ = prepare_runtime_simulator(app_path)
    print(f"Using healthy simulator: {name}, iOS {version[0]}.{version[1]}, {udid}", flush=True)

    try:
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

        simctl(["ui", udid, "appearance", "light"], timeout=20)
        launch(udid, "en", "en_US", onboarding=False, terminate=True)
        time.sleep(5)
        screenshot(udid, "onboarding-en-light.png")

        launch(
            udid,
            "en",
            "en_US",
            onboarding=True,
            terminate=True,
            extra_arguments=["--keepMeterRuntimeSeed"],
        )
        time.sleep(10)
        screenshot(udid, "dashboard-populated-en-light.png")

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
        time.sleep(8)
        screenshot(udid, "dashboard-persisted-de-dark.png")

        launch(udid, "de", "de_DE", onboarding=True, terminate=True)
        time.sleep(3)

        print("✓ Fresh-install Light/English onboarding rendered", flush=True)
        print("✓ DEBUG-only realistic purchase data seeded into SwiftData", flush=True)
        print("✓ Populated Light/English dashboard rendered", flush=True)
        print("✓ Seeded purchases survived terminate/relaunch without reseeding", flush=True)
        print("✓ Persisted Dark/German dashboard rendered from an active scene", flush=True)
        print("✓ Final clean relaunch reached an active SwiftUI scene without seed/probe arguments", flush=True)
        print("✓ Runtime screenshots passed visual-signal validation", flush=True)
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
