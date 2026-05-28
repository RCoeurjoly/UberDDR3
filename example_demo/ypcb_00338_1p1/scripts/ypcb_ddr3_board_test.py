#!/usr/bin/env python3
"""Program and validate the YPCB DDR3 BIST_MODE=2 design through FTDI JTAG."""

import argparse
import ctypes
import hashlib
import os
import json
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_PROGRAMMER = Path(os.environ.get("OPENFPGALOADER", "/home/roland/openFPGALoader/build-user/openFPGALoader"))
PROGRAMMER_COMMIT = "3ae5e5e"
DEFAULT_BITS = 960
MAGIC = 0x33445244
VERSION = 3
CALIB_DONE_STATE = 23
BIST_MODE = 2
BYTE_LANES = 2
DQ_BITS = 8

FTDI_VENDOR = 0x0403
FTDI_FT232H_PRODUCT = 0x6014
BITMODE_RESET = 0x00
BITMODE_BITBANG = 0x01
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

PIN_TCK = 0x01
PIN_TDI = 0x02
PIN_TDO = 0x04
PIN_TMS = 0x08
PIN_OUTPUT_MASK = PIN_TCK | PIN_TDI | PIN_TMS

HS3_LOW_VALUE = 0x88
HS3_LOW_DIRECTION = 0x8B
HS3_HIGH_VALUE = 0x20
HS3_HIGH_DIRECTION = 0x30


class FtdiError(RuntimeError):
    pass


class FtdiBitbangJtag:
    def __init__(self, serial, vid, pid, delay_s):
        self.delay_s = delay_s
        self.lib = ctypes.CDLL("libftdi1.so")
        self._configure_signatures()
        self.ctx = self.lib.ftdi_new()
        if not self.ctx:
            raise FtdiError("ftdi_new failed")

        serial_bytes = serial.encode("ascii") if serial else None
        rc = self.lib.ftdi_usb_open_desc_index(
            self.ctx, vid, pid, None,
            ctypes.c_char_p(serial_bytes) if serial_bytes else None, 0,
        )
        self._check(rc, "ftdi_usb_open_desc_index")
        self._check(self.lib.ftdi_usb_reset(self.ctx), "ftdi_usb_reset")
        self._check(self.lib.ftdi_usb_purge_buffers(self.ctx), "ftdi_usb_purge_buffers")
        self._check(self.lib.ftdi_set_latency_timer(self.ctx, 1), "ftdi_set_latency_timer")
        self._check(self.lib.ftdi_set_bitmode(self.ctx, 0x00, BITMODE_RESET), "reset bitmode")
        self._check(self.lib.ftdi_set_bitmode(self.ctx, PIN_OUTPUT_MASK, BITMODE_BITBANG), "enable bitbang")
        self._write_pin_byte(PIN_TMS)

    def _configure_signatures(self):
        self.lib.ftdi_new.restype = ctypes.c_void_p
        self.lib.ftdi_free.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_usb_open_desc_index.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
        self.lib.ftdi_usb_open_desc_index.restype = ctypes.c_int
        self.lib.ftdi_usb_close.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_usb_reset.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_usb_purge_buffers.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_set_latency_timer.argtypes = [ctypes.c_void_p, ctypes.c_ubyte]
        self.lib.ftdi_set_bitmode.argtypes = [ctypes.c_void_p, ctypes.c_ubyte, ctypes.c_ubyte]
        self.lib.ftdi_write_data.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte), ctypes.c_int]
        self.lib.ftdi_read_pins.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte)]
        self.lib.ftdi_get_error_string.argtypes = [ctypes.c_void_p]
        self.lib.ftdi_get_error_string.restype = ctypes.c_char_p

    def _error_string(self):
        raw = self.lib.ftdi_get_error_string(self.ctx)
        return raw.decode("utf-8", errors="replace") if raw else "unknown error"

    def _check(self, rc, what):
        if rc < 0:
            raise FtdiError(f"{what} failed: {rc}: {self._error_string()}")

    def _write_pin_byte(self, value):
        data = (ctypes.c_ubyte * 1)(value)
        rc = self.lib.ftdi_write_data(self.ctx, data, 1)
        if rc != 1:
            raise FtdiError(f"ftdi_write_data failed: {rc}: {self._error_string()}")
        if self.delay_s:
            time.sleep(self.delay_s)

    def _read_pin_byte(self):
        value = ctypes.c_ubyte()
        self._check(self.lib.ftdi_read_pins(self.ctx, ctypes.byref(value)), "ftdi_read_pins")
        return value.value

    def close(self):
        if self.ctx:
            self.lib.ftdi_set_bitmode(self.ctx, 0x00, BITMODE_RESET)
            self.lib.ftdi_usb_close(self.ctx)
            self.lib.ftdi_free(self.ctx)
            self.ctx = None

    def shift(self, tms_bits, tdi_bits):
        if len(tms_bits) != len(tdi_bits):
            raise ValueError("TMS and TDI vectors must have the same length")
        tdo_bits = []
        for tms, tdi in zip(tms_bits, tdi_bits):
            low = (PIN_TMS if tms else 0) | (PIN_TDI if tdi else 0)
            self._write_pin_byte(low)
            self._write_pin_byte(low | PIN_TCK)
            tdo_bits.append(1 if (self._read_pin_byte() & PIN_TDO) else 0)
            self._write_pin_byte(low)
        return tdo_bits


