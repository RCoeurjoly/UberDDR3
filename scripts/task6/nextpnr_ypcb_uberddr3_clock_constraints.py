"""Clock constraints for YPCB UberDDR3 nextpnr builds."""

import os


controller_clk_mhz = float(os.environ.get("YPCB_UBERDDR3_CONTROLLER_CLK_MHZ", "25.0"))

# These names are taken from nextpnr clock reports for boot-clean YPCB
# UberDDR3 rowstream-loader builds. Missing names are harmless: nextpnr logs a
# warning and ignores that specific constraint.
for name, mhz in [
    ("controller_clk", controller_clk_mhz),
    ("clk25_raw", 25.0),
    ("clk100_raw", 100.0),
    ("clk100_90_raw", 100.0),
    ("ddr3_clk", 100.0),
    ("ddr3_clk_90", 100.0),
    ("clk200_raw", 200.0),
    ("ref_clk", 200.0),
]:
    ctx.addClock(name, mhz)
    ctx.addClock("bist_top." + name, mhz)
