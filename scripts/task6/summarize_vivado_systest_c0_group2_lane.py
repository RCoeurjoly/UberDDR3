#!/usr/bin/env python3
"""Summarize focused c0.group2 lane SYSTEST PHASER/FIFO extraction."""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

IMPORTANT_PROPS = {
    "PHASER_IN_PHY": (
        "LOC", "OUTPUT_CLK_SRC", "CLKOUT_DIV", "PHASEREFCLK_PERIOD", "MEMREFCLK_PERIOD",
        "REFCLK_PERIOD", "FINE_DELAY", "HALF_CYCLE_ADJ", "ICLK_TO_RCLK_BYPASS",
        "IS_PHASEREFCLK_INVERTED", "IS_MEMREFCLK_INVERTED", "IS_RST_INVERTED",
    ),
    "PHASER_OUT_PHY": (
        "LOC", "OUTPUT_CLK_SRC", "CLKOUT_DIV", "PHASEREFCLK_PERIOD", "MEMREFCLK_PERIOD",
        "REFCLK_PERIOD", "FINE_DELAY", "DATA_CTL_N", "DATA_RD_CYCLES", "COARSE_BYPASS",
        "IS_BURSTPENDINGPHY_INVERTED", "IS_RST_INVERTED",
    ),
    "PHY_CONTROL": (
        "LOC", "BURST_MODE", "CLK_RATIO", "SYNC_MODE", "IS_PHYCTLWRENABLE_INVERTED",
        "IS_PLLLOCK_INVERTED", "IS_REFDLLLOCK_INVERTED", "IS_RESET_INVERTED", "IS_SYNCIN_INVERTED",
    ),
    "PHASER_REF": (
        "LOC", "FREQ_REF_DIV", "REFCLK_PERIOD", "IS_PWRDWN_INVERTED", "IS_RST_INVERTED",
    ),
    "IN_FIFO": ("LOC",),
    "OUT_FIFO": ("LOC",),
}

