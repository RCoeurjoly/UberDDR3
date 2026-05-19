#!/usr/bin/env python3
"""Patch byte-lane PHASER lower-T frame words from the Vivado oracle.

This is a diagnostic bridge, not the desired final representation.  It lets us
test whether the remaining PHASER_IN/OUT/PHY_CONTROL lock blocker is contained
in the lower-T CMT frame words before splitting the delta into proper segbits.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any


BIT_RE = re.compile(r"^bit_(?P<frame>[0-9a-fA-F]{8})_(?P<word>\d+)_(?P<bit>\d+)$")


def parse_reference_bits(path: Path) -> dict[int, dict[int, int]]:
    frames: dict[int, dict[int, int]] = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        match = BIT_RE.match(line)
        if match is None:
            raise ValueError(f"{path}:{line_number}: invalid bitread line: {line!r}")
        frame = int(match.group("frame"), 16)
        word = int(match.group("word"))
        bit = int(match.group("bit"))
        frames.setdefault(frame, {}).setdefault(word, 0)
        frames[frame][word] |= 1 << bit
    return frames


def parse_frame_line(line: str) -> tuple[int, list[int]]:
    frame_text, words_text = line.rstrip("\n").split(" ", 1)
    return int(frame_text, 16), [int(word, 16) for word in words_text.split(",")]


def format_frame_line(frame: int, words: list[int]) -> str:
    return f"0x{frame:08x} " + ",".join(f"0x{word:08X}" for word in words) + "\n"


def patch_frames(
    *,
    input_frames: Path,
    reference_bits: Path,
    output_frames: Path,
    frame_ids: set[int],
    first_word: int,
    last_word: int,
) -> dict[str, Any]:
    reference = parse_reference_bits(reference_bits)
    changed_words: list[dict[str, Any]] = []
    output_lines: list[str] = []

    for line_number, line in enumerate(input_frames.read_text(encoding="utf-8").splitlines(True), 1):
        if not line.strip():
            output_lines.append(line)
            continue
        frame, words = parse_frame_line(line)
        if frame not in frame_ids:
            output_lines.append(line)
            continue
        if last_word >= len(words):
            raise ValueError(
                f"{input_frames}:{line_number}: frame 0x{frame:08x} has only {len(words)} words"
            )

        reference_words = reference.get(frame, {})
        for word_index in range(first_word, last_word + 1):
            old = words[word_index]
            new = reference_words.get(word_index, 0)
            if old != new:
                changed_words.append(
                    {
                        "frame": f"0x{frame:08x}",
                        "word": word_index,
                        "old": f"0x{old:08x}",
                        "new": f"0x{new:08x}",
                    }
                )
                words[word_index] = new
        output_lines.append(format_frame_line(frame, words))

    output_frames.write_text("".join(output_lines), encoding="utf-8")
    return {
        "input_frames": str(input_frames),
        "reference_bits": str(reference_bits),
        "output_frames": str(output_frames),
        "frames": [f"0x{frame:08x}" for frame in sorted(frame_ids)],
        "first_word": first_word,
        "last_word": last_word,
        "changed_word_count": len(changed_words),
        "changed_words": changed_words,
    }


def parse_frame_id(value: str) -> int:
    return int(value, 0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-frames", required=True, type=Path)
    parser.add_argument("--reference-bits", required=True, type=Path)
    parser.add_argument("--output-frames", required=True, type=Path)
    parser.add_argument("--report-json", type=Path)
    parser.add_argument(
        "--frame",
        action="append",
        type=parse_frame_id,
        default=None,
        help="Frame ID to patch. Defaults to the original lower-T diagnostic frame set when omitted.",
    )
    parser.add_argument("--first-word", type=int, default=34)
    parser.add_argument("--last-word", type=int, default=57)
    args = parser.parse_args()

    report = patch_frames(
        input_frames=args.input_frames,
        reference_bits=args.reference_bits,
        output_frames=args.output_frames,
        frame_ids=set(args.frame or [0x00460120, 0x00460121, 0x00460122, 0x00460123]),
        first_word=args.first_word,
        last_word=args.last_word,
    )
    report_text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.report_json:
        args.report_json.write_text(report_text, encoding="utf-8")
    print(report_text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
