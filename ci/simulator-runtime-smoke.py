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


def available_devices() -> dict:
    completed = simctl(["list", "devices", "available", "-j"], timeout=15, quiet=True)
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
    simctl(["boot", udid], timeout=15, check=False)
    for attempt in range(1, 61):
        state = device_state(udid)
        print(f"Simulator state [{attempt}/60]: {state}", flush=True)
        if state == "Booted":
            print("✓ Simulator reached Booted state", flush=True)
            return
        time.sleep(2)
    raise RuntimeSmokeError("Simulator did not reach Booted state inside the bounded boot window")


def launch(udid: str, language: str, locale: str, onboarding: bool, terminate: bool) -> str:
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
    result = simctl(args, timeout=30)
    output = result.stdout.strip()
    if f"{BUNDLE_ID}:" not in output:
        raise RuntimeSmokeError(f"Unexpected simctl launch output: {output!r}")
    return output


def screenshot(udid: str, filename: str) -> Path:
    path = SCREENSHOT_DIR / filename
    simctl(["io", udid, "screenshot", str(path)], timeout=30)
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeSmokeError(f"Runtime screenshot is missing or empty: {path}")
    command(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], timeout=15)
    return path


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

        simctl(["uninstall", udid, BUNDLE_ID], timeout=15, check=False, quiet=True)
        simctl(["install", udid, str(app_path)], timeout=45)

        container = simctl(["get_app_container", udid, BUNDLE_ID, "data"], timeout=15).stdout.strip()
        if not container or not Path(container).is_dir():
            raise RuntimeSmokeError("Installed app data container could not be resolved")
        print("✓ App installed and data container exists", flush=True)

        simctl(
            [
                "status_bar", udid, "override",
                "--time", "09:41",
                "--batteryState", "charged",
                "--batteryLevel", "100",
                "--wifiBars", "3",
                "--cellularBars", "4",
            ],
            timeout=10,
            check=False,
            quiet=True,
        )

        simctl(["ui", udid, "appearance", "light"], timeout=15)
        launch(udid, "en", "en_US", onboarding=False, terminate=True)
        time.sleep(2)
        screenshot(udid, "onboarding-en-light.png")

        simctl(["terminate", udid, BUNDLE_ID], timeout=15)

        simctl(["ui", udid, "appearance", "dark"], timeout=15)
        launch(udid, "de", "de_DE", onboarding=True, terminate=False)
        time.sleep(2)
        screenshot(udid, "dashboard-de-dark.png")

        simctl(["terminate", udid, BUNDLE_ID], timeout=15)
        launch(udid, "de", "de_DE", onboarding=True, terminate=False)
        time.sleep(1)

        print("✓ KeepMeter launched in Light/English runtime", flush=True)
        print("✓ KeepMeter launched in Dark/German runtime", flush=True)
        print("✓ KeepMeter terminated and relaunched successfully", flush=True)
        print("✓ Runtime screenshots captured", flush=True)
        print("KeepMeter simulator runtime smoke passed", flush=True)
        return 0
    finally:
        simctl(["terminate", udid, BUNDLE_ID], timeout=10, check=False, quiet=True)
        simctl(["shutdown", udid], timeout=20, check=False, quiet=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeSmokeError as exc:
        print(f"::error title=Runtime smoke::{exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
