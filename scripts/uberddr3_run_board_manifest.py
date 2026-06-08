#!/usr/bin/env python3
"""Run YPCB DDR3 board tests for each row in a build manifest.

Expected CSV columns: experiment_id, seed, variant, bitstream_file.
Package manifests may use bitstream_package instead of bitstream_file and
should include byte_lanes when the debug payload is not the default 2 lanes.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from pathlib import Path

STATUS_FIELDS = [
    "experiment_id",
    "seed",
    "repeat",
    "variant",
    "byte_lanes",
    "bitstream",
    "bitstream_sha256",
    "result_json",
    "log",
    "returncode",
    "status",
    "failure_class",
    "fail_reasons",
    "attempts",
    "clk_locked",
    "calib_complete",
    "state_calibrate",
    "bist_done",
    "correct_read_data",
    "wrong_read_data",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_status(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATUS_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in STATUS_FIELDS})


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def classify_result(result_path: Path) -> dict[str, object]:
    if not result_path.exists():
        return {"failure_class": "missing_result"}
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"failure_class": "invalid_result_json"}

    fields = result.get("fields", {})
    fail_reasons = result.get("fail_reasons", [])
    if result.get("pass"):
        failure_class = "pass"
    elif "programming_failed" in fail_reasons:
        failure_class = "programming"
    elif "clk_unlocked" in fail_reasons:
        failure_class = "clock"
    elif "bad_magic" in fail_reasons or "bad_version" in fail_reasons:
        failure_class = "debug_payload"
    elif "wrong_read_data_nonzero" in fail_reasons:
        failure_class = "bist_mismatch"
    elif "calib_incomplete" in fail_reasons or "calib_state_not_done" in fail_reasons:
        state = fields.get("state_calibrate")
        if state == 0:
            failure_class = "init_or_reset"
        elif state in (1, 2, 3, 4, 13):
            failure_class = "dqs_or_early_calibration"
        elif state in (17, 18, 19, 20, 21, 22):
            failure_class = "late_calibration_or_bist_start"
        else:
            failure_class = "calibration"
    elif "bist_not_done" in fail_reasons:
        failure_class = "bist_timeout"
    else:
        failure_class = "unknown"

    return {
        "failure_class": failure_class,
        "fail_reasons": ",".join(str(reason) for reason in fail_reasons),
        "attempts": result.get("attempts", ""),
        "clk_locked": fields.get("clk_locked", ""),
        "calib_complete": fields.get("calib_complete", ""),
        "state_calibrate": fields.get("state_calibrate", ""),
        "bist_done": fields.get("bist_done", ""),
        "correct_read_data": fields.get("correct_read_data", ""),
        "wrong_read_data": fields.get("wrong_read_data", ""),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, default=Path("local-artifacts/board-sweeps"))
    parser.add_argument("--board-test", type=Path, default=Path("example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py"))
    parser.add_argument("--bitstream-name", default="ypcb_00338_1p1_ddr3_openxc7.bit")
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--continue-on-fail", action="store_true")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    status_path = args.out_dir / "sweep_status.csv"
    status_rows: list[dict[str, object]] = []
    final_rc = 0

    for row in read_csv(args.manifest):
        experiment_id = row["experiment_id"]
        result_json = args.out_dir / f"{experiment_id}.json"
        log_path = args.out_dir / f"{experiment_id}.log"
        package = row.get("bitstream_package", "")
        if row.get("bitstream_file"):
            bitstream = row["bitstream_file"]
        elif package:
            package_ref = package if package.startswith(".#") else f".#{package}"
            build_link = args.out_dir / f"build-{experiment_id}"
            build_log = args.out_dir / f"build-{experiment_id}.log"
            build_command = ["nix", "build", package_ref, "-o", str(build_link), "-L"]
            build = subprocess.run(build_command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            build_log.write_text(build.stdout, encoding="utf-8")
            if build.returncode != 0:
                status_rows.append({"experiment_id": experiment_id, "seed": row.get("seed", ""), "repeat": row.get("repeat", ""), "variant": row.get("variant", ""), "byte_lanes": row.get("byte_lanes", "2") or "2", "bitstream": package_ref, "bitstream_sha256": "", "result_json": result_json, "log": build_log, "returncode": build.returncode, "status": "fail", "failure_class": "build", "fail_reasons": "build_failed"})
                write_status(status_path, status_rows)
                if not args.continue_on_fail:
                    return build.returncode or 1
                continue
            bitstream = str(build_link / args.bitstream_name)
        else:
            raise KeyError("manifest row must include bitstream_file or bitstream_package")
        byte_lanes = row.get("byte_lanes", "2") or "2"
        bitstream_sha256 = sha256_file(Path(bitstream))

        if args.skip_existing and result_json.exists():
            classification = classify_result(result_json)
            status_rows.append({"experiment_id": experiment_id, "seed": row.get("seed", ""), "repeat": row.get("repeat", ""), "variant": row.get("variant", ""), "byte_lanes": byte_lanes, "bitstream": bitstream, "bitstream_sha256": bitstream_sha256, "result_json": result_json, "log": log_path, "returncode": "", "status": "skipped_existing", **classification})
            write_status(status_path, status_rows)
            continue

        command = ["python3", str(args.board_test), "--bitstream", bitstream, "--output", str(result_json), "--poll-count", str(args.poll_count), "--poll-interval", str(args.poll_interval), "--byte-lanes", byte_lanes]
        completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        log_path.write_text(completed.stdout, encoding="utf-8")
        status = "pass" if completed.returncode == 0 else "fail"
        classification = classify_result(result_json)
        status_rows.append({"experiment_id": experiment_id, "seed": row.get("seed", ""), "repeat": row.get("repeat", ""), "variant": row.get("variant", ""), "byte_lanes": byte_lanes, "bitstream": bitstream, "bitstream_sha256": bitstream_sha256, "result_json": result_json, "log": log_path, "returncode": completed.returncode, "status": status, **classification})
        write_status(status_path, status_rows)
        print(f"{experiment_id}: {status} rc={completed.returncode}")
        if completed.returncode != 0:
            final_rc = completed.returncode
            if not args.continue_on_fail:
                break

    (args.out_dir / "README.md").write_text("\n".join(["# YPCB DDR3 Hardware Sweep", "", "Generated by `scripts/uberddr3_run_board_manifest.py`.", "", f"- manifest: `{args.manifest}`", f"- poll count: `{args.poll_count}`", f"- poll interval seconds: `{args.poll_interval}`", f"- rows attempted: `{len(status_rows)}`", f"- status CSV: `{status_path}`", ""]), encoding="utf-8")
    print(status_path)
    return final_rc


if __name__ == "__main__":
    raise SystemExit(main())
