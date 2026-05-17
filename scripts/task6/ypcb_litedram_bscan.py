#!/usr/bin/env python3
"""Read/control the raw-BSCAN LiteDRAM BIST bridge on the YPCB OpenXC7 design."""

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
from read_jtag_debug_xvc import reset_tap, shift_dr_read, shift_ir
from write_jtag_command_ftdi_bitbang import shift_dr_write


READ_MAGIC = 0x4C445244
WRITE_MAGIC = 0x4C44434E

OP_WRITE_SCRATCH = 0x01
OP_CLEAR_SCRATCH = 0x02
OP_START_GEN = 0x10
OP_START_CHECK = 0x11
OP_RESET_BIST = 0x12
OP_SET_BASE = 0x20
OP_SET_LENGTH = 0x21
OP_SET_RANDOM = 0x22
OP_WB_WRITE = 0x30
OP_WB_READ = 0x31
OP_APPLY_RDLY = 0x40
OP_MEM32_CHECK = 0x41
OP_DFII_PATTERN = 0x42
OP_CLEAR_PHY_SAMPLE = 0x43

DFII_CONTROL_SEL = 0x01
DFII_CONTROL_CKE = 0x02
DFII_CONTROL_ODT = 0x04
DFII_CONTROL_RESET_N = 0x08

DFII_CONTROL_SOFTWARE = DFII_CONTROL_CKE | DFII_CONTROL_ODT | DFII_CONTROL_RESET_N
DFII_CONTROL_HARDWARE = DFII_CONTROL_SEL

DFII_COMMAND_CS = 0x01
DFII_COMMAND_WE = 0x02
DFII_COMMAND_CAS = 0x04
DFII_COMMAND_RAS = 0x08
DFII_COMMAND_WRDATA = 0x10
DFII_COMMAND_RDDATA = 0x20

CSR_DDRPHY_RST = 0x0800
CSR_DDRPHY_DLY_SEL = 0x0804
CSR_DDRPHY_WLEVEL_EN = 0x080C
CSR_DDRPHY_WLEVEL_STROBE = 0x0810
CSR_DDRPHY_RDLY_DQ_RST = 0x0814
CSR_DDRPHY_RDLY_DQ_INC = 0x0818
CSR_DDRPHY_RDLY_DQ_BITSLIP_RST = 0x081C
CSR_DDRPHY_RDLY_DQ_BITSLIP = 0x0820
CSR_DDRPHY_RDPHASE = 0x082C
CSR_DDRPHY_WRPHASE = 0x0830
CSR_SDRAM_DFII_CONTROL = 0x1800
CSR_SDRAM_DFII_PI0_COMMAND = 0x1804
CSR_SDRAM_DFII_PI0_COMMAND_ISSUE = 0x1808
CSR_SDRAM_DFII_PI0_ADDRESS = 0x180C
CSR_SDRAM_DFII_PI0_BADDRESS = 0x1810
CSR_SDRAM_DFII_PI0_WRDATA = 0x1814
CSR_SDRAM_DFII_PI0_RDDATA = 0x181C

SDRAM_PHY_XDR = 2
SDRAM_PHY_DFI_DATABITS = 64
SDRAM_PHY_PHASES = 4
SDRAM_PHY_RDPHASE = 1
SDRAM_PHY_WRPHASE = 2
SDRAM_PHY_DQ_DQS_RATIO = 8
SDRAM_PHY_MODULES = 4
SDRAM_PHY_DELAYS = 32
SDRAM_PHY_BITSLIPS = 8
DFII_PIX_DATA_BYTES = SDRAM_PHY_DFI_DATABITS // 8
READ_LEVELING_SEEDS = (42, 84, 36)
READ_CHECK_TEST_PATTERN_MAX_ERRORS = (
    8 * SDRAM_PHY_PHASES * DFII_PIX_DATA_BYTES // SDRAM_PHY_MODULES
)
MODULE_BITMASK = (1 << SDRAM_PHY_DQ_DQS_RATIO) - 1
MR1_WRITE_LEVELING_ENABLE = 1 << 7
MR1_TDQS_ENABLE = 1 << 11


def phy_timing(sys_clk_freq: float) -> dict[str, int]:
    """Match the LiteDRAM-generated sdram_phy.h values for the tested YPCB builds."""
    if sys_clk_freq <= 110e6:
        return {"cl": 7, "cwl": 5, "rdphase": 2, "wrphase": 3, "mr0": 0x0930, "mr2": 0x0200}
    return {"cl": 8, "cwl": 6, "rdphase": 1, "wrphase": 2, "mr0": 0x0940, "mr2": 0x0208}


def ddr3_mr1(tdqs: bool = False, override: int | None = None) -> int:
    if override is not None:
        value = override
    else:
        value = 0x0006
    if tdqs:
        value |= MR1_TDQS_ENABLE
    return value


def ddr3_mr1_write_leveling(tdqs: bool = False, override: int | None = None) -> int:
    return ddr3_mr1(tdqs=tdqs, override=override) | MR1_WRITE_LEVELING_ENABLE


def litedram_ddr3_init_sequence(
    sys_clk_freq: float,
    tdqs: bool = False,
    mr1: int | None = None,
) -> tuple[tuple[str, int, int, int, int, str], ...]:
    timing = phy_timing(sys_clk_freq)
    command = DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS
    mr1_value = ddr3_mr1(tdqs=tdqs, override=mr1)
    return (
        ("Release reset", 0x0000, 0, DFII_CONTROL_ODT | DFII_CONTROL_RESET_N, 50000, "control"),
        ("Bring CKE high", 0x0000, 0, DFII_CONTROL_SOFTWARE, 10000, "control"),
        (f"Load Mode Register 2, CWL={timing['cwl']}", timing["mr2"], 2, command, 0, "command"),
        ("Load Mode Register 3", 0x0000, 3, command, 0, "command"),
        (f"Load Mode Register 1 = 0x{mr1_value:04x}", mr1_value, 1, command, 0, "command"),
        (f"Load Mode Register 0, CL={timing['cl']}, BL=8", timing["mr0"], 0, command, 200, "command"),
        ("ZQ Calibration", 0x0400, 0, DFII_COMMAND_WE | DFII_COMMAND_CS, 200, "command"),
    )


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


