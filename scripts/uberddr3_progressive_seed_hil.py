#!/usr/bin/env python3
"""Build and HIL-test YPCB DDR3 seeds progressively.

This intentionally builds one bitstream, tests it, then moves to the next seed.
Passing seeds use one hardware run by default. Failing seeds are repeated so we
can distinguish stable failures from intermittent/programming issues without
prebuilding a large batch.
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path


DEFAULT_BOARD_TEST = Path("example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py")
DEFAULT_PROGRAMMER = Path("/home/roland/openFPGALoader/build/openFPGALoader")
BITSTREAM_NAME = "ypcb_00338_1p1_ddr3_openxc7.bit"


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)


def load_json(path: Path) -> dict[str, object]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def infer_byte_lanes(variant: str) -> int:
    if "lanes1" in variant:
        return 1
    if "lanes2" in variant:
        return 2
    return 2


def classify(result: dict[str, object]) -> tuple[str, str, str]:
    if result.get("pass") is True:
        return "pass", "pass", "pass"
    reasons = result.get("fail_reasons", [])
    fields = result.get("fields", {})
    if not isinstance(fields, dict):
        return "missing_result", "missing_result", "missing_result"
    state = fields.get("state_calibrate", "")
    calib = fields.get("calib_debug", {})
    bist = fields.get("bist_debug", {})
    if "wrong_read_data_nonzero" in reasons or (isinstance(bist, dict) and bist.get("valid")):
        mask = bist.get("byte_mismatch_mask", "") if isinstance(bist, dict) else ""
        return "bist", f"bist.mask_{mask}", f"bist.state_{state}.mask_{mask}"
    if "calib_incomplete" in reasons or "calib_state_not_done" in reasons:
        instr = calib.get("instruction_address", "") if isinstance(calib, dict) else ""
        return "calibration", f"calibration.state_{state}", f"calibration.state_{state}.instr_{instr}"
    return "unknown", "unknown", ".".join(str(reason) for reason in reasons) or "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start", type=int, required=True)
    parser.add_argument("--end", type=int, required=True)
    parser.add_argument("--variant", default="panopticon")
    parser.add_argument("--package-prefix", default="ypcb-ddr3-bitstream-panopticon-seed-")
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--board-test", type=Path, default=DEFAULT_BOARD_TEST)
    parser.add_argument("--programmer", type=Path, default=DEFAULT_PROGRAMMER)
    parser.add_argument("--pass-repeats", type=int, default=1)
    parser.add_argument("--fail-repeats", type=int, default=3)
    parser.add_argument("--poll-count", type=int, default=120)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--stable-samples", type=int, default=5)
    parser.add_argument("--stable-min-attempt", type=int, default=10)
    parser.add_argument("--byte-lanes", type=int, choices=(1, 2), help="DDR3 byte lanes for board-test decode. Defaults from --variant lanesN.")
    parser.add_argument("--continue-on-fail", action="store_true")
    args = parser.parse_args()
    byte_lanes = args.byte_lanes if args.byte_lanes is not None else infer_byte_lanes(args.variant)

    repo = Path.cwd()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    status_path = args.out_dir / "sweep_status.csv"
    fieldnames = ["seed", "repeat", "variant", "status", "stage", "coarse_family_id", "exact_family_id", "json"]

    with status_path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        csv_file.flush()

        for seed in range(args.start, args.end + 1):
            package = f".#${args.package_prefix}{seed}".replace("#$", "#")
            out_link = args.out_dir / f"seed-{seed}-result"
            build = run(["nix", "build", package, "--out-link", str(out_link), "-L"], repo)
            if build.returncode != 0:
                writer.writerow({"seed": seed, "repeat": 0, "variant": args.variant, "status": "fail", "stage": "build", "coarse_family_id": "build", "exact_family_id": "build", "json": ""})
                csv_file.flush()
                print(f"seed-{seed}: build_fail rc={build.returncode}")
                if not args.continue_on_fail:
                    return build.returncode or 1
                continue

            bitstream = out_link / BITSTREAM_NAME
            repeats_left = args.pass_repeats
            seed_failed = False
            repeat = 1
            while repeat <= repeats_left:
                json_path = args.out_dir / f"{args.variant}-seed-{seed}-repeat-{repeat}.json"
                command = [
                    str(args.board_test),
                    "--programmer", str(args.programmer),
                    "--bitstream", str(bitstream),
                    "--output", str(json_path),
                    "--poll-count", str(args.poll_count),
                    "--poll-interval", str(args.poll_interval),
                    "--stable-samples", str(args.stable_samples),
                    "--stable-min-attempt", str(args.stable_min_attempt),
                    "--byte-lanes", str(byte_lanes),
                ]
                test = run(command, repo)
                if json_path.exists():
                    result = load_json(json_path)
                    stage, coarse, exact = classify(result)
                else:
                    stage, coarse, exact = "missing_result", "missing_result", "missing_result"
                ok = test.returncode == 0 and stage == "pass"
                status = "pass" if ok else "fail"
                writer.writerow({"seed": seed, "repeat": repeat, "variant": args.variant, "status": status, "stage": stage, "coarse_family_id": coarse, "exact_family_id": exact, "json": str(json_path)})
                csv_file.flush()
                print(f"{args.variant}-seed-{seed}-repeat-{repeat}: {status} rc={test.returncode} stage={stage} coarse={coarse} exact={exact}")
                if ok:
                    repeat += 1
                    continue
                seed_failed = True
                repeats_left = max(repeats_left, args.fail_repeats)
                repeat += 1
            if seed_failed and not args.continue_on_fail:
                return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
