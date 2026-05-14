#!/usr/bin/env python3
"""Run one YPCB UberDDR3 calibration-consistency sweep row."""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
BOARD_RUN = ROOT / "scripts" / "task6" / "task6_board_run.py"
READ_JTAG = ROOT / "scripts" / "task6" / "read_jtag_debug_ftdi_bitbang.py"
LOCK_GENERATOR = ROOT / "scripts" / "task6" / "generate_nextpnr_pre_place_bel_locks.py"
EXPERIMENT_RUNNER = ROOT / "scripts" / "task6" / "task6_ddr3_experiment_runner.py"
YPCB_DIR = ROOT / "example_demo" / "ypcb_00338_1p1"
ROWSTREAM_BIT = YPCB_DIR / "ypcb_00338_1p1_uberddr3_rowstream_loader_openxc7.bit"
ROWSTREAM_STEM = "ypcb_00338_1p1_uberddr3_rowstream_loader"
BUILD_ARTIFACTS = (
    f"{ROWSTREAM_STEM}.json",
    f"{ROWSTREAM_STEM}.fasm",
    f"{ROWSTREAM_STEM}.frames",
    f"{ROWSTREAM_STEM}_openxc7.bit",
    "nextpnr-routed.json",
)
V40_LOCKS = (
    ROOT
    / "artifacts"
    / "task6"
    / "baselines"
    / "uberddr3-rowstream-loader-v40-physical-stability"
    / "known-good-packed-bel-locks.json"
)
SWEEP_ROOT = ROOT / "artifacts" / "task6" / "calibration-sweeps"

DEBUG_BITS = 512
DEBUG_MAGIC = 0x54364A44
LOCK_SETS: dict[str, tuple[str, ...]] = {
    "none": (),
    "clocks": ("ddr3_clocks",),
    "phy": ("uberddr3_phy",),
    "clocks-phy": ("ddr3_clocks", "uberddr3_phy"),
    "full": ("ddr3_clocks", "ddr3_board_pins", "uberddr3_phy"),
    "full-jtag-clocks": (
        "ddr3_clocks",
        "ddr3_board_pins",
        "uberddr3_phy",
        "jtag_clocks",
    ),
    "oracle-all": ("all_seed3",),
    "full-idelayctrl-soft": (
        "ddr3_clocks",
        "ddr3_board_pins",
        "uberddr3_phy",
        "ddr3_idelayctrl_soft",
    ),
    "full-controller-soft": (
        "ddr3_clocks",
        "ddr3_board_pins",
        "uberddr3_phy",
        "ddr3_controller_soft",
    ),
    "full-uberddr3-soft": (
        "ddr3_clocks",
        "ddr3_board_pins",
        "uberddr3_phy",
        "ddr3_idelayctrl_soft",
        "ddr3_controller_soft",
        "uberddr3_soft",
    ),
}


def run_command(
    argv: list[str],
    *,
    cwd: Path = ROOT,
    log_path: Path | None = None,
    dry_run: bool = False,
) -> subprocess.CompletedProcess[str]:
    if log_path is not None:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("w", encoding="utf-8") as log:
            log.write("$ " + shlex.join(argv) + "\n")
            log.flush()
            if dry_run:
                return subprocess.CompletedProcess(argv, 0, "")
            proc = subprocess.run(
                argv,
                cwd=cwd,
                stdout=log,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
            )
        return subprocess.CompletedProcess(argv, proc.returncode, "")

    if dry_run:
        print("$ " + shlex.join(argv))
        return subprocess.CompletedProcess(argv, 0, "")
    return subprocess.run(
        argv,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )


def devshell(args: argparse.Namespace, command: list[str]) -> list[str]:
    if not args.nix_develop:
        return command
    return ["nix", "develop", str(ROOT), "--command", *command]


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def append_jsonl(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, sort_keys=True) + "\n")


def sha256_file(path: Path) -> str | None:
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def source_commit() -> str:
    proc = run_command(["git", "rev-parse", "HEAD"])
    if proc.returncode != 0:
        return "unknown"
    return proc.stdout.strip()


def dirty_suffix() -> str:
    proc = run_command(["git", "status", "--short"])
    if proc.returncode != 0:
        return "unknown"
    return "+dirty" if proc.stdout.strip() else ""


