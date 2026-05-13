#!/usr/bin/env python3
"""Extract experimental DDR3 soft-logic BEL locks from a routed nextpnr JSON."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
from typing import Any


SOFT_TYPES = {
    "CARRY4",
    "SELMUX2_1",
    "SLICE_FFX",
    "SLICE_LUTX",
}


def attr_string(cell: dict[str, Any], name: str) -> str | None:
    value = cell.get("attributes", {}).get(name)
    if value in (None, ""):
        return None
    return str(value)


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


def cell_scope(name: str, cell_type: str) -> str | None:
    if cell_type not in SOFT_TYPES:
        return None
    if "ddr3_phy_inst.IDELAYCTRL_inst/RDY_AND_LUT_" in name:
        return "ddr3_idelayctrl_soft"
    if name.startswith("bist_top.uberddr3.ddr3_controller_inst."):
        return "ddr3_controller_soft"
    if name.startswith("bist_top.uberddr3."):
        return "uberddr3_soft"
    return None


def placement_root_names(cells: dict[str, Any], start_names: dict[str, str]) -> dict[str, str]:
    roots: dict[str, str] = {}
    for start_name, scope in start_names.items():
        name = start_name
        seen: set[str] = set()
        while name not in seen:
            seen.add(name)
            cell = cells.get(name)
            if cell is None:
                break
            parent = attr_string(cell, "CONSTR_PARENT")
            if not parent or parent not in cells:
                roots[name] = scope
                break
            name = parent
    return roots


def extract_locks(routed_json: Path) -> dict[str, Any]:
    cells = load_top_cells(routed_json)
    start_names: dict[str, str] = {}
    for name, cell in cells.items():
        scope = cell_scope(name, cell.get("type", ""))
        if scope is not None:
            start_names[name] = scope

    scoped_names = placement_root_names(cells, start_names)
    locks: list[dict[str, str]] = []
    skipped_missing_bel: list[dict[str, str]] = []
    for name, scope in sorted(scoped_names.items()):
        cell = cells[name]
        cell_type = cell.get("type", "")
        bel = cell.get("attributes", {}).get("NEXTPNR_BEL")
        if not bel:
            skipped_missing_bel.append({"cell": name, "type": cell_type, "scope": scope})
            continue
        locks.append({"cell": name, "type": cell_type, "scope": scope, "bel": bel})

    return {
        "format": "task6.nextpnr-ddr3-soft-bel-locks.v1",
        "source_routed_json": str(routed_json),
        "lock_count": len(locks),
        "type_counts": dict(sorted(Counter(lock["type"] for lock in locks).items())),
        "scope_counts": dict(sorted(Counter(lock["scope"] for lock in locks).items())),
        "skipped_missing_bel_count": len(skipped_missing_bel),
        "skipped_missing_bel": skipped_missing_bel,
        "locks": locks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--routed-json", required=True, type=Path)
    parser.add_argument("--out-json", required=True, type=Path)
    args = parser.parse_args()

    report = extract_locks(args.routed_json)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "lock_count": report["lock_count"],
                "scope_counts": report["scope_counts"],
                "type_counts": report["type_counts"],
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
