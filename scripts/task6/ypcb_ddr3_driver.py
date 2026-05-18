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
import time
from types import SimpleNamespace
from typing import Any

from ypcb_jtag_transport import JtagTransportConfig, ScriptJtagTransport
from ypcb_phaser_shell import (
    PHASER_SHELL_COMMAND_BITS,
    PHASER_SHELL_MAGIC,
    PHASER_SHELL_OP_READ_CHUNK,
    PHASER_SHELL_OP_READ_LOWBYTE,
    PHASER_SHELL_OP_WRITE_CHUNK,
    PHASER_SHELL_OP_WRITE_LOWBYTE,
    PHASER_SHELL_STATUS_BITS,
    PhaserShellCommand,
    decode_phaser_status_readback,
    phaser_command_json,
    phaser_status_summary,
)

ROWSTREAM_COMMAND_BITS = 192
ROWSTREAM_LOADER_MAGIC = 0x33445244
ROWSTREAM_OP_WRITE_CHUNK = 0x01
ROWSTREAM_OP_READ_BEAT = 0x02
ROWSTREAM_OP_WRITE_LOWBYTE = 0x03
ROWSTREAM_OP_READ_LOWBYTE = 0x04
ROWSTREAM_OP_WRITE_DENSE_BYTE = 0x05
ROWSTREAM_OP_READ_DENSE_BEAT = 0x06
ROWSTREAM_OP_READ_WB2_DEBUG = 0x07

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
        self.transport = ScriptJtagTransport(
            JtagTransportConfig(
                serial=args.serial,
                tdo_bit=args.tdo_bit,
                bits=args.bits,
                backend=args.backend,
                freq_hz=args.freq_hz,
                bit_delay_us=args.bit_delay_us,
                ir_len=args.ir_len,
                read_user_ir=args.read_user_ir,
                write_user_ir=args.write_user_ir,
                update_mode=args.update_mode,
            )
        )

    def send(self, command: RowstreamCommand) -> list[dict[str, Any]]:
        results = []
        for _ in range(self.args.command_repeats):
            results.append(
                self.transport.write_payload(
                    command.encode(),
                    bits=ROWSTREAM_COMMAND_BITS,
                )
            )
        return results

    def read_raw_status(self) -> dict[str, Any]:
        return self.transport.read_debug(bits=self.args.bits)

    def read_status(self) -> dict[str, Any]:
        return decode_status(self.read_raw_status(), self.args)

    def send_phaser(self, command: PhaserShellCommand) -> list[dict[str, Any]]:
        results = []
        for _ in range(self.args.phaser_command_repeats):
            results.append(
                self.transport.write_payload(
                    command.encode(),
                    bits=PHASER_SHELL_COMMAND_BITS,
                )
            )
        return results

    def read_phaser_status_raw(
        self,
        *,
        bits: int | None = None,
        user_ir: int | None = None,
    ) -> dict[str, Any]:
        return self.transport.read_debug(
            bits=self.args.phaser_status_bits if bits is None else bits,
            user_ir=self.args.phaser_status_user_ir if user_ir is None else user_ir,
        )

    def read_phaser_status(
        self,
        *,
        bits: int | None = None,
        user_ir: int | None = None,
    ) -> dict[str, Any]:
        bit_count = self.args.phaser_status_bits if bits is None else bits
        return decode_phaser_status_readback(
            self.read_phaser_status_raw(bits=bit_count, user_ir=user_ir),
            bit_count=bit_count,
        )

    @staticmethod
    def command_count_advanced(current: int, previous: int, delta: int) -> bool:
        return ((current - previous) & 0xFFFF) >= delta

    def wait_ready(
        self,
        min_ack_count: int,
        *,
        previous_command_count: int | None = None,
        min_command_delta: int = 0,
    ) -> dict[str, Any]:
        deadline = time.monotonic() + self.args.timeout
        while True:
            status = self.read_status()
            command_ready = (
                self.args.minimal_loader_status
                or
                previous_command_count is None
                or self.command_count_advanced(
                    int(status["command_count"]),
                    previous_command_count,
                    min_command_delta,
                )
            )
            if (
                (self.args.minimal_loader_status or status["loader_ready"])
                and status["ack_count"] >= min_ack_count
                and command_ready
            ):
                return status
            if (
                (not self.args.minimal_loader_status and status["loader_error"])
                or status["err_seen"]
            ):
                raise RuntimeError(f"loader entered error state: {status['result']}")
            if time.monotonic() >= deadline:
                raise TimeoutError(
                    "loader did not become ready: "
                    f"ack={status['ack_count']} state={status['state_name']} "
                    f"loader_state={status['loader_state']}"
                )
            time.sleep(self.args.poll_interval)

    def wait_phaser_ready(
        self,
        *,
        previous_command_count: int,
        min_command_delta: int,
        bits: int | None = None,
        user_ir: int | None = None,
    ) -> dict[str, Any]:
        deadline = time.monotonic() + self.args.timeout
        bit_count = self.args.phaser_status_bits if bits is None else bits
        while True:
            status = self.read_phaser_status(bits=bit_count, user_ir=user_ir)
            if (
                status["ready"]
                and self.command_count_advanced(
                    int(status["command_count"]),
                    previous_command_count,
                    min_command_delta,
                )
            ):
                return status
            if status["error"]:
                raise RuntimeError(
                    "PHASER shell entered error state: "
                    f"state={status['state']} last_opcode={status['last_opcode']}"
                )
            if time.monotonic() >= deadline:
                raise TimeoutError(
                    "PHASER shell did not become ready: "
                    f"state={status['state']} command_count={status['command_count']}"
                )
            time.sleep(self.args.poll_interval)

    def phaser_transact(
        self,
        command: PhaserShellCommand,
        *,
        min_command_delta: int | None = None,
        bits: int | None = None,
        user_ir: int | None = None,
    ) -> dict[str, Any]:
        before = self.read_phaser_status(bits=bits, user_ir=user_ir)
        self.send_phaser(command)
        return self.wait_phaser_ready(
            previous_command_count=int(before["command_count"]),
            min_command_delta=(
                self.args.phaser_command_repeats
                if min_command_delta is None
                else min_command_delta
            ),
            bits=bits,
            user_ir=user_ir,
        )

    def transact(self, command: RowstreamCommand) -> dict[str, Any]:
        return self.transact_with_ack_delta(command, self.args.min_ack_delta)

    def transact_with_ack_delta(
        self, command: RowstreamCommand, min_ack_delta: int
    ) -> dict[str, Any]:
        before = self.read_status()
        before_ack = int(before["ack_count"])
        before_command_count = int(before["command_count"])
        self.send(command)
        self.args.expected_addr = command.addr
        self.args.expected_byte = command.byte
        return self.wait_ready(
            before_ack + min_ack_delta,
            previous_command_count=before_command_count,
            min_command_delta=self.args.command_repeats,
        )

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
            min_ack_delta = self.args.min_ack_delta if chunk == CHUNKS_PER_BEAT - 1 else 0
            statuses.append(self.transact_with_ack_delta(command, min_ack_delta))
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

    def read_beat_chunks(
        self,
        beat_addr: int,
        expected_byte: int = 0,
        *,
        opcode: int = ROWSTREAM_OP_READ_BEAT,
    ) -> list[dict[str, Any]]:
        statuses = []
        for chunk in range(CHUNKS_PER_BEAT):
            statuses.append(
                self.transact(
                    RowstreamCommand(
                        opcode,
                        beat_addr,
                        byte=expected_byte,
                        chunk=chunk,
                    )
                )
            )
        return statuses

    def read_wb2_debug(self, addr: int) -> dict[str, Any]:
        before = self.read_status()
        before_command_count = int(before["command_count"])
        self.send(RowstreamCommand(ROWSTREAM_OP_READ_WB2_DEBUG, addr))
        self.args.expected_addr = addr
        self.args.expected_byte = 0
        return self.wait_ready(
            int(before["ack_count"]),
            previous_command_count=before_command_count,
            min_command_delta=self.args.command_repeats,
        )


