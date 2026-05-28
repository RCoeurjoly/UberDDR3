#!/usr/bin/env python3
"""Compare baseline and CNTVALUEIN3-lock focused skew audits by seed."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path
from statistics import median


LONG_POLL_GROUP = "cntvaluein3_lock_heldout_long_poll_500"


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def fnum(row: dict[str, str], key: str) -> float:
    return float(row[key])


def row_rank(row: dict[str, str]) -> tuple[int, str]:
    """Prefer long-poll hardware rows, then lexicographic experiment id."""

    return (1 if row.get("experiment_id", "").endswith("-long-poll") else 0, row.get("experiment_id", ""))


def best_by_seed(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    by_seed: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        by_seed[row["seed"]].append(row)
    return {seed: sorted(seed_rows, key=row_rank)[-1] for seed, seed_rows in by_seed.items()}


def bool_text(value: str) -> str:
    return "pass" if value == "True" else "fail"


def transition(base: dict[str, str], lock: dict[str, str]) -> str:
    return f"{bool_text(base.get('hardware_pass', ''))}_to_{bool_text(lock.get('hardware_pass', ''))}"


def fmt(value: float) -> str:
    return f"{value:.6f}".rstrip("0").rstrip(".")


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def summarize(rows: list[dict[str, str]]) -> str:
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[row["hardware_transition"]].append(row)

    lines = [
        "# CNTVALUEIN3 Pre/Post Lock Comparison",
        "",
        "This compares the same seed before and after the exact two-cell `CNTVALUEIN3` source-LUT BEL lock for the lane1 DQS1-vs-DQ14 `CNTVALUEIN3` SDF feature.",
        "",
        "Positive `delta_abs_dqs1_minus_dq14_ps` means the lock made the intended SDF skew worse; negative means it improved the skew.",
        "",
        "## Summary By Hardware Transition",
        "",
        "| transition | rows | median baseline abs ps | median locked abs ps | median delta abs ps | improved abs count | worsened abs count | median source manhattan delta |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for name in sorted(groups):
        group = groups[name]
        base_abs = [float(row["baseline_abs_dqs1_minus_dq14_ps"]) for row in group]
        lock_abs = [float(row["locked_abs_dqs1_minus_dq14_ps"]) for row in group]
        delta_abs = [float(row["delta_abs_dqs1_minus_dq14_ps"]) for row in group]
        delta_src = [float(row["delta_source_manhattan"]) for row in group]
        improved = sum(1 for value in delta_abs if value < 0)
        worsened = sum(1 for value in delta_abs if value > 0)
        lines.append(
            f"| {name} | {len(group)} | {median(base_abs):.1f} | {median(lock_abs):.1f} | "
            f"{median(delta_abs):.1f} | {improved} | {worsened} | {median(delta_src):.1f} |"
        )

    lines += [
        "",
        "## Per-Seed Table",
        "",
        "| seed | transition | baseline abs ps | locked abs ps | delta abs ps | baseline signed ps | locked signed ps | baseline source manhattan | locked source manhattan |",
        "| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in rows:
        lines.append(
            f"| {row['seed']} | {row['hardware_transition']} | {row['baseline_abs_dqs1_minus_dq14_ps']} | "
            f"{row['locked_abs_dqs1_minus_dq14_ps']} | {row['delta_abs_dqs1_minus_dq14_ps']} | "
            f"{row['baseline_signed_dqs1_minus_dq14_ps']} | {row['locked_signed_dqs1_minus_dq14_ps']} | "
            f"{row['baseline_source_manhattan']} | {row['locked_source_manhattan']} |"
        )

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-audit", required=True, type=Path)
    parser.add_argument("--locked-audit", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    baseline = best_by_seed(read_rows(args.baseline_audit))
    locked = best_by_seed(read_rows(args.locked_audit))
    seeds = sorted(set(baseline) & set(locked), key=lambda value: int(value))

    rows: list[dict[str, str]] = []
    for seed in seeds:
        base = baseline[seed]
        lock = locked[seed]
        base_abs = fnum(base, "abs_dqs1_minus_dq14_ps")
        lock_abs = fnum(lock, "abs_dqs1_minus_dq14_ps")
        base_signed = fnum(base, "signed_dqs1_minus_dq14_ps")
        lock_signed = fnum(lock, "signed_dqs1_minus_dq14_ps")
        base_src = fnum(base, "source_dqs1_minus_dq14_manhattan")
        lock_src = fnum(lock, "source_dqs1_minus_dq14_manhattan")
        base_sink = fnum(base, "sink_dqs1_minus_dq14_manhattan")
        lock_sink = fnum(lock, "sink_dqs1_minus_dq14_manhattan")

        rows.append(
            {
                "seed": seed,
                "baseline_experiment_id": base["experiment_id"],
                "locked_experiment_id": lock["experiment_id"],
                "hardware_transition": transition(base, lock),
                "baseline_pass": base.get("hardware_pass", ""),
                "locked_pass": lock.get("hardware_pass", ""),
                "baseline_abort_reason": base.get("abort_reason", ""),
                "locked_abort_reason": lock.get("abort_reason", ""),
                "locked_abort_reason_name": lock.get("abort_reason_name", ""),
                "baseline_abs_dqs1_minus_dq14_ps": fmt(base_abs),
                "locked_abs_dqs1_minus_dq14_ps": fmt(lock_abs),
                "delta_abs_dqs1_minus_dq14_ps": fmt(lock_abs - base_abs),
                "baseline_signed_dqs1_minus_dq14_ps": fmt(base_signed),
                "locked_signed_dqs1_minus_dq14_ps": fmt(lock_signed),
                "delta_signed_dqs1_minus_dq14_ps": fmt(lock_signed - base_signed),
                "baseline_source_manhattan": fmt(base_src),
                "locked_source_manhattan": fmt(lock_src),
                "delta_source_manhattan": fmt(lock_src - base_src),
                "baseline_sink_manhattan": fmt(base_sink),
                "locked_sink_manhattan": fmt(lock_sink),
                "delta_sink_manhattan": fmt(lock_sink - base_sink),
                "baseline_dq14_from_bel": base.get("dq14_from_bel", ""),
                "baseline_dqs1_from_bel": base.get("dqs1_from_bel", ""),
                "locked_dq14_from_bel": lock.get("dq14_from_bel", ""),
                "locked_dqs1_from_bel": lock.get("dqs1_from_bel", ""),
            }
        )

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "prepost_comparison.csv", rows)
    (args.out_dir / "README.md").write_text(summarize(rows), encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
