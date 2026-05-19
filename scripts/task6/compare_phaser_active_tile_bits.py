#!/usr/bin/env python3
"""Compare PHASER active-tile bitread bits between oracle and OpenXC7 outputs."""

from __future__ import annotations

import argparse
from collections import defaultdict
import json
import re
from pathlib import Path


BIT_RE = re.compile(r"^bit_(?P<frame>[0-9a-fA-F]{8})_(?P<word>\d+)_(?P<bit>\d+)$")

ACTIVE_TILES = {
    "CMT_TOP_R_LOWER_T_X8Y18": {
        "base_frame": int("00460080", 16),
        "word_offset": 34,
        "words": 7,
    },
    "CMT_TOP_R_UPPER_B_X8Y31": {
        "base_frame": int("00460080", 16),
        "word_offset": 53,
        "words": 22,
    },
}


def parse_bits(path: Path) -> set[tuple[int, int, int]]:
    bits: set[tuple[int, int, int]] = set()
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if not stripped:
            continue
        match = BIT_RE.match(stripped)
        if match is None:
            raise ValueError(f"{path}:{line_no}: invalid bit line: {stripped!r}")
        bits.add((int(match.group("frame"), 16), int(match.group("word")), int(match.group("bit"))))
    return bits


def bit_id(bit: tuple[int, int, int]) -> str:
    frame, word, bit_index = bit
    return f"bit_{frame:08x}_{word}_{bit_index}"


def tile_for_bit(bit: tuple[int, int, int]) -> tuple[str, int, int] | None:
    frame, word, bit_index = bit
    for tile, info in ACTIVE_TILES.items():
        word_offset = int(info["word_offset"])
        words = int(info["words"])
        if word_offset <= word < word_offset + words:
            minor = frame - int(info["base_frame"])
            if 0 <= minor < 128:
                segbit = (word - word_offset) * 32 + bit_index
                return tile, minor, segbit
    return None


def summarize(bits: set[tuple[int, int, int]]) -> list[dict[str, object]]:
    by_tile: dict[str, list[tuple[int, int, int, int]]] = defaultdict(list)
    for bit in sorted(bits):
        tile_info = tile_for_bit(bit)
        if tile_info is None:
            continue
        tile, minor, segbit = tile_info
        by_tile[tile].append((*bit, minor, segbit))

    rows = []
    for tile in sorted(by_tile):
        entries = by_tile[tile]
        rows.append(
            {
                "tile": tile,
                "count": len(entries),
                "bits": [
                    {
                        "bit": bit_id((frame, word, bit_index)),
                        "frame": f"{frame:08x}",
                        "word": word,
                        "bit_index": bit_index,
                        "tile_segbit": f"{minor}_{segbit}",
                    }
                    for frame, word, bit_index, minor, segbit in entries
                ],
            }
        )
    return rows


def write_markdown(path: Path, payload: dict[str, object]) -> None:
    lines = [
        "# PHASER Active Tile Bit Delta",
        "",
        "## Summary",
        "",
    ]
    summary = payload["summary"]
    assert isinstance(summary, dict)
    for key, value in summary.items():
        lines.append(f"- `{key}`: `{value}`")

    for section in ("oracle_only", "open_only"):
        lines.extend(["", f"## {section}", ""])
        rows = payload[section]
        assert isinstance(rows, list)
        for row in rows:
            lines.append(f"### {row['tile']}")
            lines.append("")
            lines.append(f"- count: `{row['count']}`")
            lines.append("")
            for item in row["bits"][:128]:
                lines.append(f"- `{item['bit']}` tile segbit `{item['tile_segbit']}`")
            if row["count"] > 128:
                lines.append(f"- ... {row['count'] - 128} more")
            lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--oracle-bits", type=Path, required=True)
    parser.add_argument("--open-bits", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--md-out", type=Path, required=True)
    args = parser.parse_args()

    oracle_bits = {bit for bit in parse_bits(args.oracle_bits) if tile_for_bit(bit) is not None}
    open_bits = {bit for bit in parse_bits(args.open_bits) if tile_for_bit(bit) is not None}
    oracle_only = oracle_bits - open_bits
    open_only = open_bits - oracle_bits
    payload: dict[str, object] = {
        "inputs": {
            "oracle_bits": str(args.oracle_bits),
            "open_bits": str(args.open_bits),
            "active_tiles": ACTIVE_TILES,
        },
        "summary": {
            "oracle_active_bits": len(oracle_bits),
            "open_active_bits": len(open_bits),
            "oracle_only_active_bits": len(oracle_only),
            "open_only_active_bits": len(open_only),
        },
        "oracle_only": summarize(oracle_only),
        "open_only": summarize(open_only),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(args.md_out, payload)
    print(f"wrote {args.json_out}")
    print(f"wrote {args.md_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
