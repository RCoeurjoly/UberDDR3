#!/usr/bin/env python3

import pathlib
import sys
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
        payload |= bscan.OP_MEM32_CHECK << 528
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
        self.assertEqual(status["diag_opcode"], "0x41")
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


if __name__ == "__main__":
    unittest.main()