def decode_status(value: int) -> dict[str, int | str | bool]:
    alignment = "direct"
    if (value & 0xFFFFFFFF) == ((READ_MAGIC << 1) & 0xFFFFFFFF):
        value >>= 1
        alignment = "right-shift-1"
    magic = value & 0xFFFFFFFF
    scratch = (value >> 32) & 0xFFFFFFFF
    counter = (value >> 64) & 0xFFFFFFFF
    command_count = (value >> 96) & 0xFFFF
    last_opcode = (value >> 112) & 0xFF
    status = (value >> 120) & 0xFF
    base = (value >> 128) & 0xFFFFFFFF
    length = (value >> 160) & 0xFFFFFFFF
    generator_ticks = (value >> 192) & 0xFFFFFFFF
    checker_ticks = (value >> 224) & 0xFFFFFFFF
    checker_errors = (value >> 256) & 0xFFFFFFFF
    byte_group_mask = (value >> 288) & 0xFFFFFFFF
    clkin_counter = (value >> 320) & 0xFFFFFFFF
    idelay_counter = (value >> 352) & 0xFFFFFFFF
    wb_addr = (value >> 384) & 0xFFFFFFFF
    wb_wdata = (value >> 416) & 0xFFFFFFFF
    wb_rdata = (value >> 448) & 0xFFFFFFFF
    wb_status = (value >> 480) & 0xFF
    wb_count = (value >> 488) & 0xFFFF
    diag_active = (value >> 511) & 0x1
    diag_state = (value >> 512) & 0xFF
    diag_status = (value >> 520) & 0xFF
    diag_opcode = (value >> 528) & 0xFF
    diag_module_mask = (value >> 536) & 0xFF
    diag_bitslip = (value >> 544) & 0xFF
    diag_delay = (value >> 552) & 0xFF
    diag_addr = (value >> 560) & 0xFFFFFFFF
    diag_expected = (value >> 592) & 0xFFFFFFFF
    diag_actual = (value >> 624) & 0xFFFFFFFF
    diag_count = (value >> 656) & 0xFFFFFFFF
    diag_error_count = (value >> 688) & 0xFFFFFFFF
    ddr_dq_now = (value >> 768) & 0xFFFFFFFF
    ddr_dq_seen_high = (value >> 800) & 0xFFFFFFFF
    ddr_dq_seen_low = (value >> 832) & 0xFFFFFFFF
    ddr_dq_toggle_seen = (value >> 864) & 0xFFFFFFFF
    ddr_dqs_status = (value >> 896) & 0xFFFFFFFF
    ddr_dqs_p_seen_high = ddr_dqs_status & 0xF
    ddr_dqs_n_seen_high = (ddr_dqs_status >> 4) & 0xF
    ddr_dqs_p_seen_low = (ddr_dqs_status >> 8) & 0xF
    ddr_dqs_n_seen_low = (ddr_dqs_status >> 12) & 0xF
    ddr_dqs_p_toggle_seen = (ddr_dqs_status >> 16) & 0xF
    ddr_dqs_n_toggle_seen = (ddr_dqs_status >> 20) & 0xF
    ddr_phase_status = (value >> 928) & 0xFFFFFFFF
    ddr_phase_nonzero_now = ddr_phase_status & 0xF
    ddr_phase_nonzero_seen = (ddr_phase_status >> 4) & 0xF
    ddr_phase_nonzero_toggle_seen = (ddr_phase_status >> 8) & 0xF
    ddr_phase_first_mask = (ddr_phase_status >> 12) & 0xF
    ddr_phase_first_valid = (ddr_phase_status >> 16) & 0x1
    ddr_phase_seen_high = (value >> 960) & 0xFFFFFFFF
    ddr_phase_first_word = (value >> 992) & 0xFFFFFFFF
    return {
        "raw": f"0x{value:0256x}",
        "alignment": alignment,
        "magic": f"0x{magic:08x}",
        "magic_ok": magic == READ_MAGIC,
        "scratch": f"0x{scratch:08x}",
        "scratch_int": scratch,
        "counter": f"0x{counter:08x}",
        "counter_int": counter,
        "command_count": command_count,
        "last_opcode": f"0x{last_opcode:02x}",
        "status": f"0x{status:02x}",
        "sys_reset_deasserted": bool(status & 0x01),
        "pll_locked": bool(status & 0x02),
        "generator_done": bool(status & 0x04),
        "checker_done": bool(status & 0x08),
        "checker_has_errors": bool(status & 0x10),
        "rst_n_raw": bool(status & 0x20),
        "base": f"0x{base:08x}",
        "base_int": base,
        "length": f"0x{length:08x}",
        "length_int": length,
        "generator_ticks": generator_ticks,
        "checker_ticks": checker_ticks,
        "checker_errors": checker_errors,
        "byte_group_mask": f"0x{byte_group_mask:08x}",
        "clkin_counter": clkin_counter,
        "idelay_counter": idelay_counter,
        "wb_addr": f"0x{wb_addr:08x}",
        "wb_addr_int": wb_addr,
        "wb_wdata": f"0x{wb_wdata:08x}",
        "wb_wdata_int": wb_wdata,
        "wb_rdata": f"0x{wb_rdata:08x}",
        "wb_rdata_int": wb_rdata,
        "wb_status": f"0x{wb_status:02x}",
        "wb_busy": bool(wb_status & 0x01),
        "wb_done": bool(wb_status & 0x02),
        "wb_timeout": bool(wb_status & 0x04),
        "wb_error": bool(wb_status & 0x08),
        "wb_count": wb_count,
        "diag_active": bool(diag_active),
        "diag_state": diag_state,
        "diag_status": f"0x{diag_status:02x}",
        "diag_opcode": f"0x{diag_opcode:02x}",
        "diag_module_mask": f"0x{diag_module_mask:02x}",
        "diag_module_mask_int": diag_module_mask,
        "diag_bitslip": diag_bitslip,
        "diag_delay": diag_delay,
        "diag_addr": f"0x{diag_addr:08x}",
        "diag_addr_int": diag_addr,
        "diag_expected": f"0x{diag_expected:08x}",
        "diag_expected_int": diag_expected,
        "diag_actual": f"0x{diag_actual:08x}",
        "diag_actual_int": diag_actual,
        "diag_count": diag_count,
        "diag_error_count": diag_error_count,
        "ddr_dq_now": f"0x{ddr_dq_now:08x}",
        "ddr_dq_seen_high": f"0x{ddr_dq_seen_high:08x}",
        "ddr_dq_seen_low": f"0x{ddr_dq_seen_low:08x}",
        "ddr_dq_toggle_seen": f"0x{ddr_dq_toggle_seen:08x}",
        "ddr_dqs_p_seen_high": f"0x{ddr_dqs_p_seen_high:x}",
        "ddr_dqs_n_seen_high": f"0x{ddr_dqs_n_seen_high:x}",
        "ddr_dqs_p_seen_low": f"0x{ddr_dqs_p_seen_low:x}",
        "ddr_dqs_n_seen_low": f"0x{ddr_dqs_n_seen_low:x}",
        "ddr_dqs_p_toggle_seen": f"0x{ddr_dqs_p_toggle_seen:x}",
        "ddr_dqs_n_toggle_seen": f"0x{ddr_dqs_n_toggle_seen:x}",
        "ddr_phase_nonzero_now": f"0x{ddr_phase_nonzero_now:x}",
        "ddr_phase_nonzero_seen": f"0x{ddr_phase_nonzero_seen:x}",
        "ddr_phase_nonzero_toggle_seen": f"0x{ddr_phase_nonzero_toggle_seen:x}",
        "ddr_phase_first_valid": bool(ddr_phase_first_valid),
        "ddr_phase_first_mask": f"0x{ddr_phase_first_mask:x}",
        "ddr_phase_seen_high": f"0x{ddr_phase_seen_high:08x}",
        "ddr_phase_first_word": f"0x{ddr_phase_first_word:08x}",
    }


