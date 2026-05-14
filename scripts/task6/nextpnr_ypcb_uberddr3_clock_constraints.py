"""Clock constraints for YPCB UberDDR3 nextpnr builds.

The defaults match example_demo/ypcb_00338_1p1/clk_wiz.v:

- 50 MHz input clock
- PLLE2_ADV CLKFBOUT_MULT=20, DIVCLK_DIVIDE=1 -> 1000 MHz VCO
- CLKOUT0_DIVIDE=8 -> controller_clk = 125 MHz
- CLKOUT1_DIVIDE=2 -> ddr3_clk = 500 MHz
- CLKOUT2_DIVIDE=5 -> ref_clk = 200 MHz
- CLKOUT3_DIVIDE=2, phase 90 -> ddr3_clk_90 = 500 MHz

The DDR3 clock must stay at or above 400 MHz on Kintex-7 DDR3 designs to avoid
the AMD/Xilinx Phaser divide-by-two operating range called out for 303-399 MHz.
"""

import os


def env_mhz(name, default):
    return float(os.environ.get(name, str(default)))


controller_clk_mhz = env_mhz("YPCB_UBERDDR3_CONTROLLER_CLK_MHZ", 125.0)
ddr3_clk_mhz = env_mhz("YPCB_UBERDDR3_DDR3_CLK_MHZ", 500.0)
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
