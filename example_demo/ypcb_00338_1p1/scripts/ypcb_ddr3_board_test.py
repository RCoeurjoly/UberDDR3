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

DEFAULT_PROGRAMMER = Path(os.environ.get("OPENFPGALOADER", "/home/roland/openFPGALoader/build/openFPGALoader"))
DEFAULT_BITS = 2048
TRACE_SCOPE_DR_BITS = 72
TRACE_SCOPE_MAGIC = 0x54524345
TRACE_SCOPE_DEPTH = 32
MAGIC = 0x33445244
VERSION = 1
DEBUG_VERSION = 2
FULL_DEBUG_VERSIONS = {VERSION, DEBUG_VERSION, 3}
STATUS_DEBUG_VERSION = 4
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
        self.lib = ctypes.CDLL(os.environ.get("LIBFTDI1_SO", "libftdi1.so"))
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


def shift_dr_value(client: FtdiMpsseJtag, bit_count: int, tdi_value: int = 0) -> int:
    clock_tms(client, [1, 0, 0])
    tms_bits = [0] * bit_count
    tms_bits[-1] = 1
    tdi_bits = [(tdi_value >> bit) & 1 for bit in range(bit_count)]
    tdo_bits = client.shift(tms_bits, tdi_bits)
    clock_tms(client, [1, 0])
    return bits_to_int(tdo_bits)


def shift_dr_read(client: FtdiMpsseJtag, bit_count: int) -> int:
    return shift_dr_value(client, bit_count, 0)


def read_payload(client: FtdiMpsseJtag, ir_len: int, user_ir: int, bit_count: int, capture_settle_cycles: int) -> int:
    reset_tap(client)
    shift_ir(client, user_ir, ir_len)
    if capture_settle_cycles > 0:
        clock_tms(client, [0] * capture_settle_cycles)
    return shift_dr_read(client, bit_count)


def read_trace_scope_words(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, word_count: int, settle_cycles: int) -> list[int]:
    reset_tap(client)
    shift_ir(client, trace_ir, ir_len)
    words: list[int] = []
    for address in range(word_count):
        shift_dr_value(client, TRACE_SCOPE_DR_BITS, address)
        if settle_cycles > 0:
            clock_tms(client, [0] * settle_cycles)
        raw = shift_dr_value(client, TRACE_SCOPE_DR_BITS, address)
        words.append(raw & ((1 << 64) - 1))
    return words


def field(payload: int, offset: int, width: int) -> int:
    return (payload >> offset) & ((1 << width) - 1)


def decode_status_fields(payload: int) -> dict[str, object]:
    debug1 = field(payload, 28, 32)
    bist_counts = field(payload, 448, 64)
    correct_read_data = field(bist_counts, 0, 32)
    wrong_read_data = field(bist_counts, 32, 32)
    return {
        "rst_n": bool(field(payload, 0, 1)),
        "clk_locked": bool(field(payload, 1, 1)),
        "bist_done": bool(field(payload, 2, 1)),
        "calib_complete": bool(field(payload, 3, 1)),
        "debug1": debug1,
        "state_calibrate": debug1 & 0x1F,
        "magic": field(payload, 60, 32),
        "version": field(payload, 92, 8),
        "debug8": bist_counts,
        "bist_counts": bist_counts,
        "correct_read_data": correct_read_data,
        "wrong_read_data": wrong_read_data,
        "rtl_fullbeat": {
            "present": True,
            "source": "debug8_bist_counters",
            "mismatch_count": wrong_read_data,
            "match_count": correct_read_data,
            "pass": wrong_read_data == 0,
        },
    }


def decode_minimal_status_payload(payload: int) -> dict[str, object]:
    decoded = decode_status_fields(payload)
    decoded.update({
        "payload_layout": "status-debug8",
        "calib_debug": {"present": False, "reason": "not_in_payload"},
        "init_reset_debug": {"present": False, "reason": "not_in_payload"},
        "init_seq_debug": {"present": False, "reason": "not_in_payload"},
        "bist_debug": {"present": False, "reason": "not_in_payload"},
        "panopticon_debug": {"present": False, "reason": "not_in_payload"},
    })
    return decoded


