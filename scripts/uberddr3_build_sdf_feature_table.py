#!/usr/bin/env python3
"""Build per-bitstream DDR SDF feature tables from semantic SDF metrics."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Iterable


HARDWARE_ID = "experiment_id"
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


def sha256_file(path: Path | None) -> str:
    if path is None or not path.exists() or not path.is_file():
        return ""
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bool_from_status(status: str) -> str:
    if status in {"pass", "robust", "no_tmdriv", "reset_locks_only"}:
        return "True"
    if status == "fail":
        return "False"
    return ""


def safe_token(value: str, default: str) -> str:
    value = value.strip() or default
    value = value.replace("[", "_").replace("]", "")
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def feature_name(row: dict[str, str]) -> str:
    parts = [
        row["metric"],
        row["family"],
        safe_token(row.get("lane", ""), "all"),
        safe_token(row.get("bit", ""), "no_bit"),
        f"ctrl_{safe_token(row.get('control_bit', ''), 'none')}",
        safe_token(row.get("scope", ""), "scope"),
        "value_ps",
    ]
    return "__".join(parts)


def load_hardware(path: Path) -> dict[str, dict[str, str]]:
    rows = read_csv(path)
    return {row[HARDWARE_ID]: row for row in rows if row.get(HARDWARE_ID)}


def load_manifest(path: Path) -> dict[str, dict[str, str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    out: dict[str, dict[str, str]] = {}
    for sample in data.get("samples", []):
        label = str(sample["label"])
        out[label] = {
            "metric_status": str(sample.get("status", "")),
            "manifest_sdf": str(sample.get("sdf", "")),
            "manifest_placed_json": str(sample.get("placed_json", "")),
        }
    return out


def path_or_none(value: str) -> Path | None:
    return Path(value) if value else None


def metadata_for_sample(
    sample: str,
    metrics_group: str,
    manifest_sample: dict[str, str],
    hardware: dict[str, dict[str, str]],
    allow_manifest_only: bool,
) -> dict[str, str] | None:
    hw = hardware.get(sample)
    if hw is None and not allow_manifest_only:
        return None

    out = {column: "" for column in METADATA_COLUMNS}
    out["experiment_id"] = sample
    out["metrics_group"] = metrics_group
    out["metric_sample"] = sample
    out["metric_status"] = manifest_sample.get("metric_status", "")

    if hw is not None:
        for key, value in hw.items():
            if key in out:
                out[key] = value
        out["hardware_pass"] = hw.get("pass", "")
        sdf = path_or_none(hw.get("cvc_sdf", ""))
        placed = path_or_none(hw.get("nextpnr_json", ""))
    else:
        out["hardware_pass"] = bool_from_status(out["metric_status"])
        sdf = path_or_none(manifest_sample.get("manifest_sdf", ""))
        placed = path_or_none(manifest_sample.get("manifest_placed_json", ""))

    if not out["cvc_sdf"]:
        out["cvc_sdf"] = str(sdf) if sdf else ""
    if not out["nextpnr_json"]:
        out["nextpnr_json"] = str(placed) if placed else ""

    out["sdf_sha256"] = sha256_file(sdf)
    out["nextpnr_json_sha256"] = sha256_file(placed)
    return out


def unique_preserving_order(values: Iterable[str]) -> list[str]:
    out = []
    seen = set()
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        out.append(value)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hardware-csv", type=Path, default=Path("artifacts/hardware/ddr3_causality_matrix.csv"))
    parser.add_argument("--sdf-metrics-dir", type=Path, action="append", required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--allow-manifest-only", action="store_true")
    args = parser.parse_args()

    hardware = load_hardware(args.hardware_csv)
    long_rows: list[dict[str, object]] = []
    wide_by_experiment: dict[str, dict[str, object]] = {}
    skipped_samples: list[dict[str, str]] = []

    for metrics_dir in args.sdf_metrics_dir:
        manifest_path = metrics_dir / "manifest.json"
        semantic_path = metrics_dir / "semantic_metrics.csv"
        if not manifest_path.exists():
            raise FileNotFoundError(manifest_path)
        if not semantic_path.exists():
            raise FileNotFoundError(semantic_path)

        metrics_group = metrics_dir.name
        manifest = load_manifest(manifest_path)
        metadata_by_sample: dict[str, dict[str, str]] = {}
        for sample, sample_info in manifest.items():
            metadata = metadata_for_sample(sample, metrics_group, sample_info, hardware, args.allow_manifest_only)
            if metadata is None:
                skipped_samples.append(
                    {
                        "metrics_group": metrics_group,
                        "metric_sample": sample,
                        "reason": "missing hardware row",
                    }
                )
                continue
            metadata_by_sample[sample] = metadata
            wide_by_experiment.setdefault(sample, dict(metadata))

        for metric_row in read_csv(semantic_path):
            sample = metric_row["sample"]
            metadata = metadata_by_sample.get(sample)
            if metadata is None:
                continue
            value = metric_row.get("value_ps", "")
            if value == "":
                continue
            feature = feature_name(metric_row)
            long = dict(metadata)
            long.update(
                {
                    "feature": feature,
                    "value_ps": value,
                    "metric": metric_row.get("metric", ""),
                    "family": metric_row.get("family", ""),
                    "lane": metric_row.get("lane", ""),
                    "bit": metric_row.get("bit", ""),
                    "control_bit": metric_row.get("control_bit", ""),
                    "scope": metric_row.get("scope", ""),
                    "count": metric_row.get("count", ""),
                    "min_ps": metric_row.get("min_ps", ""),
                    "median_ps": metric_row.get("median_ps", ""),
                    "p95_ps": metric_row.get("p95_ps", ""),
                    "max_ps": metric_row.get("max_ps", ""),
                    "spread_ps": metric_row.get("spread_ps", ""),
                }
            )
            long_rows.append(long)
            wide_by_experiment[sample][feature] = value

    feature_columns = unique_preserving_order(row["feature"] for row in long_rows)
    wide_rows = [wide_by_experiment[key] for key in sorted(wide_by_experiment)]

    long_fields = [
        *METADATA_COLUMNS,
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
    write_csv(args.out_dir / "features_long.csv", long_rows, long_fields)
    write_csv(args.out_dir / "features_wide.csv", wide_rows, [*METADATA_COLUMNS, *feature_columns])
    write_csv(args.out_dir / "skipped_samples.csv", skipped_samples, ["metrics_group", "metric_sample", "reason"])

    readme = [
        "# UberDDR3 Statistical SDF Feature Table",
        "",
        "This artifact joins committed hardware experiment rows with normalized semantic SDF metrics.",
        "",
        f"- hardware matrix: `{args.hardware_csv}`",
        f"- metrics directories: `{', '.join(str(path) for path in args.sdf_metrics_dir)}`",
        f"- experiments with features: `{len(wide_rows)}`",
        f"- semantic feature observations: `{len(long_rows)}`",
        f"- skipped metric samples: `{len(skipped_samples)}`",
        "",
        "The wide table is for modeling. The long table is for auditing and ranking. Feature names are semantic keys, not raw synthesized net names.",
        "",
    ]
    (args.out_dir / "README.md").write_text("\n".join(readme), encoding="utf-8")

    if skipped_samples:
        print(f"skipped {len(skipped_samples)} metric samples without hardware rows", file=sys.stderr)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
