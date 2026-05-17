#!/usr/bin/env python3

import argparse
import os
from types import SimpleNamespace

from migen import *

from litex.build.generic_platform import IOStandard, Misc, Pins, Subsignal
from litex.build.yosys_wrapper import YosysWrapper
from litex.soc.cores.clock import S7IDELAYCTRL, S7MMCM
from litex.soc.integration.builder import Builder
from litex.soc.integration.soc_core import SoCCore
from litex.soc.interconnect.csr import AutoCSR
from litex.soc.interconnect import wishbone

from litex_boards.platforms import ypcb_00338_1p1

from litedram.common import PHYPadsReducer
from litedram.dfii import DFIInjector
from litedram.frontend.bist import _LiteDRAMBISTChecker, _LiteDRAMBISTGenerator
from litedram.modules import MT41J256M16, MT41K256M8
from litedram.phy import s7ddrphy
from patch_ypcb_openxc7_vref import patch_openxc7_vref_bitstream


YPCB_DDRAM_PINS = {
    0: {
        "a": "AK27 AN23 AL24 AK26 AH24 AH25 AL26 AJ24 AJ25 AM23 AL28 AL25 AM25 AK24 AM27",
        "ba": "AM26 AP24 AN28",
        "ras_n": "AJ29",
        "cas_n": "AP26",
        "we_n": "AN27",
        "cs_n": "AK28",
        "cke": "AP27",
        "odt": "AK29",
        "reset_n": "AD31",
        "dq": (
            "AG17 AG16 AH17 AJ19 AH18 AH19 AJ16 AJ17",
            "AL20 AN17 AL19 AM16 AL18 AL16 AM20 AN18",
            "AL23 AN20 AK23 AP19 AN22 AN19 AM22 AP20",
            "AJ21 AH22 AK21 AG21 AG22 AG20 AH23 AG23",
            "AJ32 AK32 AK31 AL30 AL34 AL31 AK34 AL29",
            "AJ34 AH32 AJ30 AH34 AF31 AG30 AG31 AF30",
            "AE32 AC33 AF33 AC32 AD34 AC34 AE33 AE31",
            "AE26 AF29 AE24 AF28 AF24 AG25 AF26 AF25",
            "AN34 AP30 AM33 AN29 AP32 AP29 AM31 AP31",
        ),
        "dqs_p": "AK16 AM17 AP21 AH20 AK33 AG33 AE34 AE27 AN32",
        "dqs_n": "AK17 AM18 AP22 AJ20 AL33 AH33 AF34 AE28 AP33",
        "clk_p": "AN25",
        "clk_n": "AP25",
    },
    1: {
        "a": "E27 C27 B28 D27 C24 D24 C25 A24 A25 J24 F26 D26 H25 D25 B26",
        "ba": "F24 J25 E24",
        "ras_n": "E28",
        "cas_n": "E26",
        "we_n": "F25",
        "cs_n": "F28",
        "cke": "A28",
        "odt": "B27",
        "reset_n": "F18",
        "dq": (
            "A29 B33 A31 C33 C32 A30 B30 A33",
            "D31 F33 D30 D29 E33 E34 E31 F34",
            "B23 A21 C23 B20 B22 A23 C20 B21",
            "G31 G32 F29 F31 E29 G33 H33 H32",
            "B18 C17 C19 B16 A18 A16 C18 B17",
            "K27 L24 K24 L28 K26 M27 L25 M26",
            "F16 E18 E16 H19 H17 H20 E17 H18",
            "D20 F21 E23 G21 G20 D21 F20 F23",
            "L34 K34 K31 K33 L31 J30 L33 J34",
        ),
        "dqs_p": "B31 D34 A19 H29 D16 K28 G17 G22 K32",
        "dqs_n": "B32 C34 A20 H30 D17 K29 G18 G23 J32",
        "clk_p": "B25",
        "clk_n": "A26",
    },
}


