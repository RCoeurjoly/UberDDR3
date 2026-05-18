#!/usr/bin/env python3

import pathlib
import sys
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "task6"))

import ypcb_ddr3_driver as driver  # noqa: E402


class YpcbDdr3DriverTest(unittest.TestCase):
    def test_rowstream_command_encodes_expected_fields(self):
        command_a = driver.RowstreamCommand(
            driver.ROWSTREAM_OP_WRITE_LOWBYTE,
            0x1234_5678,
            byte=0x5A,
        )
        command_b = driver.RowstreamCommand(
            driver.ROWSTREAM_OP_WRITE_LOWBYTE,
            0x1234_5678,
            byte=0xA5,
        )
        encoded_a = command_a.encode()
        encoded_b = command_b.encode()

        self.assertEqual(encoded_a & 0xFFFF_FFFF, driver.ROWSTREAM_LOADER_MAGIC)
        self.assertEqual((encoded_a >> 32) & 0xFF, driver.ROWSTREAM_OP_WRITE_LOWBYTE)
        self.assertEqual((encoded_a >> 48) & 0xFFFF, 0x5678)
        self.assertNotEqual(encoded_a, encoded_b)

    def test_phaser_shell_command_layout_is_non_overlapping(self):
        command = driver.PhaserShellCommand(
            driver.PHASER_SHELL_OP_WRITE_CHUNK,
            0x1234_5678,
            flags=0xA5,
            chunk=0x03,
            aux=0x12_3456_789A,
            data128=0x0011_2233_4455_6677_8899_AABB_CCDD_EEFF,
        )
        encoded = command.encode()

        self.assertEqual(encoded & 0xFFFF_FFFF, driver.PHASER_SHELL_MAGIC)
        self.assertEqual((encoded >> 32) & 0xFF, driver.PHASER_SHELL_OP_WRITE_CHUNK)
        self.assertEqual((encoded >> 40) & 0xFF, 0xA5)
        self.assertEqual((encoded >> 48) & 0xFF, 0x03)
        self.assertEqual((encoded >> 56) & 0xFFFF_FFFF, 0x1234_5678)
        self.assertEqual((encoded >> 88) & ((1 << 40) - 1), 0x12_3456_789A)
        self.assertEqual((encoded >> 128) & ((1 << 128) - 1), 0x0011_2233_4455_6677_8899_AABB_CCDD_EEFF)

    def test_phaser_fullbeat_write_commands_split_into_four_chunks(self):
        data = bytes(range(driver.BEAT_BYTES))
        commands = driver.phaser_fullbeat_write_commands(0x20, data)

        self.assertEqual(len(commands), driver.CHUNKS_PER_BEAT)
        self.assertEqual([command.chunk for command in commands], [0, 1, 2, 3])
        self.assertEqual(
            commands[0].data128,
            driver.bytes_to_little_int(data[: driver.CHUNK_BYTES]),
        )
        self.assertEqual(
            commands[-1].data128,
            driver.bytes_to_little_int(data[-driver.CHUNK_BYTES :]),
        )


if __name__ == "__main__":
    unittest.main()
