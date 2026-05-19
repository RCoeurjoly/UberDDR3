#!/usr/bin/env python3

import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "task6"))

import extract_ypcb_phaser_sequence as extractor  # noqa: E402
import generate_ypcb_phaser_sequence_header as generator  # noqa: E402


class PhaserSequenceTest(unittest.TestCase):
    def test_checked_in_observed_header_matches_generator(self):
        spec_path = ROOT / "example_demo" / "ypcb_00338_1p1" / "ypcb_phaser_byte_lane_diag_sequence_observed.json"
        header_path = ROOT / "example_demo" / "ypcb_00338_1p1" / "ypcb_phaser_byte_lane_diag_sequence.vh"
        spec = generator.load_spec(spec_path)
        rendered = generator.render_header(
            spec,
            source="ypcb_phaser_byte_lane_diag_sequence_observed.json",
        )
        self.assertEqual(header_path.read_text(encoding="utf-8"), rendered)

    def test_extract_collapse_builds_two_steps(self):
        samples = [
            {
                "sample_index": 0,
                "sync_enable": 0,
                "phyctl_reset": 1,
                "phyctlwrenable": 0,
                "phyctlwd": 0,
                "pll_locked": 0,
            },
            {
                "sample_index": 1,
                "sync_enable": 0,
                "phyctl_reset": 1,
                "phyctlwrenable": 0,
                "phyctlwd": 0,
                "pll_locked": 1,
            },
            {
                "sample_index": 2,
                "sync_enable": 1,
                "phyctl_reset": 0,
                "phyctlwrenable": 1,
                "phyctlwd": 0x000000A5,
                "pll_locked": 1,
            },
            {
                "sample_index": 3,
                "sync_enable": 1,
                "phyctl_reset": 0,
                "phyctlwrenable": 1,
                "phyctlwd": 0x000000A5,
                "pll_locked": 1,
            },
        ]
        spec = extractor.build_spec(
            samples,
            name="unit-test-sequence",
            clock_domain="clk50",
            control_aliases=["sync_enable", "phyctl_reset", "phyctlwrenable"],
            wait_aliases=["pll_locked"],
            phyctlwd_alias="phyctlwd",
        )
        self.assertEqual(spec["schema"], "ypcb-phaser-byte-lane-sequence-v1")
        self.assertEqual(len(spec["steps"]), 2)
        self.assertEqual(spec["steps"][0]["dwell_cycles"], 2)
        self.assertTrue(spec["steps"][0]["controls"]["phyctl_reset"])
        self.assertEqual(spec["steps"][1]["phyctlwd"], 0xA5)
        self.assertEqual(spec["metadata"]["first_assertions"]["pll_locked"], 1)


if __name__ == "__main__":
    unittest.main()
