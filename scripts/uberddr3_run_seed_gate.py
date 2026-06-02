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
    "stage_rank",
    "stage_name",
    "fail_reasons",
    "attempts",
    "instruction_address",
    "state_calibrate",
    "reset_done",
    "init_i_rst_n",
    "init_idelayctrl_rdy",
    "init_o_phy_reset",
    "calib_bus_init_i_rst_n",
    "calib_bus_init_idelayctrl_rdy",
    "calib_bus_init_o_phy_reset",
    "correct_read_data",
    "wrong_read_data",
    "bist_fail_valid",
    "bist_fail_state",
    "bist_fail_address",
    "bist_fail_byte_mismatch_mask",
    "bist_fail_expected_data",
    "bist_fail_actual_data",
    "bist_fail_aux",
    "bist_fail_wb_data_q_current",
    "bist_fail_raw_iserdes_data",
    "bist_fail_index_wb_data",
    "bist_fail_delay_read_pipe0",
    "bist_fail_delay_read_pipe1",
    "bist_fail_added_read_pipe0",
    "bist_fail_data_start_index0",
    "bist_fail_idelay_data_cntvaluein0",
    "bist_fail_idelay_dqs_cntvaluein0",
    "bist_fail_byte_index",
    "bist_fail_burst_slot",
]


def write_status(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATUS_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in STATUS_FIELDS})


def classify_stage(fields: dict[str, object], reasons: list[object], passed: bool) -> tuple[int, str]:
    if passed:
        return 7, "pass"
    if "programming_failed" in reasons:
        return 0, "programming"
    if "clk_unlocked" in reasons:
        return 1, "clock_or_reset"
    if "bad_magic" in reasons or "bad_version" in reasons:
        return 1, "debug_payload"

    state = fields.get("state_calibrate")
    calib_debug = fields.get("calib_debug", {})
    if not isinstance(calib_debug, dict):
        calib_debug = {}
    bist_debug = fields.get("bist_debug", {})
    if not isinstance(bist_debug, dict):
        bist_debug = {}
    instruction_address = calib_debug.get("instruction_address", "")

    if "wrong_read_data_nonzero" in reasons:
        return 6, "bist_mismatch"
    if state == 23:
        return 6, "bist_or_done_boundary"
    if isinstance(state, int):
        if state == 0:
            if isinstance(instruction_address, int) and instruction_address < 13:
                return 2, "init_before_calibration"
            if instruction_address == 13:
                return 3, "calibration_start_handoff"
            return 2, "init_or_reset"
        if 1 <= state <= 6:
            return 4, "dqs_read_leveling"
        if 7 <= state <= 16:
            return 5, "write_read_alignment"
        if 17 <= state <= 22:
            return 6, "bist_or_late_calibration"
    if "bist_not_done" in reasons:
        return 6, "bist_timeout"
    return 1, "unknown"


