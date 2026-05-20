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
BITS_DEFAULT = 136


def decode_status(payload: int, bits: int = BITS_DEFAULT) -> dict:
    hex_digits = (bits + 3) // 4
    last_phyctl_wd_offset = 96
    version = unsigned_field(payload, 32, 8)
    status = unsigned_field(payload, 40, 32)
    fields = {
        "magic": unsigned_field(payload, 0, 32),
        "version": version,
        "status_word": status,
        "phaser_pll_locked": bool(status & (1 << 0)),
        "phaser_ref_locked": bool(status & (1 << 1)),
    }
    if version == 2:
        fields.update({
            "diagnostic": "phaser_ref_only",
            "reserved_status_bit_2": bool(status & (1 << 2)),
            "rst_n": bool(status & (1 << 3)),
            "heartbeat_bit": bool(status & (1 << 4)),
        })
    else:
        if version == 4:
            fields.update({
                "diagnostic": "phaser_byte_lane_sequence",
                "in_phase_locked": bool(status & (1 << 2)),
                "phyctl_ready": bool(status & (1 << 3)),
                "rst_n": bool(status & (1 << 4)),
                "heartbeat_bit": bool(status & (1 << 5)),
                "fifo_activity": bool(status & (1 << 6)),
                "reserved_status_bit_7": bool(status & (1 << 7)),
                "reserved_status_bit_8": bool(status & (1 << 8)),
                "ddr3_lane0_dqs_iserdes_nonzero_seen": bool(status & (1 << 9)),
                "ddr3_lane0_dqs_iserdes_toggle_seen": bool(status & (1 << 10)),
                "sequence_done": bool(status & (1 << 11)),
                "sequence_wait_satisfied": bool(status & (1 << 12)),
                "sync_enable": bool(status & (1 << 13)),
                "phyctl_wr_enable": bool(status & (1 << 14)),
                "readcalibenable": bool(status & (1 << 15)),
                "writecalibenable": bool(status & (1 << 16)),
                "phyctl_reset": bool(status & (1 << 17)),
                "phaser_ref_reset": bool(status & (1 << 18)),
                "phaser_ref_pwrdwn": bool(status & (1 << 19)),
                "lane_reset": bool(status & (1 << 20)),
                "rstdqsfind": bool(status & (1 << 21)),
                "out_coarse_overflow": bool(status & (1 << 22)),
                "out_fine_overflow": bool(status & (1 << 23)),
                "dqs_found": bool(status & (1 << 24)),
                "dqs_out_of_range": bool(status & (1 << 25)),
                "out_rd_enable": bool(status & (1 << 26)),
                "in_wrenable": bool(status & (1 << 27)),
                "ddr3_lane0_dq_seen_high_and_low": bool(status & (1 << 28)),
                "ddr3_lane0_dq_toggle_seen": bool(status & (1 << 29)),
                "ddr3_lane0_dqs_seen_high_and_low": bool(status & (1 << 30)),
                "ddr3_lane0_dqs_toggle_seen": bool(status & (1 << 31)),
                "sequence_advance_count": unsigned_field(payload, 72, 16),
                "sequence_step": unsigned_field(payload, 88, 16),
                "last_phyctl_wd": f"0x{unsigned_field(payload, last_phyctl_wd_offset, 32):08x}",
            })
        else:
            fields.update({
                "diagnostic": "phaser_byte_lane",
                "in_phase_locked": bool(status & (1 << 2)),
                "phyctl_ready": bool(status & (1 << 3)),
                "rst_n": bool(status & (1 << 4)),
                "heartbeat_bit": bool(status & (1 << 5)),
                "fifo_activity": bool(status & (1 << 6)),
                "phyctl_almost_full": bool(status & (1 << 7)),
                "phyctl_full": bool(status & (1 << 8)),
                "phyctl_empty": bool(status & (1 << 9)),
            })
            if version == 3:
                fields.update({
                    "phyctl_stimulus_count": unsigned_field(payload, 72, 16),
                })
            else:
                fields.update({
                    "phyctl_in_burst_pending": unsigned_field(payload, 72, 4),
                    "phyctl_out_burst_pending": unsigned_field(payload, 76, 4),
                    "phyctl_pc_enable_calib": unsigned_field(payload, 80, 2),
                    "in_counter_read": unsigned_field(payload, 82, 6),
                    "out_counter_read": unsigned_field(payload, 88, 9),
                })
    return {
        "raw_hex": f"0x{payload:0{hex_digits}x}",
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
    parser.add_argument("--bits", type=int, choices=(128, 136), default=BITS_DEFAULT)
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
            payload = read_payload(client, args.ir_len, args.user_ir, args.bits)
            decoded = decode_status(payload, args.bits)
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