def decode_calib_debug(payload: int, calib_debug_offset: int, byte_lanes: int, init_reset_debug: dict[str, object]) -> dict[str, object]:
    offset = calib_debug_offset

    def take(width: int) -> int:
        nonlocal offset
        value = field(payload, offset, width)
        offset += width
        return value

    calib_debug: dict[str, object] = {
        "state_calibrate": take(5),
        "instruction_address": take(5),
        "delay_counter": take(19),
        "delay_counter_is_zero": bool(take(1)),
        # lanes_clog2 is intentionally one bit even when LANES == 1.
        "lane": take(1),
        "bitslip": take(byte_lanes),
        "lane_read_dq_early": take(byte_lanes),
        "lane_write_dq_late": take(byte_lanes),
        "train_delay": take(4),
        "delay_before_read_data": take(4),
        "idelay_dqs_cntvaluein": take(5),
    }
    take(5)
    calib_debug["idelay_data_cntvaluein"] = take(5)
    take(5)
    calib_debug.update({
        # REPEAT_DQS_ANALYZE is currently 1, so reg[$clog2(REPEAT_DQS_ANALYZE):0] is one bit.
        "dqs_count_repeat": take(3),
        "dqs_start_index_repeat": take(1),
        "dqs_start_index": take(6),
        "dqs_start_index_stored": take(6),
        "dqs_target_index": take(6),
        "dqs_target_index_value": take(6),
        "dqs_target_index_orig": take(6),
        "dqs_store": take(40),
        "iserdes_dqs": take(8 * byte_lanes),
        "iserdes_bitslip_reference": take(8 * byte_lanes),
        "read_lane_data_shifted": take(32),
        "read_lane_data": take(64),
        "calib_bus_init_i_rst_n": bool(take(1)),
        "calib_bus_init_o_phy_reset": bool(take(1)),
        "calib_bus_init_idelayctrl_rdy": bool(take(1)),
        "init_i_rst_n": init_reset_debug["controller_i_rst_n"],
        "init_o_phy_reset": init_reset_debug["controller_o_phy_reset"],
        "init_idelayctrl_rdy": init_reset_debug["controller_i_phy_idelayctrl_rdy"],
        "init_instruction": take(28),
        "init_cmd_ck_en": bool(take(1)),
        "init_cmd_reset_n": bool(take(1)),
        "init_cmd_odt": bool(take(1)),
        "calib_bus_init_pause_counter": bool(take(1)),
        "calib_bus_init_final_calibration_done": bool(take(1)),
        "calib_bus_init_initial_calibration_done": bool(take(1)),
        "calib_bus_init_reset_from_calibrate": bool(take(1)),
        "init_pause_counter": init_reset_debug["controller_pause_counter"],
        "init_final_calibration_done": init_reset_debug["controller_final_calibration_done"],
        "init_initial_calibration_done": init_reset_debug["controller_initial_calibration_done"],
        "init_reset_from_calibrate": init_reset_debug["controller_reset_from_calibrate"],
        "analyze_dqs_window": take(10),
        "analyze_dqs_match": bool(take(1)),
        "analyze_dqs_at_end": bool(take(1)),
        "analyze_dqs_repeat_same": bool(take(1)),
        "analyze_dqs_repeat_done": bool(take(1)),
        "analyze_dqs_action": take(3),
    })
    calib_debug["idelay_dqs_cntvaluein_lane0"] = calib_debug["idelay_dqs_cntvaluein"]
    calib_debug["idelay_data_cntvaluein_lane0"] = calib_debug["idelay_data_cntvaluein"]
    phy_debug_offset = calib_debug_offset + 332
    calib_debug.update({
        "phy_idelayctrl_aggregate_rdy": bool(field(payload, phy_debug_offset + 0, 1)),
        "phy_idelayctrl_raw_rdy": bool(field(payload, phy_debug_offset + 1, 1)),
        "phy_dci_locked": bool(field(payload, phy_debug_offset + 2, 1)),
        "phy_sync_rst": bool(field(payload, phy_debug_offset + 3, 1)),
        "phy_reset_delay_counter": field(payload, phy_debug_offset + 4, 12),
    })
    return calib_debug


