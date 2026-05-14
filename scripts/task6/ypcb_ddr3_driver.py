#!/usr/bin/env python3
"""Host-side YPCB DDR3 rowstream driver.

This module is the software contract for the YPCB UberDDR3 experiments.  It
does not solve calibration; it assumes a programmed/calibrated rowstream shell
and drives the USER2 JTAG command interface that shell exposes.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import subprocess
import sys
import time
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
READ_JTAG = ROOT / "scripts" / "task6" / "read_jtag_debug_ftdi_bitbang.py"
WRITE_JTAG = ROOT / "scripts" / "task6" / "write_jtag_command_ftdi_bitbang.py"

ROWSTREAM_COMMAND_BITS = 192
ROWSTREAM_LOADER_MAGIC = 0x33445244
ROWSTREAM_OP_WRITE_CHUNK = 0x01
ROWSTREAM_OP_READ_BEAT = 0x02
ROWSTREAM_OP_WRITE_LOWBYTE = 0x03
ROWSTREAM_OP_READ_LOWBYTE = 0x04
ROWSTREAM_OP_WRITE_DENSE_BYTE = 0x05
ROWSTREAM_OP_READ_DENSE_BEAT = 0x06

BEAT_BYTES = 64
CHUNK_BYTES = 16
CHUNKS_PER_BEAT = BEAT_BYTES // CHUNK_BYTES


@dataclass(frozen=True)
class RowstreamCommand:
    opcode: int
    addr: int
    byte: int = 0
    chunk: int = 0
    data128: int | None = None

    def encode(self) -> int:
        if not 0 <= self.opcode <= 0xFF:
            raise ValueError("opcode must fit in 8 bits")
        if not 0 <= self.addr <= 0xFFFFFFFF:
            raise ValueError("addr must fit in 32 bits")
        if not 0 <= self.byte <= 0xFF:
            raise ValueError("byte must fit in 8 bits")
        if not 0 <= self.chunk <= 0x3:
            raise ValueError("chunk must fit in 2 bits")
        payload_data = self.byte if self.data128 is None else self.data128
        if not 0 <= payload_data < (1 << 128):
            raise ValueError("data128 must fit in 128 bits")
        return (
            ROWSTREAM_LOADER_MAGIC
            | (self.opcode << 32)
            | (self.chunk << 40)
            | (self.addr << 48)
            | (payload_data << 64)
        )

    def argv(self, args: argparse.Namespace) -> list[str]:
        argv = [
            sys.executable,
            str(WRITE_JTAG),
            "--serial",
            args.serial,
            "--tdo-bit",
            str(args.tdo_bit),
            "--bits",
            str(ROWSTREAM_COMMAND_BITS),
            "--loader-magic",
            f"0x{ROWSTREAM_LOADER_MAGIC:08x}",
            "--opcode",
            f"0x{self.opcode:02x}",
            "--chunk",
            str(self.chunk),
            "--addr",
            f"0x{self.addr:x}",
            "--byte",
            f"0x{self.byte:02x}",
            "--update-mode",
            args.update_mode,
            "--json-only",
        ]
        if self.data128 is not None:
            argv.extend(["--data128", f"0x{self.data128:032x}"])
        return argv


def parse_hex_bytes(value: str, *, expected_len: int | None = None) -> bytes:
    text = value.strip().removeprefix("0x").replace("_", "").replace(" ", "")
    if len(text) % 2:
        text = "0" + text
    data = bytes.fromhex(text)
    if expected_len is not None and len(data) != expected_len:
        raise ValueError(f"expected {expected_len} bytes, got {len(data)}")
    return data


def bytes_to_little_int(data: bytes) -> int:
    return sum(byte << (8 * index) for index, byte in enumerate(data))


def little_int_to_bytes(value: int, byte_count: int) -> bytes:
    return bytes((value >> (8 * index)) & 0xFF for index in range(byte_count))


def extract_json(stdout: str) -> dict[str, Any]:
    start = stdout.find("{")
    end = stdout.rfind("}")
    if start < 0 or end < start:
        raise RuntimeError(f"command output did not contain JSON:\n{stdout}")
    return json.loads(stdout[start : end + 1])


def decode_status(readback: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    from task6_ddr3_experiment_runner import decode_uberddr3_payload

    decode_args = SimpleNamespace(
        bitstream="already-programmed",
        command_addr=args.expected_addr,
        command_protocol="rowstream192",
        expected_byte=args.expected_byte,
        experiment="ypcb-ddr3-driver",
        variant=args.variant,
        bits=args.bits,
    )
    return decode_uberddr3_payload(readback, decode_args)


class YpcbDdr3Driver:
    def __init__(self, args: argparse.Namespace) -> None:
        self.args = args

    def run_json(self, argv: list[str]) -> dict[str, Any]:
        proc = subprocess.run(
            argv,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise RuntimeError(proc.stdout)
        return extract_json(proc.stdout)

    def send(self, command: RowstreamCommand) -> list[dict[str, Any]]:
        results = []
        for _ in range(self.args.command_repeats):
            results.append(self.run_json(command.argv(self.args)))
        return results

    def read_raw_status(self) -> dict[str, Any]:
        return self.run_json(
            [
                sys.executable,
                str(READ_JTAG),
                "--serial",
                self.args.serial,
                "--tdo-bit",
                str(self.args.tdo_bit),
                "--bits",
                str(self.args.bits),
                "--json-only",
            ]
        )

    def read_status(self) -> dict[str, Any]:
        return decode_status(self.read_raw_status(), self.args)

    def wait_ready(self, min_ack_count: int) -> dict[str, Any]:
        deadline = time.monotonic() + self.args.timeout
        while True:
            status = self.read_status()
            if status["loader_ready"] and status["ack_count"] >= min_ack_count:
                return status
            if status["loader_error"] or status["err_seen"]:
                raise RuntimeError(f"loader entered error state: {status['result']}")
            if time.monotonic() >= deadline:
                raise TimeoutError(
                    "loader did not become ready: "
                    f"ack={status['ack_count']} state={status['state_name']} "
                    f"loader_state={status['loader_state']}"
                )
            time.sleep(self.args.poll_interval)

    def transact(self, command: RowstreamCommand) -> dict[str, Any]:
        before = self.read_status()
        before_ack = int(before["ack_count"])
        self.send(command)
        self.args.expected_addr = command.addr
        self.args.expected_byte = command.byte
        return self.wait_ready(before_ack + self.args.min_ack_delta)

    def write_lowbyte(self, addr: int, byte: int) -> dict[str, Any]:
        return self.transact(RowstreamCommand(ROWSTREAM_OP_WRITE_LOWBYTE, addr, byte=byte))

    def read_lowbyte(self, addr: int, expected_byte: int = 0) -> dict[str, Any]:
        return self.transact(
            RowstreamCommand(ROWSTREAM_OP_READ_LOWBYTE, addr, byte=expected_byte)
        )

    def write_beat_full(self, beat_addr: int, data: bytes) -> list[dict[str, Any]]:
        if len(data) != BEAT_BYTES:
            raise ValueError(f"full-beat writes require exactly {BEAT_BYTES} bytes")
        statuses = []
        for chunk in range(CHUNKS_PER_BEAT):
            chunk_data = data[chunk * CHUNK_BYTES : (chunk + 1) * CHUNK_BYTES]
            command = RowstreamCommand(
                ROWSTREAM_OP_WRITE_CHUNK,
                beat_addr,
                chunk=chunk,
                data128=bytes_to_little_int(chunk_data),
            )
            statuses.append(self.transact(command))
        return statuses

    def write_beat_dense_bytes(self, beat_addr: int, data: bytes) -> list[dict[str, Any]]:
        if len(data) != BEAT_BYTES:
            raise ValueError(f"dense byte writes require exactly {BEAT_BYTES} bytes")
        statuses = []
        for lane, byte in enumerate(data):
            dense_addr = (beat_addr << 6) | lane
            statuses.append(
                self.transact(
                    RowstreamCommand(ROWSTREAM_OP_WRITE_DENSE_BYTE, dense_addr, byte=byte)
                )
            )
        return statuses

    def read_beat(self, beat_addr: int, expected_byte: int = 0) -> dict[str, Any]:
        return self.transact(
            RowstreamCommand(ROWSTREAM_OP_READ_DENSE_BEAT, beat_addr, byte=expected_byte)
        )


def print_json(payload: Any) -> None:
    print(json.dumps(payload, indent=2, sort_keys=True))


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--bits", type=int, default=1024)
    parser.add_argument("--variant", default="rowstream192")
    parser.add_argument("--command-repeats", type=int, default=2)
    parser.add_argument("--update-mode", choices=("idle", "stop-at-update"), default="idle")
    parser.add_argument("--poll-interval", type=float, default=0.05)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--min-ack-delta", type=int, default=1)
    parser.set_defaults(expected_addr=0, expected_byte=0)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    add_common_args(parser)
    subparsers = parser.add_subparsers(dest="command", required=True)

    encode = subparsers.add_parser("encode", help="print one encoded rowstream command")
    encode.add_argument("--opcode", type=lambda value: int(value, 0), required=True)
    encode.add_argument("--addr", type=lambda value: int(value, 0), default=0)
    encode.add_argument("--byte", type=lambda value: int(value, 0), default=0)
    encode.add_argument("--chunk", type=lambda value: int(value, 0), default=0)
    encode.add_argument("--data128", type=lambda value: int(value, 0))

    subparsers.add_parser("status", help="read and decode the debug payload")

    write_low = subparsers.add_parser("write-lowbyte")
    write_low.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    write_low.add_argument("--byte", type=lambda value: int(value, 0), required=True)

    read_low = subparsers.add_parser("read-lowbyte")
    read_low.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    read_low.add_argument("--expected-byte", type=lambda value: int(value, 0), default=0)

    write_beat = subparsers.add_parser("write-beat")
    write_beat.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    write_beat.add_argument("--data-hex", required=True)
    write_beat.add_argument(
        "--method",
        choices=("fullbeat", "dense-byte"),
        default="fullbeat",
        help="fullbeat is the intended DDR3 contract; dense-byte is diagnostic only",
    )

    read_beat = subparsers.add_parser("read-beat")
    read_beat.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    read_beat.add_argument("--expected-byte", type=lambda value: int(value, 0), default=0)

    memtest = subparsers.add_parser("memtest64")
    memtest.add_argument("--addr", type=lambda value: int(value, 0), default=0)
    memtest.add_argument(
        "--pattern",
        choices=("increment", "walking", "aa55"),
        default="increment",
    )
    memtest.add_argument(
        "--write-method",
        choices=("fullbeat", "dense-byte"),
        default="fullbeat",
    )
    return parser


def pattern_bytes(name: str) -> bytes:
    if name == "increment":
        return bytes(range(BEAT_BYTES))
    if name == "walking":
        return bytes(1 << (index % 8) for index in range(BEAT_BYTES))
    if name == "aa55":
        return bytes(0xAA if index % 2 == 0 else 0x55 for index in range(BEAT_BYTES))
    raise ValueError(name)


def observed_beat_bytes(status: dict[str, Any]) -> list[str]:
    if status["read_beat_bytes"]:
        return status["read_beat_bytes"]
    return status["read_window128_bytes"]


def main() -> int:
    args = build_parser().parse_args()
    driver = YpcbDdr3Driver(args)

    if args.command == "encode":
        command = RowstreamCommand(
            args.opcode,
            args.addr,
            byte=args.byte,
            chunk=args.chunk,
            data128=args.data128,
        )
        print_json(
            {
                "bits": ROWSTREAM_COMMAND_BITS,
                "command_hex": f"0x{command.encode():048x}",
                "fields": {
                    "addr": f"0x{args.addr:08x}",
                    "byte": f"0x{args.byte:02x}",
                    "chunk": args.chunk,
                    "data128": f"0x{args.data128:032x}" if args.data128 is not None else None,
                    "opcode": f"0x{args.opcode:02x}",
                },
            }
        )
        return 0

    if args.command == "status":
        print_json(driver.read_status())
        return 0

    if args.command == "write-lowbyte":
        print_json(driver.write_lowbyte(args.addr, args.byte))
        return 0

    if args.command == "read-lowbyte":
        args.expected_addr = args.addr
        args.expected_byte = args.expected_byte
        print_json(driver.read_lowbyte(args.addr, args.expected_byte))
        return 0

    if args.command == "write-beat":
        data = parse_hex_bytes(args.data_hex, expected_len=BEAT_BYTES)
        if args.method == "fullbeat":
            print_json(driver.write_beat_full(args.addr, data))
        else:
            print_json(driver.write_beat_dense_bytes(args.addr, data))
        return 0

    if args.command == "read-beat":
        args.expected_addr = args.addr
        args.expected_byte = args.expected_byte
        status = driver.read_beat(args.addr, args.expected_byte)
        print_json({"status": status, "observed_bytes": observed_beat_bytes(status)})
        return 0

    if args.command == "memtest64":
        data = pattern_bytes(args.pattern)
        if args.write_method == "fullbeat":
            write_status = driver.write_beat_full(args.addr, data)
        else:
            write_status = driver.write_beat_dense_bytes(args.addr, data)
        read_status = driver.read_beat(args.addr, data[0])
        observed = observed_beat_bytes(read_status)
        expected = [f"0x{byte:02x}" for byte in data]
        print_json(
            {
                "addr": f"0x{args.addr:x}",
                "expected": expected,
                "observed": observed,
                "pass": observed == expected,
                "read_status": read_status,
                "write_status": write_status,
            }
        )
        return 0

    raise AssertionError(args.command)


if __name__ == "__main__":
    raise SystemExit(main())
