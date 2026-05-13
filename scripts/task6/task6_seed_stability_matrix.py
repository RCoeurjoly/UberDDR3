#!/usr/bin/env python3
"""Run combinatorial seed/lock/pnr stability sweeps for YPCB rowstream calibration."""

from __future__ import annotations

import argparse
import json
import re
from itertools import product
from pathlib import Path
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SWEEP_SCRIPT = ROOT / "scripts" / "task6" / "task6_calibration_sweep.py"
SWEEP_ROOT = ROOT / "artifacts" / "task6" / "calibration-sweeps"


def parse_int_list(raw: str) -> list[int]:
    values: list[int] = []
    for token in raw.split(","):
        token = token.strip()
        if not token:
            continue
        if "-" in token:
            start, end = token.split("-", 1)
            values.extend(range(int(start), int(end) + 1))
        else:
            values.append(int(token))
    if not values:
        raise SystemExit(f"invalid seed list/range: {raw!r}")
    return sorted(set(values))


def parse_arg_list(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


def normalize_pnr_arg(value: Any) -> str:
    return " ".join(str(value).split()) if value is not None else ""


def is_seed_stable_row(
    row: dict[str, Any], target_state: int, *, allow_build_only: bool
) -> bool:
    program_status = row.get("program_status")
    program_ok = program_status == "pass" or (allow_build_only and program_status == "build-only")
    if not program_ok:
        return False

    return (
        row.get("build_status") == "built"
        and row.get("calib_seen") is True
        and row.get("calib_complete") is True
        and row.get("state") == target_state
        and row.get("loader_ready") is True
        and (row.get("err_count", 0) or 0) == 0
        and (row.get("ack_count") or 0) > 0
    )


def parse_sweep_row(stdout: str, fallback: dict[str, Any]) -> dict[str, Any]:
    match = re.findall(r"(?s)(\{.*\})\s*$", stdout.strip())
    if not match:
        return fallback
    try:
        row = json.loads(match[-1])
    except json.JSONDecodeError:
        return fallback
    row.update({k: v for k, v in fallback.items() if k not in row})
    row["raw"] = stdout
    if row.get("seed") is None:
        row["seed"] = fallback.get("seed")
    if row.get("lock_set") is None:
        row["lock_set"] = fallback.get("lock_set")
    if row.get("freq") is None:
        row["freq"] = fallback.get("freq")
    if row.get("pnr_extra_args") is None:
        row["pnr_extra_args"] = fallback.get("pnr_extra_args")
    if row.get("extra_lock_variants") is None:
        row["extra_lock_variants"] = fallback.get("extra_lock_variants")
    return row


def make_rows_for_combo(
    *,
    sweep: str,
    lock_set: str,
    seed: int,
    freq: int,
    pnr_extra_args: str,
    synth_xilinx_flags: str,
    extra_lock_jsons: list[Path],
    build_only: bool,
    notes: str,
    dry_run: bool,
    clean: bool,
    nix_develop: bool,
) -> dict[str, Any]:
    command = [
        sys.executable,
        str(SWEEP_SCRIPT),
        "--sweep",
        sweep,
        "--seed",
        str(seed),
        "--lock-set",
        lock_set,
        "--freq",
        str(freq),
        "--pnr-extra-args",
        pnr_extra_args,
        "--synth-xilinx-flags",
        synth_xilinx_flags,
        "--notes",
        notes,
    ]
    for lock_json in extra_lock_jsons:
        command.extend(["--extra-locks-json", str(lock_json)])
    if build_only and not dry_run:
        command.append("--build-only")
    if clean:
        command.append("--clean")
    else:
        command.append("--no-clean")
    if dry_run:
        command.append("--dry-run")
    if not nix_develop:
        command.append("--no-nix-develop")

    proc = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    fallback = {
        "seed": seed,
        "lock_set": lock_set,
        "freq": freq,
        "pnr_extra_args": pnr_extra_args,
        "extra_lock_variants": sorted({str(path) for path in extra_lock_jsons}),
        "sweep": sweep,
        "program_status": "build-only" if build_only else None,
        "build_status": None,
        "build_failed": proc.returncode != 0 and not dry_run,
        "returncode": proc.returncode,
        "raw": proc.stdout,
        "stderr": proc.stderr,
        "notes": notes,
    }
    row = parse_sweep_row(proc.stdout, fallback)
    if not dry_run and proc.returncode != 0 and row.get("build_status") != "built":
        row["build_status"] = "failed"
    return row


def summarise(
    rows: list[dict[str, Any]],
    seeds: list[int],
    lock_sets: list[str],
    freqs: list[int],
    pnr_extra_args_list: list[str],
    extra_lock_variants: list[tuple[str, ...]],
    target_state: int,
    *,
    build_only: bool,
) -> str:
    expected_seeds = set(seeds)
    expected_locks = set(lock_sets)
    expected_freqs = set(freqs)
    expected_pnr = {normalize_pnr_arg(v) for v in pnr_extra_args_list}
    expected_variants = {",".join(variant) for variant in extra_lock_variants}

    by_combo: dict[tuple[str, int, str, str], dict[str, int | list[int]]] = {}
    for row in rows:
        if int(row.get("seed", -1)) not in expected_seeds:
            continue
        if row.get("lock_set") not in expected_locks:
            continue
        if int(row.get("freq", -1)) not in expected_freqs:
            continue
        if normalize_pnr_arg(row.get("pnr_extra_args")) not in expected_pnr:
            continue
        row_variant = ",".join(sorted(str(item) for item in row.get("extra_lock_variants", [])))
        if expected_variants and row_variant not in expected_variants:
            continue

        key = (
            row.get("lock_set", ""),
            int(row.get("freq", 25)),
            normalize_pnr_arg(row.get("pnr_extra_args")),
            row_variant or "(none)",
        )
        entry = by_combo.setdefault(
            key,
            {"tested": 0, "passed": 0, "build_failed": 0, "seeds": []},
        )
        entry["tested"] = int(entry["tested"]) + 1
        if row.get("build_status") != "built":
            entry["build_failed"] = int(entry["build_failed"]) + 1
        if is_seed_stable_row(row, target_state, allow_build_only=build_only):
            entry["passed"] = int(entry["passed"]) + 1
            entry["seeds"].append(int(row.get("seed", -1)))

    header = [
        "lock_set",
        "freq",
        "pnr_extra_args",
        "extra_lock_variants",
        "tested",
        "passed",
        "pass_rate",
        "stable_all_seeds",
        "build_failed",
        "pass_seeds",
    ]
    lines = ["| " + " | ".join(header) + " |", "| " + " | ".join("---" for _ in header) + " |"]
    for (lock_set, freq, pnr_extra_args, extra_lock_variants), value in sorted(by_combo.items()):
        tested = int(value["tested"])
        passed = int(value["passed"])
        build_failed = int(value["build_failed"])
        seed_set = sorted(set(seed for seed in value["seeds"] if seed in expected_seeds))
        pass_rate = f"{passed}/{len(expected_seeds)}"
        stable_all_seeds = len(seed_set) == len(expected_seeds)
        lines.append(
            "| "
            + " | ".join(
                [
                    str(lock_set),
                    str(freq),
                    f"`{pnr_extra_args}`" if pnr_extra_args else "`(default)`",
                    f"`{extra_lock_variants}`" if extra_lock_variants else "`(none)`",
                    str(tested),
                    str(passed),
                    pass_rate,
                    str(stable_all_seeds),
                    str(build_failed),
                    f"{seed_set}",
                ]
            )
            + " |"
        )
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sweep", default="ypcb-rowstream-seed-stability")
    parser.add_argument("--seeds", required=True, help="Comma list / ranges, e.g. 0,1,4-7")
    parser.add_argument("--lock-sets", required=True, help="Comma-separated lock sets")
    parser.add_argument("--freqs", default="25", help="Comma-separated target frequencies")
    parser.add_argument(
        "--pnr-extra-args",
        action="append",
        default=[""],
        help="One or more --pnr-extra-args values to sweep.",
    )
    parser.add_argument("--synth-xilinx-flags", default="-flatten -family xc7")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--clean", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument(
        "--extra-locks-json",
        action="append",
        default=[],
        type=Path,
        help="Optional pre-filtered lock JSON file passed as --extra-locks-json.",
    )
    parser.add_argument("--notes", default="seed-stability-matrix")
    parser.add_argument("--target-state", type=int, default=23)
    parser.add_argument("--nix-develop", action=argparse.BooleanOptionalAction, default=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    seeds = parse_int_list(args.seeds)
    lock_sets = parse_arg_list(args.lock_sets)
    freqs = [int(value) for value in parse_arg_list(args.freqs)]
    pnr_extra_args_list = [v.strip() for v in args.pnr_extra_args] if args.pnr_extra_args else [""]
    if args.extra_locks_json:
        extra_lock_paths = sorted(str(path) for path in set(args.extra_locks_json))
        extra_lock_variants = [tuple(extra_lock_paths)]
    else:
        extra_lock_variants = [()]
    if not extra_lock_variants:
        extra_lock_variants = [()]

    rows: list[dict[str, Any]] = []
    for seed, lock_set, freq, pnr_extra_args in product(seeds, lock_sets, freqs, pnr_extra_args_list):
        notes = (
            f"seed={seed}, lock_set={lock_set}, freq={freq}, pnr-extra-args={pnr_extra_args}"
            if args.notes == "seed-stability-matrix"
            else args.notes
        )
        rows.append(
            make_rows_for_combo(
                sweep=args.sweep,
                lock_set=lock_set,
                seed=seed,
                freq=freq,
                pnr_extra_args=pnr_extra_args,
                synth_xilinx_flags=args.synth_xilinx_flags,
                extra_lock_jsons=args.extra_locks_json,
                build_only=args.build_only,
                notes=notes,
                dry_run=args.dry_run,
                clean=args.clean,
                nix_develop=args.nix_develop,
            )
        )

    out = SWEEP_ROOT / args.sweep / "stability-scorecard.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    summary = summarise(
        rows,
        seeds=seeds,
        lock_sets=lock_sets,
        freqs=freqs,
        pnr_extra_args_list=pnr_extra_args_list,
        extra_lock_variants=extra_lock_variants,
        target_state=args.target_state,
        build_only=args.build_only,
    )
    out.write_text(summary + "\n", encoding="utf-8")
    print(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
