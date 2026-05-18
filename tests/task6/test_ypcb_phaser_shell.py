#!/usr/bin/env python3

import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "task6"))

import ypcb_phaser_shell as shell  # noqa: E402


class PhaserShellProtocolTest(unittest.TestCase):
    def test_decode_status_payload_reports_expected_fields(self):
        read_data = 0x0011_2233_4455_6677_8899_AABB_CCDD_EEFF
        flags = (
            (1 << shell.PHASER_STATUS_FLAG_READY)
            | (1 << shell.PHASER_STATUS_FLAG_READ_DATA_VALID)
            | (1 << shell.PHASER_STATUS_FLAG_FULLBEAT_MODE)
        )
        payload = (
            shell.PHASER_SHELL_STATUS_MAGIC
            | (shell.PHASER_SHELL_STATUS_VERSION << 32)
            | (shell.PHASER_SHELL_STATE_BUSY << 40)
            | (shell.PHASER_SHELL_OP_READ_CHUNK << 48)
            | (0x03 << 56)
            | (0x1234 << 64)
            | (0x0022 << 80)
            | (0x0044 << 96)
            | (flags << 112)
            | (0x89AB_CDEF << 128)
            | (0x1020_3040 << 160)
            | (0x5060_7080 << 192)
            | (0x90A0_B0C0 << 224)
            | (read_data << 256)
        )

        decoded = shell.decode_phaser_status_payload(payload)

        self.assertTrue(decoded["magic_ok"])
        self.assertEqual(decoded["state"], "BUSY")
        self.assertEqual(decoded["last_opcode"], "0x02")
        self.assertEqual(decoded["last_chunk"], 3)
        self.assertEqual(decoded["command_count"], 0x1234)
        self.assertEqual(decoded["write_count"], 0x0022)
        self.assertEqual(decoded["read_count"], 0x0044)
        self.assertEqual(decoded["last_addr"], "0x89abcdef")
        self.assertEqual(decoded["user0"], "0x10203040")
        self.assertEqual(decoded["user1"], "0x50607080")
        self.assertEqual(decoded["user2"], "0x90a0b0c0")
        self.assertEqual(decoded["read_data128"], "0x00112233445566778899aabbccddeeff")
        self.assertEqual(decoded["read_data128_bytes"][:4], ["ff", "ee", "dd", "cc"])
        self.assertTrue(decoded["flags"]["ready"])
        self.assertTrue(decoded["flags"]["read_data_valid"])
        self.assertTrue(decoded["flags"]["fullbeat_mode"])
        self.assertFalse(decoded["flags"]["error"])

    def test_decode_status_readback_uses_raw_hex(self):
        payload = shell.PHASER_SHELL_STATUS_MAGIC | (shell.PHASER_SHELL_STATUS_VERSION << 32)
        decoded = shell.decode_phaser_status_readback(
            {"raw_hex": f"0x{payload:096x}"},
            bit_count=shell.PHASER_SHELL_STATUS_BITS,
        )
        self.assertTrue(decoded["magic_ok"])
        self.assertEqual(decoded["version"], shell.PHASER_SHELL_STATUS_VERSION)


if __name__ == "__main__":
    unittest.main()
