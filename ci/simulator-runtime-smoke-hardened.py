#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
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


runtime.screenshot = hardened_screenshot

if __name__ == "__main__":
    try:
        raise SystemExit(runtime.main())
    except runtime.RuntimeSmokeError as exc:
        print(f"::error title=Runtime smoke::{exc}", flush=True)
        raise SystemExit(1)
