#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
QA_DIR=$(mktemp -d "${TMPDIR:-/tmp}/keepmeter-purchase-centre.XXXXXX")
trap 'rm -rf "$QA_DIR"' EXIT
xcrun --sdk macosx swiftc -parse-as-library KeepMeter/Services/PurchaseCSV.swift ci/PurchaseCSVSmoke.swift -o "$QA_DIR/csv"
"$QA_DIR/csv"
xcrun --sdk macosx swiftc -parse-as-library KeepMeter/Services/PurchaseFilter.swift ci/PurchaseFilterSmoke.swift -o "$QA_DIR/filter"
"$QA_DIR/filter"
xcrun --sdk macosx swiftc -parse-as-library ci/fixtures/Purchase-v1.swift KeepMeter/Models/UsageEvent.swift ci/PurchaseMigrationSmoke.swift -framework SwiftData -o "$QA_DIR/legacy"
xcrun --sdk macosx swiftc -DNEW_SCHEMA -parse-as-library KeepMeter/Models/Purchase.swift KeepMeter/Models/UsageEvent.swift ci/PurchaseMigrationSmoke.swift -framework SwiftData -o "$QA_DIR/current"
"$QA_DIR/legacy" seed "$QA_DIR/purchases.store"
"$QA_DIR/current" migrate "$QA_DIR/purchases.store"
"$QA_DIR/current" verify "$QA_DIR/purchases.store"
