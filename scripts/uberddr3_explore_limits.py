#!/usr/bin/env python3
"""Run selected rows from the YPCB DDR3 limit-exploration manifest."""

from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from pathlib import Path


STATUS_FIELDS = [
    "experiment_id",
    "strategy",
    "search_index",
    "search_result",
    "bitstream_package",
    "clock_profile",
    "controller_clk_period",
    "ddr3_clk_period",
    "controller_freq_mhz",
    "ddr3_freq_mhz",
    "row_bits",
    "col_bits",
    "ba_bits",
    "byte_lanes",
    "pnr_freq_mhz",
    "pll_exact",
    "seed_mode",
    "out_dir",
    "returncode",
]


def read_manifest(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_status(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATUS_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in STATUS_FIELDS})


def freq_rank(row: dict[str, str]) -> tuple[int, int]:
    preferred = [70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 250, 300]
    freq = int(row["pnr_freq_mhz"])
    try:
        return preferred.index(freq), freq
    except ValueError:
        return len(preferred), freq


def row_rank(row: dict[str, str]) -> tuple[object, ...]:
    seed_rank = 0 if row["seed_mode"] == "noseed" else int(row["seed"] or "9999")
    return (
        0 if row["controller_clk_period"] == "15000" else 1,
        int(row["byte_lanes"]),
        int(row["row_bits"]),
        int(row["col_bits"]),
        freq_rank(row),
        seed_rank,
    )


def parse_int_set(spec: str) -> set[int] | None:
    if not spec:
        return None
    values: set[int] = set()
    for part in (item.strip() for item in spec.split(",")):
        if not part:
            continue
        if "-" in part:
            start_text, end_text = part.split("-", 1)
            start = int(start_text)
            end = int(end_text)
            step = 10 if abs(end - start) >= 10 and start % 10 == 0 and end % 10 == 0 else 1
            if start <= end:
                values.update(range(start, end + 1, step))
            else:
                values.update(range(start, end - 1, -step))
        else:
            values.add(int(part))
    return values


def maybe_int(row: dict[str, str], field: str) -> int:
    return int(row[field])


def envelope_rank(row: dict[str, str]) -> tuple[int, int, int, int, int, int]:
    """Rank rows from easier/smaller to harder/larger for binary search."""
    row_bits = maybe_int(row, "row_bits")
    col_bits = maybe_int(row, "col_bits")
    ba_bits = maybe_int(row, "ba_bits")
    byte_lanes = maybe_int(row, "byte_lanes")
    ddr3_freq_khz = int(round(float(row["ddr3_freq_mhz"]) * 1000))
    pnr_freq = maybe_int(row, "pnr_freq_mhz")
    address_bits = row_bits + col_bits + ba_bits
    capacity_score = address_bits + byte_lanes.bit_length() - 1
    bandwidth_score = byte_lanes * ddr3_freq_khz
    return (capacity_score, bandwidth_score, row_bits, col_bits, byte_lanes, pnr_freq)


def select_envelope_rows(
    rows: list[dict[str, str]],
    seed: str,
    pnr_freqs: set[int] | None,
    controller_periods: set[int] | None,
) -> list[dict[str, str]]:
    selected = []
    for row in rows:
        if row["seed"] != seed:
            continue
        if pnr_freqs is not None and maybe_int(row, "pnr_freq_mhz") not in pnr_freqs:
            continue
        if controller_periods is not None and maybe_int(row, "controller_clk_period") not in controller_periods:
            continue
        selected.append(row)
    return sorted(selected, key=envelope_rank)


def select_rows(rows: list[dict[str, str]], strategy: str) -> list[dict[str, str]]:
    if strategy == "anchor":
        rows = [
            row
            for row in rows
            if row["controller_clk_period"] == "15000"
            and row["ddr3_clk_period"] == "3750"
            and row["row_bits"] == "15"
            and row["col_bits"] == "10"
            and row["ba_bits"] == "3"
            and row["byte_lanes"] == "1"
            and row["pnr_freq_mhz"] == "100"
            and row["seed"] == "1"
        ]
    elif strategy == "noseed":
        rows = [row for row in rows if row["seed_mode"] == "noseed" and row["pnr_freq_mhz"] == "100"]
    elif strategy == "seeded":
        rows = [row for row in rows if row["seed_mode"] != "noseed" and row["pnr_freq_mhz"] == "100"]
    elif strategy == "freq":
        rows = [row for row in rows if row["seed_mode"] != "noseed"]
    elif strategy == "envelope":
        raise ValueError("envelope strategy requires select_envelope_rows")
    elif strategy != "full":
        raise ValueError(f"unknown strategy: {strategy}")
    return sorted(rows, key=row_rank)


def run_manifest_row(
    row: dict[str, str],
    args: argparse.Namespace,
    row_out_dir: Path,
    repeats: int,
    success_repeats: int | None,
    failure_repeats: int | None,
) -> int:
    package_ref = row["bitstream_package"]
    if not package_ref.startswith(".#"):
        package_ref = f".#{package_ref}"
    seed_arg = "noseed" if row["seed_mode"] == "noseed" else row["seed"]
    command = [
        sys.executable,
        str(args.runner),
        "--variant",
        row["experiment_id"],
        "--package-template",
        package_ref,
        "--seeds",
        seed_arg,
        "--freqs",
        row["pnr_freq_mhz"],
        "--out-dir",
        str(row_out_dir),
        "--repeats",
        str(repeats),
        "--intermittent-repeats",
        str(args.intermittent_repeats),
        "--poll-count",
        str(args.poll_count),
        "--poll-interval",
        str(args.poll_interval),
        "--byte-lanes",
        row["byte_lanes"],
    ]
    if success_repeats is not None:
        command.extend(["--success-repeats", str(success_repeats)])
    if failure_repeats is not None:
        command.extend(["--failure-repeats", str(failure_repeats)])
    if args.stable_samples:
        command.extend(["--stable-samples", str(args.stable_samples), "--stable-min-attempt", str(args.stable_min_attempt)])
    if args.continue_on_fail:
        command.append("--continue-on-fail")

    print(" ".join(command))
    return 0 if args.dry_run else subprocess.run(command, check=False).returncode


