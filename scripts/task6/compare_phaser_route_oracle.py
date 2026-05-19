#!/usr/bin/env python3
"""Compare Vivado PHASER route dumps against an OpenXC7 FASM file."""

from __future__ import annotations

import argparse
from collections import Counter
import json
import re
from pathlib import Path


PIP_RE = re.compile(r"^\s*PIP\s+([^/]+)/([^.\s]+)\.([^\s]+)$")
ACTIVE_TILES = {
    "CMT_TOP_R_LOWER_T_X8Y18",
    "CMT_TOP_R_UPPER_B_X8Y31",
}
INTERESTING_TOKENS = (
    "PHASER",
    "PHY_CONTROL",
    "CMT_FREQ",
    "PREF_IN",
    "REFMUX",
)
OBSERVATION_TOKENS = (
    "DQSFOUND",
    "PHASELOCKED",
    "PHYCTLREADY",
    "LOCKED",
    "OUTOFRANGE",
    "OVERFLOW",
    "LOGIC_OUTS",
)


def normalize_pip(tile: str, body: str) -> tuple[str, str, str, str] | None:
    for arrow in ("<<->>", "->>", "->"):
        if arrow in body:
            src, dst = body.split(arrow, 1)
            return tile, src, dst, f"{tile}.{dst}.{src}"
    return None


def route_class(src: str, dst: str) -> str:
    text = f"{src} {dst}"
    if any(token in text for token in OBSERVATION_TOKENS):
        return "fabric-observation"
    if "PHYCTLWD" in text or any(
        token in text
        for token in (
            "CALIBENABLE",
            "PHYCTLWRENABLE",
            "RSTDQSFIND",
            "COUNTER",
            "EDGEADV",
            "RST",
            "FINE",
            "COARSE",
            "RANKSEL",
        )
    ):
        return "hard-macro-control"
    if any(token in text for token in ("REFMUX", "MEMREFCLK", "SYNCIN", "FREQREFCLK", "CLKIN")):
        return "dedicated-clock"
    if "BURSTPENDING" in text or "ENCALIB" in text or "RANKSELPHY" in text:
        return "phy-control-ppip"
    return "other-phaser"


def parse_vivado_routes(path: Path, active_tiles: set[str]) -> list[dict[str, str]]:
    routes: list[dict[str, str]] = []
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = PIP_RE.match(line)
        if not match:
            continue
        tile, _tile_type, body = match.groups()
        normalized = normalize_pip(tile, body)
        if normalized is None:
            continue
        tile, src, dst, feature = normalized
        text = f"{tile} {src} {dst}"
        if tile not in active_tiles:
            continue
        if not any(token in text for token in INTERESTING_TOKENS):
            continue
        routes.append(
            {
                "line": line_no,
                "tile": tile,
                "src": src,
                "dst": dst,
                "feature": feature,
                "class": route_class(src, dst),
            }
        )
    return routes


def parse_fasm(path: Path) -> set[str]:
    features: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        feature = line.split(None, 1)[0]
        features.add(feature)
    return features


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, payload: dict) -> None:
    lines = [
        "# Vivado PHASER route oracle vs OpenXC7 FASM",
        "",
        "## Summary",
        "",
    ]
    for key, value in payload["summary"].items():
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## Counts by class", ""])
    for row in payload["counts_by_class"]:
        lines.append(
            f"- `{row['class']}`: `{row['total']}` total, "
            f"`{row['present']}` present, `{row['missing']}` missing"
        )
    lines.extend(["", "## Missing active CMT/PHASER routes", ""])
    missing = payload["missing_routes"]
    if not missing:
        lines.append("No Vivado active CMT/PHASER route features are missing from the OpenXC7 FASM.")
    else:
        for route in missing:
            lines.append(
                f"- `{route['class']}` `{route['feature']}` "
                f"(Vivado route dump line {route['line']})"
            )
    lines.extend(["", "## Notes", ""])
    lines.append(
        "- This report compares named route features only. It does not prove that "
        "the associated frame rows are complete or conflict-free."
    )
    lines.append(
        "- Compact Vivado and the full SYSTEST oracle use different CMT refmux lanes, "
        "so missing route rows must be judged against the exact oracle being compared."
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vivado-routes", type=Path, required=True)
    parser.add_argument("--open-fasm", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--md-out", type=Path, required=True)
    parser.add_argument(
        "--tile",
        action="append",
        dest="tiles",
        default=None,
        help="Active tile to compare. May be passed more than once.",
    )
    args = parser.parse_args()

    active_tiles = set(args.tiles) if args.tiles else set(ACTIVE_TILES)
    raw_routes = parse_vivado_routes(args.vivado_routes, active_tiles)
    fasm = parse_fasm(args.open_fasm)
    routes_by_feature: dict[str, dict[str, str | int]] = {}
    for route in raw_routes:
        feature = route["feature"]
        if feature not in routes_by_feature:
            item: dict[str, str | int] = dict(route)
            item["occurrences_in_vivado_dump"] = 0
            routes_by_feature[feature] = item
        routes_by_feature[feature]["occurrences_in_vivado_dump"] = (
            int(routes_by_feature[feature]["occurrences_in_vivado_dump"]) + 1
        )
    routes = list(routes_by_feature.values())

    compared = []
    counts: Counter[tuple[str, bool]] = Counter()
    for route in routes:
        present = str(route["feature"]) in fasm
        item = dict(route)
        item["present_in_openxc7_fasm"] = present
        compared.append(item)
        counts[(str(route["class"]), present)] += 1

    class_names = sorted({route["class"] for route in compared})
    counts_by_class = []
    for name in class_names:
        present = counts[(name, True)]
        missing = counts[(name, False)]
        counts_by_class.append(
            {
                "class": name,
                "total": present + missing,
                "present": present,
                "missing": missing,
            }
        )

    missing_routes = [route for route in compared if not route["present_in_openxc7_fasm"]]
    payload = {
        "inputs": {
            "vivado_routes": str(args.vivado_routes),
            "open_fasm": str(args.open_fasm),
            "active_tiles": sorted(active_tiles),
        },
        "summary": {
            "vivado_route_occurrences_scanned": len(raw_routes),
            "unique_vivado_routes_compared": len(compared),
            "present_in_openxc7_fasm": len(compared) - len(missing_routes),
            "missing_from_openxc7_fasm": len(missing_routes),
        },
        "counts_by_class": counts_by_class,
        "missing_routes": missing_routes,
        "routes": compared,
    }
    write_json(args.json_out, payload)
    write_markdown(args.md_out, payload)
    print(f"wrote {args.json_out}")
    print(f"wrote {args.md_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
