#!/usr/bin/env python3
"""Compare nextpnr/Yosys JSON net and cell-name presence by failure family."""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from typing import Any


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next((m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"), next(iter(modules.values())))


def load_names(path: Path) -> tuple[set[str], set[str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    module = top_module(data)
    cells = set(str(name) for name in module.get("cells", {}))
    nets = set(str(name) for name in module.get("netnames", {}))
    return cells, nets


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=Path, required=True, help="CSV with experiment_id, family_id/status, and nextpnr_json or yosys_json columns")
    parser.add_argument("--json-column", default="nextpnr_json")
    parser.add_argument("--family-column", default="coarse_family_id")
    parser.add_argument("--pass-family", default="pass")
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--focus", action="append", default=[], help="Substring focus filter. Can be repeated.")
    args = parser.parse_args()

    rows = read_csv(args.samples)
    names_by_family: dict[str, dict[str, list[set[str]]]] = defaultdict(lambda: {"cells": [], "nets": []})
    sample_counts: dict[str, int] = defaultdict(int)
    for row in rows:
        json_value = row.get(args.json_column, "")
        family = row.get(args.family_column, "") or row.get("coarse_family_id", "") or row.get("exact_family_id", "") or row.get("failure_family_id", "") or row.get("status", "")
        if not json_value or not family:
            continue
        path = Path(json_value)
        if not path.exists():
            continue
        cells, nets = load_names(path)
        if args.focus:
            cells = {name for name in cells if any(token in name for token in args.focus)}
            nets = {name for name in nets if any(token in name for token in args.focus)}
        names_by_family[family]["cells"].append(cells)
        names_by_family[family]["nets"].append(nets)
        sample_counts[family] += 1

    if args.pass_family not in names_by_family:
        raise SystemExit(f"pass family {args.pass_family!r} not found")

    pass_cells = set.intersection(*names_by_family[args.pass_family]["cells"]) if names_by_family[args.pass_family]["cells"] else set()
    pass_nets = set.intersection(*names_by_family[args.pass_family]["nets"]) if names_by_family[args.pass_family]["nets"] else set()
    out_rows = []
    for family, groups in sorted(names_by_family.items()):
        if family == args.pass_family:
            continue
        family_cells = set.intersection(*groups["cells"]) if groups["cells"] else set()
        family_nets = set.intersection(*groups["nets"]) if groups["nets"] else set()
        for kind, names in [("cell", sorted(pass_cells - family_cells)), ("net", sorted(pass_nets - family_nets))]:
            for name in names:
                out_rows.append({
                    "family_id": family,
                    "kind": kind,
                    "name": name,
                    "pass_sample_count": sample_counts[args.pass_family],
                    "family_sample_count": sample_counts[family],
                    "interpretation": "present_in_all_pass_absent_from_all_family_samples",
                })

    write_csv(args.out_dir / "pass_present_family_absent.csv", out_rows)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
