#!/usr/bin/env python3
"""XSDB driver for the Vivado YPCB-00338-1P1 systest DDR3 golden reference."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GOLDEN = (
    ROOT
    / "artifacts"
    / "task6"
    / "vivado-golden"
    / "ypcb-00338-1p1-systest-2026-05-16"
)
DEFAULT_XSDB = Path("/home/roland/Vivado/2025.2.1/Vivado/bin/xsdb")
DEFAULT_HW_SERVER = Path("/home/roland/Vivado/2025.2.1/Vivado/bin/hw_server")


@dataclass(frozen=True)
class MemRange:
    name: str
    instance: str
    base: int
    high: int
    bus_interface: str
    master: str
    range_type: str

    @property
    def size(self) -> int:
        return self.high - self.base + 1

    def to_json(self) -> dict[str, object]:
        return {
            "name": self.name,
            "instance": self.instance,
            "base": f"0x{self.base:08x}",
            "high": f"0x{self.high:08x}",
            "size": self.size,
            "bus_interface": self.bus_interface,
            "master": self.master,
            "range_type": self.range_type,
        }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def int_prop(node: ET.Element, name: str) -> int | None:
    attr_value = node.get(name)
    if attr_value is not None:
        return int(attr_value, 0)
    prop = node.find(f"./PARAMETER[@NAME='{name}']")
    if prop is None:
        return None
    value = prop.get("VALUE")
    if value is None:
        return None
    return int(value, 0)


def str_prop(node: ET.Element, name: str, default: str = "") -> str:
    attr_value = node.get(name)
    if attr_value is not None:
        return attr_value
    prop = node.find(f"./PARAMETER[@NAME='{name}']")
    if prop is None:
        return default
    return prop.get("VALUE") or default


def parse_hwh_memranges(hwh: Path) -> list[MemRange]:
    root = ET.parse(hwh).getroot()
    ranges: list[MemRange] = []
    for module in root.findall(".//MODULE"):
        instance = module.get("INSTANCE") or module.get("NAME") or ""
        for memrange in module.findall(".//MEMRANGE"):
            base = int_prop(memrange, "BASEVALUE")
            high = int_prop(memrange, "HIGHVALUE")
            if base is None or high is None:
                continue
            ranges.append(
                MemRange(
                    name=memrange.get("ADDRESSBLOCK")
                    or memrange.get("INSTANCE")
                    or memrange.get("NAME")
                    or "",
                    instance=memrange.get("INSTANCE") or instance,
                    base=base,
                    high=high,
                    bus_interface=str_prop(memrange, "SLAVEBUSINTERFACE", ""),
                    master=str_prop(memrange, "MASTERBUSINTERFACE", ""),
                    range_type=str_prop(memrange, "MEMTYPE", ""),
                )
            )
    return sorted(ranges, key=lambda item: (item.master, item.base, item.name))


def select_channel_range(
    ranges: list[MemRange],
    channel: str,
    access_master: str,
) -> MemRange:
    channel_l = channel.lower()
    if channel_l not in {"c0", "c1"}:
        raise ValueError(f"unsupported channel: {channel}")
    master_name = {"microblaze": "M_AXI_DC", "xdma": "M_AXI"}[access_master]
    candidates = [
        item
        for item in ranges
        if item.name.lower() == f"{channel_l}_memaddr" and item.master == master_name
    ]
    if not candidates:
        raise RuntimeError(f"could not find {access_master} {channel} DDR3 range")
    return candidates[0]


def pattern_value(index: int) -> int:
    value = 0xA5A50000 ^ ((index * 0x1F1F1F1F) & 0xFFFFFFFF)
    return value & 0xFFFFFFFF


def make_integrity_tcl(args: argparse.Namespace, addresses: list[int], values: list[int]) -> str:
    bitstream = str(args.bitstream.resolve())
    lines = [
        f"connect -url {{{args.hw_server_url}}}",
        "puts {YPCB_XSDB_CONNECTED}",
    ]
    if args.program:
        lines += [
            f"targets -set -filter {{{args.fpga_filter}}}",
            f"fpga -file {{{bitstream}}}",
            f"after {args.post_program_delay_ms}",
            "puts {YPCB_FPGA_PROGRAMMED}",
        ]
    lines += [
        f"targets -set -filter {{{args.processor_filter}}}",
        "catch {stop}",
        "puts {YPCB_PROCESSOR_SELECTED}",
    ]
    for index, (addr, value) in enumerate(zip(addresses, values)):
        lines.append(f"mwr -force 0x{addr:x} 0x{value:08x}")
        lines.append(f"puts {{YPCB_WRITE {index} 0x{addr:x} 0x{value:08x}}}")
    lines.append(f"after {args.post_write_delay_ms}")
    for index, (addr, value) in enumerate(zip(addresses, values)):
        lines.append(f"set ypcb_read_{index} [mrd -force 0x{addr:x}]")
        lines.append(
            f"puts \"YPCB_READ {index} 0x{addr:x} 0x{value:08x} $ypcb_read_{index}\""
        )
    lines.append("exit")
    return "\n".join(lines) + "\n"


READ_RE = re.compile(
    r"YPCB_READ\s+(?P<index>\d+)\s+"
    r"(?P<addr>0x[0-9a-fA-F]+)\s+"
    r"(?P<expected>0x[0-9a-fA-F]+)\s+"
    r"(?P<rest>.*)$"
)
HEX_RE = re.compile(r"0x[0-9a-fA-F]+|\b[0-9a-fA-F]{8}\b")


def parse_xsdb_reads(output: str) -> list[dict[str, object]]:
    reads: list[dict[str, object]] = []
    for line in output.splitlines():
        match = READ_RE.search(line)
        if not match:
            continue
        hex_values = HEX_RE.findall(match.group("rest"))
        actual_text = hex_values[-1] if hex_values else "0x0"
        expected = int(match.group("expected"), 16) & 0xFFFFFFFF
        actual = int(actual_text, 16) & 0xFFFFFFFF
        reads.append(
            {
                "index": int(match.group("index")),
                "address": match.group("addr").lower(),
                "expected": f"0x{expected:08x}",
                "actual": f"0x{actual:08x}",
                "pass": actual == expected,
                "raw": line,
            }
        )
    return reads


def emit_json(payload: dict[str, object], output: Path | None) -> None:
    text = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")
    print(text, end="")


def cmd_address_map(args: argparse.Namespace) -> int:
    ranges = parse_hwh_memranges(args.hwh)
    payload = {
        "schema": "ypcb-vivado-systest-address-map-v1",
        "hwh": str(args.hwh.resolve()),
        "hwh_sha256": sha256_file(args.hwh),
        "ranges": [item.to_json() for item in ranges],
    }
    emit_json(payload, args.output)
    return 0


def cmd_make_tcl(args: argparse.Namespace) -> int:
    ranges = parse_hwh_memranges(args.hwh)
    selected = select_channel_range(ranges, args.channel, args.access_master)
    addresses = [selected.base + args.offset + 4 * index for index in range(args.words)]
    values = [pattern_value(index) for index in range(args.words)]
    tcl = make_integrity_tcl(args, addresses, values)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(tcl, encoding="utf-8")
    else:
        print(tcl, end="")
    return 0


def cmd_integrity(args: argparse.Namespace) -> int:
    hw_server_proc: subprocess.Popen[str] | None = None
    if args.launch_hw_server:
        args.hw_server = args.hw_server.resolve()
        if not args.hw_server.exists():
            raise SystemExit(f"hw_server not found: {args.hw_server}")
        hw_server_proc = subprocess.Popen(
            [str(args.hw_server), "-s", args.hw_server_listen],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        time.sleep(args.hw_server_startup_delay)
        if hw_server_proc.poll() is not None:
            output = hw_server_proc.stdout.read() if hw_server_proc.stdout else ""
            raise SystemExit(f"hw_server exited before XSDB connect:\n{output}")

    ranges = parse_hwh_memranges(args.hwh)
    selected = select_channel_range(ranges, args.channel, args.access_master)
    addresses = [selected.base + args.offset + 4 * index for index in range(args.words)]
    values = [pattern_value(index) for index in range(args.words)]
    tcl = make_integrity_tcl(args, addresses, values)
    args.xsdb = args.xsdb.resolve()
    if not args.xsdb.exists():
        raise SystemExit(f"xsdb not found: {args.xsdb}")
    start = time.time()
    with tempfile.NamedTemporaryFile("w", suffix=".tcl", delete=False, encoding="utf-8") as handle:
        handle.write(tcl)
        tcl_path = Path(handle.name)
    try:
        proc = subprocess.run(
            [str(args.xsdb), str(tcl_path)],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
            timeout=args.timeout,
        )
    finally:
        if hw_server_proc is not None:
            hw_server_proc.terminate()
            try:
                hw_server_proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                hw_server_proc.kill()
                hw_server_proc.wait(timeout=5)
        if not args.keep_tcl:
            try:
                tcl_path.unlink()
            except FileNotFoundError:
                pass
    reads = parse_xsdb_reads(proc.stdout)
    payload = {
        "schema": "ypcb-vivado-systest-integrity-v1",
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "xsdb": str(args.xsdb),
        "bitstream": str(args.bitstream.resolve()),
        "bitstream_sha256": sha256_file(args.bitstream),
        "hwh": str(args.hwh.resolve()),
        "hwh_sha256": sha256_file(args.hwh),
        "programmed": bool(args.program),
        "channel": args.channel,
        "selected_range": selected.to_json(),
        "offset": args.offset,
        "words": args.words,
        "returncode": proc.returncode,
        "launch_hw_server": bool(args.launch_hw_server),
        "hw_server": str(args.hw_server.resolve()) if args.launch_hw_server else None,
        "hw_server_listen": args.hw_server_listen if args.launch_hw_server else None,
        "elapsed_seconds": round(time.time() - start, 3),
        "tcl_path": str(tcl_path) if args.keep_tcl else None,
        "reads": reads,
        "pass": proc.returncode == 0 and len(reads) == args.words and all(item["pass"] for item in reads),
        "xsdb_output": proc.stdout,
    }
    emit_json(payload, args.output)
    return 0 if payload["pass"] else 1


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--hwh", type=Path, default=DEFAULT_GOLDEN / "top.hwh")
    parser.add_argument("--output", type=Path)


def add_xsdb_common(parser: argparse.ArgumentParser) -> None:
    add_common(parser)
    parser.add_argument("--xsdb", type=Path, default=Path(os.environ.get("XSDB", DEFAULT_XSDB)))
    parser.add_argument("--hw-server", type=Path, default=Path(os.environ.get("HW_SERVER", DEFAULT_HW_SERVER)))
    parser.add_argument("--launch-hw-server", action="store_true")
    parser.add_argument("--hw-server-listen", default="tcp::3121")
    parser.add_argument("--hw-server-startup-delay", type=float, default=2.0)
    parser.add_argument("--bitstream", type=Path, default=DEFAULT_GOLDEN / "top_wrapper.bit")
    parser.add_argument("--hw-server-url", default="tcp:localhost:3121")
    parser.add_argument("--fpga-filter", default='name =~ "*xc7k480t*"')
    parser.add_argument("--processor-filter", default='name =~ "*MicroBlaze #0*"')
    parser.add_argument("--channel", choices=["c0", "c1"], default="c0")
    parser.add_argument("--access-master", choices=["microblaze", "xdma"], default="microblaze")
    parser.add_argument("--offset", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--words", type=int, default=16)
    parser.add_argument("--program", action="store_true")
    parser.add_argument("--post-program-delay-ms", type=int, default=3000)
    parser.add_argument("--post-write-delay-ms", type=int, default=100)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    address_map = subparsers.add_parser("address-map")
    add_common(address_map)
    address_map.set_defaults(func=cmd_address_map)

    make_tcl = subparsers.add_parser("make-integrity-tcl")
    add_xsdb_common(make_tcl)
    make_tcl.set_defaults(func=cmd_make_tcl)

    integrity = subparsers.add_parser("integrity")
    add_xsdb_common(integrity)
    integrity.add_argument("--timeout", type=float, default=120.0)
    integrity.add_argument("--keep-tcl", action="store_true")
    integrity.set_defaults(func=cmd_integrity)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
