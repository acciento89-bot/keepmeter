#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

STRING_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$')
PLACEHOLDER_RE = re.compile(r'%(?:\d+\$)?(?:ld|lld|lu|llu|[diuoxXfFeEgGaAcCsSp@])')


def parse(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
            continue
        match = STRING_RE.match(raw)
        if not match:
            raise SystemExit(f"{path}:{line_no}: unsupported or malformed .strings entry")
        key, value = match.groups()
        if key in result:
            raise SystemExit(f"{path}:{line_no}: duplicate localization key: {key}")
        if value == "":
            raise SystemExit(f"{path}:{line_no}: empty localization value: {key}")
        result[key] = value
    return result


def placeholders(value: str) -> list[str]:
    return PLACEHOLDER_RE.findall(value.replace("%%", ""))


def main() -> int:
    en_path = Path("KeepMeter/en.lproj/Localizable.strings")
    de_path = Path("KeepMeter/de.lproj/Localizable.strings")

    en = parse(en_path)
    de = parse(de_path)

    en_keys = set(en)
    de_keys = set(de)

    missing_de = sorted(en_keys - de_keys)
    missing_en = sorted(de_keys - en_keys)

    if missing_de:
        print("Missing German keys:")
        for key in missing_de:
            print(f"  - {key}")
    if missing_en:
        print("Missing English keys:")
        for key in missing_en:
            print(f"  - {key}")
    if missing_de or missing_en:
        return 1

    placeholder_errors: list[str] = []
    for key in sorted(en_keys):
        en_placeholders = placeholders(en[key])
        de_placeholders = placeholders(de[key])
        if en_placeholders != de_placeholders:
            placeholder_errors.append(
                f"{key}: EN placeholders {en_placeholders} != DE placeholders {de_placeholders}"
            )

    if placeholder_errors:
        print("Localization placeholder mismatches:")
        for error in placeholder_errors:
            print(f"  - {error}")
        return 1

    print(f"✓ EN/DE localization key parity: {len(en_keys)} keys")
    print("✓ No duplicate or empty localization entries")
    print("✓ Format placeholders match between EN and DE")
    print("KeepMeter localization preflight passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
