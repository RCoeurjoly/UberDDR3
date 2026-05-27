#!/usr/bin/env python3
"""Compare seed3 baseline against lock-perturbed seed3 builds.

This is a focused SDF/placement comparator for the IDELAY-control lock
experiment.  It intentionally ignores broad raw-SDF churn and reports the cones
that can explain the observed seed3 failures:

* reset / IDELAYCTRL-ready / state-0 release
* read / BIST / state-17 data-check paths
* IDELAY programming paths, so collateral damage near the locked cone is visible
"""

from __future__ import annotations

import argparse
from collections import defaultdict
import csv
import json
from pathlib import Path
import re
import statistics
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from uberddr3_sdf_compare import ENTRY_RE, SdfEntry, normalize_name, parse_sdf  # noqa: E402


XY_RE = re.compile(r"_X(-?\d+)Y(-?\d+)")

FOCUS_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    (
        "idelayctrl_ready",
        re.compile(r"IDELAYCTRL|idelayctrl|CTRL_DUP|\.RDY|_RDY|i_phy_idelayctrl_rdy|dci_locked", re.I),
    ),
    (
        "phy_reset_release",
        re.compile(r"delay_before_release_reset|sync_rst(?!_controller)", re.I),
    ),
    (
        "controller_reset_release",
        re.compile(r"sync_rst_controller|reset_from_|reset_after_rank|current_rank_rst|i_rst_n|rst_n", re.I),
    ),
    (
        "calib_state_release",
        re.compile(r"state_calibrate|final_calibration_done|initial_calibration_done|calib_complete|bist_done", re.I),
    ),
    (
        "idelay_programming",
        re.compile(
            r"CNTVALUE|cntvalue|idelay_.*_(?:ld|ce|inc)|odelay_.*_(?:ld|ce|inc)|"
            r"o_phy_(?:idelay|odelay).*_(?:ld|ce|inc)|\.(?:LD|CE|INC)\b",
            re.I,
        ),
    ),
    (
        "read_bist_state17",
        re.compile(
            r"wrong_read_data|correct_read_data|bist_counts|read_lane_data|read_lane_data_shifted|"
            r"stage[012]_|stage2_data|stage2_dm|stage2_pending|stage2_update|"
            r"read_pipe|shift_reg_read_pipe|o_wb_ack_read|o_wb_ack_uncalibrated|"
            r"read_dq|read_dqs|dqs_start|dqs_target|dqs_store|bitslip|late_dq|write_dq_late",
            re.I,
        ),
    ),
    (
        "dq_dqs_input",
        re.compile(r"ddr3_dq|io_ddr3_dq|ddr3_dqs|io_ddr3_dqs|ISERDES|IDELAYE2", re.I),
    ),
]


def focus_families(text: str) -> tuple[str, ...]:
    families = [name for name, pattern in FOCUS_PATTERNS if pattern.search(text)]
    return tuple(families)


def stats(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {"count": 0, "min_ps": None, "median_ps": None, "p95_ps": None, "max_ps": None}
    ordered = sorted(values)
    p95_index = min(len(ordered) - 1, int(round((len(ordered) - 1) * 0.95)))
    return {
        "count": len(values),
        "min_ps": ordered[0],
        "median_ps": statistics.median(ordered),
        "p95_ps": ordered[p95_index],
        "max_ps": ordered[-1],
    }


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )


