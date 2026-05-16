#!/usr/bin/env python3

import argparse
import os

from migen import *

from litex.build.yosys_wrapper import YosysWrapper
from litex.soc.cores.clock import S7IDELAYCTRL, S7MMCM
from litex.soc.integration.builder import Builder
from litex.soc.integration.soc_core import SoCCore

from litex_boards.platforms import ypcb_00338_1p1

from litedram.common import PHYPadsReducer
from litedram.frontend.bist import _LiteDRAMBISTChecker, _LiteDRAMBISTGenerator
from litedram.modules import MT41J256M16, MT41K256M8
from litedram.phy import s7ddrphy


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


class RawBSCANLiteDRAMBIST(Module):
    def __init__(self, platform, soc, byte_group_mask):
        generator_port = soc.sdram.crossbar.get_port()
        checker_port = soc.sdram.crossbar.get_port()
        self.submodules.generator = generator = _LiteDRAMBISTGenerator(generator_port)
        self.submodules.checker = checker = _LiteDRAMBISTChecker(checker_port)

        bist_reset = Signal()
        generator_start = Signal()
        checker_start = Signal()
        bist_base = Signal(32)
        bist_length = Signal(32)
        bist_random_data = Signal()
        bist_random_addr = Signal()

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
            p_BYTE_GROUP_MASK=byte_group_mask,
            i_sys_clk=ClockSignal("sys"),
            i_sys_rst=ResetSignal("sys"),
            i_clkin=soc.crg.pll.clkin,
            i_idelay_clk=ClockSignal("idelay"),
            i_rst_n_raw=soc.crg.rst_n,
            i_pll_locked=soc.crg.pll.locked,
            i_generator_done=generator.done,
            i_generator_ticks=generator.ticks,
            i_checker_done=checker.done,
            i_checker_ticks=checker.ticks,
            i_checker_errors=checker.errors,
            o_bist_reset=bist_reset,
            o_generator_start=generator_start,
            o_checker_start=checker_start,
            o_bist_base=bist_base,
            o_bist_length=bist_length,
            o_bist_random_data=bist_random_data,
            o_bist_random_addr=bist_random_addr,
        )

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
        ]


class YPCBLiteDRAMBISTSoC(SoCCore):
    def __init__(
        self,
        sys_clk_freq=125e6,
        dram_channel=0,
        byte_groups=(0, 1, 2, 3),
        module_name="mt41k256m8",
        with_bist=True,
        with_raw_bscan=False,
        ignore_pll_lock_reset=False,
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

        pads = PHYPadsReducer(platform.request("ddram", dram_channel), list(byte_groups))
        self.submodules.ddrphy = s7ddrphy.A7DDRPHY(
            pads=pads,
            memtype="DDR3",
            nphases=4,
            sys_clk_freq=sys_clk_freq,
        )

        module_cls = {
            "mt41k256m8": MT41K256M8,
            "mt41j256m16": MT41J256M16,
        }[module_name]
        self.add_sdram(
            "sdram",
            phy=self.ddrphy,
            module=module_cls(sys_clk_freq, "1:4"),
            size=0x20000000,
            l2_cache_size=0,
            with_bist=with_bist,
        )

        if with_raw_bscan:
            byte_group_mask = 0
            for group in byte_groups:
                byte_group_mask |= 1 << group
            self.submodules.raw_bscan_bist = RawBSCANLiteDRAMBIST(self.platform, self, byte_group_mask)


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
    parser.add_argument("--toolchain", default="openxc7", choices=("openxc7", "vivado"))
    parser.add_argument("--no-bist", action="store_true")
    parser.add_argument("--with-raw-bscan", action="store_true")
    parser.add_argument("--ignore-pll-lock-reset", action="store_true")
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
        ignore_pll_lock_reset=args.ignore_pll_lock_reset,
        toolchain=args.toolchain,
    )
    builder = Builder(
        soc,
        output_dir=args.output_dir,
        csr_csv=os.path.join(args.output_dir, "csr.csv"),
        csr_json=os.path.join(args.output_dir, "csr.json"),
    )
    builder.build(run=args.build)


if __name__ == "__main__":
    main()
