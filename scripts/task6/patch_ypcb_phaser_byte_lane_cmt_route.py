#!/usr/bin/env python3
"""Patch the YPCB PHASER byte-lane FASM to the Vivado-oracle CMT route lanes."""

from __future__ import annotations

import argparse
from pathlib import Path


REPLACEMENTS = {
    # Regenerated locking Vivado byte-lane oracle, c0 ddr_phy_4lanes_0:
    #   PHASER_REF.CLKIN       <- REFMUX_0 <- PREF_IN0
    #   PHY_CONTROL.MEMREFCLK <- REFMUX_1 <- PREF_IN1
    #   PHY_CONTROL.SYNCIN    <- REFMUX_2 <- PREF_IN2
    # Keep REFMUX_0/1 on their natural lanes and only move SYNCIN onto lane 2
    # when nextpnr emits the default lane-0 route.
    "CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN1": "CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN0",
    "CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN0": "CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN1",
    "CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN0": "CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN2",
    "CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN1": "CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN2",
    "CMT_FREQ_BB_PREF_IN0.PLL_CLK_FREQBB_REBUFOUT0": "CMT_FREQ_BB_PREF_IN2.PLL_CLK_FREQBB_REBUFOUT2",
    "MMCM_CLK_FREQ_BB_REBUF0_NS.MMCM_CLK_FREQ_BB_NS0": "MMCM_CLK_FREQ_BB_REBUF2_NS.MMCM_CLK_FREQ_BB_NS2",
    "PLL_CLK_FREQBB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFOUT0": "PLL_CLK_FREQBB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFOUT2",
    "PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN0": "PLLOUT_CLK_FREQ_BB_REBUFOUT1.PLLOUT_CLK_FREQ_BB_REBUFIN0",
    "PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN1": "PLLOUT_CLK_FREQ_BB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFIN1",
    "PLLOUT_CLK_FREQ_BB_REBUFOUT1.PLLOUT_CLK_FREQ_BB_REBUFIN1": "PLLOUT_CLK_FREQ_BB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFIN1",
    "PLL_CLK_FREQ_BB0_NS.PLL_CLK_FREQ_BB_BUFOUT_NS0": "PLL_CLK_FREQ_BB2_NS.PLL_CLK_FREQ_BB_BUFOUT_NS2",
}

COMPANION_FEATURES = (
    "CMT_TOP_R_LOWER_B_X8Y61.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE",
    "HCLK_CMT_X8Y78.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE",
    "CMT_TOP_R_UPPER_B_X8Y31.PHASER_REF_X0Y4.CLOCKED_ORACLE_ROUTE",
)

