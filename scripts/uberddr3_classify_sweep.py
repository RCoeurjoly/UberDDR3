#!/usr/bin/env python3
"""Summarize UberDDR3 seed sweep results by exact failure family."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SIGNATURE_PATHS = [
    ("pass",),
    ("fail_reasons",),
    ("fields", "state_calibrate"),
    ("fields", "calib_debug", "instruction_address"),
    ("fields", "calib_debug", "init_i_rst_n"),
    ("fields", "calib_debug", "init_idelayctrl_rdy"),
    ("fields", "calib_debug", "init_o_phy_reset"),
    ("fields", "calib_debug", "calib_bus_init_i_rst_n"),
    ("fields", "calib_debug", "calib_bus_init_idelayctrl_rdy"),
    ("fields", "calib_debug", "calib_bus_init_o_phy_reset"),
    ("fields", "init_reset_debug", "controller_reset_done"),
    ("fields", "init_reset_debug", "controller_delay_counter_is_zero"),
    ("fields", "init_seq_debug", "instruction_address"),
    ("fields", "init_seq_debug", "instruction_address_d"),
    ("fields", "init_seq_debug", "delay_counter_is_zero"),
    ("fields", "init_seq_debug", "delay_counter_is_zero_d"),
    ("fields", "init_seq_debug", "reset_done"),
    ("fields", "init_seq_debug", "reset_done_d"),
    ("fields", "init_seq_debug", "instruction_rst_done_bit"),
    ("fields", "init_seq_debug", "instruction_use_timer_bit"),
    ("fields", "init_seq_debug", "init_advance_now"),
    ("fields", "init_seq_debug", "init_advance_pending"),
    ("fields", "panopticon_debug", "marker"),
    ("fields", "panopticon_debug", "state_calibrate"),
    ("fields", "panopticon_debug", "instruction_address"),
    ("fields", "panopticon_debug", "index_wb_data"),
    ("fields", "panopticon_debug", "data_start_index0"),
    ("fields", "panopticon_debug", "idelay_data_cntvaluein0"),
    ("fields", "panopticon_debug", "idelay_dqs_cntvaluein0"),
    ("fields", "bist_debug", "valid"),
    ("fields", "bist_debug", "state_calibrate"),
    ("fields", "bist_debug", "address"),
    ("fields", "bist_debug", "byte_mismatch_mask"),
    ("fields", "bist_debug", "expected_data"),
    ("fields", "bist_debug", "actual_data"),
    ("fields", "bist_debug", "fail_byte_index"),
    ("fields", "bist_debug", "fail_burst_slot"),
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
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


def get_path(data: object, path: tuple[str, ...]) -> object:
    current = data
    for key in path:
        if not isinstance(current, dict):
            return ""
        current = current.get(key, "")
    return current


def stage_name(result: dict[str, Any]) -> str:
    if result.get("pass"):
        return "pass"
    reasons = result.get("fail_reasons", [])
    if not isinstance(reasons, list):
        reasons = []
    fields = result.get("fields", {}) if isinstance(result.get("fields"), dict) else {}
    calib = fields.get("calib_debug", {}) if isinstance(fields.get("calib_debug"), dict) else {}
    state = fields.get("state_calibrate")
    instruction = calib.get("instruction_address")
    if "programming_failed" in reasons:
        return "programming"
    if "wrong_read_data_nonzero" in reasons:
        return "bist_mismatch"
    if isinstance(state, int):
        if state == 0 and isinstance(instruction, int) and instruction < 13:
            return "init_before_calibration"
        if state == 0 and instruction == 13:
            return "calibration_start_handoff"
        if 1 <= state <= 6:
            return "dqs_read_leveling"
        if 7 <= state <= 16:
            return "write_read_alignment"
        if 17 <= state <= 22:
            return "late_calibration_or_bist"
        if state == 23:
            return "bist_or_done_boundary"
    return "unknown"


def signature(result: dict[str, Any]) -> dict[str, Any]:
    sig = {"stage_name": stage_name(result)}
    for path in SIGNATURE_PATHS:
        sig[".".join(path)] = get_path(result, path)
    return sig


def family_id(sig: dict[str, Any]) -> str:
    if sig.get("pass") is True or sig.get("pass") == "True":
        return "pass"
    raw = json.dumps(sig, sort_keys=True, separators=(",", ":"), default=str).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:16]


def seed_repeat_from_filename(result_path: Path) -> tuple[str, str]:
    match = re.search(r"-seed-(\d+)-repeat-(\d+)$", result_path.stem)
    if not match:
        return "", ""
    return match.group(1), match.group(2)


def coarse_family(result: dict[str, Any], stage: str) -> str:
    if result.get("pass"):
        return "pass"
    fields = result.get("fields", {}) if isinstance(result.get("fields"), dict) else {}
    calib = fields.get("calib_debug", {}) if isinstance(fields.get("calib_debug"), dict) else {}
    init_reset = fields.get("init_reset_debug", {}) if isinstance(fields.get("init_reset_debug"), dict) else {}
    pan = fields.get("panopticon_debug", {}) if isinstance(fields.get("panopticon_debug"), dict) else {}
    bist = fields.get("bist_debug", {}) if isinstance(fields.get("bist_debug"), dict) else {}
    canonical = fields.get("canonical_status", {})
    if not isinstance(canonical, dict):
        canonical = {}
    state = canonical.get("state_calibrate", fields.get("state_calibrate", ""))
    instruction = canonical.get("instruction_address", calib.get("instruction_address", pan.get("instruction_address", "")))
    reset_done = canonical.get("reset_done", init_reset.get("controller_reset_done", ""))
    if stage == "bist_mismatch":
        return "bist_mismatch.byte_mask_%s.byte_%s.slot_%s" % (bist.get("byte_mismatch_mask", ""), bist.get("fail_byte_index", ""), bist.get("fail_burst_slot", ""))
    if stage == "init_before_calibration":
        reset_from_calibrate_seen = canonical.get("reset_from_calibrate_seen", False)
        addr_regress_seen = canonical.get("addr_regress_seen", False)
        if reset_from_calibrate_seen:
            return "calibration_reset_restart.addr_%s.regress_%s" % (instruction, addr_regress_seen)
        if instruction in (1, 2, "1", "2"):
            return "init_before_calibration.addr_1_2.reset_done_%s" % reset_done
        return "init_before_calibration.addr_%s.reset_done_%s" % (instruction, reset_done)
    if stage == "calibration_start_handoff":
        return "calibration_start_handoff.reset_done_%s" % reset_done
    if stage == "dqs_read_leveling":
        return "dqs_read_leveling.instr_%s" % instruction
    if stage == "write_read_alignment":
        return "write_read_alignment.state_%s.instr_%s" % (state, instruction)
    return "%s.state_%s.instr_%s" % (stage, state, instruction)


def result_row(result_path: Path, status_row: dict[str, str] | None) -> dict[str, Any]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    inferred_seed, inferred_repeat = seed_repeat_from_filename(result_path)
    sig = signature(result)
    fields = result.get("fields", {}) if isinstance(result.get("fields"), dict) else {}
    calib = fields.get("calib_debug", {}) if isinstance(fields.get("calib_debug"), dict) else {}
    pan = fields.get("panopticon_debug", {}) if isinstance(fields.get("panopticon_debug"), dict) else {}
    stage = status_row.get("stage_name", stage_name(result)) if status_row else stage_name(result)
    exact_id = status_row.get("exact_family_id", "") if status_row else ""
    if not exact_id and status_row:
        exact_id = status_row.get("failure_family_id", "")
    if not exact_id:
        exact_id = family_id(sig)
    coarse_id = status_row.get("coarse_family_id", "") if status_row else ""
    if not coarse_id:
        coarse_id = coarse_family(result, stage)
    return {
        "experiment_id": status_row.get("experiment_id", result_path.stem) if status_row else result_path.stem,
        "seed": status_row.get("seed", inferred_seed) if status_row else inferred_seed,
        "repeat": status_row.get("repeat", inferred_repeat) if status_row else inferred_repeat,
        "status": "pass" if result.get("pass") else "fail",
        "stage_name": stage,
        "coarse_family_id": coarse_id,
        "exact_family_id": exact_id,
        "family_id": exact_id,
        "failure_signature": json.dumps(sig, sort_keys=True, separators=(",", ":"), default=str),
        "fail_reasons": ",".join(str(x) for x in result.get("fail_reasons", [])) if isinstance(result.get("fail_reasons"), list) else result.get("fail_reasons", ""),
        "attempts": result.get("attempts", ""),
        "poll_stop_reason": result.get("poll_stop_reason", ""),
        "stable_signature_count": result.get("stable_signature_count", ""),
        "state_calibrate": fields.get("state_calibrate", ""),
        "instruction_address": calib.get("instruction_address", ""),
        "panopticon_marker": pan.get("marker", ""),
        "bitstream_sha256": result.get("bitstream_sha256", ""),
        "result_json": str(result_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sweep_dir", type=Path)
    parser.add_argument("--status-csv", type=Path, help="Defaults to sweep_dir/sweep_status.csv")
    parser.add_argument("--out-dir", type=Path, help="Defaults to sweep_dir/analysis")
    args = parser.parse_args()

    status_path = args.status_csv or args.sweep_dir / "sweep_status.csv"
    out_dir = args.out_dir or args.sweep_dir / "analysis"
    status_by_json: dict[str, dict[str, str]] = {}
    if status_path.exists():
        for row in read_csv(status_path):
            if row.get("result_json"):
                status_by_json[str(Path(row["result_json"]))] = row

    rows = []
    for result_path in sorted(args.sweep_dir.glob("*.json")):
        rows.append(result_row(result_path, status_by_json.get(str(result_path))))

    by_family: dict[str, list[dict[str, Any]]] = defaultdict(list)
    by_seed: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        by_family[str(row["coarse_family_id"])].append(row)
        by_seed[str(row["seed"])].append(row)

    family_rows = []
    for fid, items in sorted(by_family.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        stages = Counter(str(item["stage_name"]) for item in items)
        statuses = Counter(str(item["status"]) for item in items)
        seeds = sorted({str(item["seed"]) for item in items if item.get("seed")}, key=lambda value: int(value) if value.isdigit() else 0)
        family_rows.append({
            "coarse_family_id": fid,
            "count": len(items),
            "seeds": ",".join(seeds),
            "statuses": ",".join(f"{k}:{v}" for k, v in statuses.items()),
            "stages": ",".join(f"{k}:{v}" for k, v in stages.items()),
            "example_result_json": items[0]["result_json"],
            "example_signature": items[0]["failure_signature"],
        })

    seed_rows = []
    for seed, items in sorted(by_seed.items(), key=lambda kv: int(kv[0]) if kv[0].isdigit() else 0):
        families = Counter(str(item["coarse_family_id"]) for item in items)
        exact_families = Counter(str(item["exact_family_id"]) for item in items)
        statuses = Counter(str(item["status"]) for item in items)
        seed_rows.append({
            "seed": seed,
            "repeats": len(items),
            "statuses": ",".join(f"{k}:{v}" for k, v in statuses.items()),
            "coarse_families": ",".join(f"{k}:{v}" for k, v in families.items()),
            "exact_families": ",".join(f"{k}:{v}" for k, v in exact_families.items()),
            "intermittent": len(statuses) > 1 or len(families) > 1,
        })

    write_csv(out_dir / "result_families.csv", rows)
    write_csv(out_dir / "family_summary.csv", family_rows)
    write_csv(out_dir / "seed_summary.csv", seed_rows)
    print(out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
