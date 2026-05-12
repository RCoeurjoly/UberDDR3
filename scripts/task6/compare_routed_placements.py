#!/usr/bin/env python3
"""Compare routed nextpnr JSON placements across DDR3 calibration seeds."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
from typing import Any


HIGH_RISK_TYPES = {
    "BUFGCTRL",
    "IDELAYCTRL_IDELAYCTRL",
    "IDELAYE2_IDELAYE2",
    "IOB33_INBUF_EN",
    "IOB33_OUTBUF",
    "IOB33M_INBUF_EN",
    "IOB33M_OUTBUF",
    "IOB33S_OUTBUF",
    "ISERDESE2_ISERDESE2",
    "OSERDESE2_OSERDESE2",
    "PAD",
    "PLLE2_ADV_PLLE2_ADV",
}


def load_cells(path: Path) -> dict[str, dict[str, Any]]:
    design = json.loads(path.read_text(encoding="utf-8"))
    modules = design["modules"]
    if "top" in modules:
        module = modules["top"]
    elif len(modules) == 1:
        module = next(iter(modules.values()))
    else:
        raise SystemExit(f"{path}: cannot choose top module from {sorted(modules)}")
    cells: dict[str, dict[str, Any]] = {}
    for name, cell in module["cells"].items():
        bel = cell.get("attributes", {}).get("NEXTPNR_BEL")
        if bel is None:
            continue
        cells[name] = {
            "type": cell["type"],
            "bel": bel,
        }
    return cells


def site_xy(bel: str) -> tuple[int, int] | None:
    match = re.search(r"_[XY](\d+)Y(\d+)", bel)
    if match is None:
        match = re.search(r"_X(\d+)Y(\d+)", bel)
    if match is None:
        return None
    return int(match.group(1)), int(match.group(2))


def category(name: str, cell_type: str) -> str:
    lower = name.lower()
    if cell_type in HIGH_RISK_TYPES:
        return "clock_io_phy_primitives"
    if "ddr3_phy" in lower:
        return "ddr3_phy_soft_logic"
    if "ddr3_controller" in lower:
        return "ddr3_controller_soft_logic"
    if "uberddr3" in lower:
        return "uberddr3_other_soft_logic"
    if "jtag_" in lower:
        return "jtag_soft_logic"
    return "other_soft_logic"


def bbox(cells: dict[str, dict[str, Any]], names: list[str]) -> str:
    coords = [site_xy(cells[name]["bel"]) for name in names]
    coords = [coord for coord in coords if coord is not None]
    if not coords:
        return "-"
    xs = [coord[0] for coord in coords]
    ys = [coord[1] for coord in coords]
    return f"X{min(xs)}..{max(xs)} Y{min(ys)}..{max(ys)}"


def parse_seed_json(values: list[str]) -> dict[str, Path]:
    out: dict[str, Path] = {}
    for value in values:
        if ":" not in value:
            raise SystemExit(f"--seed-json must be SEED:PATH, got {value!r}")
        seed, path = value.split(":", 1)
        out[seed] = Path(path)
    if len(out) < 2:
        raise SystemExit("need at least two --seed-json entries")
    return out


def markdown(args: argparse.Namespace) -> str:
    seed_paths = parse_seed_json(args.seed_json)
    placements = {seed: load_cells(path) for seed, path in seed_paths.items()}
    seeds = list(seed_paths)
    common = set.intersection(*(set(cells) for cells in placements.values()))

    lines: list[str] = [
        "# Routed Placement Comparison",
        "",
        "## Inputs",
        "",
        "| Seed | Routed JSON | Placed cells |",
        "| --- | --- | ---: |",
    ]
    for seed in seeds:
        lines.append(f"| `{seed}` | `{seed_paths[seed]}` | {len(placements[seed])} |")

    lines += [
        "",
        f"Common placed cell names: {len(common)}",
        "",
        "## High-Risk Primitive Stability",
        "",
        "| Type | Count | Equal across all seeds |",
        "| --- | ---: | ---: |",
    ]
    for cell_type in sorted(HIGH_RISK_TYPES):
        names = [name for name in common if placements[seeds[0]][name]["type"] == cell_type]
        if not names:
            continue
        equal_all = sum(len({placements[seed][name]["bel"] for seed in seeds}) == 1 for name in names)
        lines.append(f"| `{cell_type}` | {len(names)} | {equal_all} |")

    lines += [
        "",
        "## Category Movement",
        "",
        "| Category | Count | Equal across all seeds | Bounding boxes |",
        "| --- | ---: | ---: | --- |",
    ]
    by_category: dict[str, list[str]] = defaultdict(list)
    for name in common:
        cell_type = placements[seeds[0]][name]["type"]
        by_category[category(name, cell_type)].append(name)
    for cat in sorted(by_category):
        names = sorted(by_category[cat])
        equal_all = sum(len({placements[seed][name]["bel"] for seed in seeds}) == 1 for name in names)
        boxes = "; ".join(f"{seed}: {bbox(placements[seed], names)}" for seed in seeds)
        lines.append(f"| `{cat}` | {len(names)} | {equal_all} | {boxes} |")

    if args.pass_seed and args.fail_seed:
        pass_seeds = args.pass_seed
        fail_seed = args.fail_seed
        lines += [
            "",
            "## Pass-Consensus Versus Fail",
            "",
            "| Category | Pass seeds same, fail different | Top types |",
            "| --- | ---: | --- |",
        ]
        for cat in sorted(by_category):
            names = []
            for name in by_category[cat]:
                pass_bels = {placements[seed][name]["bel"] for seed in pass_seeds}
                if len(pass_bels) != 1:
                    continue
                if placements[fail_seed][name]["bel"] in pass_bels:
                    continue
                names.append(name)
            type_counts = Counter(placements[pass_seeds[0]][name]["type"] for name in names)
            top_types = ", ".join(f"`{typ}`={count}" for typ, count in type_counts.most_common(6))
            lines.append(f"| `{cat}` | {len(names)} | {top_types or '-'} |")

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed-json", action="append", required=True, help="SEED:nextpnr-routed.json")
    parser.add_argument("--pass-seed", action="append", default=[])
    parser.add_argument("--fail-seed")
    parser.add_argument("--out", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    text = markdown(args)
    if args.out is None:
        print(text, end="")
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