def classify_result(result_path: Path) -> dict[str, object]:
    if not result_path.exists():
        return {"failure_class": "missing_result", "stage_rank": 0, "stage_name": "missing_result"}
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"failure_class": "invalid_result_json", "stage_rank": 0, "stage_name": "invalid_result_json"}
    fields = result.get("fields", {})
    if not isinstance(fields, dict):
        fields = {}
    reasons = result.get("fail_reasons", [])
    if not isinstance(reasons, list):
        reasons = []
    passed = bool(result.get("pass"))
    stage_rank, stage_name = classify_stage(fields, reasons, passed)
    if passed:
        failure_class = "pass"
    elif "programming_failed" in reasons:
        failure_class = "programming"
    elif "clk_unlocked" in reasons:
        failure_class = "clock"
    elif "bad_magic" in reasons or "bad_version" in reasons:
        failure_class = "debug_payload"
    elif "wrong_read_data_nonzero" in reasons:
        failure_class = "bist_mismatch"
    elif stage_rank == 2:
        failure_class = "init_or_reset"
    elif stage_rank == 3:
        failure_class = "calibration_start_handoff"
    elif stage_rank == 4:
        failure_class = "dqs_or_early_calibration"
    elif stage_rank == 5:
        failure_class = "write_read_alignment"
    elif stage_rank == 6:
        failure_class = "late_calibration_or_bist"
    else:
        failure_class = "unknown"

    calib_debug = fields.get("calib_debug", {})
    if not isinstance(calib_debug, dict):
        calib_debug = {}
    init_reset_debug = fields.get("init_reset_debug", {})
    if not isinstance(init_reset_debug, dict):
        init_reset_debug = {}
    bist_debug = fields.get("bist_debug", {})
    if not isinstance(bist_debug, dict):
        bist_debug = {}

    return {
        "failure_class": failure_class,
        "stage_rank": stage_rank,
        "stage_name": stage_name,
        "fail_reasons": ",".join(str(reason) for reason in reasons),
        "attempts": result.get("attempts", ""),
        "instruction_address": calib_debug.get("instruction_address", ""),
        "state_calibrate": fields.get("state_calibrate", ""),
        "reset_done": init_reset_debug.get("controller_reset_done", ""),
        "init_i_rst_n": calib_debug.get("init_i_rst_n", ""),
        "init_idelayctrl_rdy": calib_debug.get("init_idelayctrl_rdy", ""),
        "init_o_phy_reset": calib_debug.get("init_o_phy_reset", ""),
        "calib_bus_init_i_rst_n": calib_debug.get("calib_bus_init_i_rst_n", ""),
        "calib_bus_init_idelayctrl_rdy": calib_debug.get("calib_bus_init_idelayctrl_rdy", ""),
        "calib_bus_init_o_phy_reset": calib_debug.get("calib_bus_init_o_phy_reset", ""),
        "correct_read_data": fields.get("correct_read_data", ""),
        "wrong_read_data": fields.get("wrong_read_data", ""),
        "bist_fail_valid": bist_debug.get("valid", ""),
        "bist_fail_state": bist_debug.get("state_calibrate", ""),
        "bist_fail_address": bist_debug.get("address", ""),
        "bist_fail_byte_mismatch_mask": bist_debug.get("byte_mismatch_mask", ""),
        "bist_fail_expected_data": bist_debug.get("expected_data", ""),
        "bist_fail_actual_data": bist_debug.get("actual_data", ""),
        "bist_fail_aux": bist_debug.get("fail_aux", ""),
        "bist_fail_wb_data_q_current": bist_debug.get("fail_wb_data_q_current", ""),
        "bist_fail_raw_iserdes_data": bist_debug.get("fail_raw_iserdes_data", ""),
        "bist_fail_index_wb_data": bist_debug.get("fail_index_wb_data", ""),
        "bist_fail_delay_read_pipe0": bist_debug.get("fail_delay_read_pipe0", ""),
        "bist_fail_delay_read_pipe1": bist_debug.get("fail_delay_read_pipe1", ""),
        "bist_fail_added_read_pipe0": bist_debug.get("fail_added_read_pipe0", ""),
        "bist_fail_data_start_index0": bist_debug.get("fail_data_start_index0", ""),
        "bist_fail_idelay_data_cntvaluein0": bist_debug.get("fail_idelay_data_cntvaluein0", ""),
        "bist_fail_idelay_dqs_cntvaluein0": bist_debug.get("fail_idelay_dqs_cntvaluein0", ""),
        "bist_fail_byte_index": bist_debug.get("fail_byte_index", ""),
        "bist_fail_burst_slot": bist_debug.get("fail_burst_slot", ""),
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
            row = {"experiment_id": f"{args.variant}-seed-{seed}-build", "seed": seed, "repeat": "", "variant": args.variant, "package": package, "build_log": build_log, "build_returncode": build_rc, "status": "build_fail", "failure_class": "build", "stage_rank": 0, "stage_name": "build"}
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
