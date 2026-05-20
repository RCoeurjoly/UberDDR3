#!/usr/bin/env python3
"""Normalize Vivado systest DDR3 hard-macro extraction TSVs into JSON."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import json
import re
from pathlib import Path
from typing import Any


CHANNEL_RE = re.compile(r"/c(?P<channel>[01])_u_memc_ui_top_axi/")
GROUP_RE = re.compile(r"ddr_phy_4lanes_(?P<group>\d+)\.u_ddr_phy_4lanes")
LANE_RE = re.compile(r"ddr_byte_lane_(?P<lane>[A-D])\.ddr_byte_lane_(?P=lane)")
DDR_PIN_RE = re.compile(r"DDR3_(?P<channel>[01])_(?P<signal>[A-Za-z0-9_]+)(?:\\[(?P<index>\\d+)\\])?")

ROLE_BY_REF = {
    "PHASER_REF": "phaser_ref",
    "PHASER_IN_PHY": "phaser_in",
    "PHASER_OUT_PHY": "phaser_out",
    "PHY_CONTROL": "phy_control",
    "IN_FIFO": "in_fifo",
    "OUT_FIFO": "out_fifo",
    "ISERDESE2": "iserdes",
    "OSERDESE2": "oserdes",
    "IDELAYE2": "idelay",
    "ODELAYE2": "odelay",
}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def lane_index(lane: str | None) -> int | None:
    if lane is None:
        return None
    return {"A": 0, "B": 1, "C": 2, "D": 3}[lane]


def cell_context(cell: str, ref_name: str) -> dict[str, Any]:
    channel_match = CHANNEL_RE.search("/" + cell)
    group_match = GROUP_RE.search(cell)
    lane_match = LANE_RE.search(cell)
    channel = None if channel_match is None else int(channel_match.group("channel"))
    group = None if group_match is None else int(group_match.group("group"))
    lane = None if lane_match is None else lane_match.group("lane")
    logical_lane = None
    if group is not None and lane is not None:
        logical_lane = group * 4 + lane_index(lane)
    return {
        "channel": channel,
        "phy_group": group,
        "lane": lane,
        "lane_index": lane_index(lane),
        "logical_lane": logical_lane,
        "role": ROLE_BY_REF.get(ref_name, ref_name.lower()),
    }


def pins_by_cell(rows: list[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        grouped[row["cell"]].append(
            {
                "pin": row["pin"],
                "ref_pin": row["ref_pin"],
                "direction": row["direction"],
                "net": row["net"],
                "net_type": row["net_type"],
            }
        )
    return grouped


def props_by_cell(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    grouped: dict[str, dict[str, str]] = defaultdict(dict)
    for row in rows:
        grouped[row["cell"]][row["property"]] = row["value"]
    return grouped


def summarize_ddr_pins(pins: list[dict[str, str]]) -> dict[str, Any]:
    by_channel: dict[str, Counter[str]] = defaultdict(Counter)
    examples: dict[str, list[str]] = defaultdict(list)
    for row in pins:
        for value in (row["pin"], row["net"]):
            match = DDR_PIN_RE.search(value)
            if not match:
                continue
            channel = f"c{match.group('channel')}"
            signal = match.group("signal")
            by_channel[channel][signal] += 1
            key = f"{channel}.{signal}"
            if len(examples[key]) < 5:
                examples[key].append(value)
    return {
        channel: {
            "signal_counts": dict(sorted(counter.items())),
            "examples": {
                key.split(".", 1)[1]: vals
                for key, vals in sorted(examples.items())
                if key.startswith(channel + ".")
            },
        }
        for channel, counter in sorted(by_channel.items())
    }


def build_summary(extract_dir: Path) -> dict[str, Any]:
    cells = read_tsv(extract_dir / "cells.tsv")
    pins = read_tsv(extract_dir / "pins.tsv")
    props = read_tsv(extract_dir / "cell-properties.tsv")
    pips = read_tsv(extract_dir / "net-pips.tsv")
    clocks = read_tsv(extract_dir / "clocks.tsv")

    grouped_pins = pins_by_cell(pins)
    grouped_props = props_by_cell(props)

    resources: list[dict[str, Any]] = []
    channels: dict[str, Any] = defaultdict(lambda: {"byte_lanes": {}, "phy_groups": {}, "infrastructure": []})
    ref_counts = Counter()
    role_counts = Counter()

    for row in cells:
        ref = row["ref_name"]
        ref_counts[ref] += 1
        context = cell_context(row["cell"], ref)
        role_counts[context["role"]] += 1
        item = {
            **context,
            "cell": row["cell"],
            "ref_name": ref,
            "loc": row["loc"],
            "bel": row["bel"],
            "site": row["site"],
            "properties": grouped_props.get(row["cell"], {}),
            "pins": grouped_pins.get(row["cell"], []),
        }
        resources.append(item)

        if context["channel"] is None:
            continue
        channel_key = f"c{context['channel']}"
        if context["logical_lane"] is not None:
            lane_key = f"group{context['phy_group']}.{context['lane']}"
            lane = channels[channel_key]["byte_lanes"].setdefault(
                lane_key,
                {
                    "phy_group": context["phy_group"],
                    "lane": context["lane"],
                    "lane_index": context["lane_index"],
                    "logical_lane": context["logical_lane"],
                    "resources": defaultdict(list),
                },
            )
            lane["resources"][context["role"]].append(
                {
                    "cell": row["cell"],
                    "ref_name": ref,
                    "loc": row["loc"],
                    "bel": row["bel"],
                    "site": row["site"],
                }
            )
        elif context["phy_group"] is not None:
            group_key = str(context["phy_group"])
            group = channels[channel_key]["phy_groups"].setdefault(group_key, defaultdict(list))
            group[context["role"]].append(
                {
                    "cell": row["cell"],
                    "ref_name": ref,
                    "loc": row["loc"],
                    "bel": row["bel"],
                    "site": row["site"],
                }
            )
        else:
            channels[channel_key]["infrastructure"].append(
                {
                    "role": context["role"],
                    "cell": row["cell"],
                    "ref_name": ref,
                    "loc": row["loc"],
                    "bel": row["bel"],
                    "site": row["site"],
                }
            )

    normalized_channels: dict[str, Any] = {}
    for channel, data in sorted(channels.items()):
        byte_lanes = {}
        for key, lane in sorted(
            data["byte_lanes"].items(),
            key=lambda pair: (pair[1]["phy_group"], pair[1]["lane_index"]),
        ):
            byte_lanes[key] = {
                **{k: v for k, v in lane.items() if k != "resources"},
                "resources": {
                    role: values
                    for role, values in sorted(lane["resources"].items())
                },
            }
        phy_groups = {}
        for key, group in sorted(data["phy_groups"].items(), key=lambda pair: int(pair[0])):
            phy_groups[key] = {
                role: values
                for role, values in sorted(group.items())
            }
        normalized_channels[channel] = {
            "byte_lane_count": len(byte_lanes),
            "byte_lanes": byte_lanes,
            "phy_groups": phy_groups,
            "infrastructure": sorted(data["infrastructure"], key=lambda item: item["cell"]),
        }

    missing: list[str] = []
    for channel, data in normalized_channels.items():
        for lane_key, lane in data["byte_lanes"].items():
            resources_in_lane = lane["resources"]
            for role in ("phaser_in", "phaser_out", "in_fifo", "out_fifo"):
                if role not in resources_in_lane:
                    missing.append(f"{channel}.{lane_key}.{role}")

    return {
        "schema": "ypcb-vivado-golden-ddr3-summary-v1",
        "extract_dir": str(extract_dir),
        "cell_count": len(cells),
        "pin_count": len(pins),
        "net_with_pip_count": len({row["net"] for row in pips}),
        "clock_count": len(clocks),
        "ref_counts": dict(sorted(ref_counts.items())),
        "role_counts": dict(sorted(role_counts.items())),
        "channels": normalized_channels,
        "ddr_external_pin_summary": summarize_ddr_pins(pins),
        "missing_lane_roles": missing,
        "resources": resources,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extract_dir", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--summary-only", action="store_true")
    parser.add_argument("--require-channel", action="append", choices=("c0", "c1"), default=[])
    parser.add_argument("--require-byte-lanes", type=int, default=0)
    parser.add_argument("--require-complete-lane-roles", action="store_true")
    args = parser.parse_args()

    result = build_summary(args.extract_dir)
    if args.summary_only:
        result = {key: value for key, value in result.items() if key != "resources"}

    for channel in args.require_channel:
        if channel not in result["channels"]:
            raise SystemExit(f"missing required channel {channel}")
        count = result["channels"][channel]["byte_lane_count"]
        if args.require_byte_lanes and count < args.require_byte_lanes:
            raise SystemExit(f"{channel} has {count} byte lanes, expected at least {args.require_byte_lanes}")
    if args.require_complete_lane_roles and result["missing_lane_roles"]:
        raise SystemExit("missing lane roles: " + ", ".join(result["missing_lane_roles"][:20]))

    text = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
