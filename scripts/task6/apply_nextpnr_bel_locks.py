#!/usr/bin/env python3
"""Apply nextpnr BEL locks from a routed JSON to a Yosys JSON design."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def first_module(design: dict) -> dict:
    modules = design.get("modules", {})
    if len(modules) != 1:
        raise SystemExit(f"expected exactly one module, found {len(modules)}")
    return modules[next(iter(modules))]


def module_with_locks(design: dict, prefixes: list[str]) -> dict:
    modules = design.get("modules", {})
    best = None
    best_count = -1
    for module in modules.values():
        cells = module.get("cells", {})
        count = sum(1 for name in cells if should_lock(name, prefixes))
        if count > best_count:
            best = module
            best_count = count
    if best is None or best_count <= 0:
        raise SystemExit("no module contains requested lock prefixes")
    return best


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-json", required=True)
    parser.add_argument("--lock-json", required=True)
    parser.add_argument("--output-json", required=True)
    parser.add_argument(
        "--prefix",
        action="append",
        default=[],
        help="Cell-name prefix to lock. May be passed more than once.",
    )
    parser.add_argument(
        "--cell-type",
        action="append",
        default=[],
        help="Cell type to lock. If omitted, all matching types are considered.",
    )
    return parser.parse_args()


def should_lock(name: str, prefixes: list[str]) -> bool:
    return not prefixes or any(name.startswith(prefix) for prefix in prefixes)


def main() -> int:
    args = parse_args()
    source = json.loads(Path(args.input_json).read_text(encoding="utf-8"))
    locks = json.loads(Path(args.lock_json).read_text(encoding="utf-8"))
    source_cells = module_with_locks(source, args.prefix)["cells"]
    lock_cells = first_module(locks)["cells"]

    copied = 0
    already_locked = 0
    missing = 0
    type_mismatch = 0
    for name, source_cell in source_cells.items():
        if not should_lock(name, args.prefix):
            continue
        if args.cell_type and source_cell.get("type") not in args.cell_type:
            continue
        attrs = source_cell.setdefault("attributes", {})
        if attrs.get("NEXTPNR_BEL"):
            already_locked += 1
            continue
        lock_cell = lock_cells.get(name)
        if lock_cell is None:
            missing += 1
            continue
        if lock_cell.get("type") != source_cell.get("type"):
            type_mismatch += 1
            continue
        bel = lock_cell.get("attributes", {}).get("NEXTPNR_BEL")
        if not bel:
            missing += 1
            continue
        attrs["NEXTPNR_BEL"] = bel
        attrs["BEL_STRENGTH"] = "00000000000000000000000000000101"
        copied += 1

    Path(args.output_json).write_text(json.dumps(source, sort_keys=True) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "copied": copied,
                "already_locked": already_locked,
                "missing": missing,
                "type_mismatch": type_mismatch,
                "prefixes": args.prefix,
                "cell_types": args.cell_type,
            },
            sort_keys=True,
        )
    )
    if copied == 0:
        raise SystemExit("no BEL locks copied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
