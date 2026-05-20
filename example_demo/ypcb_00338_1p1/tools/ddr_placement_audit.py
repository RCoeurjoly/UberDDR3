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

DQ_RE = re.compile(r"genblk5\[(\d+)\]")
DQS_RE = re.compile(r"genblk7\[(\d+)\]")
CMD_RE = re.compile(r"genblk1\[(\d+)\]")
SITE_Y_RE = re.compile(r"Y(\d+)$")


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


def y_number(site: str) -> int | None:
    match = SITE_Y_RE.search(site or "")
    return int(match.group(1)) if match else None


def compact_sites(sites: set[str]) -> str:
    clean = sorted((s for s in sites if s), key=lambda s: (re.sub(r"Y\d+$", "", s), y_number(s) or -1, s))
    return ",".join(clean) if clean else "-"


def site_span(sites: set[str]) -> str:
    ys = [y for y in (y_number(s) for s in sites) if y is not None]
    if not ys:
        return "-"
    return f"Y{min(ys)}..Y{max(ys)}"


def summarize_json(path: Path) -> list[str]:
    cells = load_json_cells(path)
    counts = Counter(cell_type for _, cell_type in cells if cell_type in DDR_TYPES)
    dq_lane_counts: dict[int, Counter[str]] = defaultdict(Counter)
    dqs_lane_counts: dict[int, Counter[str]] = defaultdict(Counter)
    cmd_counts: dict[int, Counter[str]] = defaultdict(Counter)

    for name, cell_type in cells:
        if cell_type not in DDR_TYPES:
            continue
        dq_match = DQ_RE.search(name)
        if dq_match:
            dq_lane_counts[int(dq_match.group(1)) // 8][cell_type] += 1
        dqs_match = DQS_RE.search(name)
        if dqs_match:
            dqs_lane_counts[int(dqs_match.group(1))][cell_type] += 1
        cmd_match = CMD_RE.search(name)
        if cmd_match:
            cmd_counts[int(cmd_match.group(1))][cell_type] += 1

    lines = [f"# JSON {path}", "## DDR primitive counts"]
    for cell_type, count in sorted(counts.items()):
        lines.append(f"{cell_type}\t{count}")

    lines.append("## Byte-lane primitive counts")
    lines.append("lane\tDQ_IOBUF\tDQ_IDELAYE2\tDQ_ISERDESE2\tDQ_OSERDESE2\tDQS_IOBUFDS\tDQS_IDELAYE2\tDQS_ISERDESE2\tDQS_OSERDESE2")
    for lane in sorted(set(dq_lane_counts) | set(dqs_lane_counts)):
        dq = dq_lane_counts[lane]
        dqs = dqs_lane_counts[lane]
        lines.append(
            f"{lane}\t{dq['IOBUF']}\t{dq['IDELAYE2']}\t{dq['ISERDESE2']}\t{dq['OSERDESE2']}\t"
            f"{dqs['IOBUFDS']}\t{dqs['IDELAYE2']}\t{dqs['ISERDESE2']}\t{dqs['OSERDESE2']}"
        )

    lines.append("## Command/address OSERDES count")
    lines.append(f"count\t{sum(c['OSERDESE2'] for c in cmd_counts.values())}")
    return lines


def summarize_vivado_tsv(path: Path) -> list[str]:
    if not path.exists():
        return [f"# Vivado TSV {path} missing"]
    counts = Counter()
    dq_sites: dict[int, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    dqs_sites: dict[int, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            ref = row.get("ref_name", "")
            counts[ref] += 1
            name = row.get("name", "")
            site = row.get("site", "")
            dq_match = DQ_RE.search(name)
            if dq_match:
                dq_sites[int(dq_match.group(1)) // 8][ref].add(site)
            dqs_match = DQS_RE.search(name)
            if dqs_match:
                dqs_sites[int(dqs_match.group(1))][ref].add(site)

    lines = [f"# Vivado cells {path}", "## DDR primitive counts"]
    for cell_type, count in sorted(counts.items()):
        lines.append(f"{cell_type}\t{count}")

    lines.append("## Byte-lane site summary")
    lines.append("lane\tDQ_IOB_span\tDQ_IDELAY_span\tDQ_ILOGIC_span\tDQ_OLOGIC_span\tDQS_IOB\tDQS_IDELAY\tDQS_ILOGIC\tDQS_OLOGIC")
    for lane in sorted(set(dq_sites) | set(dqs_sites)):
        dq = dq_sites[lane]
        dqs = dqs_sites[lane]
        lines.append(
            f"{lane}\t{site_span(dq['IOBUF'])}\t{site_span(dq['IDELAYE2'])}\t"
            f"{site_span(dq['ISERDESE2'])}\t{site_span(dq['OSERDESE2'])}\t"
            f"{compact_sites(dqs['IOBUFDS'])}\t{compact_sites(dqs['IDELAYE2'])}\t"
            f"{compact_sites(dqs['ISERDESE2'])}\t{compact_sites(dqs['OSERDESE2'])}"
        )
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
