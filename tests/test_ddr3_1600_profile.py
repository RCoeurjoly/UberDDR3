#!/usr/bin/env python3
"""Static checks for the DDR3-1600 TOC target profile."""

from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class Ddr31600ProfileTests(unittest.TestCase):
    def test_ddr3_1600_timing_constants_are_encoded(self):
        controller = (ROOT / "rtl" / "ddr3_controller.v").read_text(encoding="utf-8")
        self.assertIn("(SPEED_BIN == 3) ? 13_750", controller)
        self.assertIn("(SPEED_BIN == 3) ? 35_000", controller)
        self.assertIn("ddr3_clk_period <= 1_500 && ddr3_clk_period >= 1_250", controller)
        self.assertIn("CL_generator = 4'd11", controller)
        self.assertIn("CWL_generator = 4'd8", controller)


    def test_ddr800_profile_and_speed_mode_guards_are_present(self):
        flake = (ROOT / "flake.nix").read_text(encoding="utf-8")
        controller = (ROOT / "rtl" / "ddr3_controller.v").read_text(encoding="utf-8")
        self.assertIn('name = "ddr800";', flake)
        self.assertIn("controllerClkPeriod = 5000;", flake)
        self.assertIn("ddr3ClkPeriod = 1250;", flake)
        self.assertIn("speedBin = 3;", flake)
        self.assertIn('controllerFreqMHz = "200.000";', flake)
        self.assertIn("SPEED_MODE_DDR3_1600 = (DDR3_CLK_PERIOD == 1_250)", controller)
        self.assertIn("ENABLE_STAGE1_ANTICIPATE = !SPEED_MODE_DDR3_1600", controller)
        self.assertIn("ENABLE_SECOND_WISHBONE = SECOND_WISHBONE && !SPEED_MODE_DDR3_1600", controller)


if __name__ == "__main__":
    unittest.main()