CONTROL_PINS = {
    "PHY_CONTROL": {
        "AUXOUTPUT", "INBURSTPENDING", "OUTBURSTPENDING", "PHYCTLWD", "PHYCTLWRENABLE",
        "PLLLOCK", "READCALIBENABLE", "REFDLLLOCK", "RESET", "SYNCIN", "WRITECALIBENABLE",
    },
    "PHASER_IN_PHY": {
        "BURSTPENDINGPHY", "COUNTERLOADEN", "COUNTERREADEN", "ENCALIBPHY",
        "FINEENABLE", "FINEINC", "FREQREFCLK", "ICLK", "ICLKDIV",
        "ISERDESRST", "MEMREFCLK", "PHASEREFCLK", "PHASELOCKED",
        "PHYCLK", "RANKSEL", "RANKSELPHY", "RCLK", "RST", "RSTDQSFIND",
        "SYNCIN", "SYSCLK", "WRENABLE",
    },
    "PHASER_OUT_PHY": {
        "BURSTPENDINGPHY", "COARSEENABLE", "COARSEINC", "COUNTERLOADEN",
        "COUNTERREADEN", "ENCALIBPHY", "FINEENABLE", "FINEINC",
        "FREQREFCLK", "MEMREFCLK", "OCLK", "OCLKDELAYED", "OCLKDIV",
        "OSERDESRST", "PHASEREFCLK", "PHYCLK", "RDENABLE", "RST",
        "SYNCIN", "SYSCLK",
    },
    "IN_FIFO": {"D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "RDCLK", "RDEN", "RESET", "WRCLK", "WREN"},
    "OUT_FIFO": {"D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "RDCLK", "RDEN", "RESET", "WRCLK", "WREN"},
}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def load_extract(extract_dir: Path) -> dict[str, Any]:
    cells = read_tsv(extract_dir / "cells.tsv")
    props = read_tsv(extract_dir / "properties.tsv")
    pins = read_tsv(extract_dir / "pins.tsv")
    nets = read_tsv(extract_dir / "nets.tsv")
    pips = read_tsv(extract_dir / "net-pips.tsv")

    props_by_cell: dict[str, dict[str, str]] = defaultdict(dict)
    for row in props:
        props_by_cell[row["cell"]][row["property"]] = row["value"]

    pins_by_cell: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in pins:
        pins_by_cell[row["cell"]].append(row)

    nets_by_name = {row["net"]: row for row in nets}
    pips_by_name = {row["net"]: row for row in pips}

    resources = []
    for row in cells:
        ref = row["ref_name"]
        wanted_props = IMPORTANT_PROPS.get(ref, ("LOC",))
        pin_rows = pins_by_cell[row["cell"]]
        control_names = CONTROL_PINS.get(ref, set())
        selected_pins = []
        for pin in pin_rows:
            ref_pin = pin["ref_pin"]
            base = ref_pin.split("[", 1)[0]
            if base in control_names or ref in {"IN_FIFO", "OUT_FIFO"}:
                net = pin["net"]
                selected_pins.append({
                    "ref_pin": ref_pin,
                    "direction": pin["direction"],
                    "net": net,
                    "net_type": pin["net_type"],
                    "drivers": nets_by_name.get(net, {}).get("drivers", ""),
                    "loads": nets_by_name.get(net, {}).get("loads", ""),
                    "pip_count": int(pips_by_name.get(net, {}).get("pip_count", "0") or 0),
                })
        resources.append({
            "role": row["role"],
            "cell": row["cell"],
            "ref_name": ref,
            "loc": row["loc"],
            "bel": row["bel"],
            "site": row["site"],
            "properties": {name: props_by_cell[row["cell"]].get(name, "") for name in wanted_props if props_by_cell[row["cell"]].get(name, "") != ""},
            "selected_pins": selected_pins,
        })

    phyctl = next((r for r in resources if r["role"] == "GROUP_PHY_CONTROL"), None)
    phyctlwd = []
    if phyctl:
        for pin in phyctl["selected_pins"]:
            if pin["ref_pin"].startswith("PHYCTLWD["):
                phyctlwd.append(pin)
        phyctlwd.sort(key=lambda p: int(p["ref_pin"].split("[")[1].split("]")[0]))

    return {
        "schema": "vivado-systest-c0-group2-lane-focused-v1",
        "extract_dir": str(extract_dir),
        "cell_count": len(cells),
        "net_count": len(nets),
        "resources": resources,
        "phyctlwd_mapping": phyctlwd,
    }


def emit_markdown(summary: dict[str, Any], out: Path) -> None:
    lines = [
        "# SYSTEST c0.group2 lane Focused PHASER/FIFO Extract",
        "",
        f"Extract: `{summary['extract_dir']}`",
        "",
        "## Resource Tuple",
        "",
        "| Role | Ref | LOC | Cell |",
        "| --- | --- | --- | --- |",
    ]
    for r in summary["resources"]:
        if r["ref_name"] in {"PHASER_REF", "PHY_CONTROL", "PHASER_IN_PHY", "PHASER_OUT_PHY", "IN_FIFO", "OUT_FIFO"}:
            lines.append(f"| `{r['role']}` | `{r['ref_name']}` | `{r['loc']}` | `{r['cell']}` |")
    lines.extend(["", "## Key Properties", ""])
    for r in summary["resources"]:
        if r["properties"]:
            lines.append(f"### {r['role']} `{r['loc']}`")
            lines.append("")
            for k, v in r["properties"].items():
                lines.append(f"- `{k}` = `{v}`")
            lines.append("")
    lines.extend(["## PHY_CONTROL Word Nets", "", "| Pin | Net | Driver Count | Load Count |", "| --- | --- | --- | --- |"])
    for p in summary["phyctlwd_mapping"]:
        drivers = [d for d in p["drivers"].split(",") if d]
        loads = [l for l in p["loads"].split(",") if l]
        lines.append(f"| `{p['ref_pin']}` | `{p['net']}` | {len(drivers)} | {len(loads)} |")
    lines.extend(["", "## Initial Interpretation", ""])
    lines.extend([
        "- This is the hardware-passing SYSTEST source of truth, unlike the failed synthetic Vivado diagnostic.",
        "- `c0.group2 lane` uses the X0Y0 or X0Y1 PHASER/FIFO tuple, but its `PHY_CONTROL` is the shared group-2 instance at `PHY_CONTROL_X0Y0`.",
        "- The next open-flow patch should compare these properties and pin nets against the open diagnostic before changing FIFO segbits.",
        "- The PHY_CONTROL word is driven by MIG nets, not by the synthetic diagnostic sequence ROM; reproducing `phyctl_ready` probably needs the relevant control sequencing, not only matching FIFO `IN_USE` bits.",
    ])
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extract_dir", type=Path)
    parser.add_argument("--out-json", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    args = parser.parse_args()
    summary = load_extract(args.extract_dir)
    args.out_json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    emit_markdown(summary, args.out_md)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