def decode_payload(payload: int, bit_count: int, byte_lanes: int = 2) -> dict[str, object]:
    version = field(payload, 92, 8)
    if version not in FULL_DEBUG_VERSIONS:
        decoded = decode_minimal_status_payload(payload)
        reasons: list[str] = []
        if decoded["magic"] != MAGIC:
            reasons.append("bad_magic")
        if decoded["version"] != STATUS_DEBUG_VERSION:
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

    status_fields = decode_status_fields(payload)
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
    init_seq_debug_offset = 528
    init_seq_debug = {
        "delay_counter_is_zero": bool(field(payload, init_seq_debug_offset + 0, 1)),
        "delay_counter_is_zero_d": bool(field(payload, init_seq_debug_offset + 1, 1)),
        "reset_done": bool(field(payload, init_seq_debug_offset + 2, 1)),
        "reset_done_d": bool(field(payload, init_seq_debug_offset + 3, 1)),
        "instruction_address": field(payload, init_seq_debug_offset + 4, 5),
        "instruction_address_d": field(payload, init_seq_debug_offset + 9, 5),
        "delay_counter": field(payload, init_seq_debug_offset + 14, 19),
        "delay_counter_d": field(payload, init_seq_debug_offset + 33, 19),
        "instruction": field(payload, init_seq_debug_offset + 52, 28),
        "instruction_d": field(payload, init_seq_debug_offset + 80, 28),
        "init_reset_done_next": bool(field(payload, init_seq_debug_offset + 108, 1)),
        "instruction_rst_done_bit": bool(field(payload, init_seq_debug_offset + 109, 1)),
        "instruction_use_timer_bit": bool(field(payload, init_seq_debug_offset + 110, 1)),
        "init_timed_counter_active": bool(field(payload, init_seq_debug_offset + 111, 1)),
        "init_counter_reaches_one": bool(field(payload, init_seq_debug_offset + 112, 1)),
        "init_counter_reaches_two": bool(field(payload, init_seq_debug_offset + 113, 1)),
        "init_advance_now": bool(field(payload, init_seq_debug_offset + 114, 1)),
        "init_advance_pending": bool(field(payload, init_seq_debug_offset + 115, 1)),
        "init_pause_counter": bool(field(payload, init_seq_debug_offset + 116, 1)),
    }
    init_event_trace = []
    for index in range(7):
        event = field(payload, init_seq_debug_offset + index * 16, 16)
        init_event_trace.append({
            "index": index,
            "raw": event,
            "instruction_rst_done_bit": bool(field(event, 0, 1)),
            "instruction_use_timer_bit": bool(field(event, 1, 1)),
            "init_advance_pending": bool(field(event, 2, 1)),
            "init_advance_now": bool(field(event, 3, 1)),
            "reset_done": bool(field(event, 4, 1)),
            "delay_counter_is_zero": bool(field(event, 5, 1)),
            "instruction_address_d": field(event, 6, 5),
            "instruction_address": field(event, 11, 5),
        })
    init_seq_debug["event_marker"] = field(payload, init_seq_debug_offset + 120, 8)
    init_seq_debug["event_count"] = field(payload, init_seq_debug_offset + 115, 5)
    init_seq_debug["event_write_index"] = field(payload, init_seq_debug_offset + 112, 3)
    init_seq_debug["event_trace"] = init_event_trace
    event_valid_count = min(init_seq_debug["event_count"], 7)
    if init_seq_debug["event_count"] <= 7:
        ordered_indexes = list(range(event_valid_count))
    else:
        ordered_indexes = [
            (init_seq_debug["event_write_index"] + offset) % 7
            for offset in range(event_valid_count)
        ]
    init_seq_debug["event_trace_ordered"] = [
        dict(init_event_trace[index], chronological_index=order)
        for order, index in enumerate(ordered_indexes)
    ]
    bist_debug_offset = 656
    bist_debug = {
        "expected_data": field(payload, bist_debug_offset + 0, 128),
        "actual_data": field(payload, bist_debug_offset + 128, 128),
        "byte_mismatch_mask": field(payload, bist_debug_offset + 256, 16),
        "address": field(payload, bist_debug_offset + 272, 25),
        "state_calibrate": field(payload, bist_debug_offset + 297, 5),
        "valid": bool(field(payload, bist_debug_offset + 302, 1)),
        "fail_index_wb_data": field(payload, bist_debug_offset + 303, 1),
        "fail_delay_read_pipe0": field(payload, bist_debug_offset + 304, 2),
        "fail_delay_read_pipe1": field(payload, bist_debug_offset + 306, 2),
        "fail_added_read_pipe0": bool(field(payload, bist_debug_offset + 308, 1)),
        "fail_data_start_index0": field(payload, bist_debug_offset + 309, 7),
        "fail_idelay_data_cntvaluein0": field(payload, bist_debug_offset + 316, 5),
        "fail_idelay_dqs_cntvaluein0": field(payload, bist_debug_offset + 321, 5),
        "fail_added_read_pipe1": bool(field(payload, bist_debug_offset + 326, 1)),
        "fail_data_start_index1": field(payload, bist_debug_offset + 327, 7),
        "fail_idelay_data_cntvaluein1": field(payload, bist_debug_offset + 334, 5),
        "fail_idelay_dqs_cntvaluein1": field(payload, bist_debug_offset + 339, 5),
        "fail_wb_data_q_current": field(payload, bist_debug_offset + 344, 128),
        "fail_raw_iserdes_data": field(payload, bist_debug_offset + 472, 128),
        "fail_byte_index": field(payload, bist_debug_offset + 600, 4),
        "fail_burst_slot": field(payload, bist_debug_offset + 604, 3),
    }
    panopticon_debug_offset = 1266
    panopticon_control_offset = panopticon_debug_offset + 688
    panopticon_aux = field(payload, panopticon_control_offset + 10, 16)
    panopticon_debug = {
        "wb_data_q_current": field(payload, panopticon_debug_offset + 0, 128),
        "stage2_dm1": field(payload, panopticon_debug_offset + 128, 16),
        "stage2_dm0": field(payload, panopticon_debug_offset + 144, 16),
        "stage2_dm_unaligned": field(payload, panopticon_debug_offset + 160, 16),
        "stage2_data1": field(payload, panopticon_debug_offset + 176, 128),
        "stage2_data0": field(payload, panopticon_debug_offset + 304, 128),
        "stage2_data_unaligned": field(payload, panopticon_debug_offset + 432, 128),
        "cmd": field(payload, panopticon_debug_offset + 560, 128),
        "pause_counter": bool(field(payload, panopticon_control_offset + 0, 1)),
        "delay_before_read_data": field(payload, panopticon_control_offset + 1, 4),
        "stage2_update": bool(field(payload, panopticon_control_offset + 5, 1)),
        "stage2_we": bool(field(payload, panopticon_control_offset + 6, 1)),
        "stage2_pending": bool(field(payload, panopticon_control_offset + 7, 1)),
        "stage1_pending": bool(field(payload, panopticon_control_offset + 8, 1)),
        "o_wb_stall_calib": bool(field(payload, panopticon_control_offset + 9, 1)),
        "aux": panopticon_aux,
        "analyze_dqs_count_repeat": field(panopticon_aux, 0, 3),
        "analyze_dqs_start_index": field(panopticon_aux, 3, 6),
        "analyze_dqs_match": bool(field(panopticon_aux, 9, 1)),
        "analyze_dqs_at_end": bool(field(panopticon_aux, 10, 1)),
        "analyze_dqs_repeat_same": bool(field(panopticon_aux, 11, 1)),
        "analyze_dqs_repeat_done": bool(field(panopticon_aux, 12, 1)),
        "analyze_dqs_action": field(panopticon_aux, 13, 3),
        "o_wb_ack_uncalibrated": bool(field(payload, panopticon_control_offset + 26, 1)),
        "lane_read_dq_early0": bool(field(payload, panopticon_control_offset + 27, 1)),
        "lane_write_dq_late0": bool(field(payload, panopticon_control_offset + 28, 1)),
        "idelay_dqs_cntvaluein0": field(payload, panopticon_control_offset + 29, 5),
        "idelay_data_cntvaluein0": field(payload, panopticon_control_offset + 34, 5),
        "data_start_index0": field(payload, panopticon_control_offset + 39, 7),
        "added_read_pipe0": bool(field(payload, panopticon_control_offset + 46, 1)),
        "delay_read_pipe1": field(payload, panopticon_control_offset + 47, 2),
        "delay_read_pipe0": field(payload, panopticon_control_offset + 49, 2),
        "index_read_pipe": bool(field(payload, panopticon_control_offset + 51, 1)),
        "index_wb_data": bool(field(payload, panopticon_control_offset + 52, 1)),
        "lane0": bool(field(payload, panopticon_control_offset + 53, 1)),
        "instruction_address": field(payload, panopticon_control_offset + 54, 5),
        "state_calibrate": field(payload, panopticon_control_offset + 59, 5),
        "marker": field(payload, panopticon_debug_offset + 752, 8),
    }
    byte_mismatch_mask = bist_debug["byte_mismatch_mask"]
    fail_byte_index = 0
    for byte_index in range(16):
        if byte_mismatch_mask & (1 << byte_index):
            fail_byte_index = byte_index
            break
    bist_debug["fail_byte_index"] = fail_byte_index
    bist_debug["fail_burst_slot"] = fail_byte_index // 2

    calib_debug_offset = 100
    calib_debug = decode_calib_debug(payload, calib_debug_offset, byte_lanes, init_reset_debug)
    decoded = {
        **status_fields,
        "payload_layout": "full-debug",
        "calib_debug": calib_debug,
        "init_reset_debug": init_reset_debug,
        "init_seq_debug": init_seq_debug,
        "bist_debug": bist_debug,
        "panopticon_debug": panopticon_debug,
    }
    reasons: list[str] = []
    if decoded["magic"] != MAGIC:
        reasons.append("bad_magic")
    if decoded["version"] not in FULL_DEBUG_VERSIONS:
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



