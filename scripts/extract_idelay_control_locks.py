#!/usr/bin/env python3
"""Extract a narrow IDELAY-control BEL lock file from a placed nextpnr JSON."""

from __future__ import annotations

import argparse
import collections
import csv
import json
from pathlib import Path
import re
from typing import Any


CNTVALUEIN_RE = re.compile(r"i_controller_idelay_(?:data|dqs)_cntvaluein\[\d+\]$")


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )


def cell_from_pin(pin: str) -> str:
    return pin.rsplit(".", 1)[0]


def load_ld_source_cells(metrics_csv: Path | None, sample: str | None) -> set[str]:
    if metrics_csv is None:
        return set()
    cells: set[str] = set()
    with metrics_csv.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if sample is not None and row.get("sample") != sample:
                continue
            if row.get("family") != "idelay_ld":
                continue
            from_pin = row.get("from_pin", "")
            if from_pin.endswith(".Q"):
                cells.add(cell_from_pin(from_pin))
    return cells


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--placed-json", required=True, type=Path)
    parser.add_argument("--out-json", required=True, type=Path)
    parser.add_argument("--metrics-csv", type=Path)
    parser.add_argument("--sample", help="Sample label to select from --metrics-csv")
    parser.add_argument("--notes", default="")
    args = parser.parse_args()

    data = json.loads(args.placed_json.read_text(encoding="utf-8"))
    module = top_module(data)
    cells = module.get("cells", {})
    ld_sources = load_ld_source_cells(args.metrics_csv, args.sample)

    locks = []
    skipped = []
    for name, cell in sorted(cells.items()):
        scope = None
        if CNTVALUEIN_RE.search(name):
            scope = "idelay_cntvaluein_leaf"
        elif name in ld_sources:
            scope = "idelay_ld_source"
        if scope is None:
            continue

        lock_name = name
        lock_cell = cell
        source_cell = None
        if scope == "idelay_ld_source":
            parent = cell.get("attributes", {}).get("CONSTR_PARENT")
            if parent and parent in cells:
                lock_name = parent
                lock_cell = cells[parent]
                source_cell = name
                scope = "idelay_ld_source_parent"

        bel = lock_cell.get("attributes", {}).get("NEXTPNR_BEL")
        if not bel:
            skipped.append({"cell": lock_name, "scope": scope, "source_cell": source_cell, "reason": "missing NEXTPNR_BEL"})
            continue
        lock = {
            "cell": lock_name,
            "type": lock_cell.get("type", ""),
            "bel": bel,
            "scope": scope,
        }
        if source_cell is not None:
            lock["source_cell"] = source_cell
            lock["source_bel"] = cell.get("attributes", {}).get("NEXTPNR_BEL")
        locks.append(lock)

    scope_counts = collections.Counter(lock["scope"] for lock in locks)
    type_counts = collections.Counter(lock["type"] for lock in locks)
    out = {
        "format": "uberddr3.nextpnr-bel-locks.v1",
        "source_placed_json": str(args.placed_json),
        "source_metrics_csv": str(args.metrics_csv) if args.metrics_csv else None,
        "source_sample": args.sample,
        "notes": args.notes,
        "lock_count": len(locks),
        "scope_counts": dict(sorted(scope_counts.items())),
        "type_counts": dict(sorted(type_counts.items())),
        "skipped_missing_bel_count": len(skipped),
        "skipped_missing_bel": skipped,
        "locks": locks,
    }
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.out_json} locks={len(locks)} skipped={len(skipped)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