# Proven collision from the PLLE2_ADV_X0Y1 / PHASER lane-0 candidate:
# fasm2frames reports that this INT route clears the same frame bit required by
# CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE.
# Keep this exclusion local until the underlying segbit row is corrected in the
# database. Do not add the HCLK_CMT_X8Y182 MUX_CLK_5 force here; that broke PLL
# lock in hardware.
EXCLUDED_FEATURES = {
    "INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7",
    "INT_R_X1Y19.IMUX12.NW2END2",
    "INT_R_X1Y19.IMUX29.BYP_BOUNCE1",
    "INT_R_X1Y19.IMUX29.NE2END3",
    "INT_R_X1Y19.IMUX30.NW2END3",
    "INT_R_X1Y19.IMUX45.NW2END3",
    "INT_R_X1Y19.IMUX14.NW2END3",
    "INT_R_X1Y17.IMUX15.SW2END3",
    "INT_R_X1Y17.IMUX15.NW2END_S0_0",
    "INT_R_X1Y17.IMUX14.NW2END3",
    # Lane-0 DDR3 input proof overlap with PHASER_OUT CLKOUT_DIV_4_IN_USE
    # at bit_00460059_35_10.
    "INT_R_X1Y17.IMUX13.BYP_BOUNCE1",
    # IN_FIFO-only DDR3 lane proof overlap with PHASER_OUT CLKOUT_DIV_4_IN_USE
    # at bit_00460059_35_14.
    "INT_R_X1Y17.IMUX45.BYP_BOUNCE1",
    "INT_R_X1Y17.IMUX31.SE2END3",
    "INT_R_X1Y17.IMUX30.SW2END3",
    # Full-port FIFO DDR3 lane proof overlap with PHASER_OUT CLKOUT_DIV_4_IN_USE
    # at bit_00460059_35_20.
    "INT_R_X1Y17.IMUX30.BYP_BOUNCE2",
    "INT_R_X1Y17.IMUX46.BYP_BOUNCE2",
    "INT_R_X1Y17.IMUX46.SW2END3",
    "INT_R_X1Y17.IMUX47.SW2END3",
    "INT_R_X1Y17.IMUX47.BYP_BOUNCE3",
    "INT_R_X1Y18.IMUX32.SW2END0",
    "INT_R_X1Y18.IMUX32.NW2END0",
    "INT_R_X1Y18.IMUX41.SW2END0",
    "INT_R_X1Y18.IMUX1.SW2END0",
    "INT_R_X1Y18.IMUX9.SW2END0",
    # Overlaps the CMT_TOP_R_UPPER_B word-68 PHY_CONTROL-ready oracle bits
    # at bit_00460086_68_20 / bit_00460087_68_21.
    "INT_R_X1Y33.NE6BEG3.LOGIC_OUTS17",
    # Overlaps PHY_CONTROL.IN_USE at bit_00460080_71_25 in the
    # FIFO-idle DDR3 lane proof route.
    "INT_R_X1Y35.CLK0.WR1END1",
    "INT_R_X1Y35.CLK0.SR1END1",
    # Overlaps the focused Vivado OUT_FIFO WREN route row
    # CMT_FIFO_R.CMT_OUT_FIFO_WREN.CMT_FIFO_L_IMUX6_6 at bit_00460088_15_17.
    # IN_FIFO clock/reset DDR3 lane proof overlap with IN_FIFO_X0Y0.IN_USE
    # at bit_00460080_14_27.
    "INT_R_X1Y7.CLK1.SR1END1",
    # OUT_FIFO clock/reset DDR3 lane proof overlap with OUT_FIFO_X0Y0.IN_USE
    # at bit_00460080_14_24.
    "INT_R_X1Y7.CLK0.SR1END1",
    # Both-FIFO both-clock plus OUT-reset proof overlap with OUT_FIFO_X0Y0.IN_USE
    # at bit_00460080_15_9.
    "INT_R_X1Y7.IMUX5.SE2END2",
    "INT_R_X1Y7.IMUX6.BYP_BOUNCE2",
    "INT_R_X1Y7.IMUX6.EE2END3",
    "INT_R_X1Y7.IMUX6.SE2END3",
    "INT_R_X1Y7.IMUX6.SR1END2",
    "INT_R_X1Y7.IMUX6.SS2END2",
    "INT_R_X1Y8.IMUX7.ER1END3",
    "INT_R_X1Y8.IMUX7.BYP_BOUNCE5",
    "INT_R_X1Y8.IMUX7.EE2END3",
    "INT_R_X1Y8.IMUX7.SE2END3",
    # 136-bit readback DDR3 lane proof overlap with IN_FIFO_X0Y0.IN_USE
    # at bit_00460080_16_27.
    "INT_R_X1Y8.CLK1.SR1END1",
    # 136-bit readback DDR3 lane proof overlap with OUT_FIFO_X0Y0.IN_USE
    # at bit_00460081_16_24.
    "INT_R_X1Y8.CLK0.SR1END1",
    # SYSTEST-connected c0.group2.B IN_FIFO reset route overlap: the
    # hardware-passing DCP uses CMT_FIFO_R.CMT_IN_FIFO_RESET.CMT_FIFO_L_IMUX5_7
    # for ififo_rst, and fasm2frames reports that this INT GND route sets the
    # same bit_00460080_30_17 that the oracle-backed FIFO route clears.
    "INT_R_X1Y15.GFAN1.GND_WIRE",
}


def patch_fasm(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)

    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped in EXCLUDED_FEATURES:
            continue
        lines.append(line)
    for feature in COMPANION_FEATURES:
        if feature not in lines:
            lines.append(feature)
    text = "\n".join(lines) + "\n"

    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fasm", type=Path)
    args = parser.parse_args()
    changed = patch_fasm(args.fasm)
    print(f"{args.fasm}: {'patched' if changed else 'unchanged'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