def status_row(
    row: dict[str, str],
    args: argparse.Namespace,
    row_out_dir: Path,
    rc: int,
    search_index: int | str = "",
    search_result: str = "",
) -> dict[str, object]:
    return {
        "experiment_id": row["experiment_id"],
        "strategy": args.strategy,
        "search_index": search_index,
        "search_result": search_result,
        "bitstream_package": row["bitstream_package"],
        "clock_profile": row.get("clock_profile", ""),
        "controller_clk_period": row["controller_clk_period"],
        "ddr3_clk_period": row["ddr3_clk_period"],
        "controller_freq_mhz": row.get("controller_freq_mhz", ""),
        "ddr3_freq_mhz": row.get("ddr3_freq_mhz", ""),
        "row_bits": row["row_bits"],
        "col_bits": row["col_bits"],
        "ba_bits": row["ba_bits"],
        "byte_lanes": row["byte_lanes"],
        "pnr_freq_mhz": row["pnr_freq_mhz"],
        "pll_exact": row.get("pll_exact", ""),
        "seed_mode": row["seed_mode"],
        "out_dir": row_out_dir,
        "returncode": rc,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--strategy", choices=("anchor", "noseed", "seeded", "freq", "full", "envelope"), default="anchor")
    parser.add_argument("--out-dir", type=Path, default=Path("local-artifacts/limit-exploration"))
    parser.add_argument("--runner", type=Path, default=Path("scripts/uberddr3_run_seed_gate.py"))
    parser.add_argument("--limit", type=int, help="Run at most this many selected rows.")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--repeats", type=int)
    parser.add_argument("--success-repeats", type=int)
    parser.add_argument("--failure-repeats", type=int)
    parser.add_argument("--intermittent-repeats", type=int, default=10)
    parser.add_argument("--poll-count", type=int, default=200)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--stable-samples", type=int, default=0)
    parser.add_argument("--stable-min-attempt", type=int, default=10)
    parser.add_argument("--continue-on-fail", action="store_true")
    parser.add_argument("--envelope-seed", default="1", help="Seed to use for --strategy envelope. Defaults to seed 1.")
    parser.add_argument("--envelope-pnr-freqs", default="100", help="PNR frequencies for --strategy envelope, e.g. 100 or 80-200.")
    parser.add_argument("--envelope-controller-periods", default="", help="Optional controller periods for --strategy envelope, e.g. 15000 or 10000,12000,15000.")
    args = parser.parse_args()
    if args.strategy == "envelope" and args.limit is not None:
        parser.error("--limit is not compatible with --strategy envelope; filter the envelope with --envelope-* options instead")

    manifest_rows = read_manifest(args.manifest)
    if args.strategy == "envelope":
        selected = select_envelope_rows(
            manifest_rows,
            seed=args.envelope_seed,
            pnr_freqs=parse_int_set(args.envelope_pnr_freqs),
            controller_periods=parse_int_set(args.envelope_controller_periods),
        )
    else:
        selected = select_rows(manifest_rows, args.strategy)
    if args.limit is not None:
        selected = selected[: args.limit]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    status_path = args.out_dir / "exploration_status.csv"
    status_rows: list[dict[str, object]] = []
    final_rc = 0
    effective_repeats = args.repeats if args.repeats is not None else (1 if args.strategy == "envelope" else 3)
    effective_success_repeats = args.success_repeats
    effective_failure_repeats = args.failure_repeats
    if args.strategy == "envelope":
        effective_success_repeats = 1 if effective_success_repeats is None else effective_success_repeats
        effective_failure_repeats = 1 if effective_failure_repeats is None else effective_failure_repeats

    if args.strategy == "envelope":
        low = 0
        high = len(selected) - 1
        best_index: int | None = None
        while low <= high:
            index = (low + high) // 2
            row = selected[index]
            row_out_dir = args.out_dir / row["experiment_id"]
            rc = run_manifest_row(row, args, row_out_dir, effective_repeats, effective_success_repeats, effective_failure_repeats)
            passed = rc == 0
            status_rows.append(status_row(row, args, row_out_dir, rc, search_index=index, search_result="pass" if passed else "fail"))
            write_status(status_path, status_rows)
            if passed:
                best_index = index
                low = index + 1
            else:
                high = index - 1

        print(status_path)
        if best_index is None:
            print("No passing envelope point found.")
            return 1
        best = selected[best_index]
        print(
            "Best passing envelope point: "
            f"{best['experiment_id']} "
            f"rank={envelope_rank(best)} "
            f"index={best_index}/{len(selected) - 1}"
        )
        return 0

    for row in selected:
        row_out_dir = args.out_dir / row["experiment_id"]
        rc = run_manifest_row(row, args, row_out_dir, effective_repeats, effective_success_repeats, effective_failure_repeats)
        status_rows.append(status_row(row, args, row_out_dir, rc))
        write_status(status_path, status_rows)
        if rc != 0:
            final_rc = rc
            if not args.continue_on_fail:
                break

    print(status_path)
    return final_rc


if __name__ == "__main__":
    raise SystemExit(main())
