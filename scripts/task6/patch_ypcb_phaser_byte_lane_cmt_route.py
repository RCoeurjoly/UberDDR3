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
    "CMT_FREQ_BB_PREF_IN0.PLL_CLK_FREQBB_REBUFOUT0": "CMT_FREQ_BB_PREF_IN2.PLL_CLK_FREQBB_REBUFOUT2",
    "MMCM_CLK_FREQ_BB_REBUF0_NS.MMCM_CLK_FREQ_BB_NS0": "MMCM_CLK_FREQ_BB_REBUF2_NS.MMCM_CLK_FREQ_BB_NS2",
    "PLL_CLK_FREQBB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFOUT0": "PLL_CLK_FREQBB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFOUT2",
    "PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN1": "PLLOUT_CLK_FREQ_BB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFIN1",
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
    "INT_R_X1Y19.IMUX29.BYP_BOUNCE1",
    "INT_R_X1Y17.IMUX46.SW2END3",
    # Overlaps the CMT_TOP_R_UPPER_B word-68 PHY_CONTROL-ready oracle bits
    # at bit_00460086_68_20 / bit_00460087_68_21.
    "INT_R_X1Y33.NE6BEG3.LOGIC_OUTS17",
}


def patch_fasm(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)

    lines = [line for line in text.splitlines() if line.strip() not in EXCLUDED_FEATURES]
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
