#!/usr/bin/env python3

import argparse
import os

from migen import *

from litex.soc.cores.clock import S7MMCM
from litex.soc.cores.gpio import GPIOOut
from litex.soc.integration.builder import Builder
from litex.soc.integration.soc_core import SoCCore
from litex.soc.interconnect.csr import AutoCSR, CSRStatus, CSRStorage

from litex_boards.platforms import ypcb_00338_1p1


class SmokeRegs(Module, AutoCSR):
    def __init__(self):
        self.scratch = CSRStorage(32, reset=0x12345678)
        self.counter = CSRStatus(32)

        counter = Signal(32)
        self.sync += counter.eq(counter + 1)
        self.comb += self.counter.status.eq(counter)


class _CRG(Module):
    def __init__(self, platform, sys_clk_freq):
        self.clock_domains.cd_sys = ClockDomain()

        clk200 = platform.request("clk200")

        self.submodules.pll = pll = S7MMCM(speedgrade=-2)
        pll.register_clkin(clk200, 200e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin)


class YPCBJTAGBoneSmokeSoC(SoCCore):
    def __init__(self, sys_clk_freq=50e6, toolchain="openxc7", **kwargs):
        platform = ypcb_00338_1p1.Platform(toolchain=toolchain)
        if toolchain == "openxc7":
            platform.device = "xc7k480tffg1156-2"

        self.submodules.crg = _CRG(platform, sys_clk_freq)

        SoCCore.__init__(
            self,
            platform,
            clk_freq=sys_clk_freq,
            ident="YPCB LiteX JTAGBone smoke",
            cpu_type=None,
            integrated_rom_size=0,
            integrated_sram_size=0,
            with_uart=False,
            with_timer=False,
            with_jtagbone=True,
            **kwargs,
        )

        self.submodules.smoke = SmokeRegs()
        self.add_csr("smoke")

        led_pads = Cat([platform.request("user_led", i) for i in range(3)])
        self.submodules.leds = GPIOOut(led_pads)
        self.add_csr("leds")


def main():
    parser = argparse.ArgumentParser(description="Generate a minimal YPCB LiteX JTAGBone smoke design.")
    parser.add_argument("--sys-clk-freq", default=50e6, type=float)
    parser.add_argument("--toolchain", default="openxc7", choices=("openxc7", "vivado"))
    parser.add_argument("--build", action="store_true", help="Run synthesis/place/route.")
    parser.add_argument(
        "--output-dir",
        default=os.path.join("artifacts", "task6", "litedram-reference", "ypcb-jtagbone-smoke"),
    )
    args = parser.parse_args()

    soc = YPCBJTAGBoneSmokeSoC(sys_clk_freq=args.sys_clk_freq, toolchain=args.toolchain)
    builder = Builder(
        soc,
        output_dir=args.output_dir,
        csr_csv=os.path.join(args.output_dir, "csr.csv"),
        csr_json=os.path.join(args.output_dir, "csr.json"),
    )
    builder.build(run=args.build)


if __name__ == "__main__":
    main()