def make_run_dir(args: argparse.Namespace) -> Path:
    timestamp = datetime.now().astimezone().strftime("%Y-%m-%dT%H-%M-%S%z")
    label = f"{timestamp}-{args.lock_set}-seed{args.seed}"
    run_dir = SWEEP_ROOT / args.sweep / label
    for suffix in [""] + [f"-{index:02d}" for index in range(1, 100)]:
        candidate = Path(str(run_dir) + suffix)
        try:
            candidate.mkdir(parents=True, exist_ok=False)
            (candidate / "logs").mkdir()
            return candidate
        except FileExistsError:
            continue
    raise SystemExit(f"could not allocate sweep run dir for {label}")


def generate_lock_script(args: argparse.Namespace, run_dir: Path) -> Path:
    out_py = run_dir / f"locks-{args.lock_set}.py"
    scopes = LOCK_SETS[args.lock_set]
    if not scopes:
        out_py.write_text("# No BEL locks for this sweep row.\n", encoding="utf-8")
        return out_py

    command = [
        sys.executable,
        str(LOCK_GENERATOR),
        "--locks-json",
        str(V40_LOCKS),
    ]
    for extra_locks in args.extra_locks_json:
        command.extend(["--locks-json", str(extra_locks)])
    command.extend([
        "--ypcb-wrapper-remap",
        "--ypcb-top",
        "ypcb_00338_1p1_uberddr3_rowstream_loader",
        "--skip-cell",
        "clk100_90_bufg",
        "--out-py",
        str(out_py),
    ])
    for scope in scopes:
        command.extend(["--scope", scope])
    if args.allow_missing_locks or args.lock_set.startswith("full"):
        command.append("--allow-missing")
    proc = run_command(command, log_path=run_dir / "logs" / "generate-locks.log", dry_run=args.dry_run)
    if proc.returncode != 0:
        raise SystemExit(f"lock generation failed, see {run_dir / 'logs' / 'generate-locks.log'}")
    return out_py


def parse_lock_counts(log_text: str) -> tuple[int | None, int | None]:
    matches = re.findall(r"Task 6 pre-place BEL locks: applied=(\d+) missing=(\d+)", log_text)
    if not matches:
        return None, None
    applied, missing = matches[-1]
    return int(applied), int(missing)


def build_bitstream(args: argparse.Namespace, run_dir: Path, lock_py: Path) -> tuple[Path, str]:
    if args.bitstream is not None:
        return args.bitstream.resolve(), "supplied"

    if args.clean:
        proc = run_command(
            devshell(args, ["make", "-C", str(YPCB_DIR.relative_to(ROOT)), "clean"]),
            log_path=run_dir / "logs" / "make-clean.log",
            dry_run=args.dry_run,
        )
        if proc.returncode != 0:
            return ROWSTREAM_BIT, "clean-failed"

    pnr_pre_place = "" if args.lock_set == "none" else f"--pre-place {lock_py}"
    routed_json = run_dir / "build-artifacts" / "nextpnr-routed.json"
    routed_json.parent.mkdir(parents=True, exist_ok=True)
    make_vars = [
        "ypcb_00338_1p1_uberddr3_rowstream_loader_openxc7.bit",
        f"V40_PRE_PLACE_BEL_LOCKS={lock_py}",
        f"PNR_PRE_PLACE={pnr_pre_place}",
        f"PNR_ARGS=--seed {args.seed} --freq {args.freq} {args.pnr_extra_args}".rstrip(),
        f"PNR_DEBUG=--write {routed_json}",
        f"SYNTH_XILINX_FLAGS={args.synth_xilinx_flags}",
    ]
    if args.chipdb is not None:
        make_vars.append(f"CHIPDB={args.chipdb}")
    command = devshell(args, [
        "make",
        "-C",
        str(YPCB_DIR.relative_to(ROOT)),
        *make_vars,
    ])
    proc = run_command(command, log_path=run_dir / "logs" / "build.log", dry_run=args.dry_run)
    if proc.returncode != 0:
        return ROWSTREAM_BIT, "build-failed"
    return ROWSTREAM_BIT.resolve(), "built"


