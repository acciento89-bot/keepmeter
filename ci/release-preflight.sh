#!/bin/bash
set -euo pipefail

settings_file="$(mktemp)"
trap 'rm -f "$settings_file"' EXIT

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

app_icon_name="$(setting_value ASSETCATALOG_COMPILER_APPICON_NAME)"
app_icon_dir="KeepMeter/Assets.xcassets/AppIcon.appiconset"

if [[ -n "$app_icon_name" && -d "$app_icon_dir" && -f "$app_icon_dir/Contents.json" ]]; then
  echo "✓ App icon asset catalog configured: $app_icon_name"
else
  echo "::warning title=Release asset blocker::Final AppIcon asset catalog is not configured yet. Signed TestFlight/App Store readiness remains blocked until branding is locked and the AppIcon set is added."
fi

echo "KeepMeter Release preflight completed"
