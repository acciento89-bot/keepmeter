#!/bin/bash
set -euo pipefail

settings_file="$(mktemp)"
icon_info_file="$(mktemp)"
trap 'rm -f "$settings_file" "$icon_info_file"' EXIT

xcodebuild \
  -project KeepMeter.xcodeproj \
  -scheme KeepMeter \
  -configuration Release \
  -sdk iphonesimulator \
  -showBuildSettings > "$settings_file"

setting_value() {
  local key="$1"
  awk -F ' = ' -v key="$key" '$1 ~ "^[[:space:]]*" key "$" { print $2; exit }' "$settings_file"
}

assert_setting() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(setting_value "$key")"

  if [[ "$actual" != "$expected" ]]; then
    echo "::error title=Release preflight::$key expected '$expected' but found '${actual:-<missing>}'"
    exit 1
  fi

  echo "✓ $key = $actual"
}

assert_setting CONFIGURATION Release
assert_setting PRODUCT_BUNDLE_IDENTIFIER de.kamilunavo.keepmeter
assert_setting MARKETING_VERSION 0.1.0
assert_setting CURRENT_PROJECT_VERSION 1
assert_setting GENERATE_INFOPLIST_FILE YES
assert_setting IPHONEOS_DEPLOYMENT_TARGET 17.0
assert_setting TARGETED_DEVICE_FAMILY 1
assert_setting INFOPLIST_KEY_CFBundleDisplayName KeepMeter
assert_setting INFOPLIST_KEY_LSApplicationCategoryType public.app-category.utilities
assert_setting ASSETCATALOG_COMPILER_APPICON_NAME AppIcon

marketing_version="$(setting_value MARKETING_VERSION)"
build_number="$(setting_value CURRENT_PROJECT_VERSION)"

if [[ ! "$marketing_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error title=Release preflight::MARKETING_VERSION must use semantic x.y.z form"
  exit 1
fi

if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "::error title=Release preflight::CURRENT_PROJECT_VERSION must be a positive integer"
  exit 1
fi

asset_catalog="KeepMeter/Assets.xcassets"
app_icon_dir="$asset_catalog/AppIcon.appiconset"
app_icon_json="$app_icon_dir/Contents.json"
app_icon_png="$app_icon_dir/AppIcon.png"

for required_path in "$asset_catalog/Contents.json" "$app_icon_json" "$app_icon_png"; do
  if [[ ! -s "$required_path" ]]; then
    echo "::error title=Release asset blocker::Required AppIcon asset is missing or empty: $required_path"
    exit 1
  fi
done

python3 -m json.tool "$asset_catalog/Contents.json" >/dev/null
python3 -m json.tool "$app_icon_json" >/dev/null
grep -F '"filename" : "AppIcon.png"' "$app_icon_json" >/dev/null
grep -F '"size" : "1024x1024"' "$app_icon_json" >/dev/null

sips -g pixelWidth -g pixelHeight -g hasAlpha "$app_icon_png" > "$icon_info_file"
grep -F 'pixelWidth: 1024' "$icon_info_file" >/dev/null
grep -F 'pixelHeight: 1024' "$icon_info_file" >/dev/null

if ! grep -F 'hasAlpha: no' "$icon_info_file" >/dev/null; then
  echo "::error title=Release asset blocker::AppIcon.png must be fully opaque with no alpha channel"
  cat "$icon_info_file"
  exit 1
fi

echo "✓ AppIcon asset catalog = AppIcon"
echo "✓ AppIcon.png = 1024x1024, opaque"

privacy_manifest="KeepMeter/PrivacyInfo.xcprivacy"
if [[ ! -s "$privacy_manifest" ]]; then
  echo "::error title=Privacy manifest::PrivacyInfo.xcprivacy is missing or empty"
  exit 1
fi

plutil -lint "$privacy_manifest" >/dev/null
grep -F 'PrivacyInfo.xcprivacy in Resources' KeepMeter.xcodeproj/project.pbxproj >/dev/null

python3 - <<'PY'
import plistlib
from pathlib import Path

path = Path("KeepMeter/PrivacyInfo.xcprivacy")
with path.open("rb") as handle:
    manifest = plistlib.load(handle)

if manifest.get("NSPrivacyTracking") is not False:
    raise SystemExit("Privacy manifest must explicitly declare NSPrivacyTracking = false")

if manifest.get("NSPrivacyTrackingDomains") != []:
    raise SystemExit("KeepMeter v1 must not declare tracking domains")

if manifest.get("NSPrivacyCollectedDataTypes") != []:
    raise SystemExit("KeepMeter v1 local-first manifest must not declare collected data types")

entries = manifest.get("NSPrivacyAccessedAPITypes")
if not isinstance(entries, list):
    raise SystemExit("NSPrivacyAccessedAPITypes must be an array")

user_defaults_entries = [
    entry for entry in entries
    if entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"
]

if len(user_defaults_entries) != 1:
    raise SystemExit("Exactly one UserDefaults required-reason entry is required")

reasons = user_defaults_entries[0].get("NSPrivacyAccessedAPITypeReasons")
if reasons != ["CA92.1"]:
    raise SystemExit(f"UserDefaults reasons must be exactly ['CA92.1']; found {reasons!r}")

print("✓ Privacy manifest declares no tracking/no collected data for current v1")
print("✓ UserDefaults required reason = CA92.1")
PY

echo "KeepMeter Release preflight completed"
