#!/usr/bin/env python3
"""Summarize decoded FASM unknowns and bitread frame deltas."""

from __future__ import annotations

import argparse
from collections import Counter
import json
import re
from pathlib import Path
from typing import Any


BIT_RE = re.compile(r"^bit_(?P<frame>[0-9a-fA-F]{8})_(?P<word>\d+)_(?P<bit>\d+)$")
UNKNOWN_RE = re.compile(
    r'unknown_bit = "(?P<frame>[0-9a-fA-F]{8})_(?P<word>\d+)_(?P<bit>\d+)".*'
    r'unknown_segment = "(?P<segment>0x[0-9a-fA-F]+)".*'
    r'unknown_segbit = "(?P<segbit>[^"]+)"'
)


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


def bit_parts(bit: str) -> tuple[str, str, str]:
    match = BIT_RE.match(bit)
    if match is None:
        raise ValueError(f"invalid bit id: {bit!r}")
    return match.group("frame").lower(), match.group("word"), match.group("bit")


def summarize_bits(bits: set[str]) -> dict[str, Any]:
    frame_counts = Counter(bit_parts(bit)[0] for bit in bits)
    return {
        "bit_count": len(bits),
        "frame_count": len(frame_counts),
        "top_frames": [
            {"frame": frame, "bit_count": count}
            for frame, count in frame_counts.most_common(32)
        ],
    }


def parse_fasm(path: Path) -> dict[str, Any]:
    feature_count = 0
    unknowns: list[dict[str, str]] = []
    feature_prefix_counts: Counter[str] = Counter()
    unknown_frame_counts: Counter[str] = Counter()
    unknown_segment_counts: Counter[str] = Counter()

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        unknown_match = UNKNOWN_RE.search(stripped)
        if unknown_match:
            item = unknown_match.groupdict()
            item["frame"] = item["frame"].lower()
            unknowns.append(item)
            unknown_frame_counts[item["frame"]] += 1
            unknown_segment_counts[item["segment"].lower()] += 1
            continue

        feature_count += 1
        feature_prefix_counts[stripped.split(".", 1)[0]] += 1

    return {
        "path": str(path),
        "feature_count": feature_count,
        "feature_prefix_count": len(feature_prefix_counts),
        "top_feature_prefixes": [
            {"prefix": prefix, "feature_count": count}
            for prefix, count in feature_prefix_counts.most_common(32)
        ],
        "unknown_count": len(unknowns),
        "unknown_frame_count": len(unknown_frame_counts),
        "unknown_segment_count": len(unknown_segment_counts),
        "top_unknown_frames": [
            {"frame": frame, "unknown_count": count}
            for frame, count in unknown_frame_counts.most_common(32)
        ],
        "top_unknown_segments": [
            {"segment": segment, "unknown_count": count}
            for segment, count in unknown_segment_counts.most_common(32)
        ],
        "unknown_sample": unknowns[:32],
    }


def summarize_delta(base_bits: set[str], other_bits: set[str]) -> dict[str, Any]:
    added = other_bits - base_bits
    removed = base_bits - other_bits
    added_frames = Counter(bit_parts(bit)[0] for bit in added)
    removed_frames = Counter(bit_parts(bit)[0] for bit in removed)
    return {
        "base": summarize_bits(base_bits),
        "other": summarize_bits(other_bits),
        "added_count": len(added),
        "removed_count": len(removed),
        "top_added_frames": [
            {"frame": frame, "bit_count": count}
            for frame, count in added_frames.most_common(32)
        ],
        "top_removed_frames": [
            {"frame": frame, "bit_count": count}
            for frame, count in removed_frames.most_common(32)
        ],
        "added_sample": sorted(added)[:64],
        "removed_sample": sorted(removed)[:64],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fasm", type=Path, action="append", default=[])
    parser.add_argument("--bits", type=Path)
    parser.add_argument("--compare-bits", type=Path)
    parser.add_argument("--out-json", type=Path)
    args = parser.parse_args()

    report: dict[str, Any] = {}
    if args.fasm:
        report["fasm"] = [parse_fasm(path) for path in args.fasm]
    if args.bits:
        bits = parse_bits(args.bits)
        report["bits"] = {"path": str(args.bits), **summarize_bits(bits)}
        if args.compare_bits:
            other_bits = parse_bits(args.compare_bits)
            report["bit_delta"] = {
                "base_path": str(args.bits),
                "other_path": str(args.compare_bits),
                **summarize_delta(bits, other_bits),
            }
    elif args.compare_bits:
        raise SystemExit("--compare-bits requires --bits")

    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.out_json:
        args.out_json.parent.mkdir(parents=True, exist_ok=True)
        args.out_json.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