def decode_trace_scope_event(raw: int) -> dict[str, object]:
    return {
        "raw": raw,
        "delta_cycles": field(raw, 53, 11),
        "instruction_address": field(raw, 0, 5),
        "instruction_address_d": field(raw, 5, 5),
        "state_calibrate": field(raw, 10, 5),
        "delay_counter": field(raw, 15, 19),
        "init_timer_phase": field(raw, 34, 2),
        "delay_counter_is_zero": bool(field(raw, 36, 1)),
        "init_advance_now": bool(field(raw, 37, 1)),
        "init_advance_pending": bool(field(raw, 38, 1)),
        "init_advance_ready_q": bool(field(raw, 39, 1)),
        "init_calib_start_now": bool(field(raw, 40, 1)),
        "init_calib_start_q": bool(field(raw, 41, 1)),
        "reset_done": bool(field(raw, 42, 1)),
        "sync_rst_controller": bool(field(raw, 43, 1)),
        "o_phy_reset": bool(field(raw, 44, 1)),
        "i_phy_idelayctrl_rdy": bool(field(raw, 45, 1)),
        "pause_counter": bool(field(raw, 46, 1)),
        "instruction_use_timer_bit": bool(field(raw, 47, 1)),
        "instruction_rst_done_bit": bool(field(raw, 48, 1)),
        "init_prefetch_ready": bool(field(raw, 49, 1)),
        "init_timed_counter_active": bool(field(raw, 50, 1)),
        "init_counter_reaches_one": bool(field(raw, 51, 1)),
        "init_counter_reaches_two": bool(field(raw, 52, 1)),
    }


