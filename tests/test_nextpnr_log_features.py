#!/usr/bin/env python3
"""Unit tests for TOC-oriented nextpnr log extraction."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "uberddr3_extract_nextpnr_log_features.py"


def load_module():
    spec = importlib.util.spec_from_file_location("nextpnr_features", SCRIPT)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class NextpnrLogFeatureTests(unittest.TestCase):
    def test_extracts_toc_timing_and_controller_read_output_family(self):
        module = load_module()
        log = """
Info: Max frequency for clock 'controller_clk': 184.25 MHz (FAIL at 200.00 MHz)
Info: Critical path report for clock 'controller_clk':
  Source: ddr3_controller_inst.index_wb_data
  0.43 ns logic, 3.91 ns routing
  net ddr3_controller_inst.o_wb_data_q_current[17] -> ddr3_controller_inst.o_wb_data[17]
  Sink: ddr3_top_inst.o_wb_data[17]
Info: Slack histogram:
Info: Max frequency for clock 'controller_clk': 201.50 MHz (PASS at 200.00 MHz)
"""
        features = module.extract_features(log)
        self.assertEqual(features["clock_controller_clk_post_mhz"], 201.5)
        self.assertEqual(features["clock_controller_clk_post_status"], "PASS")
        self.assertEqual(features["toc_timing_status"], "pass")
        self.assertEqual(features["toc_critical_family"], "controller_read_output")
        self.assertEqual(features["toc_critical_source"], "ddr3_controller_inst.index_wb_data")
        self.assertEqual(features["toc_critical_sink"], "ddr3_top_inst.o_wb_data[17]")
        self.assertEqual(features["toc_critical_logic_delay_ns"], "0.43")
        self.assertEqual(features["toc_critical_routing_delay_ns"], "3.91")


    def test_extracts_pnr_timing_failure_from_strict_log(self):
        module = load_module()
        log = """
Info: Max frequency for clock 'controller_clk': 96.10 MHz (FAIL at 100.00 MHz)
Info: Critical path report for clock 'controller_clk':
  src: bank_status_q[3]
  4.20 ns routing, 1.30 ns logic
  dst: stage1_do_pre
"""
        features = module.extract_features(log)
        self.assertEqual(features["toc_timing_status"], "pnr_timing")
        self.assertEqual(features["toc_worst_clock_post_mhz"], 96.1)
        self.assertEqual(features["toc_worst_clock_target_mhz"], 100.0)
        self.assertEqual(features["toc_critical_family"], "controller_stage1_anticipate")
        self.assertEqual(features["toc_critical_logic_delay_ns"], "1.30")
        self.assertEqual(features["toc_critical_routing_delay_ns"], "4.20")

    def test_toc_critical_path_prefers_worst_clock_section(self):
        module = load_module()
        log = """
Info: Critical path report for clock 'jtag_debug_bscan_inst.tck':
  Source: jtag_debug_bscan_inst.shift_reg[1]
  0.20 ns logic, 1.10 ns routing
  Sink: jtag_debug_bscan_inst.shift_reg[2]
Info: Critical path report for clock 'controller_clk':
  Source: ddr3_controller_inst.index_wb_data
  1.80 ns logic, 9.10 ns routing
  Sink: ddr3_controller_inst.o_wb_data[106]
Info: Max frequency for clock 'jtag_debug_bscan_inst.tck': 759.30 MHz (PASS at 100.00 MHz)
ERROR: Max frequency for clock            'controller_clk': 92.02 MHz (FAIL at 100.00 MHz)
"""
        features = module.extract_features(log)
        self.assertEqual(features["toc_worst_clock_name"], "controller_clk")
        self.assertEqual(features["toc_timing_status"], "pnr_timing")
        self.assertEqual(features["clock_controller_clk_post_mhz"], 92.02)
        self.assertEqual(features["toc_critical_family"], "controller_read_output")
        self.assertEqual(features["toc_critical_source"], "ddr3_controller_inst.index_wb_data")
        self.assertEqual(features["toc_critical_sink"], "ddr3_controller_inst.o_wb_data[106]")
        self.assertEqual(features["toc_critical_logic_delay_ns"], "1.80")
        self.assertEqual(features["toc_critical_routing_delay_ns"], "9.10")


if __name__ == "__main__":
    unittest.main()
