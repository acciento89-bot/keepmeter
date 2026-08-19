#!/usr/bin/env python3
import json
from pathlib import Path

STOREKIT_PATH = Path("KeepMeter/StoreKit/KeepMeter.storekit")
EXPECTED_PRODUCT_ID = "de.kamilunavo.keepmeter.pro.lifetime"
EXPECTED_REFERENCE_NAME = "KeepMeter Lifetime Pro"
EXPECTED_TYPE = "NonConsumable"
EXPECTED_LOCALIZATIONS = {
    "de_DE": {
        "displayName": "KeepMeter Pro – Lifetime",
        "description": "Unbegrenzt aktive Käufe. Einmal zahlen.",
    },
    "en_US": {
        "displayName": "KeepMeter Pro Lifetime",
        "description": "Unlimited active purchases. Pay once.",
    },
}


def fail(message: str) -> None:
    raise SystemExit(f"StoreKit metadata preflight failed: {message}")


def main() -> None:
    data = json.loads(STOREKIT_PATH.read_text(encoding="utf-8"))
    products = data.get("products", [])
    if len(products) != 1:
        fail(f"expected exactly one v1 StoreKit product, found {len(products)}")

    product = products[0]
    if product.get("productID") != EXPECTED_PRODUCT_ID:
        fail("Lifetime Pro product ID drifted")
    if product.get("referenceName") != EXPECTED_REFERENCE_NAME:
        fail("Lifetime Pro reference name drifted")
    if product.get("type") != EXPECTED_TYPE:
        fail("Lifetime Pro must remain NonConsumable")

    product_id = product["productID"]
    if len(product_id) > 100:
        fail("product ID exceeds App Store Connect 100-character limit")
    if len(product["referenceName"]) > 64:
        fail("reference name exceeds App Store Connect 64-character limit")

    localizations = product.get("localizations", [])
    by_locale = {item.get("locale"): item for item in localizations}
    if set(by_locale) != set(EXPECTED_LOCALIZATIONS):
        fail(
            f"expected localizations {sorted(EXPECTED_LOCALIZATIONS)}, "
            f"found {sorted(by_locale)}"
        )

    for locale, expected in EXPECTED_LOCALIZATIONS.items():
        item = by_locale[locale]
        display_name = item.get("displayName", "")
        description = item.get("description", "")

        if display_name != expected["displayName"]:
            fail(f"{locale} display name drifted from the App Store handoff")
        if description != expected["description"]:
            fail(f"{locale} description drifted from the App Store handoff")
        if not (2 <= len(display_name) <= 30):
            fail(f"{locale} display name length {len(display_name)} is outside 2...30")
        if not description or len(description) > 45:
            fail(f"{locale} description length {len(description)} exceeds 45 or is empty")

        print(f"✓ {locale} display name: {len(display_name)}/30 characters")
        print(f"✓ {locale} description: {len(description)}/45 characters")

    print(f"✓ Product ID = {EXPECTED_PRODUCT_ID}")
    print("✓ Product type = NonConsumable")
    print("✓ App Store handoff copy matches local StoreKit metadata")
    print("KeepMeter App Store IAP metadata preflight passed")


if __name__ == "__main__":
    main()
