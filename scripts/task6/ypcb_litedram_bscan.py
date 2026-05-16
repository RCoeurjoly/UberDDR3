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

LITEDRAM_DDR3_INIT_SEQUENCE = (
    ("Release reset", 0x0000, 0, DFII_CONTROL_ODT | DFII_CONTROL_RESET_N, 50000, "control"),
    ("Bring CKE high", 0x0000, 0, DFII_CONTROL_SOFTWARE, 10000, "control"),
    (
        "Load Mode Register 2, CWL=6",
        0x0208,
        2,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
        0,
        "command",
    ),
    (
        "Load Mode Register 3",
        0x0000,
        3,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
        0,
        "command",
    ),
    (
        "Load Mode Register 1",
        0x0006,
        1,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
        0,
        "command",
    ),
    (
        "Load Mode Register 0, CL=8, BL=8",
        0x0940,
        0,
        DFII_COMMAND_RAS | DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS,
        200,
        "command",
    ),
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
    return {
        "raw": f"0x{value:0128x}",
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
    dfii_phase_address_write(client, args, SDRAM_PHY_WRPHASE, 0)
    dfii_phase_baddress_write(client, args, SDRAM_PHY_WRPHASE, 0)
    dfii_command(
        client,
        args,
        SDRAM_PHY_WRPHASE,
        DFII_COMMAND_CAS | DFII_COMMAND_WE | DFII_COMMAND_CS | DFII_COMMAND_WRDATA,
    )
    cdelay(args, 15)

    dfii_phase_address_write(client, args, SDRAM_PHY_RDPHASE, 0)
    dfii_phase_baddress_write(client, args, SDRAM_PHY_RDPHASE, 0)
    dfii_command(client, args, SDRAM_PHY_RDPHASE, DFII_COMMAND_CAS | DFII_COMMAND_CS | DFII_COMMAND_RDDATA)
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

    def record(name: str, **extra) -> None:
        status = read_status(client, args)
        entry = {"name": name, "status": status}
        entry.update(extra)
        steps.append(entry)

    before = read_status(client, args)
    wb_write_checked(client, args, CSR_DDRPHY_RDPHASE, 1)
    wb_write_checked(client, args, CSR_DDRPHY_WRPHASE, 2)
    record("set read/write phases")

    wb_write_checked(client, args, CSR_SDRAM_DFII_CONTROL, DFII_CONTROL_SOFTWARE)
    record("software control on")

    wb_write_checked(client, args, CSR_DDRPHY_RST, 1)
    cdelay(args, 1000)
    wb_write_checked(client, args, CSR_DDRPHY_RST, 0)
    cdelay(args, 1000)
    record("ddrphy reset pulse")

    for comment, address, bank, command, delay, kind in LITEDRAM_DDR3_INIT_SEQUENCE:
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
    return {
        "before": before,
        "generator": generator,
        "checker": checker,
        "after": after,
        "pass": (
            after["magic_ok"]
            and after["pll_locked"]
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
    return {
        "init": init,
        "best": best,
        "samples": samples,
        "pass": bool(best and best["checker_errors"] == 0 and best["checker_done"]),
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
            "reset-bist",
            "start-generator",
            "start-checker",
            "wb-read",
            "wb-write",
            "init-ddr3",
            "sweep-read",
            "dfii-read-leveling",
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
    parser.add_argument("--read-bits", type=int, default=512)
    parser.add_argument("--write-bits", type=int, default=128)
    parser.add_argument("--scratch", type=lambda value: int(value, 0), default=0x5A17C0DE)
    parser.add_argument("--addr", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--data", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--expected-data", type=lambda value: int(value, 0))
    parser.add_argument("--base", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--length", type=lambda value: int(value, 0), default=0x1000)
    parser.add_argument("--random", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--module-mask", type=lambda value: int(value, 0), default=0xF)
    parser.add_argument("--max-bitslip", type=int, default=7)
    parser.add_argument("--max-delay", type=int, default=31)
    parser.add_argument("--init-first", action="store_true")
    parser.add_argument("--stop-on-zero", action="store_true")
    parser.add_argument("--settle-s", type=float, default=0.05)
    parser.add_argument("--poll-s", type=float, default=0.1)
    parser.add_argument("--timeout-s", type=float, default=5.0)
    parser.add_argument("--sys-clk-freq", type=float, default=125e6)
    parser.add_argument("--min-delay-s", type=float, default=0.00001)
    parser.add_argument("--json-only", action="store_true")
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
