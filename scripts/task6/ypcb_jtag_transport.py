#!/usr/bin/env python3
"""Shared JTAG transport helpers for YPCB host-side tooling."""

from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
READ_JTAG = ROOT / "scripts" / "task6" / "read_jtag_debug_ftdi_bitbang.py"
WRITE_JTAG = ROOT / "scripts" / "task6" / "write_jtag_command_ftdi_bitbang.py"


class JtagTransportError(RuntimeError):
    """Raised when a JTAG read/write helper exits unsuccessfully."""


def extract_json(stdout: str) -> dict[str, Any]:
    start = stdout.find("{")
    end = stdout.rfind("}")
    if start < 0 or end < start:
        raise JtagTransportError(f"command output did not contain JSON:\n{stdout}")
    return json.loads(stdout[start : end + 1])


@dataclass(frozen=True)
class JtagTransportConfig:
    serial: str = "210299BF3824"
    tdo_bit: int = 7
    bits: int = 1024
    backend: str = "mpsse"
    freq_hz: int = 1_000_000
    bit_delay_us: float = 0.0
    ir_len: int = 6
    read_user_ir: int = 0x02
    write_user_ir: int = 0x03
    update_mode: str = "idle"


class ScriptJtagTransport:
    """Invoke the existing FTDI helper scripts through a protocol-neutral API."""

    def __init__(self, config: JtagTransportConfig) -> None:
        self.config = config

    def run_json(self, argv: list[str]) -> dict[str, Any]:
        proc = subprocess.run(
            argv,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise JtagTransportError(proc.stdout)
        return extract_json(proc.stdout)

    def read_debug(self, *, bits: int | None = None, user_ir: int | None = None) -> dict[str, Any]:
        argv = [
            sys.executable,
            str(READ_JTAG),
            "--serial",
            self.config.serial,
            "--backend",
            self.config.backend,
            "--tdo-bit",
            str(self.config.tdo_bit),
            "--ir-len",
            str(self.config.ir_len),
            "--user-ir",
            f"0x{(self.config.read_user_ir if user_ir is None else user_ir):x}",
            "--bits",
            str(self.config.bits if bits is None else bits),
            "--json-only",
        ]
        if self.config.backend == "mpsse":
            argv.extend(["--freq-hz", str(self.config.freq_hz)])
        else:
            argv.extend(["--bit-delay-us", str(self.config.bit_delay_us)])
        return self.run_json(argv)

    def write_payload(
        self,
        payload: int,
        *,
        bits: int,
        user_ir: int | None = None,
        update_mode: str | None = None,
    ) -> dict[str, Any]:
        argv = [
            sys.executable,
            str(WRITE_JTAG),
            "--serial",
            self.config.serial,
            "--backend",
            self.config.backend,
            "--tdo-bit",
            str(self.config.tdo_bit),
            "--ir-len",
            str(self.config.ir_len),
            "--user-ir",
            f"0x{(self.config.write_user_ir if user_ir is None else user_ir):x}",
            "--bits",
            str(bits),
            "--payload",
            f"0x{payload:x}",
            "--update-mode",
            update_mode or self.config.update_mode,
            "--json-only",
        ]
        if self.config.backend == "mpsse":
            argv.extend(["--freq-hz", str(self.config.freq_hz)])
        else:
            argv.extend(["--bit-delay-us", str(self.config.bit_delay_us)])
        return self.run_json(argv)
