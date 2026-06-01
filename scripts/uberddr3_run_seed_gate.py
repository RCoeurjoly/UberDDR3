#!/usr/bin/env python3
"""Build and test seeded YPCB DDR3 bitstreams one seed at a time.

This avoids building a full seed matrix before the first hardware failure is known.
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
from pathlib import Path

STATUS_FIELDS = [
    "experiment_id",
    "seed",
    "repeat",
    "variant",
    "package",
    "bitstream",
    "bitstream_sha256",
    "result_json",
    "build_log",
    "test_log",
    "build_returncode",
    "test_returncode",
    "status",
    "failure_class",
    "fail_reasons",
    "attempts",
    "state_calibrate",
    "correct_read_data",
    "wrong_read_data",
]


def write_status(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATUS_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in STATUS_FIELDS})


def classify_result(result_path: Path) -> dict[str, object]:
    if not result_path.exists():
        return {"failure_class": "missing_result"}
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"failure_class": "invalid_result_json"}
    fields = result.get("fields", {})
    reasons = result.get("fail_reasons", [])
    if result.get("pass"):
        failure_class = "pass"
    elif "programming_failed" in reasons:
        failure_class = "programming"
    elif "clk_unlocked" in reasons:
        failure_class = "clock"
    elif "bad_magic" in reasons or "bad_version" in reasons:
        failure_class = "debug_payload"
    elif "wrong_read_data_nonzero" in reasons:
        failure_class = "bist_mismatch"
    elif "calib_incomplete" in reasons or "calib_state_not_done" in reasons:
        state = fields.get("state_calibrate")
        if state == 0:
            failure_class = "init_or_reset"
        elif state in (1, 2, 3, 4, 13):
            failure_class = "dqs_or_early_calibration"
        elif state in (17, 18, 19, 20, 21, 22):
            failure_class = "late_calibration_or_bist_start"
        else:
            failure_class = "calibration"
    elif "bist_not_done" in reasons:
        failure_class = "bist_timeout"
    else:
        failure_class = "unknown"
    return {
        "failure_class": failure_class,
        "fail_reasons": ",".join(str(reason) for reason in reasons),
        "attempts": result.get("attempts", ""),
        "state_calibrate": fields.get("state_calibrate", ""),
        "correct_read_data": fields.get("correct_read_data", ""),
        "wrong_read_data": fields.get("wrong_read_data", ""),
        "bitstream_sha256": result.get("bitstream_sha256", ""),
    }


def run(command: list[str], log_path: Path) -> int:
    completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(completed.stdout, encoding="utf-8")
    return completed.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", required=True, help="Variant label for output rows, e.g. no-tmdriv")
    parser.add_argument("--package-template", required=True, help="Nix package template with {seed}, e.g. .#ypcb-ddr3-bitstream-no-tmdriv-seed-{seed}")
    parser.add_argument("--seeds", default="1-30", help="Seed range like 1-30 or comma list like 1,2,5")
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--board-test", type=Path, default=Path("example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py"))
    parser.add_argument("--poll-count", type=int, default=200)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--continue-on-fail", action="store_true")
    args = parser.parse_args()

    if "-" in args.seeds and "," not in args.seeds:
        start, end = [int(part) for part in args.seeds.split("-", 1)]
        seeds = list(range(start, end + 1))
    else:
        seeds = [int(part) for part in args.seeds.split(",") if part]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    status_path = args.out_dir / "sweep_status.csv"
    rows: list[dict[str, object]] = []
    final_rc = 0

    for seed in seeds:
        package = args.package_template.format(seed=seed)
        result_link = args.out_dir / f"build-seed-{seed}"
        build_log = args.out_dir / f"build-seed-{seed}.log"
        build_rc = run(["nix", "build", package, "-o", str(result_link)], build_log)
        if build_rc != 0:
            row = {"experiment_id": f"{args.variant}-seed-{seed}-build", "seed": seed, "repeat": "", "variant": args.variant, "package": package, "build_log": build_log, "build_returncode": build_rc, "status": "build_fail"}
            rows.append(row)
            write_status(status_path, rows)
            print(f"seed-{seed}: build_fail rc={build_rc}")
            return build_rc

        bitstream = result_link / "ypcb_00338_1p1_ddr3_openxc7.bit"
        for repeat in range(1, args.repeats + 1):
            experiment_id = f"{args.variant}-seed-{seed}-repeat-{repeat}"
            result_json = args.out_dir / f"{experiment_id}.json"
            test_log = args.out_dir / f"{experiment_id}.log"
            test_rc = run(["python3", str(args.board_test), "--bitstream", str(bitstream), "--output", str(result_json), "--poll-count", str(args.poll_count), "--poll-interval", str(args.poll_interval)], test_log)
            status = "pass" if test_rc == 0 else "fail"
            classification = classify_result(result_json)
            row = {"experiment_id": experiment_id, "seed": seed, "repeat": repeat, "variant": args.variant, "package": package, "bitstream": bitstream, "result_json": result_json, "build_log": build_log, "test_log": test_log, "build_returncode": build_rc, "test_returncode": test_rc, "status": status, **classification}
            rows.append(row)
            write_status(status_path, rows)
            print(f"{experiment_id}: {status} rc={test_rc}")
            if test_rc != 0:
                final_rc = test_rc
                if not args.continue_on_fail:
                    print(status_path)
                    return final_rc
    print(status_path)
    return final_rc


if __name__ == "__main__":
    raise SystemExit(main())
