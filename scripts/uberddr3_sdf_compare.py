#!/usr/bin/env python3
"""Compare nextpnr SDF artifacts for UberDDR3 seed investigations.

The comparator is intentionally lightweight. It treats nextpnr SDF as a source
of routed delay observations, groups delay records into DDR3-relevant families,
and compares destination-normalized keys so synthesized source-name churn does
not dominate the report.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
import csv
import json
from pathlib import Path
import re
import statistics
from typing import Iterable


DELAY_RE = re.compile(r"\((-?\d+(?:\.\d+)?):(-?\d+(?:\.\d+)?):(-?\d+(?:\.\d+)?)\)")
ENTRY_RE = re.compile(r"^\s*\((INTERCONNECT|IOPATH)\s+(.+)$")
DQ_BIT_RE = re.compile(r"(?:ddr3_dq|io_ddr3_dq)\[(\d+)\]|genblk5\[(\d+)\]")
DQS_LANE_RE = re.compile(r"(?:ddr3_dqs_[pn]|io_ddr3_dqs(?:_n)?)\[(\d+)\]|genblk7\[(\d+)\]")
XY_RE = re.compile(r"_X(-?\d+)Y(-?\d+)")


@dataclass(frozen=True)
class SdfEntry:
    kind: str
    text: str
    key: str
    delay_ps: float
    families: tuple[str, ...]
    lane: str
    bit: str


def normalize_name(text: str) -> str:
    text = text.replace("\\", "")
    text = text.replace("impl.", "")
    text = re.sub(r"\$abc\$\d+", "$abc$", text)
    text = re.sub(r"\$auto\$[^\s)]+", "$auto$", text)
    text = re.sub(r"\$\d+", "$N", text)
    text = re.sub(r"/nix/store/[a-z0-9]+-", "/nix/store/HASH-", text)
    return text


def entry_key(kind: str, body: str) -> str:
    tokens = body.split()
    if kind == "INTERCONNECT" and len(tokens) >= 2:
        # The destination pin is usually more stable than the synthesized source.
        return f"{kind}:{normalize_name(tokens[1])}"
    if kind == "IOPATH" and len(tokens) >= 2:
        return f"{kind}:{normalize_name(tokens[0])}->{normalize_name(tokens[1])}"
    return f"{kind}:{normalize_name(body)}"


def first_int(groups: Iterable[str | None]) -> int | None:
    for item in groups:
        if item is not None:
            return int(item)
    return None


def lane_and_bit(text: str) -> tuple[str, str]:
    dq = DQ_BIT_RE.search(text)
    if dq:
        bit = first_int(dq.groups())
        if bit is not None:
            return f"lane{bit // 8}", f"dq{bit}"
    dqs = DQS_LANE_RE.search(text)
    if dqs:
        lane = first_int(dqs.groups())
        if lane is not None:
            return f"lane{lane}", f"dqs{lane}"
    return "all", ""


def classify(text: str) -> tuple[str, ...]:
    t = text.lower()
    families: list[str] = []
    has_dq = "ddr3_dq" in t or "io_ddr3_dq" in t or "genblk5[" in t or "read_dq" in t
    has_dqs = "dqs" in t or "genblk7[" in t
    inputish = any(s in t for s in ["ibuf", "inbuf", "idelay", "iserdes", "read_dq", "read_dqs", "ddly"])
    outputish = any(s in t for s in ["obuf", "outbuf", "oserdes", "write_dq", "toggle_dqs", "tri_control"])

    if has_dqs and inputish:
        families.append("dqs_input")
    if has_dq and inputish:
        families.append("dq_input")
    if has_dqs and outputish:
        families.append("dqs_output")
    if has_dq and outputish:
        families.append("dq_output")
    if any(s in t for s in ["cntvalue", "_ld", ".ld", " ce", ".ce", " inc", ".inc", "idelay_data_ld", "idelay_dqs_ld", "odelay_data_ld", "odelay_dqs_ld"]):
        families.append("idelay_control")
    if "idelayctrl" in t:
        families.append("idelayctrl")
    if "delay_before_release_reset" in t:
        families.append("idelayctrl_reset_release")
    if any(s in t for s in ["state_calibrate", "calib", "bitslip", "dqs_start", "dqs_target", "dqs_store", "write_level", "mpr", "reset_from_test"]):
        families.append("calibration_fsm")
    if any(s in t for s in ["clk_wiz", "mmcm", "pll", "bufg", "bufh", "bufr", "controller_clk", "ddr3_clk", "ref_clk", "clk_90"]):
        families.append("clocking")
    if any(s in t for s in [" rst", "reset", "sync", "locked"]):
        families.append("reset_cdc")
    if any(s in t for s in ["iob", "ilogic", "ologic", "idelay_x", "pad"]):
        families.append("iologic_physical")
    return tuple(dict.fromkeys(families)) or ("other",)


def parse_sdf(path: Path) -> list[SdfEntry]:
    entries: list[SdfEntry] = []
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = ENTRY_RE.match(raw)
        if not match:
            continue
        delay_values = [float(value) for triple in DELAY_RE.findall(raw) for value in triple]
        if not delay_values:
            continue
        kind = match.group(1)
        body = match.group(2)
        lane, bit = lane_and_bit(raw)
        entries.append(
            SdfEntry(
                kind=kind,
                text=raw.strip(),
                key=entry_key(kind, body),
                delay_ps=max(delay_values),
                families=classify(raw),
                lane=lane,
                bit=bit,
            )
        )
    return entries


def stats(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {"count": 0, "min_ps": None, "median_ps": None, "p95_ps": None, "max_ps": None, "spread_ps": None}
    ordered = sorted(values)
    p95_index = min(len(ordered) - 1, int(round((len(ordered) - 1) * 0.95)))
    return {
        "count": len(values),
        "min_ps": ordered[0],
        "median_ps": statistics.median(ordered),
        "p95_ps": ordered[p95_index],
        "max_ps": ordered[-1],
        "spread_ps": ordered[-1] - ordered[0],
    }


def summarize(entries: list[SdfEntry], top_n: int) -> dict[str, object]:
    by_family: dict[str, list[float]] = defaultdict(list)
    by_family_lane: dict[tuple[str, str], list[float]] = defaultdict(list)
    for entry in entries:
        for family in entry.families:
            by_family[family].append(entry.delay_ps)
            by_family_lane[(family, entry.lane)].append(entry.delay_ps)
    return {
        "entry_count": len(entries),
        "by_family": {key: stats(values) for key, values in sorted(by_family.items())},
        "by_family_lane": {f"{family}:{lane}": stats(values) for (family, lane), values in sorted(by_family_lane.items())},
        "top": [entry_to_json(entry) for entry in sorted(entries, key=lambda item: item.delay_ps, reverse=True)[:top_n]],
    }


def entry_to_json(entry: SdfEntry) -> dict[str, object]:
    return {
        "delay_ps": entry.delay_ps,
        "kind": entry.kind,
        "families": list(entry.families),
        "lane": entry.lane,
        "bit": entry.bit,
        "key": entry.key,
        "text": entry.text,
    }


def compare(good: list[SdfEntry], bad: list[SdfEntry], top_n: int) -> dict[str, object]:
    good_by_key = {entry.key: entry for entry in good}
    bad_by_key = {entry.key: entry for entry in bad}
    common_keys = sorted(set(good_by_key) & set(bad_by_key))
    changed = []
    by_family_lane_delta: dict[tuple[str, str], list[float]] = defaultdict(list)
    for key in common_keys:
        good_entry = good_by_key[key]
        bad_entry = bad_by_key[key]
        delta = bad_entry.delay_ps - good_entry.delay_ps
        item = {
            "key": key,
            "delta_ps": delta,
            "good_ps": good_entry.delay_ps,
            "bad_ps": bad_entry.delay_ps,
            "bad_families": list(bad_entry.families),
            "bad_lane": bad_entry.lane,
            "bad_bit": bad_entry.bit,
            "good_text": good_entry.text,
            "bad_text": bad_entry.text,
        }
        changed.append(item)
        for family in bad_entry.families:
            by_family_lane_delta[(family, bad_entry.lane)].append(delta)
    return {
        "common_key_count": len(common_keys),
        "good_only_count": len(set(good_by_key) - set(bad_by_key)),
        "bad_only_count": len(set(bad_by_key) - set(good_by_key)),
        "largest_absolute_deltas": sorted(changed, key=lambda item: abs(item["delta_ps"]), reverse=True)[:top_n],
        "largest_bad_slower_deltas": sorted(changed, key=lambda item: item["delta_ps"], reverse=True)[:top_n],
        "largest_bad_faster_deltas": sorted(changed, key=lambda item: item["delta_ps"])[:top_n],
        "delta_by_family_lane": {
            f"{family}:{lane}": stats(values) for (family, lane), values in sorted(by_family_lane_delta.items())
        },
    }


def load_placement_summary(path: Path | None) -> dict[str, object] | None:
    if path is None:
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    modules = data.get("modules", {})
    module = next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )
    rows = []
    for name, cell in module.get("cells", {}).items():
        cell_type = cell.get("type", "")
        bel = str(cell.get("attributes", {}).get("NEXTPNR_BEL", ""))
        combined = f"{name} {cell_type} {bel}"
        families = classify(combined)
        if families == ("other",) and not any(s in cell_type for s in ["IDELAY", "ISERDES", "OSERDES", "IOB", "PAD", "BUFG", "MMCM", "PLL"]):
            continue
        lane, bit = lane_and_bit(combined)
        xy = XY_RE.search(bel)
        rows.append({
            "cell": normalize_name(name),
            "type": cell_type,
            "bel": bel,
            "x": int(xy.group(1)) if xy else None,
            "y": int(xy.group(2)) if xy else None,
            "families": list(families),
            "lane": lane,
            "bit": bit,
        })
    return {"path": str(path), "count": len(rows), "cells": rows}


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def write_outputs(report: dict[str, object], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    family_rows = []
    good = report["good"]["by_family_lane"]
    bad = report["bad"]["by_family_lane"]
    deltas = report["comparison"]["delta_by_family_lane"]
    for key in sorted(set(good) | set(bad) | set(deltas)):
        family, lane = key.split(":", 1)
        good_stats = good.get(key, {})
        bad_stats = bad.get(key, {})
        delta_stats = deltas.get(key, {})
        family_rows.append({
            "family": family,
            "lane": lane,
            "good_count": good_stats.get("count", 0),
            "good_max_ps": good_stats.get("max_ps"),
            "good_spread_ps": good_stats.get("spread_ps"),
            "bad_count": bad_stats.get("count", 0),
            "bad_max_ps": bad_stats.get("max_ps"),
            "bad_spread_ps": bad_stats.get("spread_ps"),
            "delta_median_ps": delta_stats.get("median_ps"),
            "delta_p95_ps": delta_stats.get("p95_ps"),
            "delta_max_ps": delta_stats.get("max_ps"),
        })
    write_csv(
        out_dir / "family_lane_metrics.csv",
        family_rows,
        ["family", "lane", "good_count", "good_max_ps", "good_spread_ps", "bad_count", "bad_max_ps", "bad_spread_ps", "delta_median_ps", "delta_p95_ps", "delta_max_ps"],
    )

    top_rows = report["comparison"]["largest_bad_slower_deltas"]
    write_csv(
        out_dir / "largest_bad_slower_deltas.csv",
        top_rows,
        ["delta_ps", "good_ps", "bad_ps", "bad_lane", "bad_bit", "bad_families", "key", "good_text", "bad_text"],
    )

    lines = [
        "# UberDDR3 SDF Comparison",
        "",
        f"- good SDF: `{report['inputs']['good_sdf']}`",
        f"- bad SDF: `{report['inputs']['bad_sdf']}`",
        f"- common normalized keys: `{report['comparison']['common_key_count']}`",
        f"- good-only keys: `{report['comparison']['good_only_count']}`",
        f"- bad-only keys: `{report['comparison']['bad_only_count']}`",
        "",
        "## Highest-Signal Tables",
        "",
        "- `family_lane_metrics.csv`: per DDR family/lane max, spread, and bad-minus-good deltas.",
        "- `largest_bad_slower_deltas.csv`: normalized paths where the bad seed is slowest relative to the good seed.",
        "- `summary.json`: full machine-readable report, including optional placement summaries.",
        "",
        "## Largest Bad-Slower Deltas",
        "",
    ]
    for item in top_rows[:20]:
        families = ",".join(item.get("bad_families", []))
        lines.append(f"- {item['delta_ps']} ps {item.get('bad_lane', 'all')} {families}: `{item['key']}`")
    (out_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--good-sdf", required=True, type=Path)
    parser.add_argument("--bad-sdf", required=True, type=Path)
    parser.add_argument("--good-json", type=Path, help="Optional nextpnr placed JSON for the good seed")
    parser.add_argument("--bad-json", type=Path, help="Optional nextpnr placed JSON for the bad seed")
    parser.add_argument("--label", default="seed-sdf")
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/sdf-comparisons"))
    parser.add_argument("--top-n", type=int, default=100)
    args = parser.parse_args()

    good_entries = parse_sdf(args.good_sdf)
    bad_entries = parse_sdf(args.bad_sdf)
    report = {
        "schema": "uberddr3-sdf-compare-v1",
        "inputs": {
            "good_sdf": str(args.good_sdf),
            "bad_sdf": str(args.bad_sdf),
            "good_json": str(args.good_json) if args.good_json else None,
            "bad_json": str(args.bad_json) if args.bad_json else None,
        },
        "good": summarize(good_entries, args.top_n),
        "bad": summarize(bad_entries, args.top_n),
        "comparison": compare(good_entries, bad_entries, args.top_n),
        "placements": {
            "good": load_placement_summary(args.good_json),
            "bad": load_placement_summary(args.bad_json),
        },
    }
    out_dir = args.out_dir / args.label
    write_outputs(report, out_dir)
    print(out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
