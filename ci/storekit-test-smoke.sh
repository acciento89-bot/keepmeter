#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
harness="$(mktemp -d /tmp/keepmeter-storekit-harness.XXXXXX)"
trap 'rm -rf "$harness"' EXIT

mkdir -p \
  "$harness/Sources/KeepMeterEntitlement" \
  "$harness/Tests/KeepMeterEntitlementTests/Resources"

# Compile the real production entitlement implementation, not a test double or copy
# maintained separately in the repository.
cp "$repo_root/KeepMeter/Services/EntitlementStore.swift" \
  "$harness/Sources/KeepMeterEntitlement/EntitlementStore.swift"
cp "$repo_root/KeepMeter/StoreKit/KeepMeter.storekit" \
  "$harness/Tests/KeepMeterEntitlementTests/Resources/KeepMeter.storekit"
cp "$repo_root/ci/StoreKitEntitlementTests.swift" \
  "$harness/Tests/KeepMeterEntitlementTests/StoreKitEntitlementTests.swift"

cat > "$harness/Package.swift" <<'SWIFT'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeepMeterStoreKitHarness",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "KeepMeterEntitlement", targets: ["KeepMeterEntitlement"])
    ],
    targets: [
        .target(
            name: "KeepMeterEntitlement",
            path: "Sources/KeepMeterEntitlement"
        ),
        .testTarget(
            name: "KeepMeterEntitlementTests",
            dependencies: ["KeepMeterEntitlement"],
            path: "Tests/KeepMeterEntitlementTests",
            resources: [
                .copy("Resources/KeepMeter.storekit")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
SWIFT

printf 'StoreKitTest harness: %s\n' "$harness"
/usr/bin/xcrun swift --version
/usr/bin/xcrun swift test --package-path "$harness"

echo "✓ StoreKitTest exercised production EntitlementStore against KeepMeter.storekit"
