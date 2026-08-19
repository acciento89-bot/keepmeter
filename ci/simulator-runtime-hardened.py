#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
import time
from pathlib import Path

CORE_PATH = Path(__file__).with_name("simulator-runtime-smoke.py")

spec = importlib.util.spec_from_file_location("keepmeter_runtime_core", CORE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Unable to load runtime smoke core: {CORE_PATH}")

runtime = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = runtime
spec.loader.exec_module(runtime)


def wait_for_materialized_png(
    path: Path,
    *,
    attempts: int = 15,
    interval: float = 1.0,
) -> bool:
    """Require a non-empty file whose size is stable across two polls."""
    previous_size: int | None = None
    stable_polls = 0

    for attempt in range(1, attempts + 1):
        try:
            size = path.stat().st_size
        except FileNotFoundError:
            size = 0

        if size > 0:
            if size == previous_size:
                stable_polls += 1
            else:
                stable_polls = 0

            if stable_polls >= 1:
                print(
                    f"✓ Screenshot file materialized and stabilized on poll {attempt}/{attempts} "
                    f"({size} bytes)",
                    flush=True,
                )
                return True
        else:
            stable_polls = 0

        previous_size = size
        print(
            f"Screenshot file [{attempt}/{attempts}]: "
            f"{'missing/empty' if size == 0 else f'{size} bytes, waiting for stability'}",
            flush=True,
        )
        time.sleep(interval)

    return False


def hardened_screenshot(udid: str, filename: str) -> Path:
    path = runtime.SCREENSHOT_DIR / filename
    errors: list[str] = []

    try:
        path.unlink()
    except FileNotFoundError:
        pass

    for capture_attempt in range(1, 3):
        print(f"Screenshot capture attempt {capture_attempt}/2: {filename}", flush=True)

        try:
            runtime.simctl(
                ["io", udid, "screenshot", str(path)],
                timeout=25,
            )
            print("✓ simctl screenshot returned successfully", flush=True)
        except runtime.RuntimeSmokeError as exc:
            errors.append(str(exc))
            print(
                "Screenshot command did not return cleanly; the materialized PNG is the evidence authority: "
                f"{exc}",
                flush=True,
            )

        if wait_for_materialized_png(path):
            break

        if capture_attempt < 2:
            print("Screenshot file did not materialize; retrying capture once", flush=True)
            try:
                path.unlink()
            except FileNotFoundError:
                pass
    else:
        detail = " | ".join(errors) if errors else "no command error was reported"
        raise runtime.RuntimeSmokeError(
            f"Runtime screenshot never materialized after two bounded capture attempts: {path}; {detail}"
        )

    # A command timeout is recoverable only when the resulting file is real and then
    # passes the same strict image/dimension and visual-signal validation as before.
    runtime.command(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
        timeout=15,
    )
    runtime.command([str(runtime.SCREENSHOT_VALIDATOR), str(path)], timeout=20)
    print(f"✓ Screenshot evidence validated: {path}", flush=True)
    return path


runtime.screenshot = hardened_screenshot


if __name__ == "__main__":
    try:
        raise SystemExit(runtime.main())
    except runtime.RuntimeSmokeError as exc:
        print(f"::error title=Runtime smoke::{exc}", file=sys.stderr, flush=True)
        raise SystemExit(1)