def archive_build_artifacts(run_dir: Path) -> dict[str, str]:
    out_dir = run_dir / "build-artifacts"
    archived: dict[str, str] = {}
    for name in BUILD_ARTIFACTS:
        source = YPCB_DIR / name
        if name == "nextpnr-routed.json":
            source = out_dir / name
        if not source.is_file():
            continue
        out_dir.mkdir(parents=True, exist_ok=True)
        destination = out_dir / name
        if source.resolve() != destination.resolve():
            shutil.copy2(source, destination)
        archived[name] = str(destination.relative_to(ROOT))
    return archived


def init_board_run(args: argparse.Namespace, run_dir: Path, bitstream: Path) -> Path:
    label = f"{args.sweep}-{args.lock_set}-seed{args.seed}"
    proc = run_command(
        [
            sys.executable,
            str(BOARD_RUN),
            "init",
            "--label",
            label,
            "--experiment",
            "task6-ddr3-calibration-sweep",
            "--bitstream",
            str(bitstream),
            "--notes",
            f"calibration sweep lock_set={args.lock_set} seed={args.seed}",
        ],
        log_path=run_dir / "logs" / "board-init.log",
        dry_run=args.dry_run,
    )
    if args.dry_run:
        board_run = run_dir / "dry-run-board-run"
        board_run.mkdir(exist_ok=True)
        (board_run / "logs").mkdir(exist_ok=True)
        return board_run
    if proc.returncode != 0:
        raise SystemExit(f"board run init failed, see {run_dir / 'logs' / 'board-init.log'}")
    log_text = (run_dir / "logs" / "board-init.log").read_text(encoding="utf-8")
    return Path(log_text.strip().splitlines()[-1])


def with_board_lock(
    board_run: Path,
    log_name: str,
    command: list[str],
    *,
    dry_run: bool,
) -> int:
    proc = run_command(
        [
            sys.executable,
            str(BOARD_RUN),
            "with-lock",
            "--run-dir",
            str(board_run),
            "--log-name",
            log_name,
            "--",
            *command,
        ],
        dry_run=dry_run,
    )
    return proc.returncode


def read_raw_debug(args: argparse.Namespace, board_run: Path, log_name: str) -> dict[str, Any] | None:
    command = devshell(args, [
        sys.executable,
        str(READ_JTAG),
        "--serial",
        args.ftdi_serial,
        "--tdo-bit",
        str(args.tdo_bit),
        "--bits",
        str(args.bits),
        "--json-only",
    ])
    rc = with_board_lock(board_run, log_name, command, dry_run=args.dry_run)
    if rc != 0 or args.dry_run:
        return None
    log_text = (board_run / "logs" / log_name).read_text(encoding="utf-8")
    start = log_text.find("{")
    end = log_text.rfind("}")
    if start < 0 or end < start:
        return None
    return json.loads(log_text[start : end + 1])


def decode_debug(readback: dict[str, Any] | None) -> dict[str, Any]:
    if readback is None:
        return {}
    raw = int(readback["raw_hex"], 16)
    status = (raw >> 40) & 0xFF
    loader_word = (raw >> 304) & 0xFFFFFFFF
    debug1 = (raw >> 112) & 0xFFFFFFFF
    return {
        "raw_hex": readback["raw_hex"],
        "magic": raw & 0xFFFFFFFF,
        "magic_ok": (raw & 0xFFFFFFFF) == DEBUG_MAGIC,
        "version": (raw >> 32) & 0xFF,
        "status": status,
        "calib_complete": bool(status & 0x1),
        "calib_seen": bool(status & 0x2),
        "cycle": (raw >> 48) & 0xFFFFFFFF,
        "calib_seen_cycle": (raw >> 80) & 0xFFFFFFFF,
        "debug1": f"0x{debug1:08x}",
        "state": debug1 & 0x1F,
        "instruction": (debug1 >> 5) & 0x1F,
        "idelay_ready": bool((debug1 >> 10) & 0x1),
        "ack_count": (raw >> 144) & 0xFFFFFFFF,
        "err_count": (raw >> 176) & 0xFFFFFFFF,
        "stall_count": (raw >> 208) & 0xFFFFFFFF,
        "loader_state": loader_word & 0xF,
        "loader_ready": (loader_word & 0xF) == 1,
        "loader_error": bool(loader_word & (1 << 9)),
        "boot_done": bool(loader_word & (1 << 11)),
        "boot_error": bool(loader_word & (1 << 14)),
    }


