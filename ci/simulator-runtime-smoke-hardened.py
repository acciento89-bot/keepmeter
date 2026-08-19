#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
import time
from pathlib import Path

BASE_SCRIPT = Path(__file__).with_name("simulator-runtime-smoke.py")
SPEC = importlib.util.spec_from_file_location("keepmeter_runtime_smoke", BASE_SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load runtime smoke module from {BASE_SCRIPT}")

runtime = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runtime)

MIN_SCREENSHOT_BYTES = 4096
FILE_POLLS = 15
FILE_POLL_INTERVAL = 1.0
MAX_CAPTURE_ATTEMPTS = 2
APP_CONTAINER_POLLS_AFTER_REBOOT = 12

_original_launch = runtime.launch
_launch_recovery_used = False


def wait_for_stable_screenshot(path: Path) -> bool:
    previous_size: int | None = None
    stable_polls = 0

    for poll in range(1, FILE_POLLS + 1):
        try:
            size = path.stat().st_size
        except FileNotFoundError:
            size = 0

        if size >= MIN_SCREENSHOT_BYTES:
            if size == previous_size:
                stable_polls += 1
            else:
                stable_polls = 0
                previous_size = size

            if stable_polls >= 1:
                print(
                    f"✓ Screenshot file stabilized at {size} bytes on poll {poll}/{FILE_POLLS}",
                    flush=True,
                )
                return True
        else:
            previous_size = None
            stable_polls = 0

        print(
            f"Screenshot file poll [{poll}/{FILE_POLLS}]: {size} bytes",
            flush=True,
        )
        time.sleep(FILE_POLL_INTERVAL)

    return False


def validate_screenshot(path: Path) -> None:
    runtime.command(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
        timeout=15,
    )
    runtime.command([str(runtime.SCREENSHOT_VALIDATOR), str(path)], timeout=20)


def hardened_screenshot(udid: str, filename: str) -> Path:
    path = runtime.SCREENSHOT_DIR / filename
    failures: list[str] = []

    for capture_attempt in range(1, MAX_CAPTURE_ATTEMPTS + 1):
        try:
            path.unlink()
        except FileNotFoundError:
            pass

        print(
            f"Screenshot capture attempt {capture_attempt}/{MAX_CAPTURE_ATTEMPTS}: {filename}",
            flush=True,
        )

        try:
            runtime.simctl(["io", udid, "screenshot", str(path)], timeout=25)
            print("✓ simctl screenshot returned successfully", flush=True)
        except runtime.RuntimeSmokeError as exc:
            # Hosted CoreSimulator can complete the screenshot request after the
            # simctl client itself stops responding. The screenshot file plus the
            # existing native visual validator remain authoritative.
            failures.append(str(exc))
            print(
                f"Screenshot client did not return cleanly; polling the actual PNG: {exc}",
                flush=True,
            )

        if wait_for_stable_screenshot(path):
            try:
                validate_screenshot(path)
                print(
                    f"✓ Runtime screenshot validated on capture attempt {capture_attempt}/{MAX_CAPTURE_ATTEMPTS}",
                    flush=True,
                )
                return path
            except runtime.RuntimeSmokeError as exc:
                failures.append(str(exc))
                print(f"Screenshot validation failed: {exc}", flush=True)
        else:
            failures.append(f"Screenshot file never stabilized: {path}")

        if capture_attempt < MAX_CAPTURE_ATTEMPTS:
            print(
                "Retrying screenshot once on the same installed simulator; no device fallback is allowed after app installation.",
                flush=True,
            )
            time.sleep(2)

    detail = " | ".join(failures)
    raise runtime.RuntimeSmokeError(
        f"Runtime screenshot could not be captured and visually validated after "
        f"{MAX_CAPTURE_ATTEMPTS} bounded attempts on the same simulator: {detail}"
    )


def wait_for_installed_app_after_reboot(udid: str) -> Path:
    for poll in range(1, APP_CONTAINER_POLLS_AFTER_REBOOT + 1):
        container = runtime.app_container(udid)
        if container is not None:
            print(
                f"✓ Existing KeepMeter installation survived same-device reboot on poll "
                f"{poll}/{APP_CONTAINER_POLLS_AFTER_REBOOT}",
                flush=True,
            )
            return container
        print(
            f"Post-reboot app container [{poll}/{APP_CONTAINER_POLLS_AFTER_REBOOT}]: not visible yet",
            flush=True,
        )
        time.sleep(2)

    raise runtime.RuntimeSmokeError(
        "KeepMeter installation was not resolvable after the bounded same-device CoreSimulator reboot"
    )


def hardened_launch(
    udid: str,
    language: str,
    locale: str,
    onboarding: bool,
    terminate: bool,
    extra_arguments: list[str] | None = None,
) -> str:
    global _launch_recovery_used

    try:
        return _original_launch(
            udid,
            language,
            locale,
            onboarding,
            terminate,
            extra_arguments,
        )
    except runtime.RuntimeSmokeError as first_error:
        if _launch_recovery_used:
            raise

        _launch_recovery_used = True
        print(
            "Active-scene launch proof failed after a successful app install; performing one bounded reboot of the SAME simulator.",
            flush=True,
        )
        print(f"Initial launch failure: {first_error}", flush=True)

        runtime.best_effort_simctl(["terminate", udid, runtime.BUNDLE_ID], timeout=8)
        runtime.best_effort_simctl(["shutdown", udid], timeout=20)
        time.sleep(5)

        try:
            runtime.wait_for_boot(udid)
            wait_for_installed_app_after_reboot(udid)
        except runtime.RuntimeSmokeError as recovery_error:
            raise runtime.RuntimeSmokeError(
                f"{first_error}; same-device CoreSimulator reboot recovery also failed: {recovery_error}"
            ) from recovery_error

        print(
            "Retrying the launch proof once after same-device reboot; all normal active-scene assertions remain required.",
            flush=True,
        )
        return _original_launch(
            udid,
            language,
            locale,
            onboarding,
            terminate,
            extra_arguments,
        )


runtime.screenshot = hardened_screenshot
runtime.launch = hardened_launch

if __name__ == "__main__":
    try:
        raise SystemExit(runtime.main())
    except runtime.RuntimeSmokeError as exc:
        print(f"::error title=Runtime smoke::{exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