def print_json(payload: Any) -> None:
    print(json.dumps(payload, indent=2, sort_keys=True))


def command_json(command: RowstreamCommand) -> dict[str, Any]:
    return {
        "addr": f"0x{command.addr:08x}",
        "byte": f"0x{command.byte:02x}",
        "chunk": command.chunk,
        "command_hex": f"0x{command.encode():048x}",
        "data128": f"0x{command.data128:032x}" if command.data128 is not None else None,
        "opcode": f"0x{command.opcode:02x}",
    }


def fullbeat_write_commands(beat_addr: int, data: bytes) -> list[RowstreamCommand]:
    if len(data) != BEAT_BYTES:
        raise ValueError(f"full-beat writes require exactly {BEAT_BYTES} bytes")
    return [
        RowstreamCommand(
            ROWSTREAM_OP_WRITE_CHUNK,
            beat_addr,
            chunk=chunk,
            data128=bytes_to_little_int(
                data[chunk * CHUNK_BYTES : (chunk + 1) * CHUNK_BYTES]
            ),
        )
        for chunk in range(CHUNKS_PER_BEAT)
    ]


def dense_byte_write_commands(beat_addr: int, data: bytes) -> list[RowstreamCommand]:
    if len(data) != BEAT_BYTES:
        raise ValueError(f"dense byte writes require exactly {BEAT_BYTES} bytes")
    return [
        RowstreamCommand(
            ROWSTREAM_OP_WRITE_DENSE_BYTE,
            (beat_addr << 6) | lane,
            byte=byte,
        )
        for lane, byte in enumerate(data)
    ]


