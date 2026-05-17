#!/usr/bin/env python3

import pathlib
import sys
from types import SimpleNamespace
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "task6"))

import ypcb_litedram_bscan as bscan  # noqa: E402


class RawBscanProtocolTest(unittest.TestCase):
    def test_command_round_trip_uses_full_32_bit_address(self):
        command = bscan.encode_command(
            bscan.OP_WB_WRITE,
            addr=0x4000_0000,
            data=0xA5A5_5A5A,
        )

        self.assertEqual(
            bscan.decode_command(command),
            {
                "magic_ok": True,
                "opcode": bscan.OP_WB_WRITE,
                "addr": 0x4000_0000,
                "data": 0xA5A5_5A5A,
            },
        )

    def test_pack_unpack_little_endian_dfii_bytes(self):
        values = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
        packed = bscan.pack_le_bytes(values)

        self.assertEqual(packed, 0xEFCD_AB89_6745_2301)
        self.assertEqual(bscan.unpack_le_bytes(packed), values)

    def test_dfii_phase_register_map_matches_generated_csr_stride(self):
        self.assertEqual(bscan.phase_reg(0, 0x00), 0x1804)
        self.assertEqual(bscan.phase_reg(0, 0x18), 0x181C)
        self.assertEqual(bscan.phase_reg(1, 0x00), 0x1824)
        self.assertEqual(bscan.phase_reg(3, 0x18), 0x187C)

    def test_extended_status_decodes_bridge_diagnostic_fields(self):
        payload = bscan.READ_MAGIC
        payload |= 1 << 511
        payload |= 0x12 << 512
        payload |= 0x03 << 520
        payload |= bscan.OP_DFII_PATTERN << 528
        payload |= 0x01 << 536
        payload |= 0x02 << 544
        payload |= 0x03 << 552
        payload |= 0x4000_0000 << 560
        payload |= 0xA5A5_5A5A << 592
        payload |= 0xFFFF_FFFF << 624
        payload |= 0x11 << 656
        payload |= 0x22 << 688

        status = bscan.decode_status(payload)

        self.assertTrue(status["diag_active"])
        self.assertEqual(status["diag_state"], 0x12)
        self.assertEqual(status["diag_status"], "0x03")
        self.assertEqual(status["diag_opcode"], "0x42")
        self.assertEqual(status["diag_module_mask_int"], 1)
        self.assertEqual(status["diag_bitslip"], 2)
        self.assertEqual(status["diag_delay"], 3)
        self.assertEqual(status["diag_addr_int"], 0x4000_0000)
        self.assertEqual(status["diag_expected_int"], 0xA5A5_5A5A)
        self.assertEqual(status["diag_actual_int"], 0xFFFF_FFFF)
        self.assertEqual(status["diag_count"], 0x11)
        self.assertEqual(status["diag_error_count"], 0x22)

    def test_lfsr32_matches_litex_known_prefix(self):
        value = 42
        prefix = []
        for _ in range(8):
            value = bscan.lfsr32(value)
            prefix.append(value)

        self.assertEqual(
            prefix,
            [
                0x0000_0015,
                0x8020_0009,
                0xC030_0007,
                0xE038_0000,
                0x701C_0000,
                0x380E_0000,
                0x1C07_0000,
                0x0E03_8000,
            ],
        )

    def test_selected_module_masks_expands_bits_in_order(self):
        self.assertEqual(bscan.selected_module_masks(0xA5), [0x01, 0x04, 0x20, 0x80])

    def test_100mhz_init_sequence_matches_generated_litedram_header(self):
        timing = bscan.phy_timing(100e6)
        sequence = bscan.litedram_ddr3_init_sequence(100e6)

        self.assertEqual(timing["rdphase"], 2)
        self.assertEqual(timing["wrphase"], 3)
        self.assertEqual(timing["mr2"], 0x0200)
        self.assertEqual(timing["mr0"], 0x0930)
        self.assertIn("CWL=5", sequence[2][0])
        self.assertEqual(sequence[2][1], 0x0200)
        self.assertIn("CL=7", sequence[5][0])
        self.assertEqual(sequence[5][1], 0x0930)

    def test_125mhz_init_sequence_matches_generated_litedram_header(self):
        timing = bscan.phy_timing(125e6)
        sequence = bscan.litedram_ddr3_init_sequence(125e6)

        self.assertEqual(timing["rdphase"], 1)
        self.assertEqual(timing["wrphase"], 2)
        self.assertEqual(timing["mr2"], 0x0208)
        self.assertEqual(timing["mr0"], 0x0940)
        self.assertIn("CWL=6", sequence[2][0])
        self.assertEqual(sequence[2][1], 0x0208)
        self.assertIn("CL=8", sequence[5][0])
        self.assertEqual(sequence[5][1], 0x0940)

    def test_tdqs_sets_mr1_bit_without_changing_termination_baseline(self):
        self.assertEqual(bscan.ddr3_mr1(tdqs=False), 0x0006)
        self.assertEqual(bscan.ddr3_mr1(tdqs=True), 0x0806)
        self.assertEqual(bscan.litedram_ddr3_init_sequence(100e6, tdqs=True)[4][1], 0x0806)

    def test_dfii_training_uses_generated_read_write_phases(self):
        calls = []

        def fake_address_write(_client, _args, phase, address):
            calls.append(("addr", phase, address))

        def fake_baddress_write(_client, _args, phase, bank):
            calls.append(("bank", phase, bank))

        def fake_command(_client, _args, phase, command):
            calls.append(("cmd", phase, command))

        def fake_write_data(_client, _args, phase, values):
            calls.append(("wrdata", phase, len(values)))

        def fake_read_data(_client, _args, phase):
            calls.append(("rddata", phase))
            return [0] * bscan.DFII_PIX_DATA_BYTES

        original = (
            bscan.dfii_phase_address_write,
            bscan.dfii_phase_baddress_write,
            bscan.dfii_command,
            bscan.dfii_write_data,
            bscan.dfii_read_data,
            bscan.cdelay,
        )
        try:
            bscan.dfii_phase_address_write = fake_address_write
            bscan.dfii_phase_baddress_write = fake_baddress_write
            bscan.dfii_command = fake_command
            bscan.dfii_write_data = fake_write_data
            bscan.dfii_read_data = fake_read_data
            bscan.cdelay = lambda _args, _cycles: None
            bscan.dfii_write_read_check_test_pattern(None, SimpleNamespace(sys_clk_freq=100e6), 0, 42)
        finally:
            (
                bscan.dfii_phase_address_write,
                bscan.dfii_phase_baddress_write,
                bscan.dfii_command,
                bscan.dfii_write_data,
                bscan.dfii_read_data,
                bscan.cdelay,
            ) = original

        self.assertIn(("cmd", 3, bscan.DFII_COMMAND_CAS | bscan.DFII_COMMAND_WE | bscan.DFII_COMMAND_CS | bscan.DFII_COMMAND_WRDATA), calls)
        self.assertIn(("cmd", 2, bscan.DFII_COMMAND_CAS | bscan.DFII_COMMAND_CS | bscan.DFII_COMMAND_RDDATA), calls)


if __name__ == "__main__":
    unittest.main()