class FtdiMpsseJtag:
    def __init__(self, serial, vid, pid, freq_hz, tdo_bit):
        self.tdo_bit = tdo_bit
        self.lib = ctypes.CDLL("libftdi1.so")
        self._configure_signatures()
        self.ctx = self.lib.ftdi_new()
        if not self.ctx:
            raise FtdiError("ftdi_new failed")

        serial_bytes = serial.encode("ascii") if serial else None
        self._check(self.lib.ftdi_set_interface(self.ctx, FTDI_INTERFACE_A), "ftdi_set_interface")
        rc = self.lib.ftdi_usb_open_desc_index(
            self.ctx, vid, pid, None,
            ctypes.c_char_p(serial_bytes) if serial_bytes else None, 0,
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

    def _configure_signatures(self):
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

    def _error_string(self):
        raw = self.lib.ftdi_get_error_string(self.ctx)
        return raw.decode("utf-8", errors="replace") if raw else "unknown error"

    def _check(self, rc, what):
        if rc < 0:
            raise FtdiError(f"{what} failed: {rc}: {self._error_string()}")

    def _write(self, data_bytes):
        data = (ctypes.c_ubyte * len(data_bytes)).from_buffer_copy(data_bytes)
        rc = self.lib.ftdi_write_data(self.ctx, data, len(data_bytes))
        if rc != len(data_bytes):
            raise FtdiError(f"ftdi_write_data failed: {rc}: {self._error_string()}")

    def _read_exact(self, byte_count):
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
                continue
            if time.monotonic() > deadline:
                raise FtdiError(f"timed out reading {byte_count} MPSSE byte(s)")
            time.sleep(0.001)
        return bytes(result)

    def _read_available(self, byte_count):
        buf = (ctypes.c_ubyte * byte_count)()
        rc = self.lib.ftdi_read_data(self.ctx, buf, byte_count)
        if rc < 0:
            raise FtdiError(f"ftdi_read_data failed: {rc}: {self._error_string()}")
        return bytes(buf[:rc])

    def _configure_clock(self, freq_hz):
        base_hz = 60_000_000
        divisor = max(0, int((base_hz / freq_hz - 1) / 2))
        self._write(bytes([DIS_DIV_5, TCK_DIVISOR, divisor & 0xFF, (divisor >> 8) & 0xFF]))
        self._read_available(4)

    def close(self):
        if self.ctx:
            self.lib.ftdi_set_bitmode(self.ctx, 0x00, BITMODE_RESET)
            self.lib.ftdi_usb_close(self.ctx)
            self.lib.ftdi_free(self.ctx)
            self.ctx = None

    def shift(self, tms_bits, tdi_bits):
        if len(tms_bits) != len(tdi_bits):
            raise ValueError("TMS and TDI vectors must have the same length")
        tdo_bits = []
        for offset in range(0, len(tms_bits), 32):
            tdo_bits.extend(self._shift_chunk(tms_bits[offset:offset + 32], tdi_bits[offset:offset + 32]))
        return tdo_bits

    def _shift_chunk(self, tms_bits, tdi_bits):
        cmd = bytearray()
        op = MPSSE_WRITE_TMS | MPSSE_LSB | MPSSE_BITMODE | MPSSE_WRITE_NEG | MPSSE_DO_READ
        for tms, tdi in zip(tms_bits, tdi_bits):
            cmd.extend([op, 0x00, (0x80 if tdi else 0x00) | (0x01 if tms else 0x00)])
        cmd.append(SEND_IMMEDIATE)
        self._write(bytes(cmd))
        raw = self._read_exact(len(tms_bits))
        return [(byte >> self.tdo_bit) & 1 for byte in raw]


def bits_to_int(bits):
    value = 0
    for index, bit in enumerate(bits):
        value |= int(bit) << index
    return value


def clock_tms(client, tms_bits):
    if tms_bits:
        client.shift(tms_bits, [0] * len(tms_bits))


def reset_tap(client):
    clock_tms(client, [1, 1, 1, 1, 1, 1, 0])


def shift_ir(client, instruction, ir_len):
    clock_tms(client, [1, 1, 0, 0])
    tdi_bits = [(instruction >> bit) & 1 for bit in range(ir_len)]
    tms_bits = [0] * ir_len
    tms_bits[-1] = 1
    client.shift(tms_bits, tdi_bits)
    clock_tms(client, [1, 0])


def shift_dr_read(client, bit_count):
    clock_tms(client, [1, 0, 0])
    tms_bits = [0] * bit_count
    tms_bits[-1] = 1
    tdo_bits = client.shift(tms_bits, [0] * bit_count)
    clock_tms(client, [1, 0])
    return bits_to_int(tdo_bits)


def read_payload(client, ir_len, user_ir, bit_count):
    reset_tap(client)
    shift_ir(client, user_ir, ir_len)
    return shift_dr_read(client, bit_count)


def field(payload, offset, width):
    return (payload >> offset) & ((1 << width) - 1)


def decode_payload(payload, bit_count):
    debug1 = field(payload, 28, 32)
    version = field(payload, 92, 8)
    debug_startup = field(payload, 4, 24) | (field(payload, 100, 40) << 24)
    debug_calib_gate = field(payload, 140, 32)
    debug_idelay = field(payload, 172, 32)
    debug_phy_startup = field(payload, 204, 8)
    debug_phy_status = field(payload, 212, 3)
    debug_phy_sync_rst = bool(field(payload, 215, 1))
    idelay_dqs_cntvalueout_raw = field(payload, 216, 5 * BYTE_LANES)
    idelay_data_cntvalueout_raw = field(payload, 226, 5 * DQ_BITS * BYTE_LANES)
    debug_calib_abort = field(payload, 306, 64)
    debug_calib_window = field(payload, 370, 64)
    debug_calib_search = field(payload, 434, 14)
    bist_counts = field(payload, 448, 64)
    debug8 = bist_counts

    idelay_data_cntvalueout = [
        field(idelay_data_cntvalueout_raw, 5 * index, 5)
        for index in range(DQ_BITS * BYTE_LANES)
    ]
    idelay_dqs_cntvalueout = [
        field(idelay_dqs_cntvalueout_raw, 5 * index, 5)
        for index in range(BYTE_LANES)
    ]

    startup_debug = {
        "sync_rst_controller": bool(field(debug_startup, 0, 1)),
        "phy_reset": bool(field(debug_startup, 1, 1)),
        "reset_from_wb2": bool(field(debug_startup, 2, 1)),
        "reset_from_calibrate": bool(field(debug_startup, 3, 1)),
        "reset_from_test": bool(field(debug_startup, 4, 1)),
        "reset_after_rank_1": bool(field(debug_startup, 5, 1)),
        "initial_calibration_done": bool(field(debug_startup, 6, 1)),
        "final_calibration_done": bool(field(debug_startup, 7, 1)),
        "state_ever_nonzero": bool(field(debug_startup, 8, 1)),
        "state_returned_idle_after_nonzero": bool(field(debug_startup, 9, 1)),
        "reset_from_test_ever": bool(field(debug_startup, 10, 1)),
        "reset_from_calibrate_ever": bool(field(debug_startup, 11, 1)),
        "reset_from_wb2_ever": bool(field(debug_startup, 12, 1)),
        "reset_after_rank_1_ever": bool(field(debug_startup, 13, 1)),
        "idelayctrl_rdy_ever": bool(field(debug_startup, 14, 1)),
        "sync_rst_released_ever": bool(field(debug_startup, 15, 1)),
        "phy_reset_released_ever": bool(field(debug_startup, 16, 1)),
        "sync_rst_reasserted_after_release": bool(field(debug_startup, 17, 1)),
        "phy_reset_reasserted_after_release": bool(field(debug_startup, 18, 1)),
        "wrong_read_seen": bool(field(debug_startup, 19, 1)),
        "done_ever": bool(field(debug_startup, 20, 1)),
        "instruction_13_ever": bool(field(debug_startup, 21, 1)),
        "state0_ready_gate_ever": bool(field(debug_startup, 22, 1)),
        "idelay_load_seen": bool(field(debug_startup, 23, 1)),
        "idelay_data_load_seen_any": bool(field(debug_startup, 24, 1)),
        "idelay_dqs_load_seen_any": bool(field(debug_startup, 25, 1)),
        "idelay_data_tap_mismatch_seen": bool(field(debug_startup, 26, 1)),
        "idelay_dqs_tap_mismatch_seen": bool(field(debug_startup, 27, 1)),
        "last_expected_data_tap": field(debug_startup, 28, 5),
        "last_actual_data_tap": field(debug_startup, 33, 5),
        "last_expected_dqs_tap": field(debug_startup, 38, 5),
        "last_actual_dqs_tap": field(debug_startup, 43, 5),
        "cycles_since_reset_release": field(debug_startup, 48, 16),
    }

    calib_gate_debug = {
        "state_calibrate": field(debug_calib_gate, 0, 5),
        "instruction_address": field(debug_calib_gate, 5, 5),
        "idelayctrl_rdy": bool(field(debug_calib_gate, 10, 1)),
        "phy_reset": bool(field(debug_calib_gate, 11, 1)),
        "sync_rst_controller": bool(field(debug_calib_gate, 12, 1)),
        "initial_calibration_done": bool(field(debug_calib_gate, 13, 1)),
        "final_calibration_done": bool(field(debug_calib_gate, 14, 1)),
    }

    idelay_debug = {
        "data_load_seen_mask": field(debug_idelay, 0, 8),
        "dqs_load_seen_mask": field(debug_idelay, 8, 8),
        "data_mismatch_lane_mask": field(debug_idelay, 16, 8),
        "dqs_mismatch_lane_mask": field(debug_idelay, 24, 8),
        "data_cntvalueout": idelay_data_cntvalueout,
        "dqs_cntvalueout": idelay_dqs_cntvalueout,
    }

    phy_debug = {
        "sync_rst": debug_phy_sync_rst,
        "status_raw": debug_phy_status,
        "cmd_cke": bool(field(debug_phy_status, 2, 1)),
        "cmd_reset_n": bool(field(debug_phy_status, 1, 1)),
        "startup_raw": debug_phy_startup,
        "startup_sync_rst": bool(field(debug_phy_startup, 0, 1)),
        "startup_combined_ready": bool(field(debug_phy_startup, 1, 1)),
        "startup_idelayctrl_rdy": bool(field(debug_phy_startup, 2, 1)),
        "startup_dci_locked": bool(field(debug_phy_startup, 3, 1)),
    }

    abort_reason = field(debug_calib_abort, 1, 4)
    abort_read_lane_data_shifted = field(debug_calib_abort, 32, 32)
    abort_expected_word = 0xD0AD51C1
    abort_debug = {
        "seen": bool(field(debug_calib_abort, 0, 1)),
        "reason": abort_reason,
        "reason_name": {
            0: "none",
            1: "analyze_data_both_assumptions_failed",
            2: "check_starting_data_search_exhausted",
            3: "idelay_load_error",
            4: "check_starting_data_forced_read_realign",
            15: "unexpected_reset_from_calibrate_state",
        }.get(abort_reason, "unknown"),
        "lane": field(debug_calib_abort, 5, 4),
        "data_start_index": field(debug_calib_abort, 9, 6),
        "dq_target_index": field(debug_calib_abort, 15, 6),
        "start_index_check": field(debug_calib_abort, 21, 6),
        "lane_write_dq_late": bool(field(debug_calib_abort, 27, 1)),
        "lane_read_dq_early": bool(field(debug_calib_abort, 28, 1)),
        "shifted_match": bool(field(debug_calib_abort, 29, 1)),
        "read_lane_data_shifted": abort_read_lane_data_shifted,
        "read_lane_data_shifted_hex": f"0x{abort_read_lane_data_shifted:08x}",
        "expected_word": abort_expected_word,
        "expected_word_hex": f"0x{abort_expected_word:08x}",
        "read_lane_data_window": debug_calib_window,
        "read_lane_data_window_hex": f"0x{debug_calib_window:016x}",
        "best_offset": field(debug_calib_search, 0, 6),
        "best_distance": field(debug_calib_search, 6, 6),
        "best_accepted": bool(field(debug_calib_search, 12, 1)),
        "xor_with_expected": abort_read_lane_data_shifted ^ abort_expected_word,
        "xor_with_expected_hex": f"0x{(abort_read_lane_data_shifted ^ abort_expected_word):08x}",
        "state_calibrate": None,
        "instruction_address": None,
    }

    decoded = {
        "rst_n": bool(field(payload, 0, 1)),
        "clk_locked": bool(field(payload, 1, 1)),
        "bist_done": bool(field(payload, 2, 1)),
        "calib_complete": bool(field(payload, 3, 1)),
        "debug1": debug1,
        "state_calibrate": debug1 & 0x1F,
        "magic": field(payload, 60, 32),
        "version": version,
        "debug8": debug8,
        "bist_counts": bist_counts,
        "correct_read_data": field(bist_counts, 0, 32),
        "wrong_read_data": field(bist_counts, 32, 32),
        "bist_mode": BIST_MODE,
        "debug_startup": debug_startup,
        "debug_calib_gate": debug_calib_gate,
        "debug_idelay": debug_idelay,
        "debug_calib_abort": debug_calib_abort,
        "debug_calib_window": debug_calib_window,
        "debug_calib_search": debug_calib_search,
        "startup_debug": startup_debug,
        "calib_gate_debug": calib_gate_debug,
        "idelay_debug": idelay_debug,
        "phy_debug": phy_debug,
        "abort_debug": abort_debug,
    }
    reasons = []
    if decoded["magic"] != MAGIC:
        reasons.append("bad_magic")
    if decoded["version"] != VERSION:
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


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def program_bitstream(programmer, bitstream):
    command = [str(programmer), "-c", "digilent_hs3", "--bitstream", str(bitstream)]
    completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return {
        "command": command,
        "returncode": completed.returncode,
        "output": completed.stdout,
    }


def make_client(args):
    if args.backend == "mpsse":
        return FtdiMpsseJtag(args.serial, args.vid, args.pid, args.freq_hz, args.tdo_bit)
    return FtdiBitbangJtag(args.serial, args.vid, args.pid, args.bit_delay_us / 1_000_000.0)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bitstream", required=True, type=Path)
    parser.add_argument("--programmer", type=Path, default=DEFAULT_PROGRAMMER)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--no-program", action="store_true")
    parser.add_argument("--serial", default="210299BF3824")
    parser.add_argument("--vid", type=lambda value: int(value, 0), default=FTDI_VENDOR)
    parser.add_argument("--pid", type=lambda value: int(value, 0), default=FTDI_FT232H_PRODUCT)
    parser.add_argument("--backend", choices=("mpsse", "bitbang"), default="mpsse")
    parser.add_argument("--freq-hz", type=int, default=1_000_000)
    parser.add_argument("--tdo-bit", type=int, choices=(0, 7), default=7)
    parser.add_argument("--bit-delay-us", type=float, default=0.0)
    parser.add_argument("--bits", type=int, default=DEFAULT_BITS)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    return parser.parse_args()


def main():
    args = parse_args()
    started_at = datetime.now(timezone.utc).isoformat()
    bitstream = args.bitstream.resolve()
    result = {
        "started_at": started_at,
        "bitstream": str(bitstream),
        "bitstream_sha256": sha256_file(bitstream),
        "programmer": {
            "path": str(args.programmer),
            "checkout_commit": PROGRAMMER_COMMIT,
            "cable": "digilent_hs3",
        },
        "jtag": {
            "backend": f"ftdi-{args.backend}",
            "serial": args.serial,
            "bits": args.bits,
            "ir_len": args.ir_len,
            "user_ir": args.user_ir,
        },
    }

    if args.no_program:
        result["programming"] = {"skipped": True}
    else:
        result["programming"] = program_bitstream(args.programmer, bitstream)
        if result["programming"]["returncode"] != 0:
            result["pass"] = False
            result["fail_reasons"] = ["programming_failed"]
            print(json.dumps(result, indent=2, sort_keys=True))
            if args.output:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
            return 1

    client = make_client(args)
    try:
        decoded = None
        for attempt in range(1, args.poll_count + 1):
            payload = read_payload(client, args.ir_len, args.user_ir, args.bits)
            decoded = decode_payload(payload, args.bits)
            if decoded["pass"] or "wrong_read_data_nonzero" in decoded["fail_reasons"]:
                break
            if attempt < args.poll_count:
                time.sleep(args.poll_interval)
    finally:
        client.close()

    result.update(decoded)
    result["attempts"] = attempt
    result["finished_at"] = datetime.now(timezone.utc).isoformat()
    print(json.dumps(result, indent=2, sort_keys=True))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return 0 if result["pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
