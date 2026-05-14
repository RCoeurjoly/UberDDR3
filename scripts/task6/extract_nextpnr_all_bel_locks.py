#!/usr/bin/env python3
"""Extract every placed nextpnr cell BEL from a routed JSON as lock records."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
from typing import Any


def load_top_cells(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    modules = data["modules"]
    if "top" in modules:
        return modules["top"]["cells"]
    if len(modules) == 1:
        return next(iter(modules.values()))["cells"]
    for module in modules.values():
        if module.get("attributes", {}).get("top") == "00000000000000000000000000000001":
            return module["cells"]
    raise KeyError(f"could not identify top module in {path}")


def extract_locks(routed_json: Path, scope: str) -> dict[str, Any]:
    cells = load_top_cells(routed_json)
    locks: list[dict[str, str]] = []
    skipped = 0
    for name, cell in sorted(cells.items()):
        bel = cell.get("attributes", {}).get("NEXTPNR_BEL")
        if not bel:
            skipped += 1
            continue
        locks.append({
            "cell": name,
            "type": str(cell.get("type", "")),
            "scope": scope,
            "bel": str(bel),
        })

    return {
        "format": "task6.nextpnr-all-bel-locks.v1",
        "source_routed_json": str(routed_json),
        "lock_count": len(locks),
        "skipped_missing_bel_count": skipped,
        "type_counts": dict(sorted(Counter(lock["type"] for lock in locks).items())),
        "scope_counts": {scope: len(locks)},
        "locks": locks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--routed-json", required=True, type=Path)
    parser.add_argument("--out-json", required=True, type=Path)
    parser.add_argument("--scope", default="all_seed3")
    args = parser.parse_args()

    report = extract_locks(args.routed_json, args.scope)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({
        "lock_count": report["lock_count"],
        "skipped_missing_bel_count": report["skipped_missing_bel_count"],
        "type_counts": report["type_counts"],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
