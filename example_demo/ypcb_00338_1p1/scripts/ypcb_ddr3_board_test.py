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
TRACE_SCOPE_MAGIC = 0x53435032
TRACE_SCOPE_DEPTH = 64
TRACE_SCOPE_SAMPLE_BITS = 692
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
    shift_dr_read(client, 1)
    if capture_settle_cycles > 0:
        clock_tms(client, [0] * capture_settle_cycles)
    return shift_dr_read(client, bit_count)


TRACE_WB_STATUS_MARKER = 0x53


def decode_trace_wb_status(status: int) -> tuple[int, int, bool, int]:
    marker = (status >> 25) & 0x7F
    seq = (status >> 17) & 0xFF
    write = bool((status >> 16) & 0x1)
    address = status & 0xFFFF
    return marker, seq, write, address


def trace_wb_transfer(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, address: int, write: bool = False, data: int = 0, settle_cycles: int = 2048) -> tuple[int, int]:
    reset_tap(client)
    shift_ir(client, trace_ir, ir_len)
    expected_address = address & 0xFFFF
    expected_write = bool(write)
    previous_seq = getattr(client, "trace_wb_last_seq", None)
    command = expected_address | ((1 if expected_write else 0) << 16) | (1 << 17) | ((data & 0xFFFFFFFF) << 32)
    shift_dr_value(client, TRACE_SCOPE_DR_BITS, command)
    last_status = 0
    last_data = 0
    for _attempt in range(16):
        if settle_cycles > 0:
            clock_tms(client, [0] * settle_cycles)
        raw = shift_dr_value(client, TRACE_SCOPE_DR_BITS, 0)
        last_data = raw & 0xFFFFFFFF
        last_status = (raw >> 32) & 0xFFFFFFFF
        marker, seq, response_write, response_address = decode_trace_wb_status(last_status)
        fresh = previous_seq is None or seq != previous_seq
        if marker == TRACE_WB_STATUS_MARKER and fresh and response_write == expected_write and response_address == expected_address:
            client.trace_wb_last_seq = seq
            return last_data, last_status
    marker, seq, response_write, response_address = decode_trace_wb_status(last_status)
    raise RuntimeError(
        "stale trace WB response: "
        f"expected addr=0x{expected_address:04x} we={int(expected_write)} prev_seq={previous_seq}; "
        f"got marker=0x{marker:02x} seq={seq} addr=0x{response_address:04x} "
        f"we={int(response_write)} status=0x{last_status:08x} data=0x{last_data:08x}"
    )


def trace_wb_read(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, address: int, settle_cycles: int) -> int:
    data, _status = trace_wb_transfer(client, ir_len, trace_ir, address, False, 0, settle_cycles)
    return data


def trace_wb_write(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, address: int, data: int, settle_cycles: int) -> None:
    trace_wb_transfer(client, ir_len, trace_ir, address, True, data, settle_cycles)


def configure_trace_scope(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, trigger: int, holdoff: int, settle_cycles: int) -> None:
    trace_wb_write(client, ir_len, trace_ir, 0x02, holdoff & 0xFFF, settle_cycles)
    trace_wb_write(client, ir_len, trace_ir, 0x03, trigger & 0x7, settle_cycles)
    trace_wb_write(client, ir_len, trace_ir, 0x05, 0x1, settle_cycles)
    if (trigger & 0x7) == 0:
        trace_wb_write(client, ir_len, trace_ir, 0x06, 0x1, settle_cycles)