def decode_trace_scope_words(words: list[int]) -> dict[str, object] | None:
    if not words:
        return None
    header = words[0]
    if field(header, 0, 32) != TRACE_SCOPE_MAGIC:
        return {
            "present": False,
            "raw_header": header,
            "reason": "bad_trace_magic",
        }
    version = field(header, 32, 8)
    count = field(header, 40, 8)
    write_index = field(header, 48, 7)
    frozen = bool(field(header, 55, 1))
    overflow = bool(field(header, 56, 1))
    slots = []
    for index, raw in enumerate(words[1:1 + TRACE_SCOPE_DEPTH]):
        event = decode_trace_scope_event(raw)
        event["slot"] = index
        slots.append(event)
    valid_count = min(count, TRACE_SCOPE_DEPTH)
    if valid_count < TRACE_SCOPE_DEPTH and not overflow:
        ordered_indexes = list(range(valid_count))
    else:
        ordered_indexes = [(write_index + offset) % TRACE_SCOPE_DEPTH for offset in range(valid_count)]
    ordered = []
    cycle = 0
    for chronological_index, slot_index in enumerate(ordered_indexes):
        event = dict(slots[slot_index])
        cycle += int(event["delta_cycles"])
        event["chronological_index"] = chronological_index
        event["approx_cycle"] = cycle
        ordered.append(event)
    return {
        "present": True,
        "version": version,
        "count": count,
        "write_index": write_index,
        "frozen": frozen,
        "overflow": overflow,
        "events": ordered,
        "slots": slots,
    }