def read_beat_command(beat_addr: int, expected_byte: int = 0) -> RowstreamCommand:
    return RowstreamCommand(ROWSTREAM_OP_READ_BEAT, beat_addr, byte=expected_byte)


def phaser_write_lowbyte_command(addr: int, byte: int) -> PhaserShellCommand:
    if not 0 <= byte <= 0xFF:
        raise ValueError("byte must fit in 8 bits")
    return PhaserShellCommand(
        PHASER_SHELL_OP_WRITE_LOWBYTE,
        addr,
        aux=byte,
    )


def phaser_read_lowbyte_command(addr: int, expected_byte: int = 0) -> PhaserShellCommand:
    if not 0 <= expected_byte <= 0xFF:
        raise ValueError("expected byte must fit in 8 bits")
    return PhaserShellCommand(
        PHASER_SHELL_OP_READ_LOWBYTE,
        addr,
        aux=expected_byte,
    )


def phaser_fullbeat_write_commands(beat_addr: int, data: bytes) -> list[PhaserShellCommand]:
    if len(data) != BEAT_BYTES:
        raise ValueError(f"PHASER full-beat writes require exactly {BEAT_BYTES} bytes")
    return [
        PhaserShellCommand(
            PHASER_SHELL_OP_WRITE_CHUNK,
            beat_addr,
            chunk=chunk,
            data128=bytes_to_little_int(
                data[chunk * CHUNK_BYTES : (chunk + 1) * CHUNK_BYTES]
            ),
        )
        for chunk in range(CHUNKS_PER_BEAT)
    ]