def read_status(client, args: argparse.Namespace) -> dict[str, int | str | bool]:
    reset_tap(client)
    shift_ir(client, args.read_ir, args.ir_len)
    return decode_status(shift_dr_read(client, args.read_bits))


def write_command(
    client,
    args: argparse.Namespace,
    opcode: int,
    data: int = 0,
    addr: int = 0,
) -> None:
    command = encode_command(opcode, addr=addr, data=data)
    reset_tap(client)
    shift_ir(client, args.write_ir, args.ir_len)
    shift_dr_write(client, command, args.write_bits, args.update_mode)


def encode_command(opcode: int, addr: int = 0, data: int = 0) -> int:
    return (
        WRITE_MAGIC
        | ((opcode & 0xFF) << 32)
        | ((addr & 0xFFFFFFFF) << 40)
        | ((data & 0xFFFFFFFF) << 72)
    )


def decode_command(command: int) -> dict[str, int | bool]:
    return {
        "magic_ok": (command & 0xFFFFFFFF) == WRITE_MAGIC,
        "opcode": (command >> 32) & 0xFF,
        "addr": (command >> 40) & 0xFFFFFFFF,
        "data": (command >> 72) & 0xFFFFFFFF,
    }


def wishbone_transaction(
    client,
    args: argparse.Namespace,
    opcode: int,
    addr: int,
    data: int = 0,
) -> dict[str, object]:
    before = read_status(client, args)
    write_command(client, args, opcode, data=data, addr=addr)
    deadline = time.monotonic() + args.timeout_s
    samples = []
    while True:
        sample = read_status(client, args)
        samples.append(sample)
        if sample["wb_count"] != before["wb_count"] and not sample["wb_busy"]:
            passed = (
                sample["magic_ok"]
                and sample["wb_done"]
                and not sample["wb_timeout"]
                and not sample["wb_error"]
            )
            expected_data = args.expected_data
            if opcode == OP_WB_READ and expected_data is not None:
                expected_data &= 0xFFFFFFFF
                actual_data = sample["wb_rdata_int"]
                passed = passed and actual_data == expected_data
                return {
                    "before": before,
                    "after": sample,
                    "samples": samples,
                    "expected_data": f"0x{expected_data:08x}",
                    "actual_data": f"0x{actual_data:08x}",
                    "data_match": actual_data == expected_data,
                    "pass": passed,
                }
            return {"before": before, "after": sample, "samples": samples, "pass": passed}
        if time.monotonic() >= deadline:
            return {"before": before, "samples": samples, "pass": False, "timeout": True}
        time.sleep(args.poll_s)


def wb_write_checked(client, args: argparse.Namespace, addr: int, data: int) -> dict[str, object]:
    result = wishbone_transaction(client, args, OP_WB_WRITE, addr, data)
    if not result["pass"]:
        raise RuntimeError(f"Wishbone write failed at 0x{addr:08x}: {json.dumps(result, sort_keys=True)}")
    return result


def wb_read_checked(client, args: argparse.Namespace, addr: int) -> tuple[int, dict[str, object]]:
    result = wishbone_transaction(client, args, OP_WB_READ, addr)
    if not result["pass"]:
        raise RuntimeError(f"Wishbone read failed at 0x{addr:08x}: {json.dumps(result, sort_keys=True)}")
    return result["after"]["wb_rdata_int"], result


def phase_reg(phase: int, offset: int) -> int:
    return CSR_SDRAM_DFII_CONTROL + 4 + phase * 0x20 + offset


def dfii_command(client, args: argparse.Namespace, phase: int, command: int) -> None:
    wb_write_checked(client, args, phase_reg(phase, 0x00), command)
    wb_write_checked(client, args, phase_reg(phase, 0x04), 1)


def dfii_phase_address_write(client, args: argparse.Namespace, phase: int, address: int) -> None:
    wb_write_checked(client, args, phase_reg(phase, 0x08), address)


def dfii_phase_baddress_write(client, args: argparse.Namespace, phase: int, bank: int) -> None:
    wb_write_checked(client, args, phase_reg(phase, 0x0C), bank)


def dfii_word_addr(phase: int, rd: bool = False) -> int:
    return phase_reg(phase, 0x18 if rd else 0x10)


