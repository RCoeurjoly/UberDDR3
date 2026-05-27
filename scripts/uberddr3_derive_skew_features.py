#!/usr/bin/env python3
"""Derive DDR skew/composite SDF features from joined semantic feature tables."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
import re
import statistics
from typing import Iterable


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
DQ_BITS = {
    "lane0": [f"dq{index}" for index in range(0, 8)],
    "lane1": [f"dq{index}" for index in range(8, 16)],
}
DQS_BIT = {"lane0": "dqs0", "lane1": "dqs1"}
CNT_CONTROLS = ["0", "1", "2", "3", "4"]


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


def median(values: Iterable[float]) -> float:
    return statistics.median(list(values))


def ffloat(value: float) -> float:
    return round(value, 6)


def source_stats(values: list[float]) -> dict[str, object]:
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


def metric_key(metric: str, family: str, lane: str, bit: str, control: str, scope: str) -> tuple[str, str, str, str, str, str]:
    return (metric, family, lane, bit, control, scope)


def build_indexes(rows: list[dict[str, str]]) -> tuple[dict[str, dict[str, str]], dict[str, dict[tuple[str, str, str, str, str, str], float]]]:
    metadata: dict[str, dict[str, str]] = {}
    values: dict[str, dict[tuple[str, str, str, str, str, str], float]] = {}
    for row in rows:
        experiment = row.get("experiment_id", "")
        if not experiment:
            continue
        metadata.setdefault(experiment, {column: row.get(column, "") for column in METADATA_COLUMNS})
        try:
            value = float(row["value_ps"])
        except (KeyError, ValueError):
            continue
        key = metric_key(
            row.get("metric", ""),
            row.get("family", ""),
            row.get("lane", ""),
            row.get("bit", ""),
            row.get("control_bit", ""),
            row.get("scope", ""),
        )
        values.setdefault(experiment, {})[key] = value
    return metadata, values


def add_row(
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
    row.update(source_stats(sources))
    rows.append(row)


def get_value(
    values: dict[tuple[str, str, str, str, str, str], float],
    metric: str,
    family: str,
    lane: str,
    bit: str,
    control: str,
    scope: str,
) -> float | None:
    return values.get(metric_key(metric, family, lane, bit, control, scope))


def available_direct(
    values: dict[tuple[str, str, str, str, str, str], float],
    family: str,
    lane: str,
    bits: list[str],
    control: str,
) -> list[float]:
    out = []
    for bit in bits:
        value = get_value(values, "direct_max", family, lane, bit, control, "endpoint")
        if value is not None:
            out.append(value)
    return out


def derive_for_experiment(metadata: dict[str, str], values: dict[tuple[str, str, str, str, str, str], float]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for lane, bits in DQ_BITS.items():
        dqs_bit = DQS_BIT[lane]
        for control in CNT_CONTROLS:
            dq_values = available_direct(values, "idelay_data_cntvaluein", lane, bits, control)
            dqs_value = get_value(values, "direct_max", "idelay_dqs_cntvaluein", lane, dqs_bit, control, "endpoint")
            if len(dq_values) >= 2:
                add_row(rows, metadata, max(dq_values) - min(dq_values), "dq_lane_range", "idelay_cntvaluein_skew", lane, "", control, "dq_lane", dq_values)
            if dqs_value is not None and dq_values:
                dq_median = median(dq_values)
                signed = dqs_value - dq_median
                add_row(rows, metadata, signed, "signed_dqs_minus_dq_median", "idelay_cntvaluein_skew", lane, dqs_bit, control, "dqs_vs_dq_lane", [dqs_value, *dq_values])
                add_row(rows, metadata, abs(signed), "abs_dqs_minus_dq_median", "idelay_cntvaluein_skew", lane, dqs_bit, control, "dqs_vs_dq_lane", [dqs_value, *dq_values])
                for bit in bits:
                    dq_value = get_value(values, "direct_max", "idelay_data_cntvaluein", lane, bit, control, "endpoint")
                    if dq_value is None:
                        continue
                    bit_signed = dqs_value - dq_value
                    add_row(rows, metadata, bit_signed, "signed_dqs_minus_dq_bit", "idelay_cntvaluein_skew", lane, bit, control, "dqs_vs_dq_bit", [dqs_value, dq_value])
                    add_row(rows, metadata, abs(bit_signed), "abs_dqs_minus_dq_bit", "idelay_cntvaluein_skew", lane, bit, control, "dqs_vs_dq_bit", [dqs_value, dq_value])

        dq_bus_skews = [
            value for bit in bits
            if (value := get_value(values, "cntvaluein_bus_skew", "idelay_data_cntvaluein", lane, bit, "", bit)) is not None
        ]
        dqs_bus_skew = get_value(values, "cntvaluein_bus_skew", "idelay_dqs_cntvaluein", lane, dqs_bit, "", dqs_bit)
        if len(dq_bus_skews) >= 2:
            add_row(rows, metadata, max(dq_bus_skews) - min(dq_bus_skews), "dq_bus_skew_range", "idelay_cntvaluein_skew", lane, "", "", "dq_lane_bus_skew", dq_bus_skews)
        if dqs_bus_skew is not None and dq_bus_skews:
            signed = dqs_bus_skew - median(dq_bus_skews)
            add_row(rows, metadata, signed, "signed_dqs_bus_skew_minus_dq_median", "idelay_cntvaluein_skew", lane, dqs_bit, "", "dqs_vs_dq_bus_skew", [dqs_bus_skew, *dq_bus_skews])
            add_row(rows, metadata, abs(signed), "abs_dqs_bus_skew_minus_dq_median", "idelay_cntvaluein_skew", lane, dqs_bit, "", "dqs_vs_dq_bus_skew", [dqs_bus_skew, *dq_bus_skews])

        for family, derived_family in [("dq_iologic", "iologic_skew"), ("clocking", "clocking_skew")]:
            dq_values = available_direct(values, family, lane, bits, "")
            dqs_value = get_value(values, "direct_max", "dqs_iologic" if family == "dq_iologic" else family, lane, dqs_bit, "", "endpoint")
            if len(dq_values) >= 2:
                add_row(rows, metadata, max(dq_values) - min(dq_values), "dq_lane_range", derived_family, lane, "", "", "dq_lane", dq_values)
            if dqs_value is not None and dq_values:
                signed = dqs_value - median(dq_values)
                add_row(rows, metadata, signed, "signed_dqs_minus_dq_median", derived_family, lane, dqs_bit, "", "dqs_vs_dq_lane", [dqs_value, *dq_values])
                add_row(rows, metadata, abs(signed), "abs_dqs_minus_dq_median", derived_family, lane, dqs_bit, "", "dqs_vs_dq_lane", [dqs_value, *dq_values])

        ld_dq_values = available_direct(values, "idelay_ld", lane, bits, "")
        ld_dqs = get_value(values, "direct_max", "idelay_ld", lane, dqs_bit, "", "endpoint")
        if len(ld_dq_values) >= 2:
            add_row(rows, metadata, max(ld_dq_values) - min(ld_dq_values), "ld_dq_lane_range", "idelay_ld_skew", lane, "", "", "dq_lane", ld_dq_values)
        if ld_dqs is not None and ld_dq_values:
            signed = ld_dqs - median(ld_dq_values)
            add_row(rows, metadata, signed, "signed_ld_dqs_minus_dq_median", "idelay_ld_skew", lane, dqs_bit, "", "dqs_vs_dq_lane", [ld_dqs, *ld_dq_values])
            add_row(rows, metadata, abs(signed), "abs_ld_dqs_minus_dq_median", "idelay_ld_skew", lane, dqs_bit, "", "dqs_vs_dq_lane", [ld_dqs, *ld_dq_values])
        for control in CNT_CONTROLS:
            cnt_dq_values = available_direct(values, "idelay_data_cntvaluein", lane, bits, control)
            if ld_dq_values and cnt_dq_values:
                signed = median(ld_dq_values) - median(cnt_dq_values)
                add_row(rows, metadata, signed, "signed_ld_minus_cntvaluein_dq_median", "idelay_ld_cntvaluein_skew", lane, "", control, "ld_vs_cntvaluein_dq_lane", [*ld_dq_values, *cnt_dq_values])
                add_row(rows, metadata, abs(signed), "abs_ld_minus_cntvaluein_dq_median", "idelay_ld_cntvaluein_skew", lane, "", control, "ld_vs_cntvaluein_dq_lane", [*ld_dq_values, *cnt_dq_values])
            cnt_dqs = get_value(values, "direct_max", "idelay_dqs_cntvaluein", lane, dqs_bit, control, "endpoint")
            if ld_dqs is not None and cnt_dqs is not None:
                signed = ld_dqs - cnt_dqs
                add_row(rows, metadata, signed, "signed_ld_minus_cntvaluein_dqs", "idelay_ld_cntvaluein_skew", lane, dqs_bit, control, "ld_vs_cntvaluein_dqs", [ld_dqs, cnt_dqs])
                add_row(rows, metadata, abs(signed), "abs_ld_minus_cntvaluein_dqs", "idelay_ld_cntvaluein_skew", lane, dqs_bit, control, "ld_vs_cntvaluein_dqs", [ld_dqs, cnt_dqs])

    for control in CNT_CONTROLS:
        lane0 = available_direct(values, "idelay_data_cntvaluein", "lane0", DQ_BITS["lane0"], control)
        lane1 = available_direct(values, "idelay_data_cntvaluein", "lane1", DQ_BITS["lane1"], control)
        if lane0 and lane1:
            signed = median(lane1) - median(lane0)
            add_row(rows, metadata, signed, "signed_lane1_minus_lane0_dq_median", "idelay_cntvaluein_skew", "all", "", control, "lane1_vs_lane0_dq", [*lane0, *lane1])
            add_row(rows, metadata, abs(signed), "abs_lane1_minus_lane0_dq_median", "idelay_cntvaluein_skew", "all", "", control, "lane1_vs_lane0_dq", [*lane0, *lane1])
        dqs0 = get_value(values, "direct_max", "idelay_dqs_cntvaluein", "lane0", "dqs0", control, "endpoint")
        dqs1 = get_value(values, "direct_max", "idelay_dqs_cntvaluein", "lane1", "dqs1", control, "endpoint")
        if dqs0 is not None and dqs1 is not None:
            signed = dqs1 - dqs0
            add_row(rows, metadata, signed, "signed_lane1_minus_lane0_dqs", "idelay_cntvaluein_skew", "all", "", control, "lane1_vs_lane0_dqs", [dqs0, dqs1])
            add_row(rows, metadata, abs(signed), "abs_lane1_minus_lane0_dqs", "idelay_cntvaluein_skew", "all", "", control, "lane1_vs_lane0_dqs", [dqs0, dqs1])

    idelayctrl = get_value(values, "direct_max", "idelayctrl", "all", "", "", "endpoint")
    reset_release = get_value(values, "direct_max", "reset_release", "all", "", "", "endpoint")
    if idelayctrl is not None and reset_release is not None:
        signed = idelayctrl - reset_release
        add_row(rows, metadata, signed, "signed_idelayctrl_minus_reset_release", "startup_relative_skew", "all", "", "", "idelayctrl_vs_reset", [idelayctrl, reset_release])
        add_row(rows, metadata, abs(signed), "abs_idelayctrl_minus_reset_release", "startup_relative_skew", "all", "", "", "idelayctrl_vs_reset", [idelayctrl, reset_release])

    return rows


def wide_rows(long_rows: list[dict[str, object]], metadata: dict[str, dict[str, str]]) -> tuple[list[dict[str, object]], list[str]]:
    by_experiment = {experiment: dict(values) for experiment, values in metadata.items()}
    features: list[str] = []
    seen = set()
    for row in long_rows:
        feature = str(row["feature"])
        if feature not in seen:
            seen.add(feature)
            features.append(feature)
        by_experiment[str(row["experiment_id"])][feature] = row["value_ps"]
    ordered = [by_experiment[key] for key in sorted(by_experiment, key=lambda value: int(by_experiment[value].get("seed", "0") or 0))]
    return ordered, features


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--features-long", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()

    source_rows = read_csv(args.features_long)
    metadata, values = build_indexes(source_rows)
    skew_rows: list[dict[str, object]] = []
    for experiment in sorted(metadata, key=lambda value: int(metadata[value].get("seed", "0") or 0)):
        skew_rows.extend(derive_for_experiment(metadata[experiment], values.get(experiment, {})))

    wide, feature_columns = wide_rows(skew_rows, metadata)
    write_csv(args.out_dir / "skew_features_long.csv", skew_rows, LONG_FIELDS)
    write_csv(args.out_dir / "skew_features_wide.csv", wide, [*METADATA_COLUMNS, *feature_columns])

    readme = [
        "# UberDDR3 Derived Skew Features",
        "",
        "This artifact derives signed and absolute DDR skew/composite features from an existing joined semantic SDF feature table.",
        "",
        f"- source feature table: `{args.features_long}`",
        f"- experiments: `{len(metadata)}`",
        f"- derived feature observations: `{len(skew_rows)}`",
        f"- derived feature columns: `{len(feature_columns)}`",
        "",
        "The rows are intentionally semantic: DQS-vs-DQ, lane-vs-lane, LD-vs-CNTVALUEIN, IOLOGIC DQS-vs-DQ, clocking DQS-vs-DQ, and IDELAYCTRL-vs-reset relative timing.",
        "",
    ]
    args.out_dir.mkdir(parents=True, exist_ok=True)
    (args.out_dir / "README.md").write_text("\n".join(readme), encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