def load_cells(path: Path) -> dict[str, dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return top_module(data).get("cells", {})


def cell_context(name: str, cell: dict[str, Any]) -> str:
    attrs = cell.get("attributes", {})
    return " ".join(
        [
            name,
            str(cell.get("type", "")),
            str(attrs.get("hdlname", "")),
            str(attrs.get("NEXTPNR_BEL", "")),
            str(attrs.get("X_ORIG_TYPE", "")),
            str(attrs.get("X_ORIG_PORT_RDY", "")),
        ]
    )


def bel_xy(bel: str | None) -> tuple[int | None, int | None]:
    if not bel:
        return None, None
    match = XY_RE.search(bel)
    if not match:
        return None, None
    return int(match.group(1)), int(match.group(2))


def manhattan(a_bel: str | None, b_bel: str | None) -> int | None:
    ax, ay = bel_xy(a_bel)
    bx, by = bel_xy(b_bel)
    if ax is None or ay is None or bx is None or by is None:
        return None
    return abs(ax - bx) + abs(ay - by)


def normalize_exact(text: str) -> str:
    return text.replace("\\", "").replace("impl.", "")


def exact_entry_key(entry: SdfEntry) -> str:
    match = ENTRY_RE.match(entry.text)
    if not match:
        return entry.key
    kind = match.group(1)
    tokens = match.group(2).split()
    if kind == "INTERCONNECT" and len(tokens) >= 2:
        return f"{kind}:{normalize_exact(tokens[1])}"
    if kind == "IOPATH" and len(tokens) >= 2:
        return f"{kind}:{normalize_exact(tokens[0])}->{normalize_exact(tokens[1])}"
    return f"{kind}:{normalize_exact(match.group(2))}"


def is_constant_edge(entry: SdfEntry) -> bool:
    return "$PACKER_GND_DRV" in entry.text or "$PACKER_VCC_DRV" in entry.text


def entry_map(entries: list[SdfEntry]) -> dict[str, SdfEntry]:
    return {exact_entry_key(entry): entry for entry in entries}


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def compare_sdf(good: list[SdfEntry], variant: list[SdfEntry], top_n: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    good_by_key = entry_map(good)
    variant_by_key = entry_map(variant)
    good_family_keys: dict[str, set[str]] = defaultdict(set)
    variant_family_keys: dict[str, set[str]] = defaultdict(set)
    for entry in good:
        for family in focus_families(entry.text):
            good_family_keys[family].add(entry.key)
    for entry in variant:
        for family in focus_families(entry.text):
            variant_family_keys[family].add(entry.key)

    rows: list[dict[str, Any]] = []
    summary: dict[str, Any] = {}
    for family, _pattern in FOCUS_PATTERNS:
        family_keys = good_family_keys[family] | variant_family_keys[family]
        common = sorted(family_keys & set(good_by_key) & set(variant_by_key))
        deltas = []
        for key in common:
            good_entry = good_by_key[key]
            variant_entry = variant_by_key[key]
            delta = variant_entry.delay_ps - good_entry.delay_ps
            constant_edge = is_constant_edge(good_entry) or is_constant_edge(variant_entry)
            if not constant_edge:
                deltas.append(delta)
            rows.append(
                {
                    "family": family,
                    "constant_edge": constant_edge,
                    "delta_ps": delta,
                    "baseline_ps": good_entry.delay_ps,
                    "variant_ps": variant_entry.delay_ps,
                    "key": key,
                    "baseline_text": good_entry.text,
                    "variant_text": variant_entry.text,
                }
            )
        summary[family] = {
            "baseline_count": len(good_family_keys[family]),
            "variant_count": len(variant_family_keys[family]),
            "common_count": len(common),
            "baseline_only_count": len(good_family_keys[family] - variant_family_keys[family]),
            "variant_only_count": len(variant_family_keys[family] - good_family_keys[family]),
            "delta_stats_ps": stats(deltas),
            "constant_common_count": sum(
                1 for key in common if is_constant_edge(good_by_key[key]) or is_constant_edge(variant_by_key[key])
            ),
            "slower_over_250ps": sum(1 for value in deltas if value >= 250),
            "slower_over_500ps": sum(1 for value in deltas if value >= 500),
            "faster_over_250ps": sum(1 for value in deltas if value <= -250),
        }

    dynamic_rows = [row for row in rows if not row["constant_edge"]]
    constant_rows = [row for row in rows if row["constant_edge"]]
    dynamic_rows.sort(key=lambda row: abs(float(row["delta_ps"])), reverse=True)
    constant_rows.sort(key=lambda row: abs(float(row["delta_ps"])), reverse=True)
    return dynamic_rows[:top_n], constant_rows[:top_n], summary


def compare_placement(
    baseline_cells: dict[str, dict[str, Any]],
    variant_cells: dict[str, dict[str, Any]],
    top_n: int,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    baseline_family_cells: dict[str, set[str]] = defaultdict(set)
    variant_family_cells: dict[str, set[str]] = defaultdict(set)
    for name, cell in baseline_cells.items():
        for family in focus_families(cell_context(name, cell)):
            baseline_family_cells[family].add(name)
    for name, cell in variant_cells.items():
        for family in focus_families(cell_context(name, cell)):
            variant_family_cells[family].add(name)

    rows: list[dict[str, Any]] = []
    summary: dict[str, Any] = {}
    for family, _pattern in FOCUS_PATTERNS:
        family_cells = baseline_family_cells[family] | variant_family_cells[family]
        common = sorted(family_cells & set(baseline_cells) & set(variant_cells))
        moves: list[int] = []
        bel_changes = 0
        for name in common:
            baseline_cell = baseline_cells[name]
            variant_cell = variant_cells[name]
            baseline_bel = baseline_cell.get("attributes", {}).get("NEXTPNR_BEL")
            variant_bel = variant_cell.get("attributes", {}).get("NEXTPNR_BEL")
            if baseline_bel == variant_bel:
                continue
            bel_changes += 1
            distance = manhattan(baseline_bel, variant_bel)
            if distance is not None:
                moves.append(distance)
            rows.append(
                {
                    "family": family,
                    "cell": normalize_name(name),
                    "type": variant_cell.get("type", baseline_cell.get("type", "")),
                    "manhattan": distance,
                    "baseline_bel": baseline_bel,
                    "variant_bel": variant_bel,
                }
            )
        summary[family] = {
            "baseline_count": len(baseline_family_cells[family]),
            "variant_count": len(variant_family_cells[family]),
            "common_count": len(common),
            "baseline_only_count": len(baseline_family_cells[family] - variant_family_cells[family]),
            "variant_only_count": len(variant_family_cells[family] - baseline_family_cells[family]),
            "bel_changed_count": bel_changes,
            "movement_stats": stats([float(value) for value in moves]),
        }

    rows.sort(key=lambda row: (-1 if row["manhattan"] is None else int(row["manhattan"])), reverse=True)
    return rows[:top_n], summary


def check_locks(lock_path: Path | None, baseline_cells: dict[str, dict[str, Any]], variant_cells: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    if lock_path is None:
        return []
    locks = json.loads(lock_path.read_text(encoding="utf-8")).get("locks", [])
    rows = []
    for lock in locks:
        name = lock["cell"]
        expected = lock["bel"]
        baseline_bel = baseline_cells.get(name, {}).get("attributes", {}).get("NEXTPNR_BEL")
        variant_bel = variant_cells.get(name, {}).get("attributes", {}).get("NEXTPNR_BEL")
        rows.append(
            {
                "cell": name,
                "scope": lock.get("scope", ""),
                "type": lock.get("type", ""),
                "expected_bel": expected,
                "baseline_bel": baseline_bel,
                "variant_bel": variant_bel,
                "matches_expected": variant_bel == expected,
                "matches_baseline": variant_bel == baseline_bel,
            }
        )
    return rows


def write_variant_report(
    out_dir: Path,
    label: str,
    baseline_sdf: Path,
    variant_sdf: Path,
    baseline_json: Path,
    variant_json: Path,
    lock_json: Path | None,
    top_n: int,
) -> dict[str, Any]:
    baseline_entries = parse_sdf(baseline_sdf)
    variant_entries = parse_sdf(variant_sdf)
    baseline_cells = load_cells(baseline_json)
    variant_cells = load_cells(variant_json)

    sdf_rows, constant_sdf_rows, sdf_summary = compare_sdf(baseline_entries, variant_entries, top_n)
    placement_rows, placement_summary = compare_placement(baseline_cells, variant_cells, top_n)
    lock_rows = check_locks(lock_json, baseline_cells, variant_cells)

    variant_dir = out_dir / label
    variant_dir.mkdir(parents=True, exist_ok=True)
    write_csv(
        variant_dir / "focused_sdf_top_deltas.csv",
        sdf_rows,
        ["family", "constant_edge", "delta_ps", "baseline_ps", "variant_ps", "key", "baseline_text", "variant_text"],
    )
    write_csv(
        variant_dir / "focused_sdf_constant_top_deltas.csv",
        constant_sdf_rows,
        ["family", "constant_edge", "delta_ps", "baseline_ps", "variant_ps", "key", "baseline_text", "variant_text"],
    )
    write_csv(
        variant_dir / "focused_placement_moves.csv",
        placement_rows,
        ["family", "manhattan", "cell", "type", "baseline_bel", "variant_bel"],
    )
    write_csv(
        variant_dir / "lock_check.csv",
        lock_rows,
        ["cell", "scope", "type", "expected_bel", "baseline_bel", "variant_bel", "matches_expected", "matches_baseline"],
    )

    report = {
        "label": label,
        "inputs": {
            "baseline_sdf": str(baseline_sdf),
            "variant_sdf": str(variant_sdf),
            "baseline_json": str(baseline_json),
            "variant_json": str(variant_json),
            "lock_json": str(lock_json) if lock_json else None,
        },
        "sdf_summary": sdf_summary,
        "placement_summary": placement_summary,
        "top_sdf_deltas": sdf_rows[:25],
        "top_constant_sdf_deltas": constant_sdf_rows[:25],
        "top_placement_moves": placement_rows[:25],
        "lock_check": {
            "count": len(lock_rows),
            "matches_expected": sum(1 for row in lock_rows if row["matches_expected"]),
            "matches_baseline": sum(1 for row in lock_rows if row["matches_baseline"]),
        },
    }
    (variant_dir / "summary.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return report


def write_readme(out_dir: Path, reports: list[dict[str, Any]]) -> None:
    lines = [
        "# Seed3 Lock-Damage Comparison",
        "",
        "Baseline is the known-passing seed3 build. Variants are the hardware-failing seed3 lock builds.",
        "",
    ]
    for report in reports:
        lines.append(f"## {report['label']}")
        lines.append("")
        lines.append(f"- lock cells matching expected BEL: `{report['lock_check']['matches_expected']}/{report['lock_check']['count']}`")
        lines.append(f"- lock cells also matching baseline BEL: `{report['lock_check']['matches_baseline']}/{report['lock_check']['count']}`")
        lines.append("")
        lines.append("| family | dynamic SDF common | constant SDF common | median delta ps | p95 delta ps | max delta ps | >=500 ps slower | moved cells | max move |")
        lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for family, _pattern in FOCUS_PATTERNS:
            sdf = report["sdf_summary"][family]
            placement = report["placement_summary"][family]
            delta = sdf["delta_stats_ps"]
            movement = placement["movement_stats"]
            lines.append(
                f"| {family} | {delta['count']} | {sdf['constant_common_count']} | {delta['median_ps']} | "
                f"{delta['p95_ps']} | {delta['max_ps']} | {sdf['slower_over_500ps']} | "
                f"{placement['bel_changed_count']} | {movement['max_ps']} |"
            )
        lines.append("")
        lines.append(f"- dynamic SDF details: `{report['label']}/focused_sdf_top_deltas.csv`")
        lines.append(f"- constant-edge SDF details: `{report['label']}/focused_sdf_constant_top_deltas.csv`")
        lines.append(f"- placement details: `{report['label']}/focused_placement_moves.csv`")
        lines.append("")
    (out_dir / "README.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-sdf", required=True, type=Path)
    parser.add_argument("--baseline-json", required=True, type=Path)
    parser.add_argument("--cnt-sdf", required=True, type=Path)
    parser.add_argument("--cnt-json", required=True, type=Path)
    parser.add_argument("--cnt-lock-json", type=Path)
    parser.add_argument("--full-sdf", required=True, type=Path)
    parser.add_argument("--full-json", required=True, type=Path)
    parser.add_argument("--full-lock-json", type=Path)
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/sdf-comparisons/seed3-lock-damage"))
    parser.add_argument("--top-n", type=int, default=250)
    args = parser.parse_args()

    reports = [
        write_variant_report(
            args.out_dir,
            "cntvaluein_lock_fail",
            args.baseline_sdf,
            args.cnt_sdf,
            args.baseline_json,
            args.cnt_json,
            args.cnt_lock_json,
            args.top_n,
        ),
        write_variant_report(
            args.out_dir,
            "cntvaluein_ld_lock_fail",
            args.baseline_sdf,
            args.full_sdf,
            args.baseline_json,
            args.full_json,
            args.full_lock_json,
            args.top_n,
        ),
    ]
    args.out_dir.mkdir(parents=True, exist_ok=True)
    (args.out_dir / "summary.json").write_text(json.dumps(reports, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_readme(args.out_dir, reports)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