def pack_le_bytes(values: list[int]) -> int:
    value = 0
    for index, byte in enumerate(values):
        value |= (byte & 0xFF) << (8 * index)
    return value


def unpack_le_bytes(value: int, size: int = DFII_PIX_DATA_BYTES) -> list[int]:
    return [(value >> (8 * index)) & 0xFF for index in range(size)]


def dfii_write_data(client, args: argparse.Namespace, phase: int, values: list[int]) -> None:
    value = pack_le_bytes(values)
    addr = dfii_word_addr(phase, rd=False)
    wb_write_checked(client, args, addr, (value >> 32) & 0xFFFFFFFF)
    wb_write_checked(client, args, addr + 4, value & 0xFFFFFFFF)


def dfii_read_data(client, args: argparse.Namespace, phase: int) -> list[int]:
    addr = dfii_word_addr(phase, rd=True)
    high, _ = wb_read_checked(client, args, addr)
    low, _ = wb_read_checked(client, args, addr + 4)
    return unpack_le_bytes(((high & 0xFFFFFFFF) << 32) | (low & 0xFFFFFFFF))


def lfsr32(prev: int) -> int:
    lsb = prev & 1
    prev >>= 1
    if lsb:
        prev ^= 0x80200003
    return prev & 0xFFFFFFFF


def cdelay(args: argparse.Namespace, cycles: int) -> None:
    if cycles <= 0:
        return
    time.sleep(max(cycles / args.sys_clk_freq, args.min_delay_s))


def dfii_command_p0(client, args: argparse.Namespace, address: int, bank: int, command: int) -> None:
    wb_write_checked(client, args, CSR_SDRAM_DFII_PI0_ADDRESS, address)
    wb_write_checked(client, args, CSR_SDRAM_DFII_PI0_BADDRESS, bank)
    dfii_command(client, args, 0, command)


def dfii_write_read_check_test_pattern(client, args: argparse.Namespace, module: int, seed: int) -> int:
    timing = phy_timing(args.sys_clk_freq)
    rdphase = timing["rdphase"]
    wrphase = timing["wrphase"]
    prv = seed
    patterns = []
    for _phase in range(SDRAM_PHY_PHASES):
        values = []
        for _byte in range(DFII_PIX_DATA_BYTES):
            value = 0
            for bit in range(8):
                prv = lfsr32(prv)
                value |= (prv & 1) << bit
            values.append(value)
        patterns.append(values)

    dfii_phase_address_write(client, args, 0, 0)
    dfii_phase_baddress_write(client, args, 0, 0)
    dfii_command(client, args, 0, DFII_COMMAND_RAS | DFII_COMMAND_CS)
    cdelay(args, 15)

    for phase, values in enumerate(patterns):
        dfii_write_data(client, args, phase, values)
    dfii_phase_address_write(client, args, wrphase, 0)
    dfii_phase_baddress_write(client, args, wrphase, 0)
    dfii_command(
        client,
        args,
        wrphase,
        DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS | DFII_COMMAND_WRDATA,
    )
    cdelay(args, 15)

    dfii_phase_address_write(client, args, rdphase, 0)
    dfii_phase_baddress_write(client, args, rdphase, 0)
    dfii_command(client, args, rdphase, DFII_COMMAND_CAS | DFII_COMMAND_CS | DFII_COMMAND_RDDATA)
    cdelay(args, 15)

    dfii_phase_address_write(client, args, 0, 0)
    dfii_phase_baddress_write(client, args, 0, 0)
    dfii_command(client, args, 0, DFII_COMMAND_RAS | DFII_COMMAND_WE | DFII_COMMAND_CS)
    cdelay(args, 15)

    errors = 0
    pebo = (module * SDRAM_PHY_DQ_DQS_RATIO) // 8
    nebo = pebo + (DFII_PIX_DATA_BYTES // SDRAM_PHY_XDR)
    ibo = (module * SDRAM_PHY_DQ_DQS_RATIO) % 8
    for phase, expected in enumerate(patterns):
        actual = dfii_read_data(client, args, phase)
        errors += (((expected[pebo] >> ibo) & MODULE_BITMASK) ^ ((actual[pebo] >> ibo) & MODULE_BITMASK)).bit_count()
        errors += (((expected[nebo] >> ibo) & MODULE_BITMASK) ^ ((actual[nebo] >> ibo) & MODULE_BITMASK)).bit_count()
    return errors


def run_dfii_test_pattern(client, args: argparse.Namespace, module: int) -> int:
    return sum(dfii_write_read_check_test_pattern(client, args, module, seed) for seed in READ_LEVELING_SEEDS)


def read_leveling_scan_module(client, args: argparse.Namespace, module: int, bitslip: int) -> dict[str, object]:
    max_errors = len(READ_LEVELING_SEEDS) * READ_CHECK_TEST_PATTERN_MAX_ERRORS
    score = 0
    samples = []
    set_read_leveling(client, args, 1 << module, bitslip, 0)
    delay_count = min(args.max_delay + 1, SDRAM_PHY_DELAYS)
    for delay in range(delay_count):
        errors = run_dfii_test_pattern(client, args, module)
        working = errors == 0
        score += (int(working) * max_errors * SDRAM_PHY_DELAYS) + (max_errors - errors)
        samples.append({"delay": delay, "errors": errors, "working": working})
        if delay != delay_count - 1:
            wb_write_checked(client, args, CSR_DDRPHY_DLY_SEL, 1 << module)
            wb_write_checked(client, args, CSR_DDRPHY_RDLY_DQ_INC, 1)
            wb_write_checked(client, args, CSR_DDRPHY_DLY_SEL, 0)
    return {"bitslip": bitslip, "score": score, "samples": samples}


def center_read_leveling_module(client, args: argparse.Namespace, module: int, bitslip: int) -> dict[str, object]:
    scan = read_leveling_scan_module(client, args, module, bitslip)
    working_delays = [sample["delay"] for sample in scan["samples"] if sample["working"]]
    if not working_delays:
        set_read_leveling(client, args, 1 << module, bitslip, 0)
        return {"bitslip": bitslip, "delay": 0, "scan": scan, "pass": False}

    ranges = []
    start = prev = working_delays[0]
    for delay in working_delays[1:]:
        if delay == prev + 1:
            prev = delay
        else:
            ranges.append((start, prev))
            start = prev = delay
    ranges.append((start, prev))
    start, end = max(ranges, key=lambda item: item[1] - item[0])
    delay = (start + end) // 2
    set_read_leveling(client, args, 1 << module, bitslip, delay)
    check_errors = run_dfii_test_pattern(client, args, module)
    return {
        "bitslip": bitslip,
        "delay": delay,
        "window_start": start,
        "window_end": end,
        "check_errors": check_errors,
        "scan": scan,
        "pass": check_errors == 0,
    }


def run_dfii_read_leveling(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None
    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_SOFTWARE)
    modules = []
    for module in range(SDRAM_PHY_MODULES):
        if not (args.module_mask & (1 << module)):
            continue
        scans = []
        best_scan = None
        for bitslip in range(min(args.max_bitslip + 1, SDRAM_PHY_BITSLIPS)):
            scan = read_leveling_scan_module(client, args, module, bitslip)
            scans.append({"bitslip": bitslip, "score": scan["score"], "samples": scan["samples"]})
            if best_scan is None or scan["score"] > best_scan["score"]:
                best_scan = scan
        centered = center_read_leveling_module(client, args, module, best_scan["bitslip"])
        modules.append({"module": module, "best_bitslip": best_scan["bitslip"], "centered": centered, "scans": scans})
    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_HARDWARE)
    after = read_status(client, args)
    return {"init": init, "modules": modules, "after": after, "pass": all(module["centered"]["pass"] for module in modules)}


