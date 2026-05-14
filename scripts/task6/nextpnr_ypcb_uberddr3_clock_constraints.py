"""Clock constraints for YPCB UberDDR3 nextpnr builds.

The rowstream/BIST top-level PLLs in fpga/rtl currently derive these clocks
from the 50 MHz board input:

- CLKOUT0_DIVIDE=10 -> ddr3_clk = 100 MHz
- CLKOUT1_DIVIDE=10, phase 90 -> ddr3_clk_90 = 100 MHz
- CLKOUT2_DIVIDE=40 -> controller_clk = 25 MHz
- CLKOUT3_DIVIDE=5 -> ref_clk = 200 MHz

These constraints intentionally match the current RTL. The AMD/Xilinx Kintex-7
Phaser note for DDR3/DDR2 says the memory clock should be 400 MHz or higher to
avoid the broken 303-399 MHz divide-by-two mode. That is an RTL/PLL and
UberDDR3-parameter change; nextpnr's global --freq option is not a substitute
for changing the generated DDR3 clock.
"""

import os


def env_mhz(name, default):
    return float(os.environ.get(name, str(default)))


controller_clk_mhz = env_mhz("YPCB_UBERDDR3_CONTROLLER_CLK_MHZ", 25.0)
ddr3_clk_mhz = env_mhz("YPCB_UBERDDR3_DDR3_CLK_MHZ", 100.0)
ref_clk_mhz = env_mhz("YPCB_UBERDDR3_REF_CLK_MHZ", 200.0)
clk25_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK25_RAW_MHZ", 25.0)
clk100_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK100_RAW_MHZ", ddr3_clk_mhz)
clk100_90_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK100_90_RAW_MHZ", ddr3_clk_mhz)

# These names are taken from nextpnr clock reports for boot-clean YPCB
# UberDDR3 rowstream-loader builds. Missing names are harmless: nextpnr logs a
# warning and ignores that specific constraint.
for name, mhz in [
    ("controller_clk", controller_clk_mhz),
    ("clk25_raw", clk25_raw_mhz),
    ("clk100_raw", clk100_raw_mhz),
    ("clk100_90_raw", clk100_90_raw_mhz),
    ("ddr3_clk", ddr3_clk_mhz),
    ("ddr3_clk_90", ddr3_clk_mhz),
    ("clk200_raw", ref_clk_mhz),
    ("ref_clk", ref_clk_mhz),
]:
    ctx.addClock(name, mhz)
    ctx.addClock("bist_top." + name, mhz)
