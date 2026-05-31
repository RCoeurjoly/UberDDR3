#!/usr/bin/env python3
"""Program and validate the YPCB DDR3 BIST_MODE=2 design through FTDI JTAG.

The bitstream must be built with -DUBERDDR3_DEBUG_JTAG, for example via
`nix build .#ypcb-ddr3-bitstream-debug-jtag`.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_PROGRAMMER = Path(os.environ.get("OPENFPGALOADER", "openFPGALoader"))
DEFAULT_BITS = 960
MAGIC = 0x33445244
VERSION = 1
DEBUG_VERSION = 2
CALIB_DONE_STATE = 23
FTDI_VENDOR = 0x0403
FTDI_FT232H_PRODUCT = 0x6014
BITMODE_RESET = 0x00
BITMODE_MPSSE = 0x02
FTDI_INTERFACE_A = 1
MPSSE_WRITE_NEG = 0x01
MPSSE_BITMODE = 0x02
MPSSE_LSB = 0x08
MPSSE_DO_READ = 0x20
MPSSE_WRITE_TMS = 0x40
SET_BITS_LOW = 0x80
SET_BITS_HIGH = 0x82
TCK_DIVISOR = 0x86
SEND_IMMEDIATE = 0x87
DIS_DIV_5 = 0x8A
HS3_LOW_VALUE = 0x88
HS3_LOW_DIRECTION = 0x8B
HS3_HIGH_VALUE = 0x20
HS3_HIGH_DIRECTION = 0x30


class FtdiError(RuntimeError):
    pass


class FtdiMpsseJtag:
    def __init__(self, serial: str | None, vid: int, pid: int, freq_hz: int, tdo_bit: int):
        self.tdo_bit = tdo_bit
        self.lib = ctypes.CDLL("libftdi1.so")
        self._configure_signatures()
        self.ctx = self.lib.ftdi_new()
        if not self.ctx:
            raise FtdiError("ftdi_new failed")
        serial_bytes = serial.encode("ascii") if serial else None
        self._check(self.lib.ftdi_set_interface(self.ctx, FTDI_INTERFACE_A), "ftdi_set_interface")
        rc = self.lib.ftdi_usb_open_desc_index(
            self.ctx, vid, pid, None, ctypes.c_char_p(serial_bytes) if serial_bytes else None, 0
        )
        self._check(rc, "ftdi_usb_open_desc_index")
        self._check(self.lib.ftdi_usb_reset(self.ctx), "ftdi_usb_reset")
        self._check(self.lib.ftdi_set_bitmode(self.ctx, 0x00, BITMODE_RESET), "reset bitmode")
        self._check(self.lib.ftdi_usb_purge_buffers(self.ctx), "ftdi_usb_purge_buffers")
        self._check(self.lib.ftdi_set_latency_timer(self.ctx, 1), "ftdi_set_latency_timer")
        self._check(self.lib.ftdi_set_bitmode(self.ctx, 0xFB, BITMODE_MPSSE), "enable mpsse")
        self._read_available(5)
        self._configure_clock(freq_hz)
        self._write(bytes([SET_BITS_LOW, HS3_LOW_VALUE, HS3_LOW_DIRECTION, SET_BITS_HIGH, HS3_HIGH_VALUE, HS3_HIGH_DIRECTION, SEND_IMMEDIATE]))
        self._read_available(2)

    def _configure_signatures(self) -> None:
        self.lib.ftdi_new.restype = ctypes.c_void_p
        self.lib.ftdi_free.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_set_interface.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.lib.ftdi_usb_open_desc_index.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
        self.lib.ftdi_usb_open_desc_index.restype = ctypes.c_int
        self.lib.ftdi_usb_close.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_usb_reset.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_usb_purge_buffers.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_set_latency_timer.argtypes = [ctypes.c_void_p, ctypes.c_ubyte]
        self.lib.ftdi_set_bitmode.argtypes = [ctypes.c_void_p, ctypes.c_ubyte, ctypes.c_ubyte]
        self.lib.ftdi_write_data.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte), ctypes.c_int]
        self.lib.ftdi_read_data.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte), ctypes.c_int]
        self.lib.ftdi_get_error_string.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_get_error_string.restype = ctypes.c_char_p

    def _error_string(self) -> str:
        raw = self.lib.ftdi_get_error_string(self.ctx)
        return raw.decode("utf-8", errors="replace") if raw else "unknown error"

    def _check(self, rc: int, what: str) -> None:
        if rc < 0:
            raise FtdiError(f"{what} failed: {rc}: {self._error_string()}")

    def _write(self, data_bytes: bytes) -> None:
        data = (ctypes.c_ubyte * len(data_bytes)).from_buffer_copy(data_bytes)
        rc = self.lib.ftdi_write_data(self.ctx, data, len(data_bytes))
        if rc != len(data_bytes):
            raise FtdiError(f"ftdi_write_data failed: {rc}: {self._error_string()}")

    def _read_exact(self, byte_count: int) -> bytes:
        result = bytearray()
        deadline = time.monotonic() + 5.0
        while len(result) < byte_count:
            remaining = byte_count - len(result)
            buf = (ctypes.c_ubyte * remaining)()
            rc = self.lib.ftdi_read_data(self.ctx, buf, remaining)
            if rc < 0:
                raise FtdiError(f"ftdi_read_data failed: {rc}: {self._error_string()}")
            if rc:
                result.extend(bytes(buf[:rc]))
            elif time.monotonic() > deadline:
                raise FtdiError(f"timed out reading {byte_count} MPSSE byte(s)")
            else:
                time.sleep(0.001)
        return bytes(result)

    def _read_available(self, byte_count: int) -> bytes:
        buf = (ctypes.c_ubyte * byte_count)()
        rc = self.lib.ftdi_read_data(self.ctx, buf, byte_count)
        if rc < 0:
            raise FtdiError(f"ftdi_read_data failed: {rc}: {self._error_string()}")
        return bytes(buf[:rc])

    def _configure_clock(self, freq_hz: int) -> None:
        divisor = max(0, int((60_000_000 / freq_hz - 1) / 2))
        self._write(bytes([DIS_DIV_5, TCK_DIVISOR, divisor & 0xFF, (divisor >> 8) & 0xFF]))
        self._read_available(4)

    def close(self) -> None:
        if self.ctx:
            self.lib.ftdi_set_bitmode(self.ctx, 0x00, BITMODE_RESET)
            self.lib.ftdi_usb_close(self.ctx)
            self.lib.ftdi_free(self.ctx)
            self.ctx = None

    def shift(self, tms_bits: list[int], tdi_bits: list[int]) -> list[int]:
        if len(tms_bits) != len(tdi_bits):
            raise ValueError("TMS and TDI vectors must have the same length")
        tdo_bits: list[int] = []
        for offset in range(0, len(tms_bits), 32):
            tdo_bits.extend(self._shift_chunk(tms_bits[offset:offset + 32], tdi_bits[offset:offset + 32]))
        return tdo_bits

    def _shift_chunk(self, tms_bits: list[int], tdi_bits: list[int]) -> list[int]:
        cmd = bytearray()
        op = MPSSE_WRITE_TMS | MPSSE_LSB | MPSSE_BITMODE | MPSSE_WRITE_NEG | MPSSE_DO_READ
        for tms, tdi in zip(tms_bits, tdi_bits):
            cmd.extend([op, 0x00, (0x80 if tdi else 0x00) | (0x01 if tms else 0x00)])
        cmd.append(SEND_IMMEDIATE)
        self._write(bytes(cmd))
        raw = self._read_exact(len(tms_bits))
        return [(byte >> self.tdo_bit) & 1 for byte in raw]


def bits_to_int(bits: list[int]) -> int:
    value = 0
    for index, bit in enumerate(bits):
        value |= int(bit) << index
    return value


def clock_tms(client: FtdiMpsseJtag, tms_bits: list[int]) -> None:
    if tms_bits:
        client.shift(tms_bits, [0] * len(tms_bits))


def reset_tap(client: FtdiMpsseJtag) -> None:
    clock_tms(client, [1, 1, 1, 1, 1, 1, 0])


def shift_ir(client: FtdiMpsseJtag, instruction: int, ir_len: int) -> None:
    clock_tms(client, [1, 1, 0, 0])
    tdi_bits = [(instruction >> bit) & 1 for bit in range(ir_len)]
    tms_bits = [0] * ir_len
    tms_bits[-1] = 1
    client.shift(tms_bits, tdi_bits)
    clock_tms(client, [1, 0])


def shift_dr_read(client: FtdiMpsseJtag, bit_count: int) -> int:
    clock_tms(client, [1, 0, 0])
    tms_bits = [0] * bit_count
    tms_bits[-1] = 1
    tdo_bits = client.shift(tms_bits, [0] * bit_count)
    clock_tms(client, [1, 0])
    return bits_to_int(tdo_bits)


def read_payload(client: FtdiMpsseJtag, ir_len: int, user_ir: int, bit_count: int) -> int:
    reset_tap(client)
    shift_ir(client, user_ir, ir_len)
    return shift_dr_read(client, bit_count)


def field(payload: int, offset: int, width: int) -> int:
    return (payload >> offset) & ((1 << width) - 1)


def decode_payload(payload: int, bit_count: int) -> dict[str, object]:
    debug1 = field(payload, 28, 32)
    bist_counts = field(payload, 448, 64)
    init_reset_debug_offset = 512
    init_reset_debug = {
        "controller_i_rst_n": bool(field(payload, init_reset_debug_offset + 0, 1)),
        "controller_i_phy_idelayctrl_rdy": bool(field(payload, init_reset_debug_offset + 1, 1)),
        "controller_o_phy_reset": bool(field(payload, init_reset_debug_offset + 2, 1)),
        "controller_sync_rst_controller": bool(field(payload, init_reset_debug_offset + 3, 1)),
        "controller_sync_rst_wb2": bool(field(payload, init_reset_debug_offset + 4, 1)),
        "controller_reset_from_wb2": bool(field(payload, init_reset_debug_offset + 5, 1)),
        "controller_reset_from_calibrate": bool(field(payload, init_reset_debug_offset + 6, 1)),
        "controller_reset_from_test": bool(field(payload, init_reset_debug_offset + 7, 1)),
        "controller_reset_after_rank_1": bool(field(payload, init_reset_debug_offset + 8, 1)),
        "controller_reset_done": bool(field(payload, init_reset_debug_offset + 9, 1)),
        "controller_pause_counter": bool(field(payload, init_reset_debug_offset + 10, 1)),
        "controller_initial_calibration_done": bool(field(payload, init_reset_debug_offset + 11, 1)),
        "controller_final_calibration_done": bool(field(payload, init_reset_debug_offset + 12, 1)),
        "controller_user_self_refresh_q": bool(field(payload, init_reset_debug_offset + 13, 1)),
        "controller_current_rank": bool(field(payload, init_reset_debug_offset + 14, 1)),
        "controller_delay_counter_is_zero": bool(field(payload, init_reset_debug_offset + 15, 1)),
    }
    calib_debug_offset = 100
    calib_debug = {
        "state_calibrate": field(payload, calib_debug_offset, 5),
        "instruction_address": field(payload, calib_debug_offset + 5, 5),
        "delay_counter": field(payload, calib_debug_offset + 10, 19),
        "delay_counter_is_zero": bool(field(payload, calib_debug_offset + 29, 1)),
        "lane": field(payload, calib_debug_offset + 30, 1),
        "bitslip": field(payload, calib_debug_offset + 31, 2),
        "lane_read_dq_early": field(payload, calib_debug_offset + 33, 2),
        "lane_write_dq_late": field(payload, calib_debug_offset + 35, 2),
        "train_delay": field(payload, calib_debug_offset + 37, 4),
        "delay_before_read_data": field(payload, calib_debug_offset + 41, 4),
        "idelay_dqs_cntvaluein_lane0": field(payload, calib_debug_offset + 45, 5),
        "idelay_dqs_cntvaluein_lane1": field(payload, calib_debug_offset + 50, 5),
        "idelay_data_cntvaluein_lane0": field(payload, calib_debug_offset + 55, 5),
        "idelay_data_cntvaluein_lane1": field(payload, calib_debug_offset + 60, 5),
        "dqs_count_repeat": field(payload, calib_debug_offset + 65, 3),
        "dqs_start_index_repeat": field(payload, calib_debug_offset + 68, 7),
        "dqs_start_index": field(payload, calib_debug_offset + 75, 6),
        "dqs_start_index_stored": field(payload, calib_debug_offset + 81, 6),
        "dqs_target_index": field(payload, calib_debug_offset + 87, 6),
        "dqs_target_index_value": field(payload, calib_debug_offset + 93, 6),
        "dqs_target_index_orig": field(payload, calib_debug_offset + 99, 6),
        "dqs_store": field(payload, calib_debug_offset + 105, 40),
        "iserdes_dqs": field(payload, calib_debug_offset + 145, 16),
        "iserdes_bitslip_reference": field(payload, calib_debug_offset + 161, 16),
        "read_lane_data_shifted": field(payload, calib_debug_offset + 177, 32),
        "read_lane_data": field(payload, calib_debug_offset + 209, 64),
        "init_i_rst_n": bool(field(payload, calib_debug_offset + 273, 1)),
        "init_o_phy_reset": bool(field(payload, calib_debug_offset + 274, 1)),
        "init_idelayctrl_rdy": bool(field(payload, calib_debug_offset + 275, 1)),
        "init_instruction": field(payload, calib_debug_offset + 276, 28),
        "init_cmd_ck_en": bool(field(payload, calib_debug_offset + 304, 1)),
        "init_cmd_reset_n": bool(field(payload, calib_debug_offset + 305, 1)),
        "init_cmd_odt": bool(field(payload, calib_debug_offset + 306, 1)),
        "init_pause_counter": bool(field(payload, calib_debug_offset + 307, 1)),
        "init_final_calibration_done": bool(field(payload, calib_debug_offset + 308, 1)),
        "init_initial_calibration_done": bool(field(payload, calib_debug_offset + 309, 1)),
        "init_reset_from_calibrate": bool(field(payload, calib_debug_offset + 310, 1)),
        "analyze_dqs_window": field(payload, calib_debug_offset + 311, 10),
        "analyze_dqs_match": bool(field(payload, calib_debug_offset + 321, 1)),
        "analyze_dqs_at_end": bool(field(payload, calib_debug_offset + 322, 1)),
        "analyze_dqs_repeat_same": bool(field(payload, calib_debug_offset + 323, 1)),
        "analyze_dqs_repeat_done": bool(field(payload, calib_debug_offset + 324, 1)),
        "analyze_dqs_action": field(payload, calib_debug_offset + 325, 3),
        "phy_idelayctrl_aggregate_rdy": bool(field(payload, calib_debug_offset + 332, 1)),
        "phy_idelayctrl_raw_rdy": bool(field(payload, calib_debug_offset + 333, 1)),
        "phy_dci_locked": bool(field(payload, calib_debug_offset + 334, 1)),
        "phy_sync_rst": bool(field(payload, calib_debug_offset + 335, 1)),
        "phy_reset_delay_counter": field(payload, calib_debug_offset + 336, 12),
    }
    decoded = {
        "rst_n": bool(field(payload, 0, 1)),
        "clk_locked": bool(field(payload, 1, 1)),
        "bist_done": bool(field(payload, 2, 1)),
        "calib_complete": bool(field(payload, 3, 1)),
        "debug1": debug1,
        "state_calibrate": debug1 & 0x1F,
        "magic": field(payload, 60, 32),
        "version": field(payload, 92, 8),
        "bist_counts": bist_counts,
        "correct_read_data": field(bist_counts, 0, 32),
        "wrong_read_data": field(bist_counts, 32, 32),
        "calib_debug": calib_debug,
        "init_reset_debug": init_reset_debug,
    }
    reasons: list[str] = []
    if decoded["magic"] != MAGIC:
        reasons.append("bad_magic")
    if decoded["version"] not in (VERSION, DEBUG_VERSION):
        reasons.append("bad_version")
    if not decoded["clk_locked"]:
        reasons.append("clk_unlocked")
    if not decoded["calib_complete"]:
        reasons.append("calib_incomplete")
    if decoded["state_calibrate"] != CALIB_DONE_STATE:
        reasons.append("calib_state_not_done")
    if not decoded["bist_done"]:
        reasons.append("bist_not_done")
    if decoded["wrong_read_data"] != 0:
        reasons.append("wrong_read_data_nonzero")
    return {
        "raw_hex": f"0x{payload:0{(bit_count + 3) // 4}x}",
        "fields": decoded,
        "pass": not reasons,
        "fail_reasons": reasons,
    }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def program_bitstream(programmer: Path, bitstream: Path) -> dict[str, object]:
    command = [str(programmer), "-c", "digilent_hs3", "--bitstream", str(bitstream)]
    completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return {"command": command, "returncode": completed.returncode, "output": completed.stdout}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bitstream", required=True, type=Path)
    parser.add_argument("--programmer", type=Path, default=DEFAULT_PROGRAMMER)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--no-program", action="store_true")
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--bits", type=int, default=DEFAULT_BITS)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    return parser.parse_args()


def write_result(path: Path | None, result: dict[str, object]) -> None:
    if path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    bitstream = args.bitstream.resolve()
    result: dict[str, object] = {
        "started_at": datetime.now(timezone.utc).isoformat(),
        "bitstream": str(bitstream),
        "bitstream_sha256": sha256_file(bitstream),
        "programmer": {"path": str(args.programmer), "cable": "digilent_hs3"},
        "jtag": {"backend": "ftdi-mpsse", "serial": args.serial, "bits": args.bits, "ir_len": args.ir_len, "user_ir": args.user_ir},
    }
    if args.no_program:
        result["programming"] = {"skipped": True}
    else:
        result["programming"] = program_bitstream(args.programmer, bitstream)
        if result["programming"]["returncode"] != 0:
            result.update({"pass": False, "fail_reasons": ["programming_failed"]})
            write_result(args.output, result)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 1

    client = FtdiMpsseJtag(args.serial, args.vid, args.pid, args.freq_hz, args.tdo_bit)
    try:
        decoded = None
        poll_samples: list[dict[str, object]] = []
        poll_start = time.monotonic()
        for attempt in range(1, args.poll_count + 1):
            decoded = decode_payload(read_payload(client, args.ir_len, args.user_ir, args.bits), args.bits)
            poll_samples.append({
                "attempt": attempt,
                "elapsed_s": round(time.monotonic() - poll_start, 6),
                **decoded,
            })
            if decoded["pass"] or "wrong_read_data_nonzero" in decoded["fail_reasons"]:
                break
            if attempt < args.poll_count:
                time.sleep(args.poll_interval)
    finally:
        client.close()

    result["poll_samples"] = poll_samples
    result.update(decoded or {})
    result["attempts"] = attempt
    result["finished_at"] = datetime.now(timezone.utc).isoformat()
    write_result(args.output, result)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result.get("pass") else 2


if __name__ == "__main__":
    raise SystemExit(main())