def run_ddr3_init(client, args: argparse.Namespace) -> dict[str, object]:
    steps = []
    timing = phy_timing(args.sys_clk_freq)

    def record(name: str, **extra) -> None:
        status = read_status(client, args)
        entry = {"name": name, "status": status}
        entry.update(extra)
        steps.append(entry)

    before = read_status(client, args)
    wb_write_checked(client, args, CSR_DDRPHY_RDPHASE, timing["rdphase"])
    wb_write_checked(client, args, CSR_DDRPHY_WRPHASE, timing["wrphase"])
    record("set read/write phases", rdphase=timing["rdphase"], wrphase=timing["wrphase"])

    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_SOFTWARE)
    record("software control on")

    wb_write_checked(client, args, CSR_DDRPHY_RST, 1)
    cdelay(args, 1000)
    wb_write_checked(client, args, CSR_DDRPHY_RST, 0)
    cdelay(args, 1000)
    record("ddrphy reset pulse")

    for comment, address, bank, command, delay, kind in litedram_ddr3_init_sequence(
        args.sys_clk_freq,
        tdqs=args.tdqs,
        mr1=args.mr1,
    ):
        if kind == "control":
            wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, command)
        else:
            dfii_command_p0(client, args, address, bank, command)
        cdelay(args, delay)
        record(comment, address=address, bank=bank, command=command, kind=kind)

    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_HARDWARE)
    after = read_status(client, args)
    return {
        "before": before,
        "timing": timing,
        "tdqs": args.tdqs,
        "mr1": f"0x{ddr3_mr1(tdqs=args.tdqs, override=args.mr1):04x}",
        "steps": steps,
        "after": after,
        "pass": (
            before["magic_ok"]
            and after["magic_ok"]
            and after["sys_reset_deasserted"]
            and after["wb_done"]
            and not after["wb_timeout"]
            and not after["wb_error"]
        ),
    }


def run_write_leveling_sample(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None

    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_SOFTWARE)
    dfii_command_p0(
        client,
        args,
        ddr3_mr1_write_leveling(tdqs=args.tdqs, override=args.mr1),
        1,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
    )
    cdelay(args, 100)
    wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_EN, 1)
    cdelay(args, 100)
    write_command(client, args, OP_CLEAR_PHY_SAMPLE)
    cdelay(args, 10)

    samples = []
    sample_count = max(1, args.count)
    for index in range(sample_count):
        wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_STROBE, 1)
        cdelay(args, 100)
        phases = []
        for phase in range(SDRAM_PHY_PHASES):
            values = dfii_read_data(client, args, phase)
            phases.append(
                {
                    "phase": phase,
                    "bytes": [f"0x{value:02x}" for value in values],
                    "word": f"0x{pack_le_bytes(values):016x}",
                    "nonzero": any(values),
                }
            )
        samples.append(
            {
                "index": index,
                "phases": phases,
                "any_nonzero": any(phase["nonzero"] for phase in phases),
            }
        )

    wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_EN, 0)
    dfii_command_p0(
        client,
        args,
        ddr3_mr1(tdqs=args.tdqs, override=args.mr1),
        1,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
    )
    cdelay(args, 100)
    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_HARDWARE)
    after = read_status(client, args)
    any_nonzero = any(sample["any_nonzero"] for sample in samples)
    return {
        "init": init,
        "tdqs": args.tdqs,
        "mr1_wlevel": f"0x{ddr3_mr1_write_leveling(tdqs=args.tdqs, override=args.mr1):04x}",
        "mr1_restore": f"0x{ddr3_mr1(tdqs=args.tdqs, override=args.mr1):04x}",
        "samples": samples,
        "after": after,
        "pass": any_nonzero,
    }


