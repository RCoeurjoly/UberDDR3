#!/usr/bin/env python3
"""Create provisional prjxray segbits rows from a clean bitread delta."""

from __future__ import annotations

import argparse
from pathlib import Path
import re


BIT_RE = re.compile(r"^bit_(?P<frame>[0-9a-fA-F]{8})_(?P<word>\d+)_(?P<bit>\d+)$")


def parse_bits(path: Path) -> set[str]:
    bits: set[str] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        if not BIT_RE.match(line):
            raise ValueError(f"{path}:{line_number}: invalid bitread line: {line!r}")
        bits.add(line)
    return bits


def bit_to_segbit(bit: str, segment_base: int) -> str:
    match = BIT_RE.match(bit)
    if match is None:
        raise ValueError(f"invalid bit id: {bit!r}")
    frame = int(match.group("frame"), 16)
    word = int(match.group("word"))
    bit_index = int(match.group("bit"))
    if frame < segment_base:
        raise ValueError(f"{bit} is before segment base 0x{segment_base:08x}")
    return f"{frame - segment_base}_{word * 32 + bit_index}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-bits", required=True, type=Path)
    parser.add_argument("--other-bits", required=True, type=Path)
    parser.add_argument("--feature", required=True)
    parser.add_argument(
        "--segment-base",
        required=True,
        type=lambda value: int(value, 0),
        help="Frame segment base, for example 0x00460080.",
    )
    parser.add_argument("--origin", default="task6-phaser-feature-oracle")
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    base_bits = parse_bits(args.base_bits)
    other_bits = parse_bits(args.other_bits)
    added = sorted(other_bits - base_bits)
    removed = sorted(base_bits - other_bits)
    if removed:
        raise SystemExit(
            f"refusing to create a single positive feature with {len(removed)} removed bits"
        )
    if not added:
        raise SystemExit("no added bits")

    segbits = [bit_to_segbit(bit, args.segment_base) for bit in added]
    text = (
        f"# Provisional; generated from {args.other_bits} minus {args.base_bits}.\n"
        f"# Verify feature name and tile type before adding to prjxray-db.\n"
        f"{args.feature} origin:{args.origin} {' '.join(segbits)}\n"
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(text, encoding="utf-8")
    print(f"wrote {args.out} with {len(segbits)} positive bits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
