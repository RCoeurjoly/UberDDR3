#!/usr/bin/env python3
"""Read the YPCB lower-lane DDR3 pins through a raw-BSCAN sampler."""

from __future__ import annotations

import argparse
import json

from read_jtag_debug_ftdi_bitbang import (
    FTDI_FT232H_PRODUCT,
    FTDI_VENDOR,
    FtdiBitbangJtag,
    FtdiMpsseJtag,
)
from read_jtag_debug_xvc import reset_tap, shift_dr_read, shift_ir


READ_MAGIC = 0x44515244


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


def decode_payload(value: int) -> dict[str, int | str | bool]:
    magic = value & 0xFFFFFFFF
    counter = (value >> 32) & 0xFFFFFFFF
    dq_now = (value >> 64) & 0xFFFFFFFF
    dq_seen_high = (value >> 96) & 0xFFFFFFFF
    dq_seen_low = (value >> 128) & 0xFFFFFFFF
    dq_toggle_seen = (value >> 160) & 0xFFFFFFFF
    dqs_p_now = (value >> 216) & 0xF
    dqs_n_now = (value >> 220) & 0xF
    dqs_status = (value >> 224) & 0xFFFFFFFF
    dqs_p_seen_high = dqs_status & 0xF
    dqs_n_seen_high = (dqs_status >> 4) & 0xF
    dqs_p_seen_low = (dqs_status >> 8) & 0xF
    dqs_n_seen_low = (dqs_status >> 12) & 0xF
    dqs_p_toggle_seen = (dqs_status >> 16) & 0xF
    dqs_n_toggle_seen = (dqs_status >> 20) & 0xF
    return {
        "raw": f"0x{value:064x}",
        "magic": f"0x{magic:08x}",
        "magic_ok": magic == READ_MAGIC,
        "counter": f"0x{counter:08x}",
        "counter_int": counter,
        "dq_now": f"0x{dq_now:08x}",
        "dq_seen_high": f"0x{dq_seen_high:08x}",
        "dq_seen_low": f"0x{dq_seen_low:08x}",
        "dq_toggle_seen": f"0x{dq_toggle_seen:08x}",
        "dqs_p_now": f"0x{dqs_p_now:x}",
        "dqs_n_now": f"0x{dqs_n_now:x}",
        "dqs_p_seen_high": f"0x{dqs_p_seen_high:x}",
        "dqs_n_seen_high": f"0x{dqs_n_seen_high:x}",
        "dqs_p_seen_low": f"0x{dqs_p_seen_low:x}",
        "dqs_n_seen_low": f"0x{dqs_n_seen_low:x}",
        "dqs_p_toggle_seen": f"0x{dqs_p_toggle_seen:x}",
        "dqs_n_toggle_seen": f"0x{dqs_n_toggle_seen:x}",
    }


def read_pins(client, args: argparse.Namespace) -> dict[str, int | str | bool]:
    reset_tap(client)
    shift_ir(client, args.read_ir, args.ir_len)
    return decode_payload(shift_dr_read(client, args.read_bits))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--read-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--read-bits", type=int, default=256)
    parser.add_argument("--json-only", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    client = make_client(args)
    try:
        result = read_pins(client, args)
    finally:
        client.close()

    result["pass"] = bool(result["magic_ok"])
    if not args.json_only:
        print("PASS" if result["pass"] else "FAIL")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