def read_trace_scope_samples(client: FtdiMpsseJtag, ir_len: int, trace_ir: int, settle_cycles: int) -> dict[str, object]:
    trace_wb_write(client, ir_len, trace_ir, 0x07, 0x1, settle_cycles)
    magic = trace_wb_read(client, ir_len, trace_ir, 0x00, settle_cycles)
    status = trace_wb_read(client, ir_len, trace_ir, 0x01, settle_cycles)
    holdoff = trace_wb_read(client, ir_len, trace_ir, 0x02, settle_cycles)
    trigger = trace_wb_read(client, ir_len, trace_ir, 0x03, settle_cycles)
    if magic != TRACE_SCOPE_MAGIC:
        return {"present": False, "magic": magic, "reason": "bad_trace_scope_magic"}
    count = field(status, 0, 12); write_index = field(status, 12, 11); trigger_select = field(status, 23, 3)
    armed = bool(field(status, 26, 1)); triggered = bool(field(status, 27, 1)); frozen = bool(field(status, 28, 1)); overflow = bool(field(status, 29, 1))
    valid_count = min(count, TRACE_SCOPE_DEPTH)
    indexes = list(range(valid_count)) if valid_count < TRACE_SCOPE_DEPTH and not overflow else [(write_index + offset) % TRACE_SCOPE_DEPTH for offset in range(valid_count)]
    samples = []
    for chronological_index, sample_index in enumerate(indexes):
        trace_wb_write(client, ir_len, trace_ir, 0x04, sample_index, settle_cycles)
        raw = 0
        for word_index in range((TRACE_SCOPE_SAMPLE_BITS + 31) // 32):
            raw |= trace_wb_read(client, ir_len, trace_ir, 0x08 + word_index, settle_cycles) << (32 * word_index)
        sample = decode_trace_scope_sample(raw); sample["chronological_index"] = chronological_index; sample["slot"] = sample_index; samples.append(sample)
    return {"present": True, "magic": magic, "status": status, "count": count, "write_index": write_index, "trigger_select": trigger_select, "holdoff": holdoff & 0xFFF, "trigger_register": trigger & 0x7, "armed": armed, "triggered": triggered, "frozen": frozen, "overflow": overflow, "samples": samples}


def field(payload: int, offset: int, width: int) -> int:
    return (payload >> offset) & ((1 << width) - 1)


def decode_payload(payload: int, bit_count: int) -> dict[str, object]:
    debug1 = field(payload, 28, 32)
    version = field(payload, 92, 8)
    bist_counts = field(payload, 448, 64)
    canonical_status_offset = 384
    canonical_status = {
        "state_calibrate": field(payload, canonical_status_offset + 0, 5),
        "instruction_address": field(payload, canonical_status_offset + 5, 5),
        "delay_counter_is_zero": bool(field(payload, canonical_status_offset + 10, 1)),
        "i_rst_n": bool(field(payload, canonical_status_offset + 11, 1)),
        "i_phy_idelayctrl_rdy": bool(field(payload, canonical_status_offset + 12, 1)),
        "o_phy_reset": bool(field(payload, canonical_status_offset + 13, 1)),
        "reset_done": bool(field(payload, canonical_status_offset + 14, 1)),
        "sync_rst_controller": bool(field(payload, canonical_status_offset + 15, 1)),
        "pause_counter": bool(field(payload, canonical_status_offset + 16, 1)),
        "delay_counter": field(payload, canonical_status_offset + 17, 19),
        "version": field(payload, canonical_status_offset + 36, 8),
        "magic": field(payload, canonical_status_offset + 44, 16),
        "addr_regress_seen": bool(field(payload, canonical_status_offset + 60, 1)),
        "sync_rst_seen": bool(field(payload, canonical_status_offset + 61, 1)),
        "reset_from_calibrate_seen": bool(field(payload, canonical_status_offset + 62, 1)),
        "external_reset_seen": bool(field(payload, canonical_status_offset + 63, 1)),
    }
    canonical_status["valid"] = canonical_status["magic"] == 0xCACE
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
        "controller_initial_addr_regress_seen": bool(field(payload, init_reset_debug_offset + 12, 1)),
        "controller_sync_rst_seen": bool(field(payload, init_reset_debug_offset + 13, 1)),
        "controller_reset_from_calibrate_seen": bool(field(payload, init_reset_debug_offset + 14, 1)),
        "controller_external_reset_seen": bool(field(payload, init_reset_debug_offset + 15, 1)),
    }
    init_seq_debug_offset = 528
    if version == 4:
        init_event_trace = []
        for index in range(7):
            event = field(payload, init_seq_debug_offset + index * 16, 16)
            init_event_trace.append({
                "index": index,
                "raw": event,
                "instruction_address": field(event, 0, 5),
                "init_timer_phase": field(event, 5, 2),
                "init_advance_ready_q": bool(field(event, 7, 1)),
                "init_advance_pending": bool(field(event, 8, 1)),
                "init_advance_now": bool(field(event, 9, 1)),
                "delay_counter_is_zero": bool(field(event, 10, 1)),
                "init_timed_counter_active": bool(field(event, 11, 1)),
                "init_counter_reaches_two": bool(field(event, 12, 1)),
                "reset_done": bool(field(event, 13, 1)),
                "instruction_use_timer_bit": bool(field(event, 14, 1)),
                "init_delay_counting_q": bool(field(event, 15, 1)),
            })
        init_seq_debug = {
            "layout": "panopticon_event_ring",
            "event_marker": field(payload, init_seq_debug_offset + 120, 8),
            "event_count": field(payload, init_seq_debug_offset + 115, 5),
            "event_write_index": field(payload, init_seq_debug_offset + 112, 3),
            "event_trace": init_event_trace,
        }
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
    else:
        init_seq_debug = {
            "layout": "live_fields",
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
    bist_debug_offset = 656
    bist_debug = {
        "expected_data": field(payload, bist_debug_offset + 0, 128),
        "actual_data": field(payload, bist_debug_offset + 128, 128),
        "byte_mismatch_mask": field(payload, bist_debug_offset + 256, 16),
        "address": field(payload, bist_debug_offset + 272, 25),
        "state_calibrate": field(payload, bist_debug_offset + 297, 5),
        "valid": bool(field(payload, bist_debug_offset + 302, 1)),
        "fail_aux": field(payload, bist_debug_offset + 304, 16),
        "fail_wb_data_q_current": field(payload, bist_debug_offset + 320, 128),
        "fail_raw_iserdes_data": field(payload, bist_debug_offset + 448, 128),
        "fail_index_wb_data": field(payload, bist_debug_offset + 576, 1),
        "fail_delay_read_pipe0": field(payload, bist_debug_offset + 577, 2),
        "fail_delay_read_pipe1": field(payload, bist_debug_offset + 579, 2),
        "fail_added_read_pipe0": bool(field(payload, bist_debug_offset + 581, 1)),
        "fail_data_start_index0": field(payload, bist_debug_offset + 582, 7),
        "fail_idelay_data_cntvaluein0": field(payload, bist_debug_offset + 589, 5),
        "fail_idelay_dqs_cntvaluein0": field(payload, bist_debug_offset + 594, 5),
        "fail_byte_index": field(payload, bist_debug_offset + 599, 4),
        "fail_burst_slot": field(payload, bist_debug_offset + 603, 3),
    }
    panopticon_debug_offset = 1266
    panopticon_control_offset = panopticon_debug_offset + 688
    read_align_context = field(payload, panopticon_debug_offset + 560, 128)
    panopticon_debug = {
        "wb_data_q_current": field(payload, panopticon_debug_offset + 0, 128),
        "stage2_dm1": field(payload, panopticon_debug_offset + 128, 16),
        "stage2_dm0": field(payload, panopticon_debug_offset + 144, 16),
        "stage2_dm_unaligned": field(payload, panopticon_debug_offset + 160, 16),
        "stage2_data1": field(payload, panopticon_debug_offset + 176, 128),
        "stage2_data0": field(payload, panopticon_debug_offset + 304, 128),
        "stage2_data_unaligned": field(payload, panopticon_debug_offset + 432, 128),
        "read_align_context_raw": read_align_context,
        "read_align_context_code": field(read_align_context, 124, 4),
        "read_align_context_state": field(read_align_context, 119, 5),
        "read_align_context_lane": field(read_align_context, 116, 3),
        "read_align_context_data_start_index": field(read_align_context, 109, 7),
        "read_align_context_start_index_check": field(read_align_context, 103, 6),
        "read_align_context_prep_done": field(read_align_context, 101, 2),
        "read_align_context_write_pattern_matches": bool(field(read_align_context, 100, 1)),
        "read_align_context_lane_write_dq_late": bool(field(read_align_context, 99, 1)),
        "read_align_context_lane_read_dq_early": bool(field(read_align_context, 98, 1)),
        "read_align_context_read_lane_data_shifted": field(read_align_context, 66, 32),
        "read_align_context_write_pattern_lane_low": field(read_align_context, 34, 32),
        "read_align_context_read_lane_data_low": field(read_align_context, 2, 32),
        "pause_counter": bool(field(payload, panopticon_control_offset + 0, 1)),
        "delay_before_read_data": field(payload, panopticon_control_offset + 1, 4),
        "stage2_update": bool(field(payload, panopticon_control_offset + 5, 1)),
        "stage2_we": bool(field(payload, panopticon_control_offset + 6, 1)),
        "stage2_pending": bool(field(payload, panopticon_control_offset + 7, 1)),
        "stage1_pending": bool(field(payload, panopticon_control_offset + 8, 1)),
        "o_wb_stall_calib": bool(field(payload, panopticon_control_offset + 9, 1)),
        "aux": field(payload, panopticon_control_offset + 10, 16),
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
        "init_sync_rst_edge_count": field(payload, panopticon_debug_offset + 776, 6),
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
        "dqs_start_index_repeat": field(payload, calib_debug_offset + 68, 3),
        "dqs_start_index": field(payload, calib_debug_offset + 71, 6),
        "dqs_start_index_stored": field(payload, calib_debug_offset + 77, 6),
        "dqs_target_index": field(payload, calib_debug_offset + 83, 6),
        "dqs_target_index_value": field(payload, calib_debug_offset + 89, 6),
        "dqs_target_index_orig": field(payload, calib_debug_offset + 95, 6),
        "dqs_store": field(payload, calib_debug_offset + 101, 40),
        "iserdes_dqs": field(payload, calib_debug_offset + 141, 16),
        "iserdes_bitslip_reference": field(payload, calib_debug_offset + 157, 16),
        "read_lane_data_shifted": field(payload, calib_debug_offset + 173, 32),
        "read_lane_data": field(payload, calib_debug_offset + 205, 64),
        "calib_bus_init_i_rst_n": bool(field(payload, calib_debug_offset + 269, 1)),
        "calib_bus_init_o_phy_reset": bool(field(payload, calib_debug_offset + 270, 1)),
        "calib_bus_init_idelayctrl_rdy": bool(field(payload, calib_debug_offset + 271, 1)),
        "init_i_rst_n": init_reset_debug["controller_i_rst_n"],
        "init_o_phy_reset": init_reset_debug["controller_o_phy_reset"],
        "init_idelayctrl_rdy": init_reset_debug["controller_i_phy_idelayctrl_rdy"],
        "init_instruction": field(payload, calib_debug_offset + 272, 28),
        "init_cmd_ck_en": bool(field(payload, calib_debug_offset + 300, 1)),
        "init_cmd_reset_n": bool(field(payload, calib_debug_offset + 301, 1)),
        "init_cmd_odt": bool(field(payload, calib_debug_offset + 302, 1)),
        "calib_bus_init_pause_counter": bool(field(payload, calib_debug_offset + 303, 1)),
        "calib_bus_init_final_calibration_done": bool(field(payload, calib_debug_offset + 304, 1)),
        "calib_bus_init_initial_calibration_done": bool(field(payload, calib_debug_offset + 305, 1)),
        "calib_bus_init_reset_from_calibrate": bool(field(payload, calib_debug_offset + 306, 1)),
        "init_pause_counter": init_reset_debug["controller_pause_counter"],
        "init_final_calibration_done": False,
        "init_initial_calibration_done": init_reset_debug["controller_initial_calibration_done"],
        "init_reset_from_calibrate": init_reset_debug["controller_reset_from_calibrate"],
        "analyze_dqs_window": field(payload, calib_debug_offset + 307, 10),
        "analyze_dqs_match": bool(field(payload, calib_debug_offset + 317, 1)),
        "analyze_dqs_at_end": bool(field(payload, calib_debug_offset + 318, 1)),
        "analyze_dqs_repeat_same": bool(field(payload, calib_debug_offset + 319, 1)),
        "analyze_dqs_repeat_done": bool(field(payload, calib_debug_offset + 320, 1)),
        "analyze_dqs_action": field(payload, calib_debug_offset + 321, 3),
        "read_align_lane_read_dq_early_live": bool(field(payload, calib_debug_offset + 324, 1)),
        "read_align_lane_write_dq_late_live": bool(field(payload, calib_debug_offset + 325, 1)),
        "read_align_prep_done_live": bool(field(payload, calib_debug_offset + 326, 1)),
        "read_align_write_pattern_matches_live": bool(field(payload, calib_debug_offset + 327, 1)),
        "read_align_reset_code": field(payload, calib_debug_offset + 328, 4),
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
        "version": version,
        "bist_counts": bist_counts,
        "correct_read_data": field(bist_counts, 0, 32),
        "wrong_read_data": field(bist_counts, 32, 32),
        "canonical_status": canonical_status,
        "calib_debug": calib_debug,
        "init_reset_debug": init_reset_debug,
        "init_seq_debug": init_seq_debug,
        "bist_debug": bist_debug,
        "panopticon_debug": panopticon_debug,
    }
    reasons: list[str] = []
    if decoded["magic"] != MAGIC:
        reasons.append("bad_magic")
    if decoded["version"] not in (VERSION, DEBUG_VERSION, 3, 4):
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



def decode_trace_scope_sample(raw: int) -> dict[str, object]:
    return {
        "raw": raw,
        "cycle": field(raw, 0, 32),
        "state_calibrate": field(raw, 32, 5),
        "state_calibrate_next": field(raw, 37, 5),
        "lane": field(raw, 42, 3),
        "read_align_invalid_retry_count": field(raw, 45, 3),
        "prep_done": field(raw, 48, 2),
        "read_align_invalid_data": bool(field(raw, 50, 1)),
        "o_wb_ack_uncalibrated": bool(field(raw, 51, 1)),
        "o_wb_stall_calib": bool(field(raw, 52, 1)),
        "index_read_pipe": bool(field(raw, 53, 1)),
        "index_wb_data": bool(field(raw, 54, 1)),
        "delay_read_pipe0": field(raw, 55, 4),
        "delay_read_pipe1": field(raw, 59, 4),
        "shift_reg_read_pipe_ack": bool(field(raw, 63, 1)),
        "shift_reg_read_pipe_aux": bool(field(raw, 64, 1)),
        "lane_capture0": bool(field(raw, 65, 1)),
        "lane_capture1": bool(field(raw, 66, 1)),
        "added_read_pipe_lane": field(raw, 67, 2),
        "added_read_pipe_max": field(raw, 69, 2),
        "data_start_index": field(raw, 71, 7),
        "start_index_check": field(raw, 78, 6),
        "iserdes_lane_burst0": field(raw, 84, 8),
        "uncal_lane_burst0": field(raw, 92, 8),
        "calib_stb": bool(field(raw, 100, 1)),
        "calib_we": bool(field(raw, 101, 1)),
        "o_phy_dqs_tri_control": bool(field(raw, 102, 1)),
        "o_phy_dq_tri_control": bool(field(raw, 103, 1)),
        "o_phy_dm_lane0": field(raw, 104, 8),
        "o_phy_data_lane0": field(raw, 112, 64),
        "cmd_read_slot": field(raw, 176, 4),
        "cmd_write_slot": field(raw, 180, 4),
        "stage0_pending": bool(field(raw, 184, 1)),
        "stage0_we": bool(field(raw, 185, 1)),
        "stage1_pending": bool(field(raw, 186, 1)),
        "stage1_we": bool(field(raw, 187, 1)),
        "stage2_pending": bool(field(raw, 188, 1)),
        "stage2_we": bool(field(raw, 189, 1)),
        "calib_aux_low": field(raw, 190, 2),
        "calib_addr_low": field(raw, 192, 4),
        "instruction_address": field(raw, 196, 5),
        "shift_reg_read_pipe0": field(raw, 201, 17),
        "shift_reg_read_pipe0_ack": bool(field(raw, 201, 1)),
        "shift_reg_read_pipe0_aux": field(raw, 202, 16),
        "o_wb_ack_read_q0": field(raw, 218, 17),
        "o_wb_ack_read_q0_ack": bool(field(raw, 218, 1)),
        "o_wb_ack_read_q0_aux": field(raw, 219, 16),
        "o_aux": field(raw, 235, 16),
        "iserdes_data_low": field(raw, 251, 32),
        "wb_data_q_current_low": field(raw, 283, 32),
        "calib_data_lane0": field(raw, 315, 64),
        "stage1_data_lane0": field(raw, 379, 64),
        "stage2_data_unaligned_lane0": field(raw, 443, 64),
        "stage2_data0_lane0": field(raw, 507, 64),
        "stage2_data1_lane0": field(raw, 571, 64),
        "calib_sel_lane0": field(raw, 635, 8),
        "stage1_dm_lane0": field(raw, 643, 8),
        "stage2_dm_unaligned_lane0": field(raw, 651, 8),
        "stage2_dm0_lane0": field(raw, 659, 8),
        "stage2_dm1_lane0": field(raw, 667, 8),
        "write_dq_pipe": field(raw, 675, 4),
        "write_dqs_pipe": field(raw, 679, 4),
        "write_dqs_val_pipe": field(raw, 683, 4),
        "late_dq0": bool(field(raw, 687, 1)),
        "lane_write_dq_late0": bool(field(raw, 688, 1)),
        "lane_read_dq_early0": bool(field(raw, 689, 1)),
        "write_dq_d": bool(field(raw, 690, 1)),
        "write_dqs_d": bool(field(raw, 691, 1)),
    }


def write_trace_vcd(path: Path, trace_scope: dict[str, object]) -> None:
    samples = trace_scope.get("samples", [])
    if not isinstance(samples, list): return
    signals = [("cycle",32),("state_calibrate",5),("state_calibrate_next",5),("lane",3),("read_align_invalid_retry_count",3),("prep_done",2),("read_align_invalid_data",1),("o_wb_ack_uncalibrated",1),("o_wb_stall_calib",1),("index_read_pipe",1),("index_wb_data",1),("delay_read_pipe0",4),("delay_read_pipe1",4),("shift_reg_read_pipe_ack",1),("shift_reg_read_pipe_aux",1),("lane_capture0",1),("lane_capture1",1),("added_read_pipe_lane",2),("added_read_pipe_max",2),("data_start_index",7),("start_index_check",6),("iserdes_lane_burst0",8),("uncal_lane_burst0",8),("calib_stb",1),("calib_we",1),("o_phy_dqs_tri_control",1),("o_phy_dq_tri_control",1),("o_phy_dm_lane0",8),("o_phy_data_lane0",64),("cmd_read_slot",4),("cmd_write_slot",4),("stage0_pending",1),("stage0_we",1),("stage1_pending",1),("stage1_we",1),("stage2_pending",1),("stage2_we",1),("calib_aux_low",2),("calib_addr_low",4),("instruction_address",5),("shift_reg_read_pipe0",17),("shift_reg_read_pipe0_ack",1),("shift_reg_read_pipe0_aux",16),("o_wb_ack_read_q0",17),("o_wb_ack_read_q0_ack",1),("o_wb_ack_read_q0_aux",16),("o_aux",16),("iserdes_data_low",32),("wb_data_q_current_low",32),("calib_data_lane0",64),("stage1_data_lane0",64),("stage2_data_unaligned_lane0",64),("stage2_data0_lane0",64),("stage2_data1_lane0",64),("calib_sel_lane0",8),("stage1_dm_lane0",8),("stage2_dm_unaligned_lane0",8),("stage2_dm0_lane0",8),("stage2_dm1_lane0",8),("write_dq_pipe",4),("write_dqs_pipe",4),("write_dqs_val_pipe",4),("late_dq0",1),("lane_write_dq_late0",1),("lane_read_dq_early0",1),("write_dq_d",1),("write_dqs_d",1)]
    ids=[chr(33+i) for i in range(len(signals))]
    with path.open("w", encoding="utf-8") as handle:
        handle.write("$timescale 12 ns $end\n$scope module ypcb_trace_scope $end\n")
        for ident,(name,width) in zip(ids,signals): handle.write(f"$var wire {width} {ident} {name} $end\n")
        handle.write("$upscope $end\n$enddefinitions $end\n")
        last={}
        for time_index,sample in enumerate(samples):
            handle.write(f"#{time_index}\n")
            for ident,(name,width) in zip(ids,signals):
                value=int(sample.get(name,0))
                if last.get(name)==value: continue
                last[name]=value
                handle.write(f"{value & 1}{ident}\n" if width==1 else f"b{value:0{width}b} {ident}\n")

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
    parser.add_argument("--trace-scope", action="store_true", help="Configure and read the USER2 BSCAN Wishbone trace scope.")
    parser.add_argument("--trace-ir", type=lambda value: int(value, 0), default=0x03)
    parser.add_argument("--trace-settle-cycles", type=int, default=2048)
    parser.add_argument("--trace-trigger", type=int, default=1, help="Trace trigger selector: -1 keep RTL boot-time scope config, 0 manual, 1 init2, 2 init2 nonzero, 3 init13, 4 DQS, 5 read-align write/read transaction, 6 success, 7 read-alignment calibration reset.")
    parser.add_argument("--trace-holdoff", type=int, default=512)
    parser.add_argument("--trace-vcd", type=Path)
    parser.add_argument("--ir-len", type=int, default=6)
    parser.add_argument("--user-ir", type=lambda value: int(value, 0), default=0x02)
    parser.add_argument("--poll-count", type=int, default=100)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--stable-samples", type=int, default=0, help="Stop polling after this many unchanged debug signatures. 0 disables.")
    parser.add_argument("--stable-min-attempt", type=int, default=10, help="Do not stable-stop before this attempt.")
    parser.add_argument("--capture-settle-cycles", type=int, default=1024)
    return parser.parse_args()


def write_result(path: Path | None, result: dict[str, object]) -> None:
    if path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


POLL_STABILITY_PATHS = [
    ("pass",),
    ("fail_reasons",),
    ("fields", "state_calibrate"),
    ("fields", "canonical_status", "valid"),
    ("fields", "canonical_status", "instruction_address"),
    ("fields", "canonical_status", "state_calibrate"),
    ("fields", "canonical_status", "reset_done"),
    ("fields", "canonical_status", "i_rst_n"),
    ("fields", "canonical_status", "i_phy_idelayctrl_rdy"),
    ("fields", "canonical_status", "o_phy_reset"),
    ("fields", "calib_debug", "instruction_address"),
    ("fields", "calib_debug", "init_i_rst_n"),
    ("fields", "calib_debug", "init_idelayctrl_rdy"),
    ("fields", "calib_debug", "init_o_phy_reset"),
    ("fields", "calib_debug", "calib_bus_init_i_rst_n"),
    ("fields", "calib_debug", "calib_bus_init_idelayctrl_rdy"),
    ("fields", "calib_debug", "calib_bus_init_o_phy_reset"),
    ("fields", "init_reset_debug", "controller_reset_done"),
    ("fields", "calib_debug", "delay_counter"),
    ("fields", "calib_debug", "delay_counter_is_zero"),
    ("fields", "init_seq_debug", "event_count"),
    ("fields", "init_seq_debug", "event_write_index"),
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
        result["programming"] = program_bitstream(args.programmer, bitstream)
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
        poll_start = time.monotonic()
        last_stability_signature = ""
        stable_signature_count = 0
        poll_stop_reason = "poll_count"
        if args.trace_scope and args.trace_trigger >= 0:
            configure_trace_scope(client, args.ir_len, args.trace_ir, args.trace_trigger, args.trace_holdoff, args.trace_settle_cycles)
        for attempt in range(1, args.poll_count + 1):
            decoded = decode_payload(read_payload(client, args.ir_len, args.user_ir, args.bits, args.capture_settle_cycles), args.bits)
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
            if "wrong_read_data_nonzero" in decoded["fail_reasons"]:
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
        if args.trace_scope:
            trace_scope = read_trace_scope_samples(client, args.ir_len, args.trace_ir, args.trace_settle_cycles)
            if args.trace_vcd and trace_scope.get("present"):
                args.trace_vcd.parent.mkdir(parents=True, exist_ok=True)
                write_trace_vcd(args.trace_vcd, trace_scope)
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
