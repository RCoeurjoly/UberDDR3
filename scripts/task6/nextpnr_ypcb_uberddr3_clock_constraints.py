"""Clock constraints for YPCB UberDDR3 nextpnr builds.

These match the hardware-calibrated v44 shell:

- ddr3_clk = 100 MHz
- ddr3_clk_90 = 100 MHz
- controller_clk = 25 MHz
- ref_clk = 200 MHz

The AMD/Xilinx Phaser divide-by-two note still matters for a future high-speed
MIG-compatible target, but the current open-source YPCB bring-up baseline is
the v44 shell that already calibrates on this board.
"""

import os


def env_mhz(name, default):
    return float(os.environ.get(name, str(default)))


controller_clk_mhz = env_mhz("YPCB_UBERDDR3_CONTROLLER_CLK_MHZ", 25.0)
ddr3_clk_mhz = env_mhz("YPCB_UBERDDR3_DDR3_CLK_MHZ", 100.0)
ref_clk_mhz = env_mhz("YPCB_UBERDDR3_REF_CLK_MHZ", 200.0)
clk25_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK25_RAW_MHZ", controller_clk_mhz)
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
