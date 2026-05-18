#!/usr/bin/env python3
"""Write a small command word to a USER JTAG data register through FTDI."""

from __future__ import annotations

import argparse
import json

from read_jtag_debug_ftdi_bitbang import (
    FTDI_FT232H_PRODUCT,
    FTDI_VENDOR,
    FtdiBitbangJtag,
    FtdiMpsseJtag,
)
from read_jtag_debug_xvc import clock_tms, reset_tap, shift_ir


def shift_dr_write(client, value: int, bit_count: int, update_mode: str) -> None:
    clock_tms(client, [1, 0, 0])
    tdi_bits = [(value >> bit) & 1 for bit in range(bit_count)]
    tms_bits = [0] * bit_count
    tms_bits[-1] = 1
    client.shift(tms_bits, tdi_bits)
    if update_mode == "idle":
        clock_tms(client, [1, 0])
    elif update_mode == "stop-at-update":
        clock_tms(client, [1])
    else:
        raise ValueError(f"unknown update mode {update_mode!r}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument(
        "--payload",
        type=lambda value: int(value, 0),
        help="Write this exact DR payload instead of assembling a protocol-specific command.",
    )
    parser.add_argument("--byte", dest="byte_value", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--data128", type=lambda value: int(value, 0))
    parser.add_argument("--addr", dest="addr_value", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--bits", type=int, default=16)
    parser.add_argument("--magic-nibble", type=lambda value: int(value, 0), default=0xA)
    parser.add_argument("--loader-magic", type=lambda value: int(value, 0), default=0x33445244)
    parser.add_argument("--opcode", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--chunk", type=lambda value: int(value, 0), default=0)
    parser.add_argument(
        "--update-mode",
        choices=("idle", "stop-at-update"),
        default="idle",
        help=(
            "TAP transition after Exit1-DR. 'idle' clocks Update-DR then Run-Test/Idle; "
            "'stop-at-update' clocks only into Update-DR and lets close/reset leave it."
        ),
    )
    parser.add_argument("--json-only", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.payload is None and (args.byte_value < 0 or args.byte_value > 0xFF):
        raise SystemExit("--byte must fit in 8 bits")
    if args.data128 is not None and not 0 <= args.data128 < (1 << 128):
        raise SystemExit("--data128 must fit in 128 bits")
    if args.addr_value < 0:
        raise SystemExit("--addr must be non-negative")
    if args.magic_nibble < 0 or args.magic_nibble > 0xF:
        raise SystemExit("--magic-nibble must fit in 4 bits")
    if args.loader_magic < 0 or args.loader_magic > 0xFFFFFFFF:
        raise SystemExit("--loader-magic must fit in 32 bits")
    if args.opcode < 0 or args.opcode > 0xFF:
        raise SystemExit("--opcode must fit in 8 bits")
    if args.chunk < 0 or args.chunk > 0x3:
        raise SystemExit("--chunk must fit in 2 bits")

    if args.payload is not None:
        if args.payload < 0 or args.payload >= (1 << args.bits):
            raise SystemExit("--payload must fit in --bits bits")
        command = args.payload
    else:
        if args.bits == 16:
            if args.addr_value > 0xFF:
                raise SystemExit("--addr must fit in 8 bits for 16-bit commands")
            command = (args.magic_nibble << 12) | (1 << 8) | args.byte_value
        else:
            if args.bits < 72:
                raise SystemExit("--bits must be 16 or at least 72 for rowstream loader commands")
            if args.addr_value > 0xFFFFFFFF:
                raise SystemExit("--addr must fit in 32 bits for rowstream loader commands")
            payload_data = args.data128 if args.data128 is not None else args.byte_value
            command = (
                args.loader_magic
                | (args.opcode << 32)
                | (args.chunk << 40)
                | (args.addr_value << 48)
                | (payload_data << 64)
            )
    if args.backend == "mpsse":
        client = FtdiMpsseJtag(
            serial=args.serial,
            vid=args.vid,
            pid=args.pid,
            freq_hz=args.freq_hz,
            tdo_bit=args.tdo_bit,
        )
    else:
        client = FtdiBitbangJtag(
            serial=args.serial,
            vid=args.vid,
            pid=args.pid,
            delay_s=args.bit_delay_us / 1_000_000.0,
        )

    try:
        reset_tap(client)
        shift_ir(client, args.user_ir, args.ir_len)
        shift_dr_write(client, command, args.bits, args.update_mode)
    finally:
        client.close()

    result = {
        "backend": f"ftdi-{args.backend}",
        "serial": args.serial,
        "user_ir": f"0x{args.user_ir:02x}",
        "bits": args.bits,
        "addr": f"0x{args.addr_value:08x}" if args.bits != 16 else f"0x{args.addr_value:02x}",
        "byte": f"0x{args.byte_value:02x}",
        "data128": f"0x{args.data128:032x}" if args.data128 is not None else None,
        "chunk": args.chunk,
        "command": f"0x{command:0{args.bits // 4}x}",
        "loader_magic": f"0x{args.loader_magic:08x}",
        "opcode": f"0x{args.opcode:02x}",
        "payload_override": f"0x{args.payload:x}" if args.payload is not None else None,
        "update_mode": args.update_mode,
    }
    if not args.json_only:
        print(
            f"Wrote USER JTAG command {result['command']} "
            f"addr={result['addr']} byte={result['byte']}"
        )
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