def add_reduced_ddram_resource(platform, channel, byte_groups):
    pins = YPCB_DDRAM_PINS[channel]
    dqs_p = pins["dqs_p"].split()
    dqs_n = pins["dqs_n"].split()
    selected_dq = []
    selected_dqs_p = []
    selected_dqs_n = []
    for group in byte_groups:
        selected_dq.extend(pins["dq"][group].split())
        selected_dqs_p.append(dqs_p[group])
        selected_dqs_n.append(dqs_n[group])

    name = "ddram_reduced"
    platform.add_extension([
        (name, channel,
            Subsignal("a",       Pins(pins["a"]),       IOStandard("SSTL15")),
            Subsignal("ba",      Pins(pins["ba"]),      IOStandard("SSTL15")),
            Subsignal("ras_n",   Pins(pins["ras_n"]),   IOStandard("SSTL15")),
            Subsignal("cas_n",   Pins(pins["cas_n"]),   IOStandard("SSTL15")),
            Subsignal("we_n",    Pins(pins["we_n"]),    IOStandard("SSTL15")),
            Subsignal("cs_n",    Pins(pins["cs_n"]),    IOStandard("SSTL15")),
            Subsignal("cke",     Pins(pins["cke"]),     IOStandard("SSTL15")),
            Subsignal("odt",     Pins(pins["odt"]),     IOStandard("SSTL15")),
            Subsignal("reset_n", Pins(pins["reset_n"]), IOStandard("SSTL15")),
            Subsignal("dq",      Pins(" ".join(selected_dq)),    IOStandard("SSTL15"), Misc("IN_TERM=UNTUNED_SPLIT_40")),
            Subsignal("dqs_p",   Pins(" ".join(selected_dqs_p)), IOStandard("DIFF_SSTL15"), Misc("IN_TERM=UNTUNED_SPLIT_40")),
            Subsignal("dqs_n",   Pins(" ".join(selected_dqs_n)), IOStandard("DIFF_SSTL15"), Misc("IN_TERM=UNTUNED_SPLIT_40")),
            Subsignal("clk_p",   Pins(pins["clk_p"]), IOStandard("DIFF_SSTL15")),
            Subsignal("clk_n",   Pins(pins["clk_n"]), IOStandard("DIFF_SSTL15")),
            Misc("SLEW=FAST"),
        )
    ])
    return platform.request(name, channel)


def phy_timing(sys_clk_freq):
    """Match the LiteDRAM-generated sdram_phy.h values for the tested YPCB builds."""
    if sys_clk_freq <= 110e6:
        return {"rdphase": 2, "wrphase": 3}
    return {"rdphase": 1, "wrphase": 2}


class _CRG(Module):
    def __init__(self, platform, sys_clk_freq, ignore_pll_lock_reset=False):
        self.rst = Signal()
        self.clock_domains.cd_sys = ClockDomain()
        self.clock_domains.cd_sys4x = ClockDomain()
        self.clock_domains.cd_sys4x_dqs = ClockDomain()
        self.clock_domains.cd_idelay = ClockDomain()

        clk200 = platform.request("clk200")
        rst_n = platform.request("rst_n")
        self.rst_n = rst_n

        self.submodules.pll = pll = S7MMCM(speedgrade=-2)
        self.comb += pll.reset.eq(~rst_n | self.rst)
        pll.register_clkin(clk200, 200e6)
        with_reset = not ignore_pll_lock_reset
        pll.create_clkout(self.cd_sys, sys_clk_freq, with_reset=with_reset)
        pll.create_clkout(self.cd_sys4x, 4 * sys_clk_freq, with_reset=with_reset)
        pll.create_clkout(self.cd_sys4x_dqs, 4 * sys_clk_freq, phase=135, with_reset=with_reset)
        pll.create_clkout(self.cd_idelay, 200e6, with_reset=with_reset)
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin)

        self.submodules.idelayctrl = S7IDELAYCTRL(self.cd_idelay)