def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def program_bitstream(programmer: Path, bitstream: Path, serial: str) -> dict[str, object]:
    command = [str(programmer), "-c", "digilent_hs3", "--ftdi-serial", serial, str(bitstream)]
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
    parser.add_argument("--byte-lanes", type=int, choices=(1, 2, 4, 8), default=2, help="DDR3 byte lanes in the debug bitstream.")
    parser.add_argument("--trace-scope", action="store_true", help="Read the USER2 BSCAN addressed trace scope.")
    parser.add_argument("--trace-ir", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--trace-settle-cycles", type=int, default=2048)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--stable-samples", type=int, default=0, help="Stop polling after this many unchanged debug signatures. 0 disables.")
    parser.add_argument("--stable-min-attempt", type=int, default=10, help="Do not stable-stop before this attempt.")
    parser.add_argument("--capture-settle-cycles", type=int, default=1024)
    parser.add_argument("--continue-on-wrong-read-data", action="store_true",
        help="Keep polling after wrong_read_data_nonzero; useful for calibration diagnostics.")
    return parser.parse_args()


def write_result(path: Path | None, result: dict[str, object]) -> None:
    if path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


POLL_STABILITY_PATHS = [
    ("pass",),
    ("fail_reasons",),
    ("fields", "state_calibrate"),
    ("fields", "calib_debug", "instruction_address"),
    ("fields", "calib_debug", "init_i_rst_n"),
    ("fields", "calib_debug", "init_idelayctrl_rdy"),
    ("fields", "calib_debug", "init_o_phy_reset"),
    ("fields", "calib_debug", "calib_bus_init_i_rst_n"),
    ("fields", "calib_debug", "calib_bus_init_idelayctrl_rdy"),
    ("fields", "calib_debug", "calib_bus_init_o_phy_reset"),
    ("fields", "init_reset_debug", "controller_reset_done"),
    ("fields", "panopticon_debug", "marker"),
    ("fields", "panopticon_debug", "state_calibrate"),
    ("fields", "panopticon_debug", "instruction_address"),
    ("fields", "bist_debug", "valid"),
    ("fields", "bist_debug", "byte_mismatch_mask"),
]


