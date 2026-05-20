#!/usr/bin/env python3
"""Compare SYSTEST c0.group2.B FIFO oracle routes against an OpenXC7 FASM."""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

PIP_RE = re.compile(r"^(?P<tile>[^/]+)/(?P<tile_type>[^.]+)\.(?P<body>.+)$")
FASM_ROUTE_RE = re.compile(r"^(?P<tile>CMT_FIFO_R_X\d+Y\d+)\.(?P<dst>[A-Za-z0-9_]+)\.(?P<src>[A-Za-z0-9_]+)$")
FOCUS_REFS = {"IN_FIFO", "OUT_FIFO", "PHASER_IN_PHY", "PHASER_OUT_PHY", "PHY_CONTROL", "PHASER_REF"}
FOCUS_PIN_BASES = {
    "IN_FIFO": {"RDCLK", "WRCLK", "RESET", "RDEN", "WREN", "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9"},
    "OUT_FIFO": {"RDCLK", "WRCLK", "RESET", "RDEN", "WREN", "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9"},
    "PHASER_IN_PHY": {"ICLKDIV", "ICLK", "WRENABLE", "ISERDESRST", "PHASELOCKED", "RCLK", "RST", "RSTDQSFIND", "SYNCIN", "PHASEREFCLK", "MEMREFCLK", "FREQREFCLK", "SYSCLK", "BURSTPENDINGPHY", "ENCALIBPHY", "RANKSELPHY"},
    "PHASER_OUT_PHY": {"OCLK", "OCLKDIV", "OCLKDELAYED", "RDENABLE", "OSERDESRST", "RST", "SYNCIN", "PHASEREFCLK", "MEMREFCLK", "FREQREFCLK", "SYSCLK", "BURSTPENDINGPHY", "ENCALIBPHY"},
    "PHY_CONTROL": {"PHYCTLREADY", "PHYCTLWD", "PHYCTLWRENABLE", "PLLLOCK", "REFDLLLOCK", "RESET", "SYNCIN", "READCALIBENABLE", "WRITECALIBENABLE", "INBURSTPENDING", "OUTBURSTPENDING", "PCENABLECALIB"},
}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def split_pip(body: str) -> tuple[str, str] | None:
    for arrow in ("<<->>", "->>", "->"):
        if arrow in body:
            src, dst = body.split(arrow, 1)
            return src, dst
    return None


def route_key(src: str, dst: str) -> str:
    return f"CMT_FIFO_R.{dst}.{src}"


def route_class(src: str, dst: str) -> str:
    text = f"{src} {dst}"
    if "CLK" in text:
        return "clock"
    if any(token in text for token in ("RESET", "RDEN", "WREN")):
        return "control"
    if re.search(r"_D\d", text) or any(token in text for token in ("_D0", "_D1", "_D2", "_D3", "_D4", "_D5", "_D6", "_D7", "_D8", "_D9")):
        return "data"
    if any(token in text for token in ("EMPTY", "FULL", "LOGIC_OUTS")):
        return "status"
    return "other"


def parse_pip(pip: str, focus_tile: str) -> dict[str, str] | None:
    match = PIP_RE.match(pip.strip())
    if not match:
        return None
    tile = match.group("tile")
    tile_type = match.group("tile_type")
    if tile != focus_tile or tile_type != "CMT_FIFO_R":
        return None
    parts = split_pip(match.group("body"))
    if parts is None:
        return None
    src, dst = parts
    return {
        "tile": tile,
        "tile_type": tile_type,
        "src": src,
        "dst": dst,
        "key": route_key(src, dst),
        "feature": f"{tile}.{dst}.{src}",
        "class": route_class(src, dst),
        "pip": pip,
    }


def load_oracle_routes(extract_dir: Path, focus_tile: str) -> tuple[dict[str, dict[str, Any]], dict[str, list[dict[str, str]]]]:
    pips = read_tsv(extract_dir / "net-pips.tsv")
    routes: dict[str, dict[str, Any]] = {}
    routes_by_net: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in pips:
        net = row["net"]
        for raw_pip in filter(None, row.get("sampled_pips", "").split(",")):
            parsed = parse_pip(raw_pip, focus_tile)
            if parsed is None:
                continue
            parsed["net"] = net
            routes_by_net[net].append(parsed)
            item = routes.setdefault(parsed["key"], {**parsed, "nets": [], "occurrences": 0})
            item["occurrences"] += 1
            if net not in item["nets"]:
                item["nets"].append(net)
    return routes, routes_by_net


def load_open_routes(open_fasm: Path, focus_tile: str) -> dict[str, dict[str, Any]]:
    routes: dict[str, dict[str, Any]] = {}
    for line_no, raw_line in enumerate(open_fasm.read_text(encoding="utf-8").splitlines(), 1):
        feature = raw_line.split("#", 1)[0].strip().split(None, 1)[0] if raw_line.split("#", 1)[0].strip() else ""
        if not feature:
            continue
        match = FASM_ROUTE_RE.match(feature)
        if not match or match.group("tile") != focus_tile:
            continue
        dst = match.group("dst")
        src = match.group("src")
        routes[route_key(src, dst)] = {
            "tile": focus_tile,
            "src": src,
            "dst": dst,
            "key": route_key(src, dst),
            "feature": feature,
            "class": route_class(src, dst),
            "line": line_no,
        }
    return routes