class LiteDRAMDFIIOnly(Module, AutoCSR):
    def __init__(self, phy, module):
        self.controller = SimpleNamespace(
            settings=SimpleNamespace(
                phy=phy.settings,
                timing=module.timing_settings,
                geom=module.geom_settings,
            )
        )
        self.submodules.dfii = DFIInjector(
            addressbits=max(module.geom_settings.addressbits, getattr(phy, "addressbits", 0)),
            bankbits=max(module.geom_settings.bankbits, getattr(phy, "bankbits", 0)),
            nranks=phy.settings.nranks,
            databits=phy.settings.dfi_databits,
            nphases=phy.settings.nphases,
            is_clam_shell=phy.settings.is_clam_shell,
        )
        self.comb += self.dfii.master.connect(phy.dfi)


class RawBSCANLiteDRAMBIST(Module):
    def __init__(self, platform, soc, phy, byte_group_mask, rdphase, wrphase, with_bist=True):
        bist_reset = Signal()
        generator_start = Signal()
        checker_start = Signal()
        bist_base = Signal(32)
        bist_length = Signal(32)
        bist_random_data = Signal()
        bist_random_addr = Signal()
        generator_done = Signal()
        generator_ticks = Signal(32)
        checker_done = Signal()
        checker_ticks = Signal(32)
        checker_errors = Signal(32)
        ddr_dq_sample = Signal(32)
        ddr_phase_sample = Signal(128)
        ddr_dqs_p_sample = Signal(4)
        ddr_dqs_n_sample = Signal(4)
        self.wishbone = wishbone.Interface(data_width=32, adr_width=30)
        soc.bus.add_master(name="raw_bscan", master=self.wishbone)

        rdphase_index = int(rdphase)
        rddata_width = min(len(phy.dfi.phases[rdphase_index].rddata), 32)
        phase_samples = []
        for phase in range(min(len(phy.dfi.phases), 4)):
            phase_sample = Signal(32)
            phase_width = min(len(phy.dfi.phases[phase].rddata), 32)
            self.comb += phase_sample[:phase_width].eq(phy.dfi.phases[phase].rddata[:phase_width])
            phase_samples.append(phase_sample)
        while len(phase_samples) < 4:
            phase_samples.append(Constant(0, 32))
        self.comb += [
            ddr_dq_sample[:rddata_width].eq(phy.dfi.phases[rdphase_index].rddata[:rddata_width]),
            ddr_phase_sample.eq(Cat(*phase_samples)),
            ddr_dqs_p_sample.eq(0),
            ddr_dqs_n_sample.eq(0),
        ]

        if with_bist:
            generator_port = soc.sdram.crossbar.get_port()
            checker_port = soc.sdram.crossbar.get_port()
            self.submodules.generator = generator = _LiteDRAMBISTGenerator(generator_port)
            self.submodules.checker = checker = _LiteDRAMBISTChecker(checker_port)
            self.comb += [
                generator.reset.eq(bist_reset),
                generator.start.eq(generator_start),
                generator.base.eq(bist_base),
                generator.end.eq(bist_base + bist_length),
                generator.length.eq(bist_length),
                generator.random_data.eq(bist_random_data),
                generator.random_addr.eq(bist_random_addr),
                checker.reset.eq(bist_reset),
                checker.start.eq(checker_start),
                checker.base.eq(bist_base),
                checker.end.eq(bist_base + bist_length),
                checker.length.eq(bist_length),
                checker.random_data.eq(bist_random_data),
                checker.random_addr.eq(bist_random_addr),
                generator_done.eq(generator.done),
                generator_ticks.eq(generator.ticks),
                checker_done.eq(checker.done),
                checker_ticks.eq(checker.ticks),
                checker_errors.eq(checker.errors),
            ]

        platform.add_source(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
                "example_demo",
                "ypcb_00338_1p1",
                "ypcb_litedram_bscan_bridge.v",
            )
        )

        self.specials += Instance(
            "ypcb_litedram_bscan_bridge",
            p_BYTE_GROUP_MASK=Constant(int(byte_group_mask), 32),
            p_RDPHASE=Constant(int(rdphase), 2),
            p_WRPHASE=Constant(int(wrphase), 2),
            i_sys_clk=ClockSignal("sys"),
            i_sys_rst=ResetSignal("sys"),
            i_clkin=soc.crg.pll.clkin,
            i_idelay_clk=ClockSignal("idelay"),
            i_rst_n_raw=soc.crg.rst_n,
            i_pll_locked=soc.crg.pll.locked,
            i_ddr_dq_sample=ddr_dq_sample,
            i_ddr_phase_sample=ddr_phase_sample,
            i_ddr_dqs_p_sample=ddr_dqs_p_sample,
            i_ddr_dqs_n_sample=ddr_dqs_n_sample,
            i_generator_done=generator_done,
            i_generator_ticks=generator_ticks,
            i_checker_done=checker_done,
            i_checker_ticks=checker_ticks,
            i_checker_errors=checker_errors,
            o_bist_reset=bist_reset,
            o_generator_start=generator_start,
            o_checker_start=checker_start,
            o_bist_base=bist_base,
            o_bist_length=bist_length,
            o_bist_random_data=bist_random_data,
            o_bist_random_addr=bist_random_addr,
            o_wb_adr=self.wishbone.adr,
            o_wb_dat_w=self.wishbone.dat_w,
            i_wb_dat_r=self.wishbone.dat_r,
            o_wb_sel=self.wishbone.sel,
            o_wb_cyc=self.wishbone.cyc,
            o_wb_stb=self.wishbone.stb,
            o_wb_we=self.wishbone.we,
            i_wb_ack=self.wishbone.ack,
            i_wb_err=self.wishbone.err,
        )

        self.comb += [
            self.wishbone.cti.eq(0),
            self.wishbone.bte.eq(0),
        ]