def run_write_leveling_sweep(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None
    samples = []
    hits = []

    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_SOFTWARE)
    dfii_command_p0(
        client,
        args,
        ddr3_mr1_write_leveling(tdqs=args.tdqs, override=args.mr1),
        1,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
    )
    cdelay(args, 100)
    wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_EN, 1)
    cdelay(args, 100)

    try:
        sample_count = max(1, args.count)
        for module_mask in selected_module_masks(args.module_mask):
            for bitslip in range(args.max_bitslip + 1):
                for delay in range(args.max_delay + 1):
                    set_read_leveling(client, args, module_mask, bitslip, delay)
                    write_command(client, args, OP_CLEAR_PHY_SAMPLE)
                    cdelay(args, 10)
                    for _ in range(sample_count):
                        wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_STROBE, 1)
                        cdelay(args, 100)
                    status = read_status(client, args)
                    summary = {
                        "module_mask": module_mask,
                        "bitslip": bitslip,
                        "delay": delay,
                        "first_valid": status["ddr_phase_first_valid"],
                        "first_mask": status["ddr_phase_first_mask"],
                        "first_word": status["ddr_phase_first_word"],
                        "nonzero_seen": status["ddr_phase_nonzero_seen"],
                        "nonzero_toggle_seen": status["ddr_phase_nonzero_toggle_seen"],
                        "seen_high": status["ddr_phase_seen_high"],
                        "dq_seen_high": status["ddr_dq_seen_high"],
                    }
                    samples.append(summary)
                    if status["ddr_phase_first_valid"]:
                        hits.append(summary)
                        if args.stop_on_zero:
                            result = {
                                "init": init,
                                "tdqs": args.tdqs,
                                "mr1_wlevel": f"0x{ddr3_mr1_write_leveling(tdqs=args.tdqs, override=args.mr1):04x}",
                                "hits": hits,
                                "samples": samples,
                                "pass": True,
                            }
                            if args.summary_only:
                                result.pop("init")
                                result.pop("samples")
                            return result
    finally:
        wb_write_checked(client, args, CSR_DDRPHY_WLEVEL_EN, 0)
        dfii_command_p0(
            client,
            args,
            ddr3_mr1(tdqs=args.tdqs, override=args.mr1),
            1,
            DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
        )
        cdelay(args, 100)
        wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_HARDWARE)

    after = read_status(client, args)
    result = {
        "init": init,
        "tdqs": args.tdqs,
        "mr1_wlevel": f"0x{ddr3_mr1_write_leveling(tdqs=args.tdqs, override=args.mr1):04x}",
        "mr1_restore": f"0x{ddr3_mr1(tdqs=args.tdqs, override=args.mr1):04x}",
        "hits": hits,
        "samples": samples,
        "after": after,
        "pass": bool(hits),
    }
    if args.summary_only:
        result.pop("init")
        result.pop("after")
        result.pop("samples")
    return result


def contiguous_windows(delays: list[int]) -> list[dict[str, int]]:
    if not delays:
        return []
    windows = []
    start = prev = delays[0]
    for delay in delays[1:]:
        if delay == prev + 1:
            prev = delay
            continue
        windows.append({"start": start, "end": prev, "width": prev - start + 1})
        start = prev = delay
    windows.append({"start": start, "end": prev, "width": prev - start + 1})
    return windows


def select_write_leveling_window(hits: list[dict[str, object]], module_mask: int) -> dict[str, object] | None:
    best = None
    bitslips = sorted({int(hit["bitslip"]) for hit in hits if int(hit["module_mask"]) == module_mask})
    for bitslip in bitslips:
        delays = sorted(
            {
                int(hit["delay"])
                for hit in hits
                if int(hit["module_mask"]) == module_mask and int(hit["bitslip"]) == bitslip
            }
        )
        for window in contiguous_windows(delays):
            candidate = {
                "module_mask": module_mask,
                "bitslip": bitslip,
                "start": window["start"],
                "end": window["end"],
                "width": window["width"],
                "delay": (window["start"] + window["end"]) // 2,
            }
            if best is None or (
                candidate["width"],
                candidate["delay"],
            ) > (
                best["width"],
                best["delay"],
            ):
                best = candidate
    return best