def phaser_fullbeat_read_commands(
    beat_addr: int,
    expected_byte: int = 0,
) -> list[PhaserShellCommand]:
    if not 0 <= expected_byte <= 0xFF:
        raise ValueError("expected byte must fit in 8 bits")
    return [
        PhaserShellCommand(
            PHASER_SHELL_OP_READ_CHUNK,
            beat_addr,
            chunk=chunk,
            aux=expected_byte,
        )
        for chunk in range(CHUNKS_PER_BEAT)
    ]


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--read-user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--write-user-ir", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--bits", type=int, default=1024)
    parser.add_argument("--variant", default="rowstream192")
    parser.add_argument("--command-repeats", type=int, default=2)
    parser.add_argument("--phaser-command-repeats", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--update-mode", choices=("idle", "stop-at-update"), default="idle")
    parser.add_argument("--poll-interval", type=float, default=0.05)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--min-ack-delta", type=int, default=1)
    parser.add_argument("--phaser-status-bits", type=int, default=PHASER_SHELL_STATUS_BITS)
    parser.add_argument(
        "--phaser-status-user-ir",
        type=lambda value: int(value, 0),
        default=0x02,
    )
    parser.add_argument(
        "--minimal-loader-status",
        action="store_true",
        help=(
            "Do not require loader_ready/command_count telemetry. Use this only "
            "with shells that intentionally hide loader debug to preserve calibration."
        ),
    )
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

    debug_wb2 = subparsers.add_parser("debug-wb2")
    debug_wb2.add_argument("--addr", type=lambda value: int(value, 0), required=True)

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

    phaser_encode = subparsers.add_parser("phaser-encode", help="print one encoded PHASER shell command")
    phaser_encode.add_argument("--opcode", type=lambda value: int(value, 0), required=True)
    phaser_encode.add_argument("--addr", type=lambda value: int(value, 0), default=0)
    phaser_encode.add_argument("--flags", type=lambda value: int(value, 0), default=0)
    phaser_encode.add_argument("--chunk", type=lambda value: int(value, 0), default=0)
    phaser_encode.add_argument("--aux", type=lambda value: int(value, 0), default=0)
    phaser_encode.add_argument("--data128", type=lambda value: int(value, 0), default=0)

    subparsers.add_parser("phaser-status")

    phaser_status_raw = subparsers.add_parser("phaser-status-raw")
    phaser_status_raw.add_argument("--status-bits", type=int, default=PHASER_SHELL_STATUS_BITS)
    phaser_status_raw.add_argument("--status-user-ir", type=lambda value: int(value, 0), default=0x02)

    phaser_write_low = subparsers.add_parser("phaser-write-lowbyte")
    phaser_write_low.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    phaser_write_low.add_argument("--byte", type=lambda value: int(value, 0), required=True)

    phaser_read_low = subparsers.add_parser("phaser-read-lowbyte")
    phaser_read_low.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    phaser_read_low.add_argument("--expected-byte", type=lambda value: int(value, 0), default=0)

    phaser_write_beat = subparsers.add_parser("phaser-write-beat")
    phaser_write_beat.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    phaser_write_beat.add_argument("--data-hex", required=True)

    phaser_read_beat = subparsers.add_parser("phaser-read-beat")
    phaser_read_beat.add_argument("--addr", type=lambda value: int(value, 0), required=True)
    phaser_read_beat.add_argument("--expected-byte", type=lambda value: int(value, 0), default=0)
    return parser


def pattern_bytes(name: str) -> bytes:
    if name == "increment":
        return bytes(range(BEAT_BYTES))
    if name == "walking":
        return bytes(1 << (index % 8) for index in range(BEAT_BYTES))
    if name == "aa55":
        return bytes(0xAA if index % 2 == 0 else 0x55 for index in range(BEAT_BYTES))
    raise ValueError(name)


def observed_status_bytes(status: dict[str, Any]) -> list[str]:
    if status["version"] >= 49:
        return status["read_window128_bytes"]
    if status["version"] != 44 and status["read_beat_bytes"]:
        return status["read_beat_bytes"]
    return status["read_window128_bytes"]


def observed_beat_bytes(statuses: list[dict[str, Any]]) -> list[str]:
    for status in statuses:
        read_beat_bytes = status["read_beat_bytes"]
        if status["version"] < 49 and len(read_beat_bytes) >= BEAT_BYTES:
            return read_beat_bytes[:BEAT_BYTES]
    return [
        byte
        for status in statuses
        for byte in observed_status_bytes(status)[:CHUNK_BYTES]
    ]


def summarize_status(status: dict[str, Any]) -> dict[str, Any]:
    return {
        "ack_count": status["ack_count"],
        "calibration": status["result"]["calibration"],
        "command_gate": status["result"]["command_gate"],
        "err_count": status["err_count"],
        "integrity": status["result"]["integrity"],
        "last_opcode": status["last_opcode"],
        "loader_error": status["loader_error"],
        "loader_ready": status["loader_ready"],
        "loader_accept_seen": status.get("loader_accept_seen"),
        "loader_accept_we": status.get("loader_accept_we"),
        "loader_accept_addr_low": status.get("loader_accept_addr_low"),
        "loader_accept_sel_low": status.get("loader_accept_sel_low"),
        "loader_accept_data_low": status.get("loader_accept_data_low"),
        "read_ack_seen": status["read_ack_seen"],
        "state_name": status["state_name"],
        "version": status["version"],
        "write_ack_seen": status["write_ack_seen"],
    }


def summarize_statuses(statuses: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "count": len(statuses),
        "first": summarize_status(statuses[0]) if statuses else None,
        "last": summarize_status(statuses[-1]) if statuses else None,
        "pass_count": sum(
            1 for status in statuses if status["result"]["integrity"] == "pass"
        ),
    }


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

    if args.command == "phaser-encode":
        command = PhaserShellCommand(
            args.opcode,
            args.addr,
            flags=args.flags,
            chunk=args.chunk,
            aux=args.aux,
            data128=args.data128,
        )
        print_json(
            {
                "bits": PHASER_SHELL_COMMAND_BITS,
                "command_hex": f"0x{command.encode():064x}",
                "fields": phaser_command_json(command),
            }
        )
        return 0

    if args.command == "status":
        print_json(driver.read_status())
        return 0

    if args.command == "phaser-status":
        status = driver.read_phaser_status()
        print_json(
            {
                "status": status,
                "summary": phaser_status_summary(status),
            }
        )
        return 0

    if args.command == "phaser-status-raw":
        print_json(
            driver.transport.read_debug(
                bits=args.status_bits,
                user_ir=args.status_user_ir,
            )
        )
        return 0

    if args.command == "debug-wb2":
        if args.dry_run:
            print_json(command_json(RowstreamCommand(ROWSTREAM_OP_READ_WB2_DEBUG, args.addr)))
            return 0
        status = driver.read_wb2_debug(args.addr)
        print_json(
            {
                "addr": f"0x{args.addr:02x}",
                "status": summarize_status(status),
                "wb2_debug_word": status["wb2_debug_word"],
            }
        )
        return 0

    if args.command == "write-lowbyte":
        if args.dry_run:
            print_json(command_json(RowstreamCommand(ROWSTREAM_OP_WRITE_LOWBYTE, args.addr, byte=args.byte)))
            return 0
        print_json(driver.write_lowbyte(args.addr, args.byte))
        return 0

    if args.command == "read-lowbyte":
        args.expected_addr = args.addr
        args.expected_byte = args.expected_byte
        if args.dry_run:
            print_json(
                command_json(
                    RowstreamCommand(
                        ROWSTREAM_OP_READ_LOWBYTE,
                        args.addr,
                        byte=args.expected_byte,
                    )
                )
            )
            return 0
        print_json(driver.read_lowbyte(args.addr, args.expected_byte))
        return 0

    if args.command == "phaser-write-lowbyte":
        command = phaser_write_lowbyte_command(args.addr, args.byte)
        if args.dry_run:
            print_json(phaser_command_json(command))
            return 0
        status = driver.phaser_transact(command)
        print_json({"command": phaser_command_json(command), "status": status})
        return 0

    if args.command == "phaser-read-lowbyte":
        command = phaser_read_lowbyte_command(args.addr, args.expected_byte)
        if args.dry_run:
            print_json(phaser_command_json(command))
            return 0
        status = driver.phaser_transact(command)
        print_json({"command": phaser_command_json(command), "status": status})
        return 0

    if args.command == "write-beat":
        data = parse_hex_bytes(args.data_hex, expected_len=BEAT_BYTES)
        if args.dry_run:
            commands = (
                fullbeat_write_commands(args.addr, data)
                if args.method == "fullbeat"
                else dense_byte_write_commands(args.addr, data)
            )
            print_json(
                {
                    "addr": f"0x{args.addr:x}",
                    "method": args.method,
                    "commands": [command_json(command) for command in commands],
                }
            )
            return 0
        if args.method == "fullbeat":
            print_json(driver.write_beat_full(args.addr, data))
        else:
            print_json(driver.write_beat_dense_bytes(args.addr, data))
        return 0

    if args.command == "read-beat":
        args.expected_addr = args.addr
        args.expected_byte = args.expected_byte
        if args.dry_run:
            print_json(
                [
                    command_json(
                        RowstreamCommand(
                            ROWSTREAM_OP_READ_BEAT,
                            args.addr,
                            byte=args.expected_byte,
                            chunk=chunk,
                        )
                    )
                    for chunk in range(CHUNKS_PER_BEAT)
                ]
            )
            return 0
        statuses = driver.read_beat_chunks(args.addr, args.expected_byte)
        print_json(
            {
                "observed_bytes": observed_beat_bytes(statuses),
                "status": summarize_statuses(statuses),
            }
        )
        return 0

    if args.command == "phaser-write-beat":
        data = parse_hex_bytes(args.data_hex, expected_len=BEAT_BYTES)
        commands = phaser_fullbeat_write_commands(args.addr, data)
        if args.dry_run:
            print_json(
                {
                    "addr": f"0x{args.addr:x}",
                    "commands": [phaser_command_json(command) for command in commands],
                }
            )
            return 0
        statuses = [driver.phaser_transact(command) for command in commands]
        print_json(
            {
                "addr": f"0x{args.addr:x}",
                "commands": [phaser_command_json(command) for command in commands],
                "status": [phaser_status_summary(status) for status in statuses],
            }
        )
        return 0

    if args.command == "phaser-read-beat":
        commands = phaser_fullbeat_read_commands(args.addr, args.expected_byte)
        if args.dry_run:
            print_json(
                {
                    "addr": f"0x{args.addr:x}",
                    "commands": [phaser_command_json(command) for command in commands],
                }
            )
            return 0
        statuses = [driver.phaser_transact(command) for command in commands]
        print_json(
            {
                "addr": f"0x{args.addr:x}",
                "commands": [phaser_command_json(command) for command in commands],
                "observed_bytes": [
                    byte
                    for status in statuses
                    for byte in status["read_data128_bytes"]
                ],
                "status": [phaser_status_summary(status) for status in statuses],
            }
        )
        return 0

    if args.command == "memtest64":
        data = pattern_bytes(args.pattern)
        if args.dry_run:
            write_commands = (
                fullbeat_write_commands(args.addr, data)
                if args.write_method == "fullbeat"
                else dense_byte_write_commands(args.addr, data)
            )
            read_opcode = (
                ROWSTREAM_OP_READ_BEAT
                if args.write_method == "fullbeat"
                else ROWSTREAM_OP_READ_DENSE_BEAT
            )
            print_json(
                {
                    "addr": f"0x{args.addr:x}",
                    "expected": [f"0x{byte:02x}" for byte in data],
                    "read_commands": [
                        command_json(
                            RowstreamCommand(
                                read_opcode,
                                args.addr,
                                byte=data[0],
                                chunk=chunk,
                            )
                        )
                        for chunk in range(CHUNKS_PER_BEAT)
                    ],
                    "write_commands": [command_json(command) for command in write_commands],
                    "write_method": args.write_method,
                }
            )
            return 0
        if args.write_method == "fullbeat":
            write_status = driver.write_beat_full(args.addr, data)
        else:
            write_status = driver.write_beat_dense_bytes(args.addr, data)
        read_opcode = (
            ROWSTREAM_OP_READ_BEAT
            if args.write_method == "fullbeat"
            else ROWSTREAM_OP_READ_DENSE_BEAT
        )
        read_statuses = driver.read_beat_chunks(args.addr, data[0], opcode=read_opcode)
        observed = observed_beat_bytes(read_statuses)
        expected = [f"0x{byte:02x}" for byte in data]
        compare_len = min(len(observed), len(expected))
        print_json(
            {
                "addr": f"0x{args.addr:x}",
                "compared_bytes": compare_len,
                "expected": expected[:compare_len],
                "observed": observed,
                "pass": observed == expected[:compare_len] and compare_len == BEAT_BYTES,
                "read_status": summarize_statuses(read_statuses),
                "write_status": summarize_statuses(write_status),
                "window_only": compare_len < BEAT_BYTES,
            }
        )
        return 0

    raise AssertionError(args.command)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, TimeoutError, ValueError) as error:
        print_json({"error": str(error), "pass": False})
        raise SystemExit(1)
