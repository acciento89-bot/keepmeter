#!/bin/bash
set -euo pipefail

app_path="${1:-/tmp/keepmeter-debug-derived/Build/Products/Debug-iphonesimulator/KeepMeter.app}"
bundle_id="de.kamilunavo.keepmeter"
screenshot_dir="/tmp/keepmeter-runtime"

if [[ ! -d "$app_path" ]]; then
  echo "::error title=Runtime smoke::Debug app bundle not found at $app_path"
  exit 1
fi

mkdir -p "$screenshot_dir"
rm -f "$screenshot_dir"/*.png

udid="$(python3 - <<'PY'
import json
import re
import subprocess

payload = subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "-j"],
    text=True,
)
data = json.loads(payload)

candidates = []
for runtime, devices in data.get("devices", {}).items():
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
        # Prefer the newest installed iOS runtime, then a modern Pro device name.
        pro_score = 2 if "Pro" in name else 1 if "Plus" in name or "Max" in name else 0
        candidates.append((version, pro_score, name, device["udid"]))

if not candidates:
    raise SystemExit("No available iPhone simulator found")

candidates.sort()
print(candidates[-1][3])
PY
)"

cleanup() {
  xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Using simulator: $udid"
xcrun simctl boot "$udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$udid" -b

xcrun simctl uninstall "$udid" "$bundle_id" >/dev/null 2>&1 || true
xcrun simctl install "$udid" "$app_path"

container_path="$(xcrun simctl get_app_container "$udid" "$bundle_id" data)"
if [[ ! -d "$container_path" ]]; then
  echo "::error title=Runtime smoke::Installed app data container could not be resolved"
  exit 1
fi

echo "✓ App installed and data container exists"

# Stable status-bar values improve screenshot diffability. Do not fail the runtime smoke if
# a future Simulator runtime changes the status_bar command surface.
xcrun simctl status_bar "$udid" override \
  --time 09:41 \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4 >/dev/null 2>&1 || true

xcrun simctl ui "$udid" appearance light
light_launch="$(xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" \
  -AppleLanguages '(en)' \
  -AppleLocale en_US \
  -hasCompletedOnboarding NO)"
echo "$light_launch"
grep -F "$bundle_id:" <<<"$light_launch" >/dev/null
sleep 2
xcrun simctl io "$udid" screenshot "$screenshot_dir/onboarding-en-light.png" >/dev/null

xcrun simctl terminate "$udid" "$bundle_id"

xcrun simctl ui "$udid" appearance dark
dark_launch="$(xcrun simctl launch "$udid" "$bundle_id" \
  -AppleLanguages '(de)' \
  -AppleLocale de_DE \
  -hasCompletedOnboarding YES)"
echo "$dark_launch"
grep -F "$bundle_id:" <<<"$dark_launch" >/dev/null
sleep 2
xcrun simctl io "$udid" screenshot "$screenshot_dir/dashboard-de-dark.png" >/dev/null

# Explicit terminate/relaunch lifecycle smoke. This is not a data-persistence claim; the
# file-backed SwiftData reopen gate covers storage semantics separately.
xcrun simctl terminate "$udid" "$bundle_id"
relaunch="$(xcrun simctl launch "$udid" "$bundle_id" \
  -AppleLanguages '(de)' \
  -AppleLocale de_DE \
  -hasCompletedOnboarding YES)"
echo "$relaunch"
grep -F "$bundle_id:" <<<"$relaunch" >/dev/null
sleep 1

for screenshot in \
  "$screenshot_dir/onboarding-en-light.png" \
  "$screenshot_dir/dashboard-de-dark.png"; do
  test -s "$screenshot"
  sips -g pixelWidth -g pixelHeight "$screenshot"
done

echo "✓ KeepMeter launched in Light/English runtime"
echo "✓ KeepMeter launched in Dark/German runtime"
echo "✓ KeepMeter terminated and relaunched successfully"
echo "✓ Runtime screenshots captured"
echo "KeepMeter simulator runtime smoke passed"
