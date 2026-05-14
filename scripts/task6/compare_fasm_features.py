#!/usr/bin/env python3
"""Compare FASM feature sets across pass/fail DDR3 calibration builds."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import re


def parse_label_path(value: str) -> tuple[str, Path]:
    if ":" not in value:
        raise SystemExit(f"expected LABEL:PATH, got {value!r}")
    label, path = value.split(":", 1)
    return label, Path(path)


def load_features(path: Path) -> set[str]:
    features: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        features.add(line)
    return features


def tile_type(feature: str) -> str:
    tile = feature.split(".", 1)[0]
    return re.sub(r"_X\d+Y\d+$", "", tile)


def summarize_features(features: set[str], *, limit: int) -> str:
    counts = Counter(tile_type(feature) for feature in features)
    if not counts:
        return "-"
    return ", ".join(f"`{name}`={count}" for name, count in counts.most_common(limit))


def markdown(args: argparse.Namespace) -> str:
    inputs = dict(parse_label_path(value) for value in args.fasm)
    features = {label: load_features(path) for label, path in inputs.items()}
    labels = list(inputs)

    lines = [
        "# FASM Feature Comparison",
        "",
        "## Inputs",
        "",
        "| Label | FASM | Features |",
        "| --- | --- | ---: |",
    ]
    for label in labels:
        lines.append(f"| `{label}` | `{inputs[label]}` | {len(features[label])} |")

    lines += [
        "",
        "## Pairwise Deltas",
        "",
        "| From | To | Added in To | Removed from From | Top Added Tile Types | Top Removed Tile Types |",
        "| --- | --- | ---: | ---: | --- | --- |",
    ]
    for left in labels:
        for right in labels:
            if left == right:
                continue
            added = features[right] - features[left]
            removed = features[left] - features[right]
            lines.append(
                "| "
                + " | ".join(
                    [
                        f"`{left}`",
                        f"`{right}`",
                        str(len(added)),
                        str(len(removed)),
                        summarize_features(added, limit=args.limit),
                        summarize_features(removed, limit=args.limit),
                    ]
                )
                + " |"
            )

    if args.pass_label and args.fail_label:
        pass_common = set.intersection(*(features[label] for label in args.pass_label))
        fail_common = set.intersection(*(features[label] for label in args.fail_label))
        pass_only = pass_common - fail_common
        fail_only = fail_common - pass_common
        lines += [
            "",
            "## Pass-Consensus Versus Fail-Consensus",
            "",
            f"Pass labels: {', '.join(f'`{label}`' for label in args.pass_label)}",
            "",
            f"Fail labels: {', '.join(f'`{label}`' for label in args.fail_label)}",
            "",
            f"Pass-consensus-only features: {len(pass_only)}",
            "",
            f"Fail-consensus-only features: {len(fail_only)}",
            "",
            f"Top pass-only tile types: {summarize_features(pass_only, limit=args.limit)}",
            "",
            f"Top fail-only tile types: {summarize_features(fail_only, limit=args.limit)}",
        ]

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fasm", action="append", required=True, help="LABEL:path/to/design.fasm")
    parser.add_argument("--pass-label", action="append", default=[])
    parser.add_argument("--fail-label", action="append", default=[])
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--out", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    text = markdown(args)
    if args.out is None:
        print(text, end="")
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
