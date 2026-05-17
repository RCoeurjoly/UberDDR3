#!/usr/bin/env python3
"""Extract the YPCB MIG PHASER placement oracle from Vivado's implemented XDC."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any


LOC_RE = re.compile(
    r"^set_property\s+LOC\s+(\S+)\s+\[get_cells\s+-hier\s+-filter\s+\{NAME\s+=~\s+\*/([^}]+)\}\]"
)
CHANNEL_RE = re.compile(r"/c(?P<channel>[01])_u_memc_ui_top_axi/")
GROUP_RE = re.compile(r"ddr_phy_4lanes_(?P<group>\d+)\.u_ddr_phy_4lanes")
LANE_RE = re.compile(r"ddr_byte_lane_(?P<lane>[A-D])\.ddr_byte_lane_(?P=lane)")
PRIMITIVE_SITE_PREFIXES = (
    "PHASER_IN_PHY",
    "PHASER_OUT_PHY",
    "PHASER_REF",
    "PHY_CONTROL",
    "IN_FIFO",
    "OUT_FIFO",
    "OLOGIC",
    "ILOGIC",
    "PLLE2_ADV",
    "MMCME2_ADV",
)


def site_kind(site: str) -> str:
    for prefix in PRIMITIVE_SITE_PREFIXES:
        if site.startswith(prefix + "_"):
            return prefix
    return site.split("_X", 1)[0]


def role_from_cell_path(site: str, cell_path: str) -> str:
    kind = site_kind(site)
    if kind == "PHASER_IN_PHY":
        return "phaser_in"
    if kind == "PHASER_OUT_PHY":
        return "phaser_out"
    if kind == "PHASER_REF":
        return "phaser_ref"
    if kind == "PHY_CONTROL":
        return "phy_control"
    if kind == "IN_FIFO":
        return "in_fifo"
    if kind == "OUT_FIFO":
        return "out_fifo"
    if kind == "OLOGIC" and "slave_ts" in cell_path:
        return "slave_ts_ologic"
    if kind == "PLLE2_ADV":
        return "pll"
    if kind == "MMCME2_ADV":
        return "mmcm"
    return kind.lower()


def lane_index(lane: str | None) -> int | None:
    if lane is None:
        return None
    return {"A": 0, "B": 1, "C": 2, "D": 3}[lane]


def parse_oracle(path: Path) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    channels: dict[str, dict[str, Any]] = defaultdict(
        lambda: {
            "byte_lanes": {},
            "phy_groups": defaultdict(dict),
            "infrastructure": {},
        }
    )

    for line_number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
        match = LOC_RE.match(line.strip())
        if not match:
            continue

        site, cell_path = match.groups()
        kind = site_kind(site)
        if kind not in PRIMITIVE_SITE_PREFIXES:
            continue

        channel_match = CHANNEL_RE.search("/" + cell_path)
        channel = channel_match.group("channel") if channel_match else None
        group_match = GROUP_RE.search(cell_path)
        group = int(group_match.group("group")) if group_match else None
        lane_match = LANE_RE.search(cell_path)
        lane = lane_match.group("lane") if lane_match else None
        role = role_from_cell_path(site, cell_path)

        entry = {
            "line": line_number,
            "site": site,
            "site_kind": kind,
            "role": role,
            "channel": None if channel is None else int(channel),
            "phy_group": group,
            "lane": lane,
            "lane_index": lane_index(lane),
            "cell_glob": "*/" + cell_path,
        }
        entries.append(entry)

        if channel is None:
            continue

        channel_key = f"c{channel}"
        if lane is not None and group is not None:
            logical_lane = group * 4 + lane_index(lane)
            lane_key = f"group{group}.{lane}"
            lane_data = channels[channel_key]["byte_lanes"].setdefault(
                lane_key,
                {
                    "phy_group": group,
                    "lane": lane,
                    "lane_index": lane_index(lane),
                    "logical_lane": logical_lane,
                    "resources": {},
                },
            )
            lane_data["resources"][role] = site
        elif group is not None:
            channels[channel_key]["phy_groups"][str(group)][role] = site
        else:
            channels[channel_key]["infrastructure"][role] = site

    normalized_channels: dict[str, Any] = {}
    for channel, data in sorted(channels.items()):
        normalized_channels[channel] = {
            "byte_lanes": {
                key: data["byte_lanes"][key]
                for key in sorted(
                    data["byte_lanes"],
                    key=lambda item: (
                        data["byte_lanes"][item]["phy_group"],
                        data["byte_lanes"][item]["lane_index"],
                    ),
                )
            },
            "phy_groups": {
                key: data["phy_groups"][key]
                for key in sorted(data["phy_groups"], key=lambda item: int(item))
            },
            "infrastructure": dict(sorted(data["infrastructure"].items())),
        }

    return {
        "source": str(path),
        "entry_count": len(entries),
        "entries": entries,
        "channels": normalized_channels,
    }


def summarize(oracle: dict[str, Any]) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "source": oracle["source"],
        "entry_count": oracle["entry_count"],
        "channels": {},
    }
    for channel, data in oracle["channels"].items():
        role_counts: dict[str, int] = defaultdict(int)
        for lane in data["byte_lanes"].values():
            for role in lane["resources"]:
                role_counts[role] += 1
        for group in data["phy_groups"].values():
            for role in group:
                role_counts[role] += 1
        for role in data["infrastructure"]:
            role_counts[role] += 1
        summary["channels"][channel] = {
            "byte_lane_count": len(data["byte_lanes"]),
            "phy_group_count": len(data["phy_groups"]),
            "role_counts": dict(sorted(role_counts.items())),
        }
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--implemented-xdc",
        type=Path,
        default=Path("artifacts/task6/vivado-oracle/ypcb-systest/implemented.xdc"),
    )
    parser.add_argument("--out", type=Path)
    parser.add_argument("--summary", action="store_true")
    parser.add_argument("--require-channel", choices=("c0", "c1"), action="append", default=[])
    parser.add_argument("--require-byte-lanes", type=int, default=0)
    args = parser.parse_args()

    oracle = parse_oracle(args.implemented_xdc)
    result = summarize(oracle) if args.summary else oracle

    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    else:
        print(json.dumps(result, indent=2, sort_keys=True))

    for channel in args.require_channel:
        if channel not in oracle["channels"]:
            raise SystemExit(f"missing required channel {channel}")
        if args.require_byte_lanes:
            count = len(oracle["channels"][channel]["byte_lanes"])
            if count < args.require_byte_lanes:
                raise SystemExit(
                    f"{channel} has {count} byte lanes, expected at least {args.require_byte_lanes}"
                )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
