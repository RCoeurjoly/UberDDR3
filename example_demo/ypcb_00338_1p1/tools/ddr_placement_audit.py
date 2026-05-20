#!/usr/bin/env python3
"""Summarize DDR primitive structure from Yosys JSON and Vivado cell TSV."""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

DDR_TYPES = {
    "ISERDESE2",
    "OSERDESE2",
    "IDELAYE2",
    "ODELAYE2",
    "IDELAYCTRL",
    "IOBUF",
    "IOBUFDS",
    "PLLE2_ADV",
    "BUFG",
}

LANE_RE = re.compile(r"genblk5\[(\d+)\]")
CMD_RE = re.compile(r"genblk1\[(\d+)\]")


def top_module(modules: dict) -> str:
    candidates = [name for name, mod in modules.items() if mod.get("cells")]
    preferred = [name for name in candidates if not name.startswith("$")]
    if not preferred:
        raise SystemExit("no populated user module found in JSON")
    return preferred[-1]


def load_json_cells(path: Path) -> list[tuple[str, str]]:
    data = json.loads(path.read_text())
    module_name = top_module(data["modules"])
    cells = data["modules"][module_name]["cells"]
    return [(name, cell.get("type", "")) for name, cell in cells.items()]


def summarize_json(path: Path) -> list[str]:
    cells = load_json_cells(path)
    counts = Counter(cell_type for _, cell_type in cells if cell_type in DDR_TYPES)
    lane_counts: dict[int, Counter[str]] = defaultdict(Counter)
    cmd_counts: dict[int, Counter[str]] = defaultdict(Counter)

    for name, cell_type in cells:
        if cell_type not in DDR_TYPES:
            continue
        lane_match = LANE_RE.search(name)
        if lane_match:
            lane_counts[int(lane_match.group(1))][cell_type] += 1
        cmd_match = CMD_RE.search(name)
        if cmd_match:
            cmd_counts[int(cmd_match.group(1))][cell_type] += 1

    lines = [f"# JSON {path}", "## DDR primitive counts"]
    for cell_type, count in sorted(counts.items()):
        lines.append(f"{cell_type}\t{count}")

    lines.append("## DQ/DQS lane primitive counts")
    lines.append("lane\tIOBUF\tIOBUFDS\tIDELAYE2\tISERDESE2\tOSERDESE2")
    for lane in sorted(lane_counts):
        c = lane_counts[lane]
        lines.append(
            f"{lane}\t{c['IOBUF']}\t{c['IOBUFDS']}\t{c['IDELAYE2']}\t{c['ISERDESE2']}\t{c['OSERDESE2']}"
        )

    lines.append("## Command/address OSERDES count")
    lines.append(f"count\t{sum(c['OSERDESE2'] for c in cmd_counts.values())}")
    return lines


def summarize_vivado_tsv(path: Path) -> list[str]:
    if not path.exists():
        return [f"# Vivado TSV {path} missing"]
    counts = Counter()
    lane_sites: dict[int, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    rows = []
    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)
            ref = row.get("ref_name", "")
            counts[ref] += 1
            lane_match = LANE_RE.search(row.get("name", ""))
            if lane_match:
                lane_sites[int(lane_match.group(1))][ref].add(row.get("site", ""))

    lines = [f"# Vivado cells {path}", "## DDR primitive counts"]
    for cell_type, count in sorted(counts.items()):
        lines.append(f"{cell_type}\t{count}")

    lines.append("## DQ/DQS lane sites")
    lines.append("lane\tIOBUF_sites\tIOBUFDS_sites\tIDELAYE2_sites\tISERDESE2_sites\tOSERDESE2_sites")
    for lane in sorted(lane_sites):
        refs = lane_sites[lane]
        fields = []
        for ref in ["IOBUF", "IOBUFDS", "IDELAYE2", "ISERDESE2", "OSERDESE2"]:
            sites = sorted(s for s in refs[ref] if s)
            fields.append(",".join(sites) if sites else "-")
        lines.append(f"{lane}\t" + "\t".join(fields))
    return lines


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="append", default=[], help="Yosys/OpenXC7 JSON to summarize")
    parser.add_argument("--vivado-tsv", action="append", default=[], help="Vivado DDR cell TSV to summarize")
    args = parser.parse_args()

    output: list[str] = []
    for path in args.json:
        output.extend(summarize_json(Path(path)))
        output.append("")
    for path in args.vivado_tsv:
        output.extend(summarize_vivado_tsv(Path(path)))
        output.append("")
    print("\n".join(output).rstrip())


if __name__ == "__main__":
    main()
