#!/usr/bin/env python3
"""Read and write the YPCB raw-BSCAN OpenXC7 smoke-test registers."""

from __future__ import annotations

import argparse
import json
import time

from read_jtag_debug_ftdi_bitbang import (
    FTDI_FT232H_PRODUCT,
    FTDI_VENDOR,
    FtdiBitbangJtag,
    FtdiMpsseJtag,
)
from read_jtag_debug_xvc import clock_tms, reset_tap, shift_dr_read, shift_ir
from write_jtag_command_ftdi_bitbang import shift_dr_write


READ_MAGIC = 0x42535244
WRITE_MAGIC = 0x4253434E
OP_WRITE_SCRATCH = 0x01
OP_CLEAR_SCRATCH = 0x02


def make_client(args: argparse.Namespace):
    if args.backend == "mpsse":
        return FtdiMpsseJtag(
            serial=args.serial,
            vid=args.vid,
            pid=args.pid,
            freq_hz=args.freq_hz,
            tdo_bit=args.tdo_bit,
        )
    return FtdiBitbangJtag(
        serial=args.serial,
        vid=args.vid,
        pid=args.pid,
        delay_s=args.bit_delay_us / 1_000_000.0,
    )


def decode_read_payload(value: int) -> dict[str, int | str | bool]:
    magic = value & 0xFFFFFFFF
    scratch = (value >> 32) & 0xFFFFFFFF
    counter = (value >> 64) & 0xFFFFFFFF
    command_count = (value >> 96) & 0xFFFF
    last_opcode = (value >> 112) & 0xFF
    status = (value >> 120) & 0xFF
    return {
        "raw": f"0x{value:032x}",
        "magic": f"0x{magic:08x}",
        "magic_ok": magic == READ_MAGIC,
        "scratch": f"0x{scratch:08x}",
        "scratch_int": scratch,
        "counter": f"0x{counter:08x}",
        "counter_int": counter,
        "command_count": command_count,
        "last_opcode": f"0x{last_opcode:02x}",
        "status": f"0x{status:02x}",
    }


def read_smoke(client, args: argparse.Namespace) -> dict[str, int | str | bool]:
    reset_tap(client)
    shift_ir(client, args.read_ir, args.ir_len)
    return decode_read_payload(shift_dr_read(client, args.read_bits))


def write_smoke(client, args: argparse.Namespace, opcode: int, data: int) -> None:
    command = WRITE_MAGIC | (opcode << 32) | ((data & 0xFFFFFFFF) << 64)
    reset_tap(client)
    shift_ir(client, args.write_ir, args.ir_len)
    shift_dr_write(client, command, args.write_bits, args.update_mode)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("read", "write-scratch", "clear-scratch", "check"))
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--read-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--write-ir", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--read-bits", type=int, default=128)
    parser.add_argument("--write-bits", type=int, default=96)
    parser.add_argument("--scratch", type=lambda value: int(value, 0), default=0x5A17C0DE)
    parser.add_argument("--settle-s", type=float, default=0.05)
    parser.add_argument("--json-only", action="store_true")
    parser.add_argument("--update-mode", choices=("idle", "stop-at-update"), default="idle")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not 0 <= args.scratch <= 0xFFFFFFFF:
        raise SystemExit("--scratch must fit in 32 bits")

    client = make_client(args)
    try:
        before = read_smoke(client, args)
        if args.action == "read":
            result = {"before": before, "pass": before["magic_ok"]}
        elif args.action == "write-scratch":
            write_smoke(client, args, OP_WRITE_SCRATCH, args.scratch)
            time.sleep(args.settle_s)
            after = read_smoke(client, args)
            result = {
                "before": before,
                "after": after,
                "pass": after["magic_ok"] and after["scratch_int"] == args.scratch,
            }
        elif args.action == "clear-scratch":
            write_smoke(client, args, OP_CLEAR_SCRATCH, 0)
            time.sleep(args.settle_s)
            after = read_smoke(client, args)
            result = {
                "before": before,
                "after": after,
                "pass": after["magic_ok"] and after["scratch_int"] == 0,
            }
        else:
            write_smoke(client, args, OP_WRITE_SCRATCH, args.scratch)
            time.sleep(args.settle_s)
            mid = read_smoke(client, args)
            write_smoke(client, args, OP_CLEAR_SCRATCH, 0)
            time.sleep(args.settle_s)
            after = read_smoke(client, args)
            counter_advanced = after["counter_int"] != before["counter_int"]
            command_count_advanced = after["command_count"] >= before["command_count"] + 2
            result = {
                "before": before,
                "mid": mid,
                "after": after,
                "counter_advanced": counter_advanced,
                "command_count_advanced": command_count_advanced,
                "pass": (
                    before["magic_ok"]
                    and mid["magic_ok"]
                    and after["magic_ok"]
                    and mid["scratch_int"] == args.scratch
                    and after["scratch_int"] == 0
                    and counter_advanced
                    and command_count_advanced
                ),
            }
    finally:
        client.close()

    if not args.json_only:
        print("PASS" if result["pass"] else "FAIL")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