class YPCBLiteDRAMBISTSoC(SoCCore):
    csr_map = {
        "ctrl": 0,
        "ddrphy": 1,
        "identifier_mem": 2,
        "sdram": 3,
    }

    def __init__(
        self,
        sys_clk_freq=125e6,
        dram_channel=0,
        byte_groups=(0, 1, 2, 3),
        module_name="mt41k256m8",
        with_bist=True,
        with_raw_bscan=False,
        dfii_only=False,
        ignore_pll_lock_reset=False,
        s7_phy="a7",
        toolchain="openxc7",
        **kwargs,
    ):
        platform = ypcb_00338_1p1.Platform(toolchain=toolchain)
        if toolchain == "openxc7":
            platform.device = "xc7k480tffg1156-2"
            platform.toolchain._yosys_template = list(YosysWrapper._default_template)
            platform.toolchain._yosys_template.insert(-1, "delete t:$scopeinfo")
        self.submodules.crg = _CRG(platform, sys_clk_freq, ignore_pll_lock_reset=ignore_pll_lock_reset)

        SoCCore.__init__(
            self,
            platform,
            sys_clk_freq,
            ident="YPCB LiteDRAM BIST reference",
            cpu_type=None,
            integrated_rom_size=0,
            integrated_sram_size=0,
            with_uart=False,
            with_timer=False,
            with_jtagbone=not with_raw_bscan,
            **kwargs,
        )

        if len(byte_groups) == 9:
            pads = PHYPadsReducer(platform.request("ddram", dram_channel), list(byte_groups))
        else:
            pads = add_reduced_ddram_resource(platform, dram_channel, byte_groups)
        phy_cls = {
            "a7": s7ddrphy.A7DDRPHY,
            "k7": s7ddrphy.K7DDRPHY,
        }[s7_phy]
        self.submodules.ddrphy = phy_cls(
            pads=pads,
            memtype="DDR3",
            nphases=4,
            sys_clk_freq=sys_clk_freq,
        )

        module_cls = {
            "mt41k256m8": MT41K256M8,
            "mt41j256m16": MT41J256M16,
        }[module_name]
        module = module_cls(sys_clk_freq, "1:4")
        if dfii_only:
            self.submodules.sdram = LiteDRAMDFIIOnly(self.ddrphy, module)
        else:
            self.add_sdram(
                "sdram",
                phy=self.ddrphy,
                module=module,
                size=0x20000000,
                l2_cache_size=0,
                with_bist=with_bist,
            )

        if with_raw_bscan:
            byte_group_mask = 0
            for group in byte_groups:
                byte_group_mask |= 1 << group
            timing = phy_timing(sys_clk_freq)
            self.submodules.raw_bscan_bist = RawBSCANLiteDRAMBIST(
                self.platform,
                self,
                self.ddrphy,
                byte_group_mask,
                rdphase=timing["rdphase"],
                wrphase=timing["wrphase"],
                with_bist=with_bist and not dfii_only,
            )


