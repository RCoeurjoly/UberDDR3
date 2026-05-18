#!/usr/bin/env python3
"""Shared host-side protocol helpers for the YPCB PHASER shell contract."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


PHASER_SHELL_COMMAND_BITS = 256
PHASER_SHELL_STATUS_BITS = 384

PHASER_SHELL_MAGIC = 0x5048434E  # "PHCN"
PHASER_SHELL_STATUS_MAGIC = 0x50485354  # "PHST"
PHASER_SHELL_STATUS_VERSION = 0x01

PHASER_SHELL_OP_WRITE_CHUNK = 0x01
PHASER_SHELL_OP_READ_CHUNK = 0x02
PHASER_SHELL_OP_WRITE_LOWBYTE = 0x03
PHASER_SHELL_OP_READ_LOWBYTE = 0x04

PHASER_SHELL_STATE_IDLE = 0x00
PHASER_SHELL_STATE_BUSY = 0x01
PHASER_SHELL_STATE_ERROR = 0x02

PHASER_STATUS_FLAG_READY = 0
PHASER_STATUS_FLAG_ERROR = 1
PHASER_STATUS_FLAG_COMMAND_VALID = 2
PHASER_STATUS_FLAG_WRITE_DATA_STAGED = 3
PHASER_STATUS_FLAG_READ_DATA_VALID = 4
PHASER_STATUS_FLAG_CALIB_DONE = 5
PHASER_STATUS_FLAG_PHASER_REF_LOCKED = 6
PHASER_STATUS_FLAG_IN_PHASE_LOCKED = 7
PHASER_STATUS_FLAG_PHYCTL_READY = 8
PHASER_STATUS_FLAG_SEQUENCE_ACTIVE = 9
PHASER_STATUS_FLAG_SEQUENCE_DONE = 10
PHASER_STATUS_FLAG_WRITE_PENDING = 11
PHASER_STATUS_FLAG_READ_PENDING = 12
PHASER_STATUS_FLAG_LOWBYTE_MODE = 13
PHASER_STATUS_FLAG_FULLBEAT_MODE = 14

PHASER_STATUS_FLAG_NAMES = (
    "ready",
    "error",
    "command_valid",
    "write_data_staged",
    "read_data_valid",
    "calib_done",
    "phaser_ref_locked",
    "in_phase_locked",
    "phyctl_ready",
    "sequence_active",
    "sequence_done",
    "write_pending",
    "read_pending",
    "lowbyte_mode",
    "fullbeat_mode",
)

PHASER_STATE_NAMES = {
    PHASER_SHELL_STATE_IDLE: "IDLE",
    PHASER_SHELL_STATE_BUSY: "BUSY",
    PHASER_SHELL_STATE_ERROR: "ERROR",
}


def unsigned_field(value: int, offset: int, width: int) -> int:
    return (value >> offset) & ((1 << width) - 1)


def little_int_to_bytes(value: int, byte_count: int) -> bytes:
    return bytes((value >> (8 * index)) & 0xFF for index in range(byte_count))


def phaser_status_flags(flags: int) -> dict[str, bool]:
    return {
        name: bool(flags & (1 << bit_index))
        for bit_index, name in enumerate(PHASER_STATUS_FLAG_NAMES)
    }


def phaser_status_summary(fields: dict[str, Any]) -> dict[str, Any]:
    return {
        "command_count": fields["command_count"],
        "error": fields["error"],
        "flags_hex": fields["flags_hex"],
        "last_addr": fields["last_addr"],
        "last_chunk": fields["last_chunk"],
        "last_opcode": fields["last_opcode"],
        "magic_ok": fields["magic_ok"],
        "read_count": fields["read_count"],
        "ready": fields["ready"],
        "state": fields["state"],
        "version": fields["version"],
        "write_count": fields["write_count"],
    }


def decode_phaser_status_payload(
    payload: int,
    *,
    bit_count: int = PHASER_SHELL_STATUS_BITS,
) -> dict[str, Any]:
    if bit_count < 256:
        raise ValueError("PHASER shell status payload must be at least 256 bits")

    magic = unsigned_field(payload, 0, 32)
    version = unsigned_field(payload, 32, 8)
    state_code = unsigned_field(payload, 40, 8)
    last_opcode = unsigned_field(payload, 48, 8)
    last_chunk = unsigned_field(payload, 56, 8)
    command_count = unsigned_field(payload, 64, 16)
    write_count = unsigned_field(payload, 80, 16)
    read_count = unsigned_field(payload, 96, 16)
    flags = unsigned_field(payload, 112, 16)
    last_addr = unsigned_field(payload, 128, 32)
    user0 = unsigned_field(payload, 160, 32)
    user1 = unsigned_field(payload, 192, 32)
    user2 = unsigned_field(payload, 224, 32)
    read_data128 = unsigned_field(payload, 256, 128)

    decoded_flags = phaser_status_flags(flags)
    return {
        "raw_hex": f"0x{payload:0{(bit_count + 3) // 4}x}",
        "magic": f"0x{magic:08x}",
        "magic_ok": magic == PHASER_SHELL_STATUS_MAGIC,
        "version": version,
        "state_code": state_code,
        "state": PHASER_STATE_NAMES.get(state_code, f"UNKNOWN_{state_code}"),
        "last_opcode": f"0x{last_opcode:02x}",
        "last_chunk": last_chunk,
        "command_count": command_count,
        "write_count": write_count,
        "read_count": read_count,
        "flags": decoded_flags,
        "flags_hex": f"0x{flags:04x}",
        "ready": decoded_flags["ready"],
        "error": decoded_flags["error"],
        "last_addr": f"0x{last_addr:08x}",
        "user0": f"0x{user0:08x}",
        "user1": f"0x{user1:08x}",
        "user2": f"0x{user2:08x}",
        "read_data128": f"0x{read_data128:032x}",
        "read_data128_bytes": [f"{byte:02x}" for byte in little_int_to_bytes(read_data128, 16)],
    }


def decode_phaser_status_readback(
    readback: dict[str, Any],
    *,
    bit_count: int = PHASER_SHELL_STATUS_BITS,
) -> dict[str, Any]:
    raw_hex = readback.get("raw_hex")
    if not isinstance(raw_hex, str):
        raise ValueError("readback did not contain a raw_hex payload")
    return decode_phaser_status_payload(int(raw_hex, 16), bit_count=bit_count)


@dataclass(frozen=True)
class PhaserShellCommand:
    opcode: int
    addr: int
    flags: int = 0
    chunk: int = 0
    aux: int = 0
    data128: int = 0

    def encode(self) -> int:
        if not 0 <= self.opcode <= 0xFF:
            raise ValueError("opcode must fit in 8 bits")
        if not 0 <= self.flags <= 0xFF:
            raise ValueError("flags must fit in 8 bits")
        if not 0 <= self.chunk <= 0xFF:
            raise ValueError("chunk must fit in 8 bits")
        if not 0 <= self.addr <= 0xFFFFFFFF:
            raise ValueError("addr must fit in 32 bits")
        if not 0 <= self.aux < (1 << 40):
            raise ValueError("aux must fit in 40 bits")
        if not 0 <= self.data128 < (1 << 128):
            raise ValueError("data128 must fit in 128 bits")
        return (
            PHASER_SHELL_MAGIC
            | (self.opcode << 32)
            | (self.flags << 40)
            | (self.chunk << 48)
            | (self.addr << 56)
            | (self.aux << 88)
            | (self.data128 << 128)
        )


def phaser_command_json(command: PhaserShellCommand) -> dict[str, Any]:
    return {
        "addr": f"0x{command.addr:08x}",
        "aux": f"0x{command.aux:010x}",
        "chunk": command.chunk,
        "command_hex": f"0x{command.encode():064x}",
        "data128": f"0x{command.data128:032x}",
        "flags": f"0x{command.flags:02x}",
        "opcode": f"0x{command.opcode:02x}",
    }
