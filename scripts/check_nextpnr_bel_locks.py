#!/usr/bin/env python3
"""Assert that a placed nextpnr JSON satisfies an UberDDR3 BEL lock file."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locks-json", required=True, type=Path)
    parser.add_argument("--placed-json", required=True, type=Path)
    parser.add_argument("--allow-missing", action="store_true")
    args = parser.parse_args()

    locks = json.loads(args.locks_json.read_text(encoding="utf-8"))["locks"]
    data = json.loads(args.placed_json.read_text(encoding="utf-8"))
    cells = top_module(data).get("cells", {})

    missing = []
    mismatched = []
    for lock in locks:
        name = lock["cell"]
        expected = lock["bel"]
        cell = cells.get(name)
        if cell is None:
            missing.append(lock)
            continue
        actual = cell.get("attributes", {}).get("NEXTPNR_BEL")
        if actual != expected:
            mismatched.append({
                "cell": name,
                "type": lock.get("type", ""),
                "scope": lock.get("scope", ""),
                "expected": expected,
                "actual": actual,
            })

    if missing and not args.allow_missing:
        raise SystemExit(f"missing locked cells: {missing[:16]}")
    if mismatched:
        raise SystemExit(f"BEL lock mismatches: {mismatched[:16]}")

    print(f"BEL locks verified: checked={len(locks)} missing={len(missing)} placed={args.placed_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