def load_focus_pins(extract_dir: Path, routes_by_net: dict[str, list[dict[str, str]]]) -> list[dict[str, Any]]:
    pins = read_tsv(extract_dir / "pins.tsv")
    rows: list[dict[str, Any]] = []
    for pin in pins:
        ref = pin["ref_name"]
        if ref not in FOCUS_REFS:
            continue
        base = pin["ref_pin"].split("[", 1)[0]
        if base not in FOCUS_PIN_BASES.get(ref, set()):
            continue
        net = pin["net"]
        cmt_routes = routes_by_net.get(net, [])
        rows.append({
            "ref_name": ref,
            "ref_pin": pin["ref_pin"],
            "direction": pin["direction"],
            "net": net,
            "net_type": pin["net_type"],
            "cmt_fifo_route_count": len(cmt_routes),
            "cmt_fifo_route_keys": sorted({r["key"] for r in cmt_routes}),
        })
    rows.sort(key=lambda r: (r["ref_name"], r["ref_pin"], r["net"]))
    return rows


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, payload: dict[str, Any]) -> None:
    lines = [
        "# SYSTEST c0.group2.B FIFO Oracle vs OpenXC7",
        "",
        "## Summary",
        "",
    ]
    for key, value in payload["summary"].items():
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## Counts By Class", ""])
    for row in payload["counts_by_class"]:
        lines.append(f"- `{row['class']}`: `{row['total']}` SYSTEST, `{row['present']}` present, `{row['missing']}` missing")
    lines.extend(["", "## Missing SYSTEST CMT_FIFO Routes", ""])
    if payload["missing_systest_routes"]:
        for row in payload["missing_systest_routes"]:
            nets = ", ".join(f"`{n}`" for n in row["nets"][:3])
            lines.append(f"- `{row['class']}` `{row['feature']}` from {nets}")
    else:
        lines.append("No sampled SYSTEST CMT_FIFO routes are missing from the OpenXC7 FASM.")
    lines.extend(["", "## Extra Open CMT_FIFO Routes", ""])
    if payload["extra_open_routes"]:
        for row in payload["extra_open_routes"]:
            lines.append(f"- `{row['class']}` `{row['feature']}` (line {row['line']})")
    else:
        lines.append("No OpenXC7 CMT_FIFO routes are outside the sampled SYSTEST oracle set.")
    lines.extend(["", "## SYSTEST Control Pins With CMT_FIFO Routes", "", "| Ref | Pin | Net Type | CMT_FIFO routes | Net |", "| --- | --- | --- | ---: | --- |"])
    for row in payload["focus_pins"]:
        if row["cmt_fifo_route_count"]:
            lines.append(f"| `{row['ref_name']}` | `{row['ref_pin']}` | `{row['net_type']}` | {row['cmt_fifo_route_count']} | `{row['net']}` |")
    lines.extend(["", "## Notes", ""])
    lines.append("- This report compares sampled Vivado PIPs from `net-pips.tsv`; high-fanout nets may be truncated by the extractor sample limit.")
    lines.append("- A missing route is an investigation target, not yet a database patch. Frame-bit deltas still need to back any new row.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extract-dir", type=Path, required=True)
    parser.add_argument("--open-fasm", type=Path, required=True)
    parser.add_argument("--focus-tile", default="CMT_FIFO_R_X7Y20")
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--md-out", type=Path, required=True)
    args = parser.parse_args()

    systest_routes, routes_by_net = load_oracle_routes(args.extract_dir, args.focus_tile)
    open_routes = load_open_routes(args.open_fasm, args.focus_tile)
    present = []
    missing = []
    counts: Counter[tuple[str, bool]] = Counter()
    for key in sorted(systest_routes):
        item = dict(systest_routes[key])
        item["present_in_open"] = key in open_routes
        if item["present_in_open"]:
            item["open_feature"] = open_routes[key]["feature"]
            item["open_line"] = open_routes[key]["line"]
            present.append(item)
        else:
            missing.append(item)
        counts[(item["class"], item["present_in_open"])] += 1

    extra = [dict(v) for k, v in sorted(open_routes.items()) if k not in systest_routes]
    classes = sorted({item["class"] for item in systest_routes.values()} | {item["class"] for item in extra})
    by_class = []
    for name in classes:
        seen = counts[(name, True)]
        miss = counts[(name, False)]
        by_class.append({"class": name, "total": seen + miss, "present": seen, "missing": miss})

    payload: dict[str, Any] = {
        "inputs": {
            "extract_dir": str(args.extract_dir),
            "open_fasm": str(args.open_fasm),
            "focus_tile": args.focus_tile,
        },
        "summary": {
            "systest_sampled_cmt_fifo_routes": len(systest_routes),
            "open_cmt_fifo_routes": len(open_routes),
            "systest_routes_present_in_open": len(present),
            "systest_routes_missing_from_open": len(missing),
            "extra_open_routes_not_in_systest_sample": len(extra),
        },
        "counts_by_class": by_class,
        "focus_pins": load_focus_pins(args.extract_dir, routes_by_net),
        "present_systest_routes": present,
        "missing_systest_routes": missing,
        "extra_open_routes": extra,
    }
    write_json(args.json_out, payload)
    write_markdown(args.md_out, payload)
    print(f"wrote {args.json_out}")
    print(f"wrote {args.md_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