def _read_json_if_exists(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def program_and_rowstream_contract(
    args: argparse.Namespace,
    run_dir: Path,
    bitstream: Path,
) -> tuple[str, dict[str, Any]]:
    if args.skip_program:
        board_run = init_board_run(args, run_dir, bitstream)
        return str(board_run), {"program_status": "skipped"}

    label = f"{args.sweep}-{args.lock_set}-seed{args.seed}"
    argv = [
        sys.executable,
        str(EXPERIMENT_RUNNER),
        "--label",
        label,
        "--experiment",
        "task6-ddr3-calibration-sweep",
        "--variant",
        "rowstream-calibration-sweep",
        "--command-protocol",
        "rowstream192",
        "--expected-byte",
        f"0x{args.rowstream_expected_byte:02x}",
        "--command-byte",
        f"0x{args.rowstream_command_byte:02x}",
        "--command-addr",
        str(args.rowstream_command_addr),
        "--command-repeats",
        str(args.rowstream_command_repeats),
        "--command-opcode",
        f"0x{args.rowstream_command_opcode:02x}",
        "--rowstream-poll-timeout",
        str(args.rowstream_poll_timeout),
        "--rowstream-poll-interval",
        str(args.rowstream_poll_interval),
        "--rowstream-min-ack-delta",
        str(args.rowstream_min_ack_delta),
        "--rowstream-lowbyte-addr-offset",
        str(args.rowstream_lowbyte_addr_offset),
        "--ftdi-serial",
        args.ftdi_serial,
        "--openocd-interface",
        args.openocd_interface,
        "--openocd-target",
        args.openocd_target,
        "--openocd-speed",
        str(args.openocd_speed),
        "--tdo-bit",
        str(args.tdo_bit),
        "--bits",
        str(args.bits),
        "--bitstream",
        str(bitstream),
        "--programmer",
        "openocd",
    ]
    if args.rowstream_readback_after_write:
        argv.append("--rowstream-readback-after-write")
    if args.rowstream_command_update_mode:
        argv.extend(["--command-update-mode", args.rowstream_command_update_mode])

    log_path = run_dir / "logs" / "rowstream-contract.log"
    proc = run_command(devshell(args, argv), log_path=log_path, dry_run=args.dry_run)
    if args.dry_run:
        return "dry-run-rowstream-contract", {"program_status": "pass"}
    if proc.returncode != 0:
        return "rowstream-contract-failed", {
            "program_status": "fail",
            "raw_runner_output": log_path.read_text(encoding="utf-8"),
        }

    runner_stdout = log_path.read_text(encoding="utf-8")
    output_lines = [line.strip() for line in runner_stdout.splitlines() if line.strip()]
    board_run_path_text = next(
        (line for line in reversed(output_lines) if line.startswith("/")),
        "",
    )
    if not board_run_path_text:
        return "rowstream-contract-failed", {"program_status": "fail", "raw_runner_output": runner_stdout}

    board_run = Path(board_run_path_text)
    if not board_run.is_absolute():
        board_run = ROOT / board_run_path_text
    if not board_run.is_dir():
        return str(board_run), {"program_status": "fail"}

    decoded = _read_json_if_exists(board_run / "readback" / f"decoded-tdo{args.tdo_bit}.json")
    if decoded is None:
        return str(board_run), {"program_status": "fail", "board_run_dir": str(board_run)}

    result = decoded.get("result", {})
    calibration_pass = result.get("calibration") == "pass"
    row = {
        "program_status": "pass",
        "loader_ready": decoded.get("loader_ready"),
        "loader_error": decoded.get("loader_error"),
        "calib_seen": decoded.get("calib_seen", calibration_pass),
        "calib_complete": decoded.get("calib_complete", calibration_pass),
        "state": decoded.get("state"),
        "state_name": decoded.get("state_name"),
        "ack_count": decoded.get("ack_count"),
        "err_count": decoded.get("err_count"),
        "read_byte": decoded.get("read_byte"),
        "expected_byte": decoded.get("expected_byte"),
        "command_gate": result.get("command_gate"),
        "integrity": result.get("integrity"),
        "calibration": result.get("calibration"),
        "board": result.get("board"),
        "poll_count": None,
    }
    verdict = _read_json_if_exists(board_run / "verdict.json")
    if verdict is not None:
        row["board_verdict_status"] = verdict.get("status")
        row["board_verdict_correctness"] = verdict.get("correctness")
        row["board_verdict_board"] = verdict.get("board")
    return str(board_run), row


def program_and_poll(args: argparse.Namespace, run_dir: Path, bitstream: Path) -> tuple[str, dict[str, Any]]:
    if args.skip_program:
        board_run = init_board_run(args, run_dir, bitstream)
    else:
        board_run = init_board_run(args, run_dir, bitstream)
        program = devshell(args, [
            "openocd",
            "-f",
            args.openocd_interface,
            "-c",
            f"adapter serial {args.ftdi_serial}",
            "-f",
            args.openocd_target,
            "-c",
            f"adapter speed {args.openocd_speed}",
            "-c",
            "init",
            "-c",
            f"pld load 0 {bitstream}",
            "-c",
            "exit",
        ])
        rc = with_board_lock(board_run, "program.log", program, dry_run=args.dry_run)
        if rc != 0:
            return str(board_run), {"program_status": "fail"}

    deadline = time.monotonic() + args.poll_seconds
    last: dict[str, Any] = {}
    index = 0
    while args.dry_run or time.monotonic() <= deadline:
        readback = read_raw_debug(args, board_run, f"readback-{index:03d}.log")
        last = decode_debug(readback)
        if args.dry_run:
            break
        if (
            last.get("magic_ok")
            and last.get("calib_seen")
            and last.get("calib_complete")
            and last.get("loader_ready")
            and not last.get("loader_error")
        ):
            break
        index += 1
        time.sleep(args.poll_interval)
    last["program_status"] = "skipped" if args.skip_program else "pass"
    last["poll_count"] = index + 1
    return str(board_run), last


def markdown_table(rows: list[dict[str, Any]]) -> str:
    headers = [
        "created_at",
        "lock_set",
        "seed",
        "build_status",
        "program_status",
        "calib_seen",
        "calib_complete",
        "loader_ready",
        "state",
        "ack_count",
        "err_count",
        "applied_locks",
        "missing_locks",
        "notes",
    ]
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(str(row.get(key, "")) for key in headers) + " |")
    return "\n".join(lines) + "\n"


