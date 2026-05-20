#!/usr/bin/env python3
"""Program a PHASER diagnostic bitstream and read/check it atomically.

This helper is intended to be run as the child command of
``task6_board_run.py with-lock``. It performs all board-visible work inside
that one locked process so the decoded status is attributable to the bitstream
that was just programmed.
"""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import shlex
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REQUIREMENTS = (
    "magic_ok=true",
    "fields.version=4",
    "fields.phaser_pll_locked=true",
    "fields.phaser_ref_locked=true",
    "fields.phyctl_ready=true",
    "fields.sequence_done=true",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run_logged(argv: list[str], log_path: Path) -> int:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8") as log:
        log.write("$ " + shlex.join(argv) + "\n")
        log.flush()
        proc = subprocess.run(
            argv,
            cwd=ROOT,
            stdout=log,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
    return proc.returncode


def run_json_logged(argv: list[str], log_path: Path) -> tuple[int, dict[str, Any] | None]:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8") as log:
        log.write("$ " + shlex.join(argv) + "\n")
        log.flush()
        proc = subprocess.run(
            argv,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        log.write(proc.stdout)
    if proc.returncode != 0:
        return proc.returncode, None
    try:
        return proc.returncode, json.loads(proc.stdout)
    except json.JSONDecodeError:
        return proc.returncode, None


def parse_expected_value(text: str) -> Any:
    lowered = text.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered == "null":
        return None
    try:
        return int(text, 0)
    except ValueError:
        return text


def parse_requirement(text: str) -> tuple[str, Any]:
    if "=" not in text:
        raise argparse.ArgumentTypeError(f"requirement must be field=value: {text!r}")
    key, value = text.split("=", 1)
    key = key.strip()
    if not key:
        raise argparse.ArgumentTypeError(f"empty requirement field in {text!r}")
    return key, parse_expected_value(value.strip())


def lookup_path(payload: dict[str, Any], dotted_path: str) -> Any:
    value: Any = payload
    for part in dotted_path.split("."):
        if not isinstance(value, dict) or part not in value:
            raise KeyError(dotted_path)
        value = value[part]
    return value


def evaluate_requirements(
    decoded: dict[str, Any],
    requirements: list[tuple[str, Any]],
) -> tuple[bool, list[dict[str, Any]]]:
    checks: list[dict[str, Any]] = []
    passed = True
    for path, expected in requirements:
        try:
            actual = lookup_path(decoded, path)
            ok = actual == expected
        except KeyError:
            actual = None
            ok = False
        checks.append({
            "field": path,
            "expected": expected,
            "actual": actual,
            "pass": ok,
        })
        passed = passed and ok
    return passed, checks


def update_verdict(run_dir: Path, pass_result: bool, cycles: list[dict[str, Any]]) -> None:
    verdict_path = run_dir / "verdict.json"
    if verdict_path.exists():
        try:
            verdict = json.loads(verdict_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            verdict = {}
    else:
        verdict = {}
    verdict.update({
        "schema": verdict.get("schema", "task6-board-verdict-v1"),
        "status": "PASS" if pass_result else "FAIL",
        "updated_at": datetime.now().astimezone().isoformat(),
        "correctness": pass_result,
        "phaser_atomic_hil": {
            "pass": pass_result,
            "cycles": cycles,
        },
    })
    write_json(verdict_path, verdict)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--bitstream", required=True, type=Path)
    parser.add_argument("--cycles", type=int, default=1)
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--jtag-link", default="digilent_hs3")
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--reader-backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--reader-freq-hz", type=int, default=1_000_000)
    parser.add_argument("--read-bits", type=int, choices=(128, 136), default=136)
    parser.add_argument("--artifact", action="append", type=Path, default=[])
    parser.add_argument("--require", dest="requirements", action="append", default=[])
    parser.add_argument("--no-default-requirements", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    run_dir = args.run_dir.resolve()
    if not run_dir.is_dir():
        raise SystemExit(f"run dir does not exist: {run_dir}")
    bitstream = args.bitstream.resolve()
    if not bitstream.is_file():
        raise SystemExit(f"bitstream does not exist: {bitstream}")
    if args.cycles < 1:
        raise SystemExit("--cycles must be at least 1")

    requirement_texts: list[str] = []
    if not args.no_default_requirements:
        requirement_texts.extend(DEFAULT_REQUIREMENTS)
    requirement_texts.extend(args.requirements)
    requirements = [parse_requirement(item) for item in requirement_texts]

    artifacts = [{
        "path": str(bitstream),
        "sha256": sha256_file(bitstream),
        "role": "bitstream",
    }]
    for artifact in args.artifact:
        path = artifact.resolve()
        artifacts.append({
            "path": str(path),
            "sha256": sha256_file(path) if path.is_file() else None,
            "role": path.suffix.lstrip(".") or "artifact",
        })
    write_json(run_dir / "phaser-atomic-hil-artifacts.json", {
        "schema": "phaser-atomic-hil-artifacts-v1",
        "artifacts": artifacts,
    })

    cycle_results: list[dict[str, Any]] = []
    overall_pass = True
    for cycle in range(1, args.cycles + 1):
        program_argv = [
            "openFPGALoader",
            "-c",
            args.jtag_link,
            "--ftdi-serial",
            args.serial,
            "--bitstream",
            str(bitstream),
        ]
        program_rc = run_logged(program_argv, run_dir / "logs" / f"atomic-program-cycle{cycle}.log")
        if program_rc != 0:
            result = {
                "cycle": cycle,
                "program_returncode": program_rc,
                "read_returncode": None,
                "pass": False,
                "checks": [],
                "decoded_path": None,
            }
            cycle_results.append(result)
            overall_pass = False
            continue

        read_argv = [
            sys.executable,
            "scripts/task6/read_ypcb_phaser_diag_status.py",
            "--serial",
            args.serial,
            "--backend",
            args.reader_backend,
            "--freq-hz",
            str(args.reader_freq_hz),
            "--tdo-bit",
            str(args.tdo_bit),
            "--bits",
            str(args.read_bits),
        ]
        read_rc, decoded = run_json_logged(
            read_argv,
            run_dir / "logs" / f"atomic-read-cycle{cycle}.log",
        )
        decoded_path = run_dir / "readback" / f"phaser-cycle{cycle}.json"
        if decoded is not None:
            write_json(decoded_path, decoded)
            pass_result, checks = evaluate_requirements(decoded, requirements)
        else:
            pass_result = False
            checks = []
        result = {
            "cycle": cycle,
            "program_returncode": program_rc,
            "read_returncode": read_rc,
            "pass": pass_result,
            "checks": checks,
            "decoded_path": str(decoded_path.relative_to(ROOT)) if decoded is not None else None,
            "raw_hex": decoded.get("raw_hex") if decoded else None,
        }
        cycle_results.append(result)
        overall_pass = overall_pass and pass_result

    summary = {
        "schema": "phaser-atomic-hil-v1",
        "created_at": datetime.now().astimezone().isoformat(),
        "run_dir": str(run_dir.relative_to(ROOT)),
        "bitstream": str(bitstream),
        "bitstream_sha256": sha256_file(bitstream),
        "cycles_requested": args.cycles,
        "pass": overall_pass,
        "requirements": [{"field": path, "expected": expected} for path, expected in requirements],
        "cycles": cycle_results,
    }
    write_json(run_dir / "phaser-atomic-hil-summary.json", summary)
    update_verdict(run_dir, overall_pass, cycle_results)
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0 if overall_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