def get_path(data: object, path: tuple[str, ...]) -> object:
    current = data
    for key in path:
        if not isinstance(current, dict):
            return ""
        current = current.get(key, "")
    return current


def poll_stability_signature(decoded: dict[str, object]) -> str:
    signature = {".".join(path): get_path(decoded, path) for path in POLL_STABILITY_PATHS}
    encoded = json.dumps(signature, sort_keys=True, separators=(",", ":"), default=str).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def stable_stop_allowed(decoded: dict[str, object]) -> bool:
    fields = decoded.get("fields", {})
    if not isinstance(fields, dict):
        return False
    state = int(fields.get("state_calibrate", 0))
    if 17 <= state < CALIB_DONE_STATE:
        return False
    if fields.get("calib_complete") or fields.get("bist_done"):
        return False
    return True


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
        result["programming"] = program_bitstream(args.programmer, bitstream, args.serial)
        if result["programming"]["returncode"] != 0:
            result.update({"pass": False, "fail_reasons": ["programming_failed"]})
            write_result(args.output, result)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 1

    client = FtdiMpsseJtag(args.serial, args.vid, args.pid, args.freq_hz, args.tdo_bit)
    try:
        decoded = None
        trace_scope = None
        poll_samples: list[dict[str, object]] = []
        if args.trace_scope:
            trace_scope = decode_trace_scope_words(read_trace_scope_words(client, args.ir_len, args.trace_ir, TRACE_SCOPE_DEPTH + 1, args.trace_settle_cycles))
        poll_start = time.monotonic()
        last_stability_signature = ""
        stable_signature_count = 0
        poll_stop_reason = "poll_count"
        for attempt in range(1, args.poll_count + 1):
            decoded = decode_payload(read_payload(client, args.ir_len, args.user_ir, args.bits, args.capture_settle_cycles), args.bits, args.byte_lanes)
            stability_signature = poll_stability_signature(decoded)
            if stability_signature == last_stability_signature:
                stable_signature_count += 1
            else:
                last_stability_signature = stability_signature
                stable_signature_count = 1
            poll_samples.append({
                "attempt": attempt,
                "elapsed_s": round(time.monotonic() - poll_start, 6),
                "stability_signature": stability_signature[:16],
                "stable_signature_count": stable_signature_count,
                **decoded,
            })
            if decoded["pass"]:
                poll_stop_reason = "pass"
                break
            if "wrong_read_data_nonzero" in decoded["fail_reasons"] and not args.continue_on_wrong_read_data:
                poll_stop_reason = "wrong_read_data_nonzero"
                break
            if (
                args.stable_samples
                and attempt >= args.stable_min_attempt
                and stable_signature_count >= args.stable_samples
                and stable_stop_allowed(decoded)
            ):
                poll_stop_reason = "stable_debug_signature"
                break
            if attempt < args.poll_count:
                time.sleep(args.poll_interval)
    finally:
        client.close()

    result["poll_samples"] = poll_samples
    result.update(decoded or {})
    if trace_scope is not None:
        result.setdefault("fields", {})["trace_scope"] = trace_scope
    result["attempts"] = attempt
    result["poll_stop_reason"] = poll_stop_reason
    result["stable_signature_count"] = stable_signature_count
    result["stability_signature"] = last_stability_signature[:16]
    result["finished_at"] = datetime.now(timezone.utc).isoformat()
    write_result(args.output, result)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result.get("pass") else 2


if __name__ == "__main__":
    raise SystemExit(main())
