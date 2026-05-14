#!/usr/bin/env python3
"""Compare nextpnr routed net metadata across calibration builds."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
from typing import Any


def parse_label_path(value: str) -> tuple[str, Path]:
    if ":" not in value:
        raise SystemExit(f"expected LABEL:PATH, got {value!r}")
    label, path = value.split(":", 1)
    return label, Path(path)


def load_routes(path: Path) -> dict[str, str]:
    design = json.loads(path.read_text(encoding="utf-8"))
    modules = design["modules"]
    module = modules.get("top") or next(iter(modules.values()))
    routes: dict[str, str] = {}
    for name, net in module.get("netnames", {}).items():
        routing = net.get("attributes", {}).get("ROUTING")
        if routing is not None:
            routes[name] = str(routing)
    return routes


def category(name: str) -> str:
    lower = name.lower()
    if "ddr3_phy" in lower:
        return "ddr3_phy"
    if "ddr3_controller" in lower:
        return "ddr3_controller"
    if "uberddr3" in lower:
        return "uberddr3_other"
    if "jtag_" in lower:
        return "jtag"
    if "clk" in lower or "clock" in lower:
        return "clock"
    return "other"


def route_tile_types(route: str) -> Counter[str]:
    counts: Counter[str] = Counter()
    for token in route.split(";"):
        if "/" not in token:
            continue
        _, rest = token.split("/", 1)
        tile = rest.split("/", 1)[0]
        tile_type = re.sub(r"_X\d+Y\d+$", "", tile)
        counts[tile_type] += 1
    return counts


def summarize_route_tiles(routes: list[str], limit: int) -> str:
    counts: Counter[str] = Counter()
    for route in routes:
        counts.update(route_tile_types(route))
    if not counts:
        return "-"
    return ", ".join(f"`{name}`={count}" for name, count in counts.most_common(limit))


def markdown(args: argparse.Namespace) -> str:
    inputs = dict(parse_label_path(value) for value in args.json)
    routes = {label: load_routes(path) for label, path in inputs.items()}
    labels = list(inputs)
    common = set.intersection(*(set(value) for value in routes.values()))

    lines = [
        "# Routed Net Comparison",
        "",
        "## Inputs",
        "",
        "| Label | Routed JSON | Routed nets |",
        "| --- | --- | ---: |",
    ]
    for label in labels:
        lines.append(f"| `{label}` | `{inputs[label]}` | {len(routes[label])} |")
    lines += ["", f"Common routed net names: {len(common)}", ""]

    by_category: dict[str, list[str]] = defaultdict(list)
    for name in common:
        by_category[category(name)].append(name)

    lines += [
        "## Route Stability By Net Category",
        "",
        "| Category | Common Nets | Equal Routes Across All Builds | Top Route Tile Types |",
        "| --- | ---: | ---: | --- |",
    ]
    for cat in sorted(by_category):
        names = sorted(by_category[cat])
        equal = sum(len({routes[label][name] for label in labels}) == 1 for name in names)
        route_text = [routes[labels[0]][name] for name in names]
        lines.append(
            f"| `{cat}` | {len(names)} | {equal} | {summarize_route_tiles(route_text, args.limit)} |"
        )

    if args.pass_label and args.fail_label:
        pass_labels = args.pass_label
        fail_labels = args.fail_label
        lines += [
            "",
            "## Pass-Consensus Route Versus Fail",
            "",
            "| Category | Pass Same, Any Fail Different | Top Route Tile Types In Pass |",
            "| --- | ---: | --- |",
        ]
        for cat in sorted(by_category):
            names = []
            for name in by_category[cat]:
                pass_routes = {routes[label][name] for label in pass_labels}
                if len(pass_routes) != 1:
                    continue
                pass_route = next(iter(pass_routes))
                if any(routes[label][name] != pass_route for label in fail_labels):
                    names.append(name)
            route_text = [routes[pass_labels[0]][name] for name in names]
            lines.append(
                f"| `{cat}` | {len(names)} | {summarize_route_tiles(route_text, args.limit)} |"
            )

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="append", required=True, help="LABEL:path/to/nextpnr-routed.json")
    parser.add_argument("--pass-label", action="append", default=[])
    parser.add_argument("--fail-label", action="append", default=[])
    parser.add_argument("--limit", type=int, default=10)
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
