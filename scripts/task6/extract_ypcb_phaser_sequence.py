#!/usr/bin/env python3
"""Collapse a Vivado ILA CSV capture into a PHASER byte-lane sequence spec."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


SCHEMA = "ypcb-phaser-byte-lane-sequence-v1"


def parse_mapping(items: list[str]) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise ValueError(f"expected alias=column mapping, got {item!r}")
        alias, column = item.split("=", 1)
        alias = alias.strip()
        column = column.strip()
        if not alias or not column:
            raise ValueError(f"invalid mapping {item!r}")
        mapping[alias] = column
    return mapping


def parse_csv_capture(path: Path) -> tuple[list[str], list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        rows = list(reader)
    if len(rows) < 2:
        raise ValueError("expected at least a header row and a radix row")
    header = rows[0]
    radix = rows[1]
    data_rows = [dict(zip(header, row)) for row in rows[2:] if any(cell.strip() for cell in row)]
    return header, radix, data_rows


def parse_value(text: str, radix: str) -> int:
    value = text.strip()
    if value == "":
        return 0
    base = radix.strip().upper()
    if base == "HEX":
        return int(value, 16)
    if base == "BIN":
        return int(value, 2)
    if base == "UNSIGNED":
        return int(value, 10)
    return int(value, 0)


def normalized_samples(
    header: list[str],
    radix: list[str],
    rows: list[dict[str, str]],
    *,
    signal_map: dict[str, str],
) -> list[dict[str, int]]:
    radix_by_column = dict(zip(header, radix))
    samples: list[dict[str, int]] = []
    for sample_index, row in enumerate(rows):
        sample = {"sample_index": sample_index}
        for alias, column_name in signal_map.items():
            if column_name not in row:
                raise ValueError(f"missing mapped CSV column {column_name!r}")
            sample[alias] = parse_value(row[column_name], radix_by_column.get(column_name, "UNSIGNED"))
        samples.append(sample)
    return samples


def collapse_steps(
    samples: list[dict[str, int]],
    *,
    control_aliases: list[str],
    phyctlwd_alias: str | None,
) -> list[dict[str, Any]]:
    if not samples:
        raise ValueError("capture did not contain any samples")

    steps: list[dict[str, Any]] = []
    current_controls = None
    current_phyctlwd = 0
    current_start = 0
    current_count = 0

    for sample in samples:
        controls = tuple(sample[alias] for alias in control_aliases)
        phyctlwd = sample.get(phyctlwd_alias, 0) if phyctlwd_alias else 0
        if current_controls is None:
            current_controls = controls
            current_phyctlwd = phyctlwd
            current_start = sample["sample_index"]
            current_count = 1
            continue
        if controls == current_controls and phyctlwd == current_phyctlwd:
            current_count += 1
            continue
        steps.append(
            {
                "sample_start": current_start,
                "sample_end": current_start + current_count - 1,
                "dwell_cycles": current_count,
                "controls": {
                    alias: bool(value)
                    for alias, value in zip(control_aliases, current_controls)
                },
                "phyctlwd": current_phyctlwd,
            }
        )
        current_controls = controls
        current_phyctlwd = phyctlwd
        current_start = sample["sample_index"]
        current_count = 1

    steps.append(
        {
            "sample_start": current_start,
            "sample_end": current_start + current_count - 1,
            "dwell_cycles": current_count,
            "controls": {
                alias: bool(value)
                for alias, value in zip(control_aliases, current_controls)
            },
            "phyctlwd": current_phyctlwd,
        }
    )
    return steps


def first_assertions(samples: list[dict[str, int]], aliases: list[str]) -> dict[str, int | None]:
    observed: dict[str, int | None] = {alias: None for alias in aliases}
    for sample in samples:
        for alias in aliases:
            if observed[alias] is None and sample.get(alias, 0):
                observed[alias] = sample["sample_index"]
    return observed


def build_spec(
    samples: list[dict[str, int]],
    *,
    name: str,
    clock_domain: str,
    control_aliases: list[str],
    wait_aliases: list[str],
    phyctlwd_alias: str | None,
) -> dict[str, Any]:
    steps = collapse_steps(
        samples,
        control_aliases=control_aliases,
        phyctlwd_alias=phyctlwd_alias,
    )
    return {
        "schema": SCHEMA,
        "name": name,
        "clock_domain": clock_domain,
        "final_step_hold": True,
        "metadata": {
            "sample_count": len(samples),
            "control_aliases": control_aliases,
            "wait_aliases": wait_aliases,
            "first_assertions": first_assertions(samples, wait_aliases),
        },
        "steps": [
            {
                "name": f"capture_step_{index}",
                "dwell_cycles": step["dwell_cycles"],
                "controls": step["controls"],
                "phyctlwd": step["phyctlwd"],
                "wait_for": [],
                "sample_start": step["sample_start"],
                "sample_end": step["sample_end"],
            }
            for index, step in enumerate(steps)
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--name", default="vivado-captured-byte-lane-sequence")
    parser.add_argument("--clock-domain", default="clk50")
    parser.add_argument(
        "--map",
        action="append",
        default=[],
        help="alias=csv_column mapping; controls and waits are selected from these aliases",
    )
    parser.add_argument(
        "--control-alias",
        action="append",
        default=[],
        help="Alias to treat as a step-defining control bit. Repeat for each control.",
    )
    parser.add_argument(
        "--wait-alias",
        action="append",
        default=[],
        help="Alias to report as a status assertion in metadata. Repeat as needed.",
    )
    parser.add_argument(
        "--phyctlwd-alias",
        help="Alias to treat as the captured PHYCTLWD word.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    signal_map = parse_mapping(args.map)
    header, radix, rows = parse_csv_capture(args.csv)
    samples = normalized_samples(header, radix, rows, signal_map=signal_map)
    spec = build_spec(
        samples,
        name=args.name,
        clock_domain=args.clock_domain,
        control_aliases=args.control_alias,
        wait_aliases=args.wait_alias,
        phyctlwd_alias=args.phyctlwd_alias,
    )
    args.out.write_text(json.dumps(spec, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