def update_summary(args: argparse.Namespace, row: dict[str, Any]) -> None:
    jsonl = SWEEP_ROOT / args.sweep / "results.jsonl"
    append_jsonl(jsonl, row)
    rows = [json.loads(line) for line in jsonl.read_text(encoding="utf-8").splitlines() if line.strip()]
    (SWEEP_ROOT / args.sweep / "results.md").write_text(markdown_table(rows), encoding="utf-8")


def run_row(args: argparse.Namespace) -> dict[str, Any]:
    run_dir = make_run_dir(args)
    lock_py = generate_lock_script(args, run_dir)
    bitstream, build_status = build_bitstream(args, run_dir, lock_py)
    build_log = run_dir / "logs" / "build.log"
    applied_locks = missing_locks = None
    if build_log.is_file():
        applied_locks, missing_locks = parse_lock_counts(build_log.read_text(encoding="utf-8"))

    board_run = ""
    debug: dict[str, Any] = {}
    if build_status in {"built", "supplied"}:
        if build_status == "built":
            archived_artifacts = archive_build_artifacts(run_dir)
        else:
            archived_artifacts = {}
        if args.build_only:
            debug = {"program_status": "build-only"}
        else:
            if args.rowstream_check:
                board_run, debug = program_and_rowstream_contract(args, run_dir, bitstream)
            else:
                board_run, debug = program_and_poll(args, run_dir, bitstream)
    else:
        archived_artifacts = {}

    row = {
        "created_at": datetime.now().astimezone().isoformat(),
        "source_commit": source_commit() + dirty_suffix(),
        "seed": args.seed,
        "freq": args.freq,
        "lock_set": args.lock_set,
        "lock_scopes": list(LOCK_SETS[args.lock_set]),
        "chipdb": str(args.chipdb) if args.chipdb is not None else None,
        "run_dir": str(run_dir.relative_to(ROOT)),
        "board_run_dir": board_run,
        "bitstream": str(bitstream),
        "bitstream_sha256": sha256_file(bitstream),
        "archived_artifacts": archived_artifacts,
        "build_status": build_status,
        "program_status": debug.get("program_status"),
        "program_notes": debug.get("raw_runner_output"),
        "pnr_extra_args": args.pnr_extra_args,
        "calib_seen": debug.get("calib_seen"),
        "calib_complete": debug.get("calib_complete"),
        "state_name": debug.get("state_name"),
        "loader_ready": debug.get("loader_ready"),
        "loader_error": debug.get("loader_error"),
        "state": debug.get("state"),
        "debug1": debug.get("debug1"),
        "ack_count": debug.get("ack_count"),
        "err_count": debug.get("err_count"),
        "read_byte": debug.get("read_byte"),
        "expected_byte": debug.get("expected_byte"),
        "command_gate": debug.get("command_gate"),
        "integrity": debug.get("integrity"),
        "calibration": debug.get("calibration"),
        "board": debug.get("board"),
        "poll_count": debug.get("poll_count"),
        "board_verdict_status": debug.get("board_verdict_status"),
        "board_verdict_correctness": debug.get("board_verdict_correctness"),
        "board_verdict_board": debug.get("board_verdict_board"),
        "applied_locks": applied_locks,
        "missing_locks": missing_locks,
        "notes": args.notes,
    }
    write_json(run_dir / "row.json", row)
    if not args.dry_run:
        update_summary(args, row)
    print(json.dumps(row, indent=2, sort_keys=True))
    return row


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sweep", default="ypcb-rowstream-calibration")
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--lock-set", choices=sorted(LOCK_SETS), required=True)
    parser.add_argument("--freq", type=int, default=25)
    parser.add_argument("--pnr-extra-args", default="")
    parser.add_argument("--synth-xilinx-flags", default="-flatten -family xc7")
    parser.add_argument("--bitstream", type=Path)
    parser.add_argument("--clean", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--skip-program", action="store_true")
    parser.add_argument(
        "--rowstream-check",
        action="store_true",
        help="Use task6_ddr3_experiment_runner rowstream192 contract verification.",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--nix-develop", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--allow-missing-locks", action="store_true")
    parser.add_argument("--extra-locks-json", action="append", default=[], type=Path)
    parser.add_argument("--poll-seconds", type=float, default=60.0)
    parser.add_argument("--poll-interval", type=float, default=2.0)
    parser.add_argument("--ftdi-serial", default="210299BF3824")
    parser.add_argument("--openocd-interface", default="interface/ftdi/digilent_jtag_hs3.cfg")
    parser.add_argument("--openocd-target", default="cpld/xilinx-xc7.cfg")
    parser.add_argument("--openocd-speed", default="6000")
    parser.add_argument("--tdo-bit", type=int, default=7)
    parser.add_argument("--bits", type=int, default=DEBUG_BITS)
    parser.add_argument("--rowstream-command-byte", type=lambda value: int(value, 0), default=0xA5)
    parser.add_argument("--rowstream-expected-byte", type=lambda value: int(value, 0), default=0xA5)
    parser.add_argument("--rowstream-command-addr", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--rowstream-command-repeats", type=int, default=1)
    parser.add_argument("--rowstream-command-opcode", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument(
        "--rowstream-readback-after-write",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument("--rowstream-poll-timeout", type=float, default=8.0)
    parser.add_argument("--rowstream-poll-interval", type=float, default=0.05)
    parser.add_argument("--rowstream-min-ack-delta", type=int, default=1)
    parser.add_argument("--rowstream-lowbyte-addr-offset", type=int, default=1)
    parser.add_argument(
        "--rowstream-command-update-mode",
        choices=("idle", "stop-at-update"),
        default="idle",
    )
    parser.add_argument("--chipdb", type=Path, help="Override CHIPDB directory or direct .bin path.")
    parser.add_argument("--notes", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    run_row(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
