#!/usr/bin/env python3
import json
from pathlib import Path

PATH = Path("metadata/AppStoreListing.json")
REQUIRED_LOCALES = {"de-DE", "en-US"}
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "promotionalText": 170,
    "description": 4000,
}


def fail(message: str) -> None:
    raise SystemExit(f"App Store listing preflight failed: {message}")


def main() -> None:
    data = json.loads(PATH.read_text(encoding="utf-8"))
    if set(data) != REQUIRED_LOCALES:
        fail(f"expected locales {sorted(REQUIRED_LOCALES)}, found {sorted(data)}")

    for locale, fields in data.items():
        if fields.get("name") != "KeepMeter":
            fail(f"{locale} app name drifted from KeepMeter")

        for key, limit in LIMITS.items():
            value = fields.get(key, "")
            if not value:
                fail(f"{locale} {key} is empty")
            if len(value) > limit:
                fail(f"{locale} {key} is {len(value)} characters; limit is {limit}")
            print(f"✓ {locale} {key}: {len(value)}/{limit} characters")

        keywords = fields.get("keywords", "")
        keyword_bytes = len(keywords.encode("utf-8"))
        if not keywords:
            fail(f"{locale} keywords are empty")
        if keyword_bytes > 100:
            fail(f"{locale} keywords are {keyword_bytes} UTF-8 bytes; limit is 100")
        if " " in keywords:
            fail(f"{locale} keywords must remain comma-separated without spaces")
        print(f"✓ {locale} keywords: {keyword_bytes}/100 UTF-8 bytes")

    print("KeepMeter App Store listing metadata preflight passed")


if __name__ == "__main__":
    main()
