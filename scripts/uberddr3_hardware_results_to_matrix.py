#!/usr/bin/env python3
"""Convert YPCB DDR3 board-test JSON results to causality matrix rows."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


FIELDS = [
    "experiment_id",
    "run_group",
    "seed",
    "variant",
    "payload_version",
    "pass",
    "fail_reasons",
    "state_calibrate",
    "instruction_address",
    "calib_complete",
    "bist_done",
    "correct_read_data",
    "wrong_read_data",
    "abort_seen",
    "abort_reason",
    "abort_reason_name",
    "abort_lane",
    "abort_state",
    "abort_instruction",
    "abort_start_index_check",
    "abort_lane_write_dq_late",
    "abort_lane_read_dq_early",
    "abort_dq_target_index",
    "abort_data_start_index",
    "idelay_data_tap_mismatch_seen",
    "idelay_dqs_tap_mismatch_seen",
    "data_mismatch_lane_mask",
    "dqs_mismatch_lane_mask",
    "reset_from_calibrate_ever",
    "reset_from_test_ever",
    "sync_rst_reasserted_after_release",
    "phy_reset_reasserted_after_release",
    "wrong_read_seen",
    "bitstream_sha256",
    "result_json",
    "finished_at",
    "nextpnr_json",
    "cvc_sdf",
    "fasm",
    "interpretation",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in FIELDS})


def b(value: object) -> str:
    if isinstance(value, bool):
        return "True" if value else "False"
    return str(value) if value is not None else ""


def interpretation(result: dict[str, object], fields: dict[str, object], abort: dict[str, object]) -> str:
    if result.get("pass"):
        return "passes calibration and BIST"
    reason = abort.get("reason_name", "none")
    state = fields.get("state_calibrate", "")
    instr = fields.get("calib_gate_debug", {}).get("instruction_address", "")
    if abort.get("seen"):
        return (
            f"fails after {reason}; final state {state} instruction {instr}; "
            f"lane {abort.get('lane')} start_index_check={abort.get('start_index_check')} "
            f"dq_target_index={abort.get('dq_target_index')}"
        )
    return f"fails without abort; final state {state} instruction {instr}"


def row_for(manifest: dict[str, str], result_path: Path, run_group: str) -> dict[str, object]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    fields = result.get("fields", {})
    startup = fields.get("startup_debug", {})
    idelay = fields.get("idelay_debug", {})
    abort = fields.get("abort_debug", {})
    calib = fields.get("calib_gate_debug", {})

    return {
        "experiment_id": manifest["experiment_id"],
        "run_group": run_group,
        "seed": manifest["seed"],
        "variant": manifest["variant"],
        "payload_version": fields.get("version", ""),
        "pass": b(result.get("pass", "")),
        "fail_reasons": ",".join(result.get("fail_reasons", [])),
        "state_calibrate": fields.get("state_calibrate", ""),
        "instruction_address": calib.get("instruction_address", ""),
        "calib_complete": b(fields.get("calib_complete", "")),
        "bist_done": b(fields.get("bist_done", "")),
        "correct_read_data": fields.get("correct_read_data", ""),
        "wrong_read_data": fields.get("wrong_read_data", ""),
        "abort_seen": b(abort.get("seen", "")),
        "abort_reason": abort.get("reason", ""),
        "abort_reason_name": abort.get("reason_name", ""),
        "abort_lane": abort.get("lane", ""),
        "abort_state": abort.get("state_calibrate", ""),
        "abort_instruction": abort.get("instruction_address", ""),
        "abort_start_index_check": abort.get("start_index_check", ""),
        "abort_lane_write_dq_late": b(abort.get("lane_write_dq_late", "")),
        "abort_lane_read_dq_early": b(abort.get("lane_read_dq_early", "")),
        "abort_dq_target_index": abort.get("dq_target_index", ""),
        "abort_data_start_index": abort.get("data_start_index", ""),
        "idelay_data_tap_mismatch_seen": b(startup.get("idelay_data_tap_mismatch_seen", "")),
        "idelay_dqs_tap_mismatch_seen": b(startup.get("idelay_dqs_tap_mismatch_seen", "")),
        "data_mismatch_lane_mask": idelay.get("data_mismatch_lane_mask", ""),
        "dqs_mismatch_lane_mask": idelay.get("dqs_mismatch_lane_mask", ""),
        "reset_from_calibrate_ever": b(startup.get("reset_from_calibrate_ever", "")),
        "reset_from_test_ever": b(startup.get("reset_from_test_ever", "")),
        "sync_rst_reasserted_after_release": b(startup.get("sync_rst_reasserted_after_release", "")),
        "phy_reset_reasserted_after_release": b(startup.get("phy_reset_reasserted_after_release", "")),
        "wrong_read_seen": b(startup.get("wrong_read_seen", "")),
        "bitstream_sha256": result.get("bitstream_sha256", ""),
        "result_json": str(result_path),
        "finished_at": result.get("finished_at", ""),
        "nextpnr_json": manifest.get("nextpnr_json_file", ""),
        "cvc_sdf": manifest.get("cvc_sdf_file", ""),
        "fasm": "",
        "interpretation": interpretation(result, fields, abort),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--results-dir", type=Path, required=True)
    parser.add_argument("--run-group", required=True)
    parser.add_argument("--out-csv", type=Path, required=True)
    parser.add_argument("--out-json", type=Path, required=True)
    args = parser.parse_args()

    rows = []
    for manifest in read_csv(args.manifest):
        result_path = args.results_dir / f"{manifest['experiment_id']}.json"
        if not result_path.exists():
            raise FileNotFoundError(result_path)
        rows.append(row_for(manifest, result_path, args.run_group))

    write_csv(args.out_csv, rows)
    args.out_json.write_text(json.dumps(rows, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(args.out_csv)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