def run_write_leveling_calibrate(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None
    original_module_mask = args.module_mask
    original_init_first = args.init_first
    selections = []
    sweeps = []

    try:
        args.init_first = False
        for module_mask in selected_module_masks(original_module_mask):
            args.module_mask = module_mask
            sweep = run_write_leveling_sweep(client, args)
            selected = select_write_leveling_window(sweep["hits"], module_mask)
            if selected is not None:
                set_read_leveling(
                    client,
                    args,
                    module_mask,
                    int(selected["bitslip"]),
                    int(selected["delay"]),
                )
            selections.append(
                {
                    "module_mask": module_mask,
                    "selected": selected,
                    "hit_count": len(sweep["hits"]),
                    "pass": selected is not None,
                }
            )
            if not args.summary_only:
                sweeps.append(sweep)
    finally:
        args.module_mask = original_module_mask
        args.init_first = original_init_first

    result = {
        "init": init,
        "selections": selections,
        "sweeps": sweeps,
        "after": read_status(client, args),
        "pass": all(selection["pass"] for selection in selections),
    }
    if args.summary_only:
        result.pop("init")
        result.pop("sweeps")
        result.pop("after")
    return result


def run_memtest(client, args: argparse.Namespace) -> dict[str, object]:
    before = read_status(client, args)
    write_command(client, args, OP_RESET_BIST)
    time.sleep(args.settle_s)
    write_command(client, args, OP_SET_BASE, args.base)
    time.sleep(args.settle_s)
    write_command(client, args, OP_SET_LENGTH, args.length)
    time.sleep(args.settle_s)
    write_command(client, args, OP_SET_RANDOM, args.random)
    time.sleep(args.settle_s)
    write_command(client, args, OP_START_GEN)
    generator = poll_until(client, args, "generator_done")
    write_command(client, args, OP_START_CHECK)
    checker = poll_until(client, args, "checker_done")
    after = read_status(client, args)
    pll_ok = after["pll_locked"] or args.ignore_pll_lock
    return {
        "before": before,
        "generator": generator,
        "checker": checker,
        "after": after,
        "pll_ok": pll_ok,
        "pass": (
            after["magic_ok"]
            and pll_ok
            and after["generator_done"]
            and after["checker_done"]
            and after["checker_errors"] == 0
        ),
    }


def set_read_leveling(client, args: argparse.Namespace, module_mask: int, bitslip: int, delay: int) -> None:
    wb_write_checked(client, args, CSR_DDRPHY_DLY_SEL, module_mask)
    wb_write_checked(client, args, CSR_DDRPHY_RDLY_DQ_RST, 1)
    wb_write_checked(client, args, CSR_DDRPHY_RDLY_DQ_BITSLIP_RST, 1)
    for _ in range(bitslip):
        wb_write_checked(client, args, CSR_DDRPHY_RDLY_DQ_BITSLIP, 1)
    for _ in range(delay):
        wb_write_checked(client, args, CSR_DDRPHY_RDLY_DQ_INC, 1)
    wb_write_checked(client, args, CSR_DDRPHY_DLY_SEL, 0)


def run_read_sweep(client, args: argparse.Namespace) -> dict[str, object]:
    init = None
    if args.init_first:
        init = run_ddr3_init(client, args)

    samples = []
    best = None
    module_mask = args.module_mask
    for bitslip in range(args.max_bitslip + 1):
        for delay in range(args.max_delay + 1):
            set_read_leveling(client, args, module_mask, bitslip, delay)
            sample = run_memtest(client, args)
            after = sample["after"]
            summary = {
                "bitslip": bitslip,
                "delay": delay,
                "checker_errors": after["checker_errors"],
                "checker_done": after["checker_done"],
                "generator_done": after["generator_done"],
                "checker_ticks": after["checker_ticks"],
                "generator_ticks": after["generator_ticks"],
                "pass": sample["pass"],
            }
            samples.append(summary)
            if best is None or (
                summary["checker_errors"],
                not summary["checker_done"],
                not summary["generator_done"],
            ) < (
                best["checker_errors"],
                not best["checker_done"],
                not best["generator_done"],
            ):
                best = summary
            if args.stop_on_zero and summary["checker_errors"] == 0 and summary["checker_done"]:
                return {"init": init, "best": best, "samples": samples, "pass": True}
    result = {
        "init": init,
        "best": best,
        "samples": samples,
        "pass": bool(best and best["checker_errors"] == 0 and best["checker_done"]),
    }
    if args.summary_only:
        zero_error_samples = [
            sample
            for sample in samples
            if sample["checker_errors"] == 0 and sample["checker_done"] and sample["generator_done"]
        ]
        result.pop("init")
        result.pop("samples")
        result["sample_count"] = len(samples)
        result["zero_error_count"] = len(zero_error_samples)
        result["zero_error_samples"] = zero_error_samples[:8]
    return result


def run_bridge_diag(client, args: argparse.Namespace, opcode: int) -> dict[str, object]:
    before = read_status(client, args)
    command_data = (
        (args.module_mask & 0xFF)
        | ((args.bitslip & 0xFF) << 8)
        | ((args.delay & 0xFF) << 16)
    )
    if opcode == OP_MEM32_CHECK:
        write_command(client, args, OP_WRITE_SCRATCH, args.data)
        time.sleep(args.settle_s)
    write_command(client, args, opcode, data=command_data, addr=args.addr)
    deadline = time.monotonic() + args.timeout_s
    samples = []
    while True:
        sample = read_status(client, args)
        samples.append(sample)
        if sample["diag_count"] != before["diag_count"] and not sample["diag_active"]:
            pass_status = sample["diag_status"] == "0x02"
            if opcode == OP_MEM32_CHECK:
                pass_status = pass_status and sample["diag_actual_int"] == args.data
            if opcode == OP_DFII_PATTERN:
                pass_status = pass_status and sample["diag_error_count"] == 0
            return {"before": before, "after": sample, "samples": samples, "pass": pass_status}
        if time.monotonic() >= deadline:
            return {"before": before, "samples": samples, "pass": False, "timeout": True}
        time.sleep(args.poll_s)


def selected_module_masks(module_mask: int) -> list[int]:
    return [1 << bit for bit in range(8) if module_mask & (1 << bit)]


def run_bridge_mem32_sweep(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None
    samples = []
    passes = []
    module_masks = selected_module_masks(args.module_mask)
    for module_mask in module_masks:
        args.module_mask = module_mask
        for bitslip in range(args.max_bitslip + 1):
            args.bitslip = bitslip
            for delay in range(args.max_delay + 1):
                args.delay = delay
                result = run_bridge_diag(client, args, OP_MEM32_CHECK)
                after = result["after"] if "after" in result else result["samples"][-1]
                summary = {
                    "module_mask": module_mask,
                    "bitslip": bitslip,
                    "delay": delay,
                    "diag_status": after["diag_status"],
                    "diag_actual": after["diag_actual"],
                    "diag_actual_int": after["diag_actual_int"],
                    "diag_count": after["diag_count"],
                    "diag_error_count": after["diag_error_count"],
                    "wb_status": after["wb_status"],
                    "pass": result["pass"],
                }
                samples.append(summary)
                if result["pass"]:
                    passes.append(summary)
                    if args.stop_on_zero:
                        return {
                            "init": init,
                            "passes": passes,
                            "samples": samples,
                            "pass": True,
                        }
    return {
        "init": init,
        "passes": passes,
        "samples": samples,
        "pass": bool(passes),
    }


def run_bridge_dfii_pattern_sweep(client, args: argparse.Namespace) -> dict[str, object]:
    init = run_ddr3_init(client, args) if args.init_first else None
    samples = []
    passes = []
    best = None
    module_masks = selected_module_masks(args.module_mask)
    for module_mask in module_masks:
        args.module_mask = module_mask
        for bitslip in range(args.max_bitslip + 1):
            args.bitslip = bitslip
            for delay in range(args.max_delay + 1):
                args.delay = delay
                result = run_bridge_diag(client, args, OP_DFII_PATTERN)
                after = result["after"] if "after" in result else result["samples"][-1]
                summary = {
                    "module_mask": module_mask,
                    "bitslip": bitslip,
                    "delay": delay,
                    "diag_status": after["diag_status"],
                    "diag_count": after["diag_count"],
                    "diag_error_count": after["diag_error_count"],
                    "wb_status": after["wb_status"],
                    "pass": result["pass"],
                }
                samples.append(summary)
                if best is None or summary["diag_error_count"] < best["diag_error_count"]:
                    best = summary
                if result["pass"]:
                    passes.append(summary)
                    if args.stop_on_zero:
                        return {
                            "init": init,
                            "best": best,
                            "passes": passes,
                            "samples": samples,
                            "pass": True,
                        }
    return {
        "init": init,
        "best": best,
        "passes": passes,
        "samples": samples,
        "pass": bool(passes),
    }


def poll_until(client, args: argparse.Namespace, field: str) -> dict[str, object]:
    samples = []
    deadline = time.monotonic() + args.timeout_s
    while True:
        sample = read_status(client, args)
        samples.append(sample)
        if sample.get(field):
            return {"pass": True, "samples": samples}
        if time.monotonic() >= deadline:
            return {"pass": False, "samples": samples}
        time.sleep(args.poll_s)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=(
            "read",
            "write-scratch",
            "clear-scratch",
            "clear-phy-sample",
            "reset-bist",
            "start-generator",
            "start-checker",
            "wb-read",
            "wb-write",
            "init-ddr3",
            "sweep-read",
            "dfii-read-leveling",
            "bridge-apply-rdly",
            "bridge-mem32-check",
            "bridge-mem32-sweep",
            "bridge-dfii-pattern-check",
            "bridge-dfii-pattern-sweep",
            "write-leveling-sample",
            "write-leveling-sweep",
            "write-leveling-calibrate",
            "memtest",
        ),
    )
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
    parser.add_argument("--read-bits", type=int, default=1024)
    parser.add_argument("--write-bits", type=int, default=128)
    parser.add_argument("--scratch", type=lambda value: int(value, 0), default=0x5A17C0DE)
    parser.add_argument("--addr", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--data", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--expected-data", type=lambda value: int(value, 0))
    parser.add_argument("--base", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--length", type=lambda value: int(value, 0), default=0x1000)
    parser.add_argument("--random", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--module-mask", type=lambda value: int(value, 0), default=0xF)
    parser.add_argument("--bitslip", type=int, default=0)
    parser.add_argument("--delay", type=int, default=0)
    parser.add_argument("--max-bitslip", type=int, default=7)
    parser.add_argument("--max-delay", type=int, default=31)
    parser.add_argument("--init-first", action="store_true")
    parser.add_argument("--stop-on-zero", action="store_true")
    parser.add_argument("--settle-s", type=float, default=0.05)
    parser.add_argument("--poll-s", type=float, default=0.1)
    parser.add_argument("--timeout-s", type=float, default=5.0)
    parser.add_argument("--sys-clk-freq", type=float, default=125e6)
    parser.add_argument("--tdqs", action="store_true")
    parser.add_argument(
        "--mr1",
        type=lambda value: int(value, 0),
        help=(
            "Override DDR3 MR1 during manual DFII initialization. "
            "--tdqs still forces MR1[11] on top of this value."
        ),
    )
    parser.add_argument("--count", type=int, default=8)
    parser.add_argument("--min-delay-s", type=float, default=0.00001)
    parser.add_argument("--json-only", action="store_true")
    parser.add_argument("--summary-only", action="store_true")
    parser.add_argument(
        "--ignore-pll-lock",
        action="store_true",
        help=(
            "Do not fail memtest solely because the exported PLL-lock bit is low. "
            "Use this with ignore-lock diagnostic bitstreams where fabric counters "
            "and BSCAN access prove the clock is running."
        ),
    )
    parser.add_argument("--update-mode", choices=("idle", "stop-at-update"), default="idle")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    client = make_client(args)
    try:
        if args.action == "read":
            result = {"status": read_status(client, args)}
            result["pass"] = result["status"]["magic_ok"]
        elif args.action == "write-scratch":
            before = read_status(client, args)
            write_command(client, args, OP_WRITE_SCRATCH, args.scratch)
            time.sleep(args.settle_s)
            after = read_status(client, args)
            result = {"before": before, "after": after, "pass": after["scratch_int"] == args.scratch}
        elif args.action == "clear-scratch":
            before = read_status(client, args)
            write_command(client, args, OP_CLEAR_SCRATCH)
            time.sleep(args.settle_s)
            after = read_status(client, args)
            result = {"before": before, "after": after, "pass": after["scratch_int"] == 0}
        elif args.action == "clear-phy-sample":
            before = read_status(client, args)
            write_command(client, args, OP_CLEAR_PHY_SAMPLE)
            time.sleep(args.settle_s)
            after = read_status(client, args)
            result = {"before": before, "after": after, "pass": after["magic_ok"]}
        elif args.action == "reset-bist":
            write_command(client, args, OP_RESET_BIST)
            time.sleep(args.settle_s)
            result = {"status": read_status(client, args)}
            result["pass"] = result["status"]["magic_ok"]
        elif args.action == "start-generator":
            write_command(client, args, OP_START_GEN)
            result = poll_until(client, args, "generator_done")
        elif args.action == "start-checker":
            write_command(client, args, OP_START_CHECK)
            result = poll_until(client, args, "checker_done")
        elif args.action == "wb-write":
            result = wishbone_transaction(client, args, OP_WB_WRITE, args.addr, args.data)
        elif args.action == "wb-read":
            result = wishbone_transaction(client, args, OP_WB_READ, args.addr)
        elif args.action == "init-ddr3":
            result = run_ddr3_init(client, args)
        elif args.action == "sweep-read":
            result = run_read_sweep(client, args)
        elif args.action == "dfii-read-leveling":
            result = run_dfii_read_leveling(client, args)
        elif args.action == "bridge-apply-rdly":
            result = run_bridge_diag(client, args, OP_APPLY_RDLY)
        elif args.action == "bridge-mem32-check":
            result = run_bridge_diag(client, args, OP_MEM32_CHECK)
        elif args.action == "bridge-mem32-sweep":
            result = run_bridge_mem32_sweep(client, args)
        elif args.action == "bridge-dfii-pattern-check":
            result = run_bridge_diag(client, args, OP_DFII_PATTERN)
        elif args.action == "bridge-dfii-pattern-sweep":
            result = run_bridge_dfii_pattern_sweep(client, args)
        elif args.action == "write-leveling-sample":
            result = run_write_leveling_sample(client, args)
        elif args.action == "write-leveling-sweep":
            result = run_write_leveling_sweep(client, args)
        elif args.action == "write-leveling-calibrate":
            result = run_write_leveling_calibrate(client, args)
        else:
            result = run_memtest(client, args)
    finally:
        client.close()

    if not args.json_only:
        print("PASS" if result["pass"] else "FAIL")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
