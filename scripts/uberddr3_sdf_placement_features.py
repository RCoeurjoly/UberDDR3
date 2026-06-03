#!/usr/bin/env python3
"""Derive semantic placement-distance features from SDF direct entries.

The SDF metrics table tells us which normalized DDR edges matter.  This script
joins those edges back to nextpnr JSON BEL placement and emits feature rows that
can be ranked with ``uberddr3_statistical_sdf_analysis.py``.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import statistics
from typing import Any


METADATA_COLUMNS = [
    "experiment_id",
    "metrics_group",
    "metric_sample",
    "metric_status",
    "hardware_pass",
    "seed",
    "run_group",
    "variant",
    "payload_version",
    "fail_reasons",
    "state_calibrate",
    "instruction_address",
    "calib_complete",
    "bist_done",
    "wrong_read_data",
    "abort_seen",
    "abort_reason",
    "abort_reason_name",
    "abort_lane",
    "abort_state",
    "abort_instruction",
    "abort_start_index_check",
    "abort_lane_write_dq_late",
    "abort_lane_read_dq_early",
    "abort_dq_target_index",
    "abort_data_start_index",
    "idelay_data_tap_mismatch_seen",
    "idelay_dqs_tap_mismatch_seen",
    "data_mismatch_lane_mask",
    "dqs_mismatch_lane_mask",
    "bitstream_sha256",
    "sdf_sha256",
    "nextpnr_json_sha256",
    "result_json",
    "nextpnr_json",
    "cvc_sdf",
    "interpretation",
]

FEATURE_COLUMNS = [
    "feature",
    "value_ps",
    "metric",
    "family",
    "lane",
    "bit",
    "control_bit",
    "scope",
    "count",
    "min_ps",
    "median_ps",
    "p95_ps",
    "max_ps",
    "spread_ps",
]

LONG_FIELDS = [*METADATA_COLUMNS, *FEATURE_COLUMNS]
BEL_SITE_RE = re.compile(r"(?P<site>[A-Z0-9_]+_X(?P<x>-?\d+)Y(?P<y>-?\d+))/(?P<bel>.+)$")


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )


def load_cells(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return top_module(data).get("cells", {})


def cell_from_pin(pin: str) -> str:
    return pin.replace("\\", "").rsplit(".", 1)[0]


def cell_bel(cells: dict[str, Any], cell_name: str) -> str:
    cell = cells.get(cell_name)
    if not isinstance(cell, dict):
        return ""
    attrs = cell.get("attributes", {})
    if not isinstance(attrs, dict):
        return ""
    return str(attrs.get("NEXTPNR_BEL", ""))


def site_xy(bel: str) -> tuple[str, int, int] | None:
    match = BEL_SITE_RE.match(bel)
    if match is None:
        return None
    return match.group("site").split("_X", 1)[0], int(match.group("x")), int(match.group("y"))


def manhattan(source_bel: str, sink_bel: str) -> float | None:
    source = site_xy(source_bel)
    sink = site_xy(sink_bel)
    if source is None or sink is None:
        return None
    if source[0] != sink[0]:
        return None
    return float(abs(source[1] - sink[1]) + abs(source[2] - sink[2]))


def safe_token(value: str, default: str) -> str:
    value = value.strip() or default
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def feature_name(metric: str, family: str, lane: str, bit: str, control_bit: str, scope: str) -> str:
    return "__".join(
        [
            safe_token(metric, "metric"),
            safe_token(family, "family"),
            safe_token(lane, "all"),
            safe_token(bit, "no_bit"),
            f"ctrl_{safe_token(control_bit, 'none')}",
            safe_token(scope, "scope"),
            "value_ps",
        ]
    )


def ffloat(value: float) -> float:
    return round(value, 6)


def stats(values: list[float]) -> dict[str, object]:
    if not values:
        return {}
    ordered = sorted(values)
    p95_index = min(len(ordered) - 1, int(round((len(ordered) - 1) * 0.95)))
    return {
        "count": len(ordered),
        "min_ps": ffloat(ordered[0]),
        "median_ps": ffloat(statistics.median(ordered)),
        "p95_ps": ffloat(ordered[p95_index]),
        "max_ps": ffloat(ordered[-1]),
        "spread_ps": ffloat(ordered[-1] - ordered[0]),
    }


def add_feature(
    rows: list[dict[str, object]],
    metadata: dict[str, str],
    value: float,
    metric: str,
    family: str,
    lane: str,
    bit: str,
    control_bit: str,
    scope: str,
    sources: list[float],
) -> None:
    row: dict[str, object] = {column: metadata.get(column, "") for column in METADATA_COLUMNS}
    row.update(
        {
            "feature": feature_name(metric, family, lane, bit, control_bit, scope),
            "value_ps": ffloat(value),
            "metric": metric,
            "family": family,
            "lane": lane,
            "bit": bit,
            "control_bit": control_bit,
            "scope": scope,
        }
    )
    row.update(stats(sources))
    rows.append(row)


def metadata_by_experiment(features_long: Path) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    for row in read_csv(features_long):
        experiment_id = row.get("experiment_id", "")
        if experiment_id and experiment_id not in out:
            out[experiment_id] = {column: row.get(column, "") for column in METADATA_COLUMNS}
    return out


def placed_json_by_sample(manifest_path: Path) -> dict[str, Path]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    out: dict[str, Path] = {}
    for sample in manifest.get("samples", []):
        label = str(sample["label"])
        placed = sample.get("placed_json")
        if placed:
            out[label] = Path(str(placed))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--features-long", type=Path, required=True)
    parser.add_argument("--direct-entries", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()

    metadata = metadata_by_experiment(args.features_long)
    placed_by_sample = placed_json_by_sample(args.manifest)
    cells_cache: dict[Path, dict[str, Any]] = {}

    rows: list[dict[str, object]] = []
    grouped: dict[tuple[str, str, str, str, str, str], list[float]] = {}
    direct_rows: list[dict[str, object]] = []
    for entry in read_csv(args.direct_entries):
        sample = entry.get("sample", "")
        meta = metadata.get(sample)
        placed_json = placed_by_sample.get(sample)
        if meta is None or placed_json is None:
            continue
        if placed_json not in cells_cache:
            cells_cache[placed_json] = load_cells(placed_json)
        cells = cells_cache[placed_json]
        source_cell = cell_from_pin(entry.get("from_pin", ""))
        sink_cell = cell_from_pin(entry.get("to_pin", ""))
        source_bel = cell_bel(cells, source_cell)
        sink_bel = cell_bel(cells, sink_cell)
        distance = manhattan(source_bel, sink_bel)
        if distance is None:
            continue

        family = entry.get("family", "")
        lane = entry.get("lane", "")
        bit = entry.get("bit", "")
        control_bit = entry.get("control_bit", "")
        endpoint = entry.get("endpoint", "")
        direct = {
            **{column: meta.get(column, "") for column in METADATA_COLUMNS},
            "family": family,
            "lane": lane,
            "bit": bit,
            "control_bit": control_bit,
            "endpoint": endpoint,
            "source_cell": source_cell,
            "sink_cell": sink_cell,
            "source_bel": source_bel,
            "sink_bel": sink_bel,
            "source_to_sink_manhattan": ffloat(distance),
        }
        direct_rows.append(direct)

        key = (sample, family, lane, bit, control_bit, "endpoint")
        grouped.setdefault(key, []).append(distance)

    for (sample, family, lane, bit, control_bit, scope), values in grouped.items():
        meta = metadata[sample]
        add_feature(rows, meta, max(values), "placement_manhattan_max", family, lane, bit, control_bit, scope, values)
        if len(values) > 1:
            add_feature(rows, meta, max(values) - min(values), "placement_manhattan_spread", family, lane, bit, control_bit, scope, values)

    wide_by_experiment = {experiment: dict(meta) for experiment, meta in metadata.items()}
    feature_columns: list[str] = []
    seen: set[str] = set()
    for row in rows:
        feature = str(row["feature"])
        if feature not in seen:
            seen.add(feature)
            feature_columns.append(feature)
        wide_by_experiment[str(row["experiment_id"])][feature] = row["value_ps"]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "placement_direct_edges.csv", direct_rows, [*METADATA_COLUMNS, "family", "lane", "bit", "control_bit", "endpoint", "source_cell", "sink_cell", "source_bel", "sink_bel", "source_to_sink_manhattan"])
    write_csv(args.out_dir / "placement_features_long.csv", rows, LONG_FIELDS)
    write_csv(args.out_dir / "placement_features_wide.csv", [wide_by_experiment[key] for key in sorted(wide_by_experiment)], [*METADATA_COLUMNS, *feature_columns])
    (args.out_dir / "README.md").write_text(
        "# UberDDR3 SDF-Referenced Placement Features\n\n"
        "This artifact joins normalized SDF query edges to nextpnr JSON BEL placement and reports source-to-sink Manhattan distances in same-site coordinates. "
        "The statistical columns reuse `value_ps` for compatibility with the existing ranking script; values are placement-site Manhattan distances, not picoseconds.\n",
        encoding="utf-8",
    )
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
