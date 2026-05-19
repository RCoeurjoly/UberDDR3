#!/usr/bin/env python3
"""Patch OpenXC7 frames with oracle bits for selected PHASER active tiles."""

from __future__ import annotations

import argparse
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
            raise ValueError(f"{path}:{line_no}: invalid bit line {stripped!r}")
        bits.add((int(match.group("frame"), 16), int(match.group("word")), int(match.group("bit"))))
    return bits


def selected(
    bit: tuple[int, int, int],
    selected_tiles: set[str],
    selected_words: set[int] | None,
) -> bool:
    frame, word, _bit_index = bit
    if selected_words is not None and word not in selected_words:
        return False
    for tile in selected_tiles:
        info = ACTIVE_TILES[tile]
        if not (0 <= frame - int(info["base_frame"]) < 128):
            continue
        start = int(info["word_offset"])
        if start <= word < start + int(info["words"]):
            return True
    return False


def parse_frames(path: Path) -> dict[int, list[int]]:
    frames: dict[int, list[int]] = {}
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if not stripped:
            continue
        frame_text, words_text = stripped.split(None, 1)
        words = [int(word, 16) for word in words_text.split(",")]
        if len(words) != 101:
            raise ValueError(f"{path}:{line_no}: expected 101 words, got {len(words)}")
        frames[int(frame_text, 16)] = words
    return frames


def write_frames(path: Path, frames: dict[int, list[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = []
    for frame in sorted(frames):
        words = ",".join(f"0x{word:08x}" for word in frames[frame])
        lines.append(f"0x{frame:08x} {words}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--open-frames", type=Path, required=True)
    parser.add_argument("--open-bits", type=Path, required=True)
    parser.add_argument("--oracle-bits", type=Path, required=True)
    parser.add_argument("--out-frames", type=Path, required=True)
    parser.add_argument("--report-json", type=Path, required=True)
    parser.add_argument("--tile", action="append", choices=sorted(ACTIVE_TILES), default=None)
    parser.add_argument(
        "--word",
        action="append",
        type=int,
        default=None,
        help="Limit patching to one or more absolute frame word indices.",
    )
    parser.add_argument(
        "--no-clear",
        action="store_true",
        help="Only set oracle-only bits; leave open-only bits unchanged.",
    )
    args = parser.parse_args()

    selected_tiles = set(args.tile) if args.tile else set(ACTIVE_TILES)
    selected_words = set(args.word) if args.word else None
    open_bits = {
        bit for bit in parse_bits(args.open_bits) if selected(bit, selected_tiles, selected_words)
    }
    oracle_bits = {
        bit for bit in parse_bits(args.oracle_bits) if selected(bit, selected_tiles, selected_words)
    }
    bits_to_set = oracle_bits - open_bits
    bits_to_clear = set() if args.no_clear else open_bits - oracle_bits

    frames = parse_frames(args.open_frames)
    changed_words: set[tuple[int, int]] = set()
    for frame, word, bit_index in bits_to_set:
        if frame not in frames:
            frames[frame] = [0] * 101
        before = frames[frame][word]
        frames[frame][word] |= 1 << bit_index
        if frames[frame][word] != before:
            changed_words.add((frame, word))
    for frame, word, bit_index in bits_to_clear:
        if frame not in frames:
            continue
        before = frames[frame][word]
        frames[frame][word] &= ~(1 << bit_index)
        if frames[frame][word] != before:
            changed_words.add((frame, word))

    write_frames(args.out_frames, frames)
    report = {
        "inputs": {
            "open_frames": str(args.open_frames),
            "open_bits": str(args.open_bits),
            "oracle_bits": str(args.oracle_bits),
            "selected_tiles": sorted(selected_tiles),
            "selected_words": sorted(selected_words) if selected_words is not None else None,
            "no_clear": args.no_clear,
        },
        "bits_set": len(bits_to_set),
        "bits_cleared": len(bits_to_clear),
        "changed_word_count": len(changed_words),
        "changed_words": [
            {"frame": f"{frame:08x}", "word": word} for frame, word in sorted(changed_words)
        ],
    }
    args.report_json.parent.mkdir(parents=True, exist_ok=True)
    args.report_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {args.out_frames}")
    print(f"wrote {args.report_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
