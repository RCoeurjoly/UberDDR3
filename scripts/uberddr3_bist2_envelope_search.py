#!/usr/bin/env python3
"""Search the YPCB DDR3 BIST_MODE=2 parameter envelope one bitstream at a time."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from pathlib import Path
from typing import Iterable

DEFAULT_BOARD_TEST = Path("example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py")
BITSTREAM_NAME = "ypcb_00338_1p1_ddr3_openxc7.bit"
STATUS_FIELDS = [
    "index",
    "suffix",
    "label",
    "axis",
    "seed",
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
    "strict_fail_reasons",
    "board_fail_reasons",
    "attempts",
    "poll_stop_reason",
    "clk_locked",
    "calib_complete",
    "state_calibrate",
    "bist_done",
    "correct_read_data",
    "wrong_read_data",
    "controller_clk_period",
    "ddr3_clk_period",
    "row_bits",
    "col_bits",
    "ba_bits",
    "byte_lanes",
    "aux_width",
    "wb2_addr_bits",
    "wb2_data_bits",
    "second_wishbone",
    "wb_error",
    "bist_mode",
    "bist_test_datamask",
    "ecc_enable",
    "dic",
    "rtt_nom",
    "self_refresh",
    "speed_bin",
    "sdram_capacity",
    "notes",
]


def run(command: list[str], cwd: Path, log_path: Path) -> int:
    completed = subprocess.run(command, cwd=cwd, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(completed.stdout, encoding="utf-8")
    return completed.returncode


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


def load_result(path: Path) -> dict[str, object]:
    if not path.exists():
        return {"pass": False, "fail_reasons": ["missing_result"]}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"pass": False, "fail_reasons": ["invalid_result_json"]}


def strict_fail_reasons(result: dict[str, object]) -> list[str]:
    fields = result.get("fields", {})
    if not isinstance(fields, dict):
        return ["missing_fields"]
    reasons: list[str] = []
    board_reasons = result.get("fail_reasons", [])
    if not isinstance(board_reasons, list):
        board_reasons = ["invalid_fail_reasons"]
    if result.get("pass") is not True:
        reasons.append("board_pass_not_true")
    if fields.get("clk_locked") is not True:
        reasons.append("clk_locked_not_true")
    if fields.get("calib_complete") is not True:
        reasons.append("calib_complete_not_true")
    if fields.get("state_calibrate") != 23:
        reasons.append("state_calibrate_not_23")
    if fields.get("bist_done") is not True:
        reasons.append("bist_done_not_true")
    if fields.get("wrong_read_data") != 0:
        reasons.append("wrong_read_data_nonzero")
    if board_reasons:
        reasons.append("board_fail_reasons_nonempty")
    return reasons


def is_strict_pass(result: dict[str, object]) -> bool:
    return not strict_fail_reasons(result)


def failure_class(result: dict[str, object], strict_reasons: list[str]) -> str:
    board_reasons = result.get("fail_reasons", [])
    if not isinstance(board_reasons, list):
        board_reasons = []
    if not strict_reasons:
        return "pass"
    if "programming_failed" in board_reasons:
        return "programming"
    if "bad_magic" in board_reasons or "bad_version" in board_reasons or "missing_fields" in strict_reasons:
        return "debug_payload"
    if "clk_unlocked" in board_reasons or "clk_locked_not_true" in strict_reasons:
        return "clock"
    if "wrong_read_data_nonzero" in board_reasons or "wrong_read_data_nonzero" in strict_reasons:
        return "bist_mismatch"
    if "bist_not_done" in board_reasons or "bist_done_not_true" in strict_reasons:
        return "bist_timeout"
    if "calib_incomplete" in board_reasons or "calib_state_not_done" in board_reasons:
        return "calibration"
    return "strict_rule"


def build_matrix(args: argparse.Namespace, repo: Path) -> Path:
    if args.matrix:
        return args.matrix
    out_link = args.out_dir / "matrix.csv"
    log_path = args.out_dir / "build-matrix.log"
    rc = run(["nix", "build", args.matrix_package, "-o", str(out_link)], repo, log_path)
    if rc != 0:
        raise RuntimeError(f"matrix build failed rc={rc}; see {log_path}")
    return out_link


def package_for(row: dict[str, str]) -> str:
    package = row.get("bitstream_package", "")
    if package:
        return f".#{package}" if not package.startswith(".#") else package
    return f".#ypcb-ddr3-bitstream-{row['suffix']}-seed-1"


def byte_lanes_for(row: dict[str, str]) -> str:
    return row.get("byte_lanes") or "2"


def board_reasons(result: dict[str, object]) -> str:
    reasons = result.get("fail_reasons", [])
    if isinstance(reasons, list):
        return ",".join(str(reason) for reason in reasons)
    return str(reasons)


def result_fields(result: dict[str, object]) -> dict[str, object]:
    fields = result.get("fields", {})
    return fields if isinstance(fields, dict) else {}


def test_index(index: int, matrix: list[dict[str, str]], args: argparse.Namespace, repo: Path, rows: list[dict[str, object]], cache: dict[int, bool]) -> bool:
    if index in cache and not args.retest:
        return cache[index]
    row = matrix[index]
    suffix = row["suffix"]
    package = package_for(row)
    build_link = args.out_dir / f"build-p{index:03d}"
    build_log = args.out_dir / f"build-p{index:03d}.log"
    result_json = args.out_dir / f"p{index:03d}-{suffix}-seed-1.json"
    test_log = args.out_dir / f"p{index:03d}-{suffix}-seed-1.log"
    status_row: dict[str, object] = {
        **row,
        "index": index,
        "seed": row.get("seed", "1"),
        "package": package,
        "build_log": build_log,
        "test_log": test_log,
        "result_json": result_json,
    }

    build_rc = run(["nix", "build", package, "-o", str(build_link), "-L"], repo, build_log)
    status_row["build_returncode"] = build_rc
    if build_rc != 0:
        status_row.update({"status": "fail", "failure_class": "build", "strict_fail_reasons": "build_failed"})
        rows.append(status_row)
        write_status(args.out_dir / "status.csv", rows)
        cache[index] = False
        print(f"p{index:03d} {suffix}: build_fail rc={build_rc}")
        return False

    bitstream = build_link / BITSTREAM_NAME
    status_row["bitstream"] = bitstream
    status_row["bitstream_sha256"] = sha256_file(bitstream)
    command = [
        "python3",
        str(args.board_test),
        "--bitstream",
        str(bitstream),
        "--output",
        str(result_json),
        "--poll-count",
        str(args.poll_count),
        "--poll-interval",
        str(args.poll_interval),
        "--byte-lanes",
        byte_lanes_for(row),
    ]
    if args.programmer:
        command.extend(["--programmer", str(args.programmer)])
    if args.stable_samples:
        command.extend(["--stable-samples", str(args.stable_samples), "--stable-min-attempt", str(args.stable_min_attempt)])
    test_rc = run(command, repo, test_log)
    result = load_result(result_json)
    fields = result_fields(result)
    strict_reasons = strict_fail_reasons(result)
    passed = test_rc == 0 and is_strict_pass(result)
    status_row.update({
        "test_returncode": test_rc,
        "status": "pass" if passed else "fail",
        "failure_class": failure_class(result, strict_reasons),
        "strict_fail_reasons": ",".join(strict_reasons),
        "board_fail_reasons": board_reasons(result),
        "attempts": result.get("attempts", ""),
        "poll_stop_reason": result.get("poll_stop_reason", ""),
        "clk_locked": fields.get("clk_locked", ""),
        "calib_complete": fields.get("calib_complete", ""),
        "state_calibrate": fields.get("state_calibrate", ""),
        "bist_done": fields.get("bist_done", ""),
        "correct_read_data": fields.get("correct_read_data", ""),
        "wrong_read_data": fields.get("wrong_read_data", ""),
    })
    rows.append(status_row)
    write_status(args.out_dir / "status.csv", rows)
    cache[index] = passed
    print(f"p{index:03d} {suffix}: {'pass' if passed else 'fail'} rc={test_rc} class={status_row['failure_class']}")
    return passed


def unique_order(items: Iterable[int]) -> list[int]:
    seen: set[int] = set()
    ordered = []
    for item in items:
        if item not in seen:
            seen.add(item)
            ordered.append(item)
    return ordered


def search(matrix: list[dict[str, str]], args: argparse.Namespace, repo: Path) -> tuple[int | None, int | None, list[dict[str, object]]]:
    rows: list[dict[str, object]] = []
    cache: dict[int, bool] = {}
    last_pass: int | None = None
    first_fail: int | None = None
    count = len(matrix)

    if count == 0:
        return None, None, rows
    if test_index(0, matrix, args, repo, rows, cache):
        last_pass = 0
    else:
        first_fail = 0

    probe = 1
    while first_fail is None and probe < count:
        if test_index(probe, matrix, args, repo, rows, cache):
            last_pass = probe
            probe *= 2
        else:
            first_fail = probe
            break
    if first_fail is None:
        return last_pass, None, rows

    low = last_pass if last_pass is not None else -1
    high = first_fail
    while high - low > 1:
        mid = (low + high) // 2
        if test_index(mid, matrix, args, repo, rows, cache):
            low = mid
            last_pass = mid
        else:
            high = mid
            first_fail = mid

    first_fail = high
    last_pass = low if low >= 0 else None
    for index in unique_order(range(max(0, first_fail - 2), min(count, first_fail + 3))):
        test_index(index, matrix, args, repo, rows, cache)
    return last_pass, first_fail, rows


def write_summary(path: Path, matrix_path: Path, last_pass: int | None, first_fail: int | None, rows: list[dict[str, object]]) -> None:
    summary = {
        "matrix": str(matrix_path),
        "status_csv": str(path / "status.csv"),
        "tested_count": len(rows),
        "highest_passing_index": last_pass,
        "first_failing_index": first_fail,
    }
    (path / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (path / "README.md").write_text(
        "\n".join([
            "# YPCB DDR3 BIST_MODE=2 Envelope Search",
            "",
            "Generated by `scripts/uberddr3_bist2_envelope_search.py`.",
            "",
            f"- matrix: `{matrix_path}`",
            f"- status CSV: `{path / 'status.csv'}`",
            f"- highest passing index: `{last_pass}`",
            f"- first failing index: `{first_fail}`",
            "",
        ]),
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--matrix", type=Path, help="Existing envelope CSV. Defaults to building --matrix-package.")
    parser.add_argument("--matrix-package", default=".#ypcb-ddr3-bist2-envelope-matrix")
    parser.add_argument("--out-dir", type=Path, default=Path("local-artifacts/bist2-envelope-search"))
    parser.add_argument("--board-test", type=Path, default=DEFAULT_BOARD_TEST)
    parser.add_argument("--programmer", type=Path)
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--stable-samples", type=int, default=0)
    parser.add_argument("--stable-min-attempt", type=int, default=10)
    parser.add_argument("--retest", action="store_true", help="Retest indices even if this run already tested them.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path.cwd()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    matrix_path = build_matrix(args, repo)
    matrix = read_csv(matrix_path)
    last_pass, first_fail, rows = search(matrix, args, repo)
    write_summary(args.out_dir, matrix_path, last_pass, first_fail, rows)
    print(args.out_dir / "status.csv")
    print(f"highest_passing_index={last_pass} first_failing_index={first_fail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