def parse_byte_groups(value):
    groups = tuple(int(item, 0) for item in value.split(",") if item.strip())
    if not groups:
        raise argparse.ArgumentTypeError("at least one byte group is required")
    return groups


def main():
    parser = argparse.ArgumentParser(description="Generate a YPCB LiteDRAM BIST reference.")
    parser.add_argument("--sys-clk-freq", default=125e6, type=float)
    parser.add_argument("--dram-channel", default=0, type=int, choices=(0, 1))
    parser.add_argument("--byte-groups", default=(0, 1, 2, 3), type=parse_byte_groups)
    parser.add_argument("--module", default="mt41k256m8", choices=("mt41k256m8", "mt41j256m16"))
    parser.add_argument(
        "--s7-phy",
        default="a7",
        choices=("a7", "k7"),
        help="LiteDRAM 7-series PHY variant. a7 is no-ODELAY; k7 enables ODELAY.",
    )
    parser.add_argument("--toolchain", default="openxc7", choices=("openxc7", "vivado"))
    parser.add_argument("--no-bist", action="store_true")
    parser.add_argument("--with-raw-bscan", action="store_true")
    parser.add_argument(
        "--dfii-only",
        action="store_true",
        help="Keep the DDR PHY/DFII CSR path but omit the SDRAM main-RAM SoC interconnect.",
    )
    parser.add_argument("--ignore-pll-lock-reset", action="store_true")
    parser.add_argument(
        "--no-openxc7-vref-patch",
        action="store_true",
        help="Do not append the YPCB 0.750 V internal VREF FASM features after OpenXC7 builds.",
    )
    parser.add_argument("--build", action="store_true", help="Run synthesis/place/route, not just generation.")
    parser.add_argument(
        "--output-dir",
        default=os.path.join("artifacts", "task6", "litedram-reference", "ypcb-bist-openxc7"),
    )
    args = parser.parse_args()

    soc = YPCBLiteDRAMBISTSoC(
        sys_clk_freq=args.sys_clk_freq,
        dram_channel=args.dram_channel,
        byte_groups=args.byte_groups,
        module_name=args.module,
        with_bist=not args.no_bist,
        with_raw_bscan=args.with_raw_bscan,
        dfii_only=args.dfii_only,
        ignore_pll_lock_reset=args.ignore_pll_lock_reset,
        s7_phy=args.s7_phy,
        toolchain=args.toolchain,
    )
    builder = Builder(
        soc,
        output_dir=args.output_dir,
        csr_csv=os.path.join(args.output_dir, "csr.csv"),
        csr_json=os.path.join(args.output_dir, "csr.json"),
    )
    builder.build(run=args.build)
    if args.build and args.toolchain == "openxc7" and not args.no_openxc7_vref_patch:
        result = patch_openxc7_vref_bitstream(args.output_dir)
        print("Patched OpenXC7 YPCB VREF features into", result["bitstream"])


if __name__ == "__main__":
    main()
