#!/usr/bin/env python3
"""Extract selected BEL locks from a nextpnr --write JSON artifact."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


def load_top_cells(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    for module in data["modules"].values():
        if module.get("attributes", {}).get("top") == "00000000000000000000000000000001":
            return module["cells"]
    if "top" in data["modules"]:
        return data["modules"]["top"]["cells"]
    if len(data["modules"]) == 1:
        return next(iter(data["modules"].values()))["cells"]
    raise KeyError("could not identify top module")


def parse_prefix_scope(values: list[str]) -> list[tuple[str, str]]:
    parsed = []
    for value in values:
        if "=" not in value:
            raise ValueError("prefix scope must be SCOPE=PREFIX")
        scope, prefix = value.split("=", 1)
        if not scope or not prefix:
            raise ValueError("prefix scope must be SCOPE=PREFIX")
        parsed.append((scope, prefix))
    return parsed


def parse_typed_attr_substrings(values: list[str]) -> list[tuple[str, str, str, str]]:
    parsed = []
    for value in values:
        if "=" not in value:
            raise ValueError("typed attr substring must be SCOPE=TYPE:ATTR:TEXT")
        scope, selector = value.split("=", 1)
        parts = selector.split(":", 2)
        if not scope or len(parts) != 3 or not all(parts):
            raise ValueError("typed attr substring must be SCOPE=TYPE:ATTR:TEXT")
        cell_type, attr_name, needle = parts
        parsed.append((scope, cell_type, attr_name, needle))
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--placed-json", required=True, type=Path)
    parser.add_argument("--out-json", required=True, type=Path)
    parser.add_argument("--include-cell-prefix", action="append", default=[])
    parser.add_argument("--include-type", action="append", default=[])
    parser.add_argument("--include-typed-attr-substring", action="append", default=[])
    args = parser.parse_args()

    cells = load_top_cells(args.placed_json)
    prefix_scopes = parse_prefix_scope(args.include_cell_prefix)
    typed_attr_substrings = parse_typed_attr_substrings(args.include_typed_attr_substring)
    include_types = set(args.include_type)
    locks = []
    skipped_missing_bel = []

    for name, cell in sorted(cells.items()):
        cell_type = cell.get("type", "")
        scope = None
        for candidate_scope, prefix in prefix_scopes:
            if name.startswith(prefix):
                scope = candidate_scope
                break
        if scope is None:
            attrs = cell.get("attributes", {})
            for candidate_scope, candidate_type, attr_name, needle in typed_attr_substrings:
                if cell_type == candidate_type and needle in str(attrs.get(attr_name, "")):
                    scope = candidate_scope
                    break
        if scope is None and cell_type in include_types:
            scope = "selected_type"
        if scope is None:
            continue

        bel = cell.get("attributes", {}).get("NEXTPNR_BEL")
        if not bel:
            skipped_missing_bel.append({"cell": name, "type": cell_type, "scope": scope})
            continue
        locks.append({"cell": name, "type": cell_type, "scope": scope, "bel": bel})

    report = {
        "format": "uberddr3.nextpnr-bel-locks.v1",
        "source_placed_json": str(args.placed_json),
        "lock_count": len(locks),
        "type_counts": dict(sorted(Counter(lock["type"] for lock in locks).items())),
        "scope_counts": dict(sorted(Counter(lock["scope"] for lock in locks).items())),
        "skipped_missing_bel_count": len(skipped_missing_bel),
        "skipped_missing_bel": skipped_missing_bel,
        "locks": locks,
    }
    args.out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({key: report[key] for key in ("lock_count", "type_counts", "scope_counts")}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
