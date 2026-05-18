#!/usr/bin/env python3
"""Read the YPCB PHASER byte-lane diagnostic USER1 status payload."""

import argparse
import json
import time

from read_jtag_debug_ftdi_bitbang import (
    FTDI_FT232H_PRODUCT,
    FTDI_VENDOR,
    FtdiBitbangJtag,
    FtdiMpsseJtag,
    read_payload,
)
from read_jtag_debug_xvc import unsigned_field


MAGIC = 0x50485344
BITS = 128


def decode_status(payload: int) -> dict:
    status = unsigned_field(payload, 40, 32)
    fields = {
        "magic": unsigned_field(payload, 0, 32),
        "version": unsigned_field(payload, 32, 8),
        "status_word": status,
        "phaser_pll_locked": bool(status & (1 << 0)),
        "phaser_ref_locked": bool(status & (1 << 1)),
        "in_phase_locked": bool(status & (1 << 2)),
        "phyctl_ready": bool(status & (1 << 3)),
        "rst_n": bool(status & (1 << 4)),
        "heartbeat_bit": bool(status & (1 << 5)),
        "fifo_activity": bool(status & (1 << 6)),
        "phyctl_almost_full": bool(status & (1 << 7)),
        "phyctl_full": bool(status & (1 << 8)),
        "phyctl_empty": bool(status & (1 << 9)),
        "phyctl_in_burst_pending": unsigned_field(payload, 72, 4),
        "phyctl_out_burst_pending": unsigned_field(payload, 76, 4),
        "phyctl_pc_enable_calib": unsigned_field(payload, 80, 2),
        "in_counter_read": unsigned_field(payload, 82, 6),
        "out_counter_read": unsigned_field(payload, 88, 9),
    }
    return {
        "raw_hex": f"0x{payload:032x}",
        "magic_ok": fields["magic"] == MAGIC,
        "fields": fields,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=0)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--poll", action="store_true")
    parser.add_argument("--poll-count", type=int, default=20)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
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
        attempts = args.poll_count if args.poll else 1
        decoded = None
        for attempt in range(attempts):
            payload = read_payload(client, args.ir_len, args.user_ir, BITS)
            decoded = decode_status(payload)
            fields = decoded["fields"]
            if not args.poll or (
                decoded["magic_ok"]
                and fields["phaser_pll_locked"]
                and fields["phaser_ref_locked"]
                and fields["rst_n"]
            ):
                break
            if attempt + 1 < attempts:
                time.sleep(args.poll_interval)

        print(json.dumps({
            "backend": f"ftdi-{args.backend}",
            "serial": args.serial,
            "attempts": attempt + 1,
            **decoded,
        }, indent=2, sort_keys=True))
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
