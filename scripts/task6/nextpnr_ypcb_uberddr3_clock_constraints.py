"""Clock constraints for YPCB UberDDR3 nextpnr builds.

These match the AMD/Xilinx Kintex-7 external-memory-interface guidance used by
the active YPCB shell:

- ddr3_clk = 500 MHz
- ddr3_clk_90 = 500 MHz
- controller_clk = 125 MHz
- ref_clk = 200 MHz
"""

import os


def env_mhz(name, default):
    return float(os.environ.get(name, str(default)))


controller_clk_mhz = env_mhz("YPCB_UBERDDR3_CONTROLLER_CLK_MHZ", 125.0)
ddr3_clk_mhz = env_mhz("YPCB_UBERDDR3_DDR3_CLK_MHZ", 500.0)
ref_clk_mhz = env_mhz("YPCB_UBERDDR3_REF_CLK_MHZ", 200.0)
clk125_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK125_RAW_MHZ", controller_clk_mhz)
clk500_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK500_RAW_MHZ", ddr3_clk_mhz)
clk500_90_raw_mhz = env_mhz("YPCB_UBERDDR3_CLK500_90_RAW_MHZ", ddr3_clk_mhz)

# These names are taken from nextpnr clock reports for boot-clean YPCB
# UberDDR3 rowstream-loader builds. Missing names are harmless: nextpnr logs a
# warning and ignores that specific constraint.
for name, mhz in [
    ("controller_clk", controller_clk_mhz),
    ("clk125_raw", clk125_raw_mhz),
    ("clk500_raw", clk500_raw_mhz),
    ("clk500_90_raw", clk500_90_raw_mhz),
    ("ddr3_clk", ddr3_clk_mhz),
    ("ddr3_clk_90", ddr3_clk_mhz),
    ("clk200_raw", ref_clk_mhz),
    ("ref_clk", ref_clk_mhz),
]:
    ctx.addClock(name, mhz)
    ctx.addClock("bist_top." + name, mhz)
