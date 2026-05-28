#!/usr/bin/env python3
"""Global no-rebuild SDF/HIL causality analysis with gnuplot artifacts."""

from __future__ import annotations

import argparse
import csv
import math
import shutil
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
import statistics


DEFAULT_FEATURE_TABLES = [
    ("direct", Path("artifacts/statistical-sdf/baseline-no-lock-seed-1-30/features_long.csv")),
    ("direct", Path("artifacts/statistical-sdf/seed-31-60-baseline-no-lock/features_long.csv")),
    ("direct", Path("artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock/features_long.csv")),
    ("direct", Path("artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll/features_long.csv")),
    ("direct", Path("artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost/features_long.csv")),
    ("direct", Path("artifacts/statistical-sdf/exact-abort-seed3-lock-matrix/features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/baseline-no-lock-seed-1-30-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/seed-31-60-baseline-no-lock-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost-skew/skew_features_long.csv")),
]

RANK_FIELDS = [
    "comparison",
    "feature_layer",
    "feature",
    "metric",
    "family",
    "lane",
    "bit",
    "control_bit",
    "scope",
    "n_pass",
    "n_fail",
    "pass_min_ps",
    "pass_median_ps",
    "pass_max_ps",
    "fail_min_ps",
    "fail_median_ps",
    "fail_max_ps",
    "fail_minus_pass_median_ps",
    "auc_fail_higher",
    "auc_best_direction",
    "auc_best",
    "cliffs_delta_fail_higher",
    "strict_separation",
    "strict_margin_ps",
    "support_score",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if fieldnames is None:
        seen: list[str] = []
        for row in rows:
            for key in row:
                if key not in seen:
                    seen.append(key)
        fieldnames = seen
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def parse_bool(value: str) -> bool | None:
    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes", "pass"}:
        return True
    if normalized in {"false", "0", "no", "fail"}:
        return False
    return None


def median(values: list[float]) -> float | None:
    return statistics.median(values) if values else None


def auc_fail_higher(pass_values: list[float], fail_values: list[float]) -> float | None:
    total = len(pass_values) * len(fail_values)
    if total == 0:
        return None
    score = 0.0
    for fail in fail_values:
        for passed in pass_values:
            if fail > passed:
                score += 1.0
            elif fail == passed:
                score += 0.5
    return score / total


def fnum(value: float | None) -> float | str:
    if value is None:
        return ""
    return round(value, 6)


def quantile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def safe_name(value: str, limit: int = 110) -> str:
    out = []
    for char in value:
        out.append(char if char.isalnum() or char in "._-" else "_")
    compact = "".join(out).strip("_")
    while "__" in compact:
        compact = compact.replace("__", "_")
    return (compact or "feature")[:limit]


def failure_class(row: dict[str, str]) -> str:
    if parse_bool(row.get("hardware_pass", "")) is True:
        return "pass"
    if row.get("abort_reason") == "2" or row.get("abort_reason_name") == "check_starting_data_search_exhausted":
        lane = row.get("abort_lane", "")
        return f"fail_abort2_lane{lane or 'unknown'}"
    if row.get("abort_seen", "").lower() == "false" or row.get("abort_reason") in {"0", ""}:
        return "fail_no_abort_or_startup"
    return f"fail_abort_{row.get('abort_reason', 'unknown')}"


def distribution_category(row: dict[str, str]) -> tuple[int, str]:
    klass = failure_class(row)
    if klass == "pass":
        return 1, "pass"
    if klass.startswith("fail_abort2"):
        return 2, "fail-reason-2"
    if klass == "fail_no_abort_or_startup":
        return 3, "no-abort"
    return 4, "fail-other"


def stable_jitter(value: str) -> float:
    total = sum((index + 1) * ord(char) for index, char in enumerate(value))
    return ((total % 1000) / 1000.0 - 0.5) * 0.22


def load_feature_rows(paths: list[tuple[str, Path]]) -> tuple[list[dict[str, str]], list[dict[str, object]]]:
    rows: list[dict[str, str]] = []
    inventory: list[dict[str, object]] = []
    seen = set()
    for layer, path in paths:
        if not path.exists():
            inventory.append({"feature_layer": layer, "path": str(path), "exists": False, "rows": 0, "experiments": 0})
            continue
        source_rows = read_csv(path)
        experiments = {row.get("experiment_id", "") for row in source_rows if row.get("experiment_id")}
        inventory.append(
            {
                "feature_layer": layer,
                "path": str(path),
                "exists": True,
                "rows": len(source_rows),
                "experiments": len(experiments),
            }
        )
        for row in source_rows:
            key = (layer, row.get("experiment_id", ""), row.get("feature", ""))
            if key in seen:
                continue
            seen.add(key)
            row = dict(row)
            row["feature_layer"] = layer
            row["failure_class"] = failure_class(row)
            rows.append(row)
    return rows, inventory


def stat_rows(rows: list[dict[str, str]], comparison: str) -> list[dict[str, object]]:
    grouped: dict[tuple[str, str], dict[str, object]] = {}
    for row in rows:
        outcome = parse_bool(row.get("hardware_pass", ""))
        if outcome is None:
            continue
        try:
            value = float(row.get("value_ps", ""))
        except ValueError:
            continue
        key = (row.get("feature_layer", ""), row.get("feature", ""))
        group = grouped.setdefault(
            key,
            {
                "comparison": comparison,
                "feature_layer": row.get("feature_layer", ""),
                "feature": row.get("feature", ""),
                "metric": row.get("metric", ""),
                "family": row.get("family", ""),
                "lane": row.get("lane", ""),
                "bit": row.get("bit", ""),
                "control_bit": row.get("control_bit", ""),
                "scope": row.get("scope", ""),
                "pass_values": [],
                "fail_values": [],
            },
        )
        group["pass_values" if outcome else "fail_values"].append(value)  # type: ignore[index]

    out: list[dict[str, object]] = []
    for group in grouped.values():
        pass_values = sorted(group.pop("pass_values"))  # type: ignore[arg-type]
        fail_values = sorted(group.pop("fail_values"))  # type: ignore[arg-type]
        if not pass_values or not fail_values:
            continue
        pass_median = median(pass_values)
        fail_median = median(fail_values)
        auc_high = auc_fail_higher(pass_values, fail_values)
        if auc_high is None:
            continue
        fail_min_minus_pass_max = min(fail_values) - max(pass_values)
        pass_min_minus_fail_max = min(pass_values) - max(fail_values)
        if fail_min_minus_pass_max > 0:
            strict = "fail_higher"
            strict_margin = fail_min_minus_pass_max
        elif pass_min_minus_fail_max > 0:
            strict = "fail_lower"
            strict_margin = pass_min_minus_fail_max
        else:
            strict = "overlap"
            strict_margin = 0.0
        direction = "fail_higher" if auc_high >= 0.5 else "fail_lower"
        auc_best = max(auc_high, 1.0 - auc_high)
        effect = (fail_median or 0.0) - (pass_median or 0.0)
        support_score = (auc_best - 0.5) * math.sqrt(len(pass_values) * len(fail_values))
        if strict != "overlap":
            support_score += 0.25
        out.append(
            {
                **group,
                "n_pass": len(pass_values),
                "n_fail": len(fail_values),
                "pass_min_ps": fnum(pass_values[0]),
                "pass_median_ps": fnum(pass_median),
                "pass_max_ps": fnum(pass_values[-1]),
                "fail_min_ps": fnum(fail_values[0]),
                "fail_median_ps": fnum(fail_median),
                "fail_max_ps": fnum(fail_values[-1]),
                "fail_minus_pass_median_ps": fnum(effect),
                "auc_fail_higher": fnum(auc_high),
                "auc_best_direction": direction,
                "auc_best": fnum(auc_best),
                "cliffs_delta_fail_higher": fnum(2.0 * auc_high - 1.0),
                "strict_separation": strict,
                "strict_margin_ps": fnum(strict_margin),
                "support_score": fnum(support_score),
            }
        )
    return sorted(
        out,
        key=lambda row: (
            float(row["support_score"]),
            float(row["auc_best"]),
            abs(float(row["fail_minus_pass_median_ps"])),
        ),
        reverse=True,
    )


def select_comparisons(rows: list[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    return {
        "all_usable": rows,
        "baseline_all": [r for r in rows if r.get("variant") == "baseline-no-lock"],
        "baseline_seed_1_30": [r for r in rows if r.get("run_group") == "baseline_no_lock_seed_1_30"],
        "baseline_seed_31_60": [
            r
            for r in rows
            if r.get("run_group") == "seed_31_60_baseline_cntvaluein3_lock_long_poll_500"
            and r.get("variant") == "baseline-no-lock"
        ],
        "baseline_abort2_vs_pass": [
            r
            for r in rows
            if r.get("variant") == "baseline-no-lock"
            and (parse_bool(r.get("hardware_pass", "")) is True or r.get("abort_reason") == "2")
        ],
        "cntvaluein3_locked_only": [r for r in rows if r.get("variant") == "cntvaluein3-skew-locked"],
        "locked_abort2_vs_pass": [
            r
            for r in rows
            if r.get("variant") == "cntvaluein3-skew-locked"
            and (parse_bool(r.get("hardware_pass", "")) is True or r.get("abort_reason") == "2")
        ],
    }


def experiment_inventory(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    first: dict[tuple[str, str], dict[str, str]] = {}
    for row in rows:
        key = (row.get("feature_layer", ""), row.get("experiment_id", ""))
        if key[1] and key not in first:
            first[key] = row
    counts: Counter[tuple[str, str, str, str, str]] = Counter()
    for (layer, _experiment), row in first.items():
        counts[
            (
                layer,
                row.get("run_group", ""),
                row.get("variant", ""),
                str(parse_bool(row.get("hardware_pass", ""))),
                failure_class(row),
            )
        ] += 1
    return [
        {
            "feature_layer": layer,
            "run_group": run_group,
            "variant": variant,
            "hardware_pass": passed,
            "failure_class": klass,
            "experiments": count,
        }
        for (layer, run_group, variant, passed, klass), count in sorted(counts.items())
    ]


def validation_rows(rankings: dict[str, list[dict[str, object]]], primary: str, checks: list[str], limit: int) -> list[dict[str, object]]:
    by_comparison = {name: {row["feature_layer"] + "::" + row["feature"]: row for row in rows} for name, rows in rankings.items()}
    out: list[dict[str, object]] = []
    for rank, row in enumerate(rankings.get(primary, [])[:limit], 1):
        key = row["feature_layer"] + "::" + row["feature"]
        support = 0
        directions = []
        for check in checks:
            other = by_comparison.get(check, {}).get(key)
            if not other:
                directions.append(f"{check}:missing")
                continue
            if other.get("auc_best_direction") == row.get("auc_best_direction") and float(other.get("auc_best", 0) or 0) >= 0.65:
                support += 1
            directions.append(f"{check}:{other.get('auc_best_direction')}:{other.get('auc_best')}")
        out.append(
            {
                "primary_rank": rank,
                "feature_layer": row["feature_layer"],
                "feature": row["feature"],
                "primary_auc_best": row["auc_best"],
                "primary_direction": row["auc_best_direction"],
                "primary_effect_ps": row["fail_minus_pass_median_ps"],
                "validation_support_count": support,
                "validation_details": "; ".join(directions),
            }
        )
    return out


def plot_data(rows: list[dict[str, str]], feature_layer: str, feature: str) -> tuple[list[dict[str, object]], str]:
    selected = [
        r
        for r in rows
        if r.get("feature_layer") == feature_layer
        and r.get("feature") == feature
        and parse_bool(r.get("hardware_pass", "")) is not None
    ]
    selected = sorted(selected, key=lambda r: (r.get("run_group", ""), int(r.get("seed") or 0), r.get("variant", ""), r.get("experiment_id", "")))
    out = []
    for index, row in enumerate(selected, 1):
        try:
            value = float(row.get("value_ps", ""))
        except ValueError:
            continue
        passed = parse_bool(row.get("hardware_pass", ""))
        out.append(
            {
                "index": index,
                "seed": row.get("seed", ""),
                "value_ps": fnum(value),
                "pass_value_ps": fnum(value) if passed is True else "",
                "fail_value_ps": fnum(value) if passed is False else "",
                "status": "pass" if passed else "fail",
                "failure_class": failure_class(row),
                "run_group": row.get("run_group", ""),
                "variant": row.get("variant", ""),
                "experiment_id": row.get("experiment_id", ""),
            }
        )
    title = feature
    return out, title


def write_plot(plot_dir: Path, rows: list[dict[str, str]], rank_row: dict[str, object], prefix: str) -> dict[str, object] | None:
    feature_layer = str(rank_row["feature_layer"])
    feature = str(rank_row["feature"])
    points, title = plot_data(rows, feature_layer, feature)
    if not points:
        return None
    name = safe_name(f"{prefix}_{feature_layer}_{feature}")
    dat = plot_dir / f"{name}.dat"
    gp = plot_dir / f"{name}.gp"
    png = plot_dir / f"{name}.png"
    plot_title = title[:120].replace("'", "_")
    write_csv(dat, points, ["index", "seed", "value_ps", "pass_value_ps", "fail_value_ps", "status", "failure_class", "run_group", "variant", "experiment_id"])
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid",
                "set xlabel 'Experiment index'",
                "set ylabel 'Feature value (ps)'",
                f"set title '{plot_title}'",
                "plot \\",
                f"  '{dat.name}' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {"plot": name, "feature_layer": feature_layer, "feature": feature, "dat": str(dat), "gp": str(gp), "png": str(png)}


def render_plots(plot_dir: Path, plot_rows: list[dict[str, object]], gnuplot: str | None) -> int:
    if not gnuplot:
        return 0
    rendered = 0
    for row in plot_rows:
        gp = Path(str(row["gp"]))
        subprocess.run([gnuplot, gp.name], cwd=plot_dir, check=True)
        rendered += 1
    return rendered


def is_signed_skew(row: dict[str, object]) -> bool:
    return str(row.get("feature_layer", "")) == "skew" and str(row.get("metric", "")).startswith("signed_")


def signed_skew_candidates(rankings: dict[str, list[dict[str, object]]], top_per_comparison: int) -> list[dict[str, object]]:
    candidates: list[dict[str, object]] = []
    for comparison in [
        "baseline_seed_1_30",
        "baseline_abort2_vs_pass",
        "baseline_seed_31_60",
        "cntvaluein3_locked_only",
        "locked_abort2_vs_pass",
    ]:
        signed = [row for row in rankings.get(comparison, []) if is_signed_skew(row)]
        candidates.extend(signed[:top_per_comparison])
    return candidates


def collect_feature_values(rows: list[dict[str, str]], feature_layer: str, feature: str) -> list[dict[str, object]]:
    out: list[dict[str, object]] = []
    for row in rows:
        if row.get("feature_layer") != feature_layer or row.get("feature") != feature:
            continue
        passed = parse_bool(row.get("hardware_pass", ""))
        if passed is None:
            continue
        try:
            value = float(row.get("value_ps", ""))
        except ValueError:
            continue
        out.append(
            {
                "value_ps": value,
                "passed": passed,
                "failure_class": failure_class(row),
                "seed": row.get("seed", ""),
                "run_group": row.get("run_group", ""),
                "variant": row.get("variant", ""),
                "experiment_id": row.get("experiment_id", ""),
            }
        )
    return out


def best_one_sided_threshold(pass_values: list[float], fail_values: list[float]) -> dict[str, object]:
    values = sorted(set(pass_values + fail_values))
    if not values:
        return {}
    candidates = [values[0] - 1e-9, values[-1] + 1e-9]
    candidates.extend(values)
    for left, right in zip(values, values[1:]):
        candidates.append((left + right) / 2.0)

    best: dict[str, object] | None = None
    for direction in ["fail_ge_threshold", "fail_le_threshold"]:
        for threshold in candidates:
            if direction == "fail_ge_threshold":
                false_fail = sum(1 for value in pass_values if value >= threshold)
                false_pass = sum(1 for value in fail_values if value < threshold)
            else:
                false_fail = sum(1 for value in pass_values if value <= threshold)
                false_pass = sum(1 for value in fail_values if value > threshold)
            errors = false_fail + false_pass
            balance = max(false_fail, false_pass)
            row = {
                "best_rule": direction,
                "threshold_ps": fnum(threshold),
                "false_fail_pass_points": false_fail,
                "false_pass_fail_points": false_pass,
                "threshold_errors": errors,
                "threshold_error_rate": fnum(errors / (len(pass_values) + len(fail_values))),
                "threshold_error_balance": balance,
            }
            if best is None or (
                errors,
                balance,
                abs(float(row["threshold_ps"]) if row["threshold_ps"] != "" else 0.0),
            ) < (
                int(best["threshold_errors"]),
                int(best["threshold_error_balance"]),
                abs(float(best["threshold_ps"]) if best["threshold_ps"] != "" else 0.0),
            ):
                best = row
    return best or {}


def failure_free_intervals(pass_values: list[float], fail_values: list[float]) -> list[dict[str, object]]:
    if not pass_values or not fail_values:
        return []
    intervals: list[dict[str, object]] = []
    all_min = min(pass_values + fail_values)
    all_max = max(pass_values + fail_values)
    fail_min = min(fail_values)
    fail_max = max(fail_values)
    if all_min < fail_min:
        intervals.append(
            {
                "interval_kind": "low_tail",
                "low_ps": fnum(all_min),
                "high_ps": fnum(fail_min),
                "width_ps": fnum(fail_min - all_min),
                "pass_points_inside": sum(1 for value in pass_values if all_min <= value < fail_min),
            }
        )
    if fail_max < all_max:
        intervals.append(
            {
                "interval_kind": "high_tail",
                "low_ps": fnum(fail_max),
                "high_ps": fnum(all_max),
                "width_ps": fnum(all_max - fail_max),
                "pass_points_inside": sum(1 for value in pass_values if fail_max < value <= all_max),
            }
        )
    fail_sorted = sorted(fail_values)
    for left, right in zip(fail_sorted, fail_sorted[1:]):
        if left == right:
            continue
        pass_inside = sum(1 for value in pass_values if left < value < right)
        if pass_inside:
            intervals.append(
                {
                    "interval_kind": "internal_gap",
                    "low_ps": fnum(left),
                    "high_ps": fnum(right),
                    "width_ps": fnum(right - left),
                    "pass_points_inside": pass_inside,
                }
            )
    return sorted(intervals, key=lambda row: (float(row["width_ps"]), int(row["pass_points_inside"])), reverse=True)


def threshold_report_rows(rows: list[dict[str, str]], plot_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    reports: list[dict[str, object]] = []
    for plot in plot_rows:
        feature_layer = str(plot["feature_layer"])
        feature = str(plot["feature"])
        values = collect_feature_values(rows, feature_layer, feature)
        pass_values = sorted(float(row["value_ps"]) for row in values if row["passed"] is True)
        fail_values = sorted(float(row["value_ps"]) for row in values if row["passed"] is False)
        if not pass_values or not fail_values:
            continue
        intervals = failure_free_intervals(pass_values, fail_values)
        largest = intervals[0] if intervals else {}
        threshold = best_one_sided_threshold(pass_values, fail_values)
        reports.append(
            {
                "plot": plot["plot"],
                "feature_layer": feature_layer,
                "feature": feature,
                "n_pass": len(pass_values),
                "n_fail": len(fail_values),
                "pass_min_ps": fnum(pass_values[0]),
                "pass_median_ps": fnum(median(pass_values)),
                "pass_max_ps": fnum(pass_values[-1]),
                "fail_min_ps": fnum(fail_values[0]),
                "fail_median_ps": fnum(median(fail_values)),
                "fail_max_ps": fnum(fail_values[-1]),
                "failure_free_interval_kind": largest.get("interval_kind", ""),
                "failure_free_low_ps": largest.get("low_ps", ""),
                "failure_free_high_ps": largest.get("high_ps", ""),
                "failure_free_width_ps": largest.get("width_ps", ""),
                "failure_free_pass_points_inside": largest.get("pass_points_inside", ""),
                **threshold,
            }
        )
    return sorted(
        reports,
        key=lambda row: (
            int(row.get("threshold_errors", 10**9) or 10**9),
            -float(row.get("failure_free_width_ps", 0) or 0),
        ),
    )


def distribution_plot_data(rows: list[dict[str, str]], feature_layer: str, feature: str) -> tuple[list[dict[str, object]], list[dict[str, object]], str]:
    selected = [
        r
        for r in rows
        if r.get("feature_layer") == feature_layer
        and r.get("feature") == feature
        and parse_bool(r.get("hardware_pass", "")) is not None
    ]
    selected = sorted(selected, key=lambda r: (distribution_category(r)[0], int(r.get("seed") or 0), r.get("experiment_id", "")))
    points: list[dict[str, object]] = []
    values_by_category: dict[int, list[float]] = defaultdict(list)
    labels: dict[int, str] = {}
    for row in selected:
        try:
            value = float(row.get("value_ps", ""))
        except ValueError:
            continue
        category_x, category = distribution_category(row)
        labels[category_x] = category
        values_by_category[category_x].append(value)
        jitter_x = category_x + stable_jitter(row.get("experiment_id", ""))
        passed = parse_bool(row.get("hardware_pass", ""))
        points.append(
            {
                "x": fnum(jitter_x),
                "category_x": category_x,
                "value_ps": fnum(value),
                "pass_value_ps": fnum(value) if passed is True else "",
                "fail_value_ps": fnum(value) if passed is False else "",
                "category": category,
                "failure_class": failure_class(row),
                "seed": row.get("seed", ""),
                "run_group": row.get("run_group", ""),
                "variant": row.get("variant", ""),
                "experiment_id": row.get("experiment_id", ""),
            }
        )
    summary: list[dict[str, object]] = []
    for category_x, values in sorted(values_by_category.items()):
        q1 = quantile(values, 0.25)
        med = quantile(values, 0.5)
        q3 = quantile(values, 0.75)
        summary.append(
            {
                "category_x": category_x,
                "category": labels[category_x],
                "q1_ps": fnum(q1),
                "median_ps": fnum(med),
                "q3_ps": fnum(q3),
                "n": len(values),
            }
        )
    return points, summary, feature


def write_distribution_plot(plot_dir: Path, rows: list[dict[str, str]], rank_row: dict[str, object], prefix: str) -> dict[str, object] | None:
    feature_layer = str(rank_row["feature_layer"])
    feature = str(rank_row["feature"])
    points, summary, title = distribution_plot_data(rows, feature_layer, feature)
    if not points or not summary:
        return None
    name = safe_name(f"{prefix}_{feature_layer}_{feature}_distribution")
    dat = plot_dir / f"{name}.dat"
    summary_dat = plot_dir / f"{name}.summary.dat"
    gp = plot_dir / f"{name}.gp"
    png = plot_dir / f"{name}.png"
    plot_title = title[:120].replace("'", "_")
    write_csv(
        dat,
        points,
        ["x", "category_x", "value_ps", "pass_value_ps", "fail_value_ps", "category", "failure_class", "seed", "run_group", "variant", "experiment_id"],
    )
    write_csv(summary_dat, summary, ["category_x", "category", "q1_ps", "median_ps", "q3_ps", "n"])
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid ytics",
                "set xrange [0.45:4.55]",
                "set xtics ('pass' 1, 'fail-reason-2' 2, 'no-abort' 3, 'fail-other' 4)",
                "set xlabel 'Hardware outcome class'",
                "set ylabel 'SDF feature value (ps)'",
                f"set title '{plot_title}'",
                "plot \\",
                f"  '{summary_dat.name}' using 1:4:3:5 with yerrorbars pt 9 ps 1.5 lw 3 lc rgb '#333333' title 'median + IQR', \\",
                f"  '{dat.name}' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {
        "plot": name,
        "plot_type": "distribution",
        "feature_layer": feature_layer,
        "feature": feature,
        "dat": str(dat),
        "summary_dat": str(summary_dat),
        "gp": str(gp),
        "png": str(png),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/statistical-sdf/global-ddr3-causality-analysis"))
    parser.add_argument("--top-plots", type=int, default=24)
    parser.add_argument("--render-plots", action="store_true")
    parser.add_argument("--gnuplot", default=shutil.which("gnuplot") or "")
    args = parser.parse_args()

    paths = DEFAULT_FEATURE_TABLES
    rows, source_inventory = load_feature_rows(paths)
    comparisons = {name: subset for name, subset in select_comparisons(rows).items() if subset}
    rankings = {name: stat_rows(subset, name) for name, subset in comparisons.items()}
    all_ranked = [row for name in comparisons for row in rankings[name]]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "feature_source_inventory.csv", source_inventory)
    write_csv(args.out_dir / "experiment_inventory.csv", experiment_inventory(rows))
    write_csv(args.out_dir / "ranked_features.csv", all_ranked, RANK_FIELDS)
    for name, ranked in rankings.items():
        write_csv(args.out_dir / f"ranked_{safe_name(name)}.csv", ranked, RANK_FIELDS)
    validation = validation_rows(rankings, "baseline_seed_1_30", ["baseline_seed_31_60", "cntvaluein3_locked_only"], 100)
    write_csv(args.out_dir / "cross_stratum_validation.csv", validation)

    plot_dir = args.out_dir / "plots"
    plot_dir.mkdir(parents=True, exist_ok=True)
    plot_rows: list[dict[str, object]] = []
    plot_candidates = []
    for comparison in ["baseline_seed_1_30", "baseline_abort2_vs_pass", "baseline_seed_31_60", "cntvaluein3_locked_only", "locked_abort2_vs_pass"]:
        plot_candidates.extend(rankings.get(comparison, [])[: max(1, args.top_plots // 3)])
    seen_features = set()
    for row in plot_candidates:
        key = (row["feature_layer"], row["feature"])
        if key in seen_features:
            continue
        seen_features.add(key)
        plot = write_plot(plot_dir, rows, row, str(row["comparison"]))
        if plot:
            plot_rows.append(plot)
        if len(plot_rows) >= args.top_plots:
            break
    rendered = render_plots(plot_dir, plot_rows, args.gnuplot if args.render_plots else None)
    write_csv(args.out_dir / "plot_manifest.csv", plot_rows)

    distribution_dir = args.out_dir / "distribution-plots"
    distribution_dir.mkdir(parents=True, exist_ok=True)
    distribution_rows: list[dict[str, object]] = []
    seen_distribution_features = set()
    for row in plot_candidates:
        key = (row["feature_layer"], row["feature"])
        if key in seen_distribution_features:
            continue
        seen_distribution_features.add(key)
        plot = write_distribution_plot(distribution_dir, rows, row, str(row["comparison"]))
        if plot:
            distribution_rows.append(plot)
        if len(distribution_rows) >= args.top_plots:
            break
    distribution_rendered = render_plots(distribution_dir, distribution_rows, args.gnuplot if args.render_plots else None)
    write_csv(args.out_dir / "distribution_plot_manifest.csv", distribution_rows)

    signed_dir = args.out_dir / "signed-skew-distribution-plots"
    signed_dir.mkdir(parents=True, exist_ok=True)
    signed_rows: list[dict[str, object]] = []
    signed_candidates = signed_skew_candidates(rankings, max(4, args.top_plots // 3))
    seen_signed_features = set()
    for row in signed_candidates:
        key = (row["comparison"], row["feature_layer"], row["feature"])
        if key in seen_signed_features:
            continue
        seen_signed_features.add(key)
        plot = write_distribution_plot(signed_dir, rows, row, f"signed_{row['comparison']}")
        if plot:
            signed_rows.append(plot)
        if len(signed_rows) >= args.top_plots:
            break
    signed_rendered = render_plots(signed_dir, signed_rows, args.gnuplot if args.render_plots else None)
    write_csv(args.out_dir / "signed_skew_distribution_plot_manifest.csv", signed_rows)
    signed_threshold_rows = threshold_report_rows(rows, signed_rows)
    write_csv(args.out_dir / "signed_skew_threshold_report.csv", signed_threshold_rows)

    pass_fail_1_30 = Counter()
    for row in {r.get("experiment_id", ""): r for r in rows if r.get("run_group") == "baseline_no_lock_seed_1_30"}.values():
        pass_fail_1_30[str(parse_bool(row.get("hardware_pass", "")))] += 1
    top = rankings.get("baseline_seed_1_30", [])[:10]
    readme = [
        "# Global UberDDR3 SDF/HIL Causality Analysis",
        "",
        "This no-rebuild analysis joins existing HIL outcomes with existing SDF/JSON-derived feature tables.",
        "",
        "## Inventory",
        "",
        f"- feature observations: `{len(rows)}`",
        f"- comparisons ranked: `{len(rankings)}`",
        f"- baseline seed 1..30 pass/fail check: pass `{pass_fail_1_30.get('True', 0)}`, fail `{pass_fail_1_30.get('False', 0)}`",
        f"- index plot scripts/data generated: `{len(plot_rows)}`",
        f"- index plot PNGs rendered: `{rendered}`",
        f"- distribution plot scripts/data generated: `{len(distribution_rows)}`",
        f"- distribution plot PNGs rendered: `{distribution_rendered}`",
        f"- focused signed-skew distribution plots generated: `{len(signed_rows)}`",
        f"- focused signed-skew distribution PNGs rendered: `{signed_rendered}`",
        f"- focused signed-skew threshold reports generated: `{len(signed_threshold_rows)}`",
        "",
        "Pass points are green and fail points are red in every gnuplot graph. Distribution plots group points by `pass`, `fail-reason-2`, `no-abort`, and `fail-other`, with median + IQR overlays. Focused signed-skew plots intentionally exclude absolute-value metrics and show only signed skew/order hypotheses. The threshold report tests one-sided signed-skew rules and reports the least-error threshold, false-pass/false-fail counts, and the largest observed failure-free interval.",
        "",
        "## Top Baseline Seed 1..30 Features",
        "",
        "| rank | layer | direction | AUC | effect ps | feature |",
        "|---:|---|---|---:|---:|---|",
    ]
    for idx, row in enumerate(top, 1):
        readme.append(
            f"| {idx} | {row['feature_layer']} | {row['auc_best_direction']} | {row['auc_best']} | {row['fail_minus_pass_median_ps']} | `{row['feature']}` |"
        )
    readme.extend(
        [
            "",
            "## Signed-Skew Threshold Highlights",
            "",
            "| errors | plot | rule | threshold ps | false fail | false pass | no-fail interval | pass pts | feature |",
            "|---:|---|---|---:|---:|---:|---|---:|---|",
        ]
    )
    for row in signed_threshold_rows[:10]:
        interval = ""
        if row.get("failure_free_interval_kind"):
            interval = f"{row['failure_free_interval_kind']} [{row['failure_free_low_ps']}, {row['failure_free_high_ps']}]"
        readme.append(
            f"| {row.get('threshold_errors', '')} | `{row.get('plot', '')}` | {row.get('best_rule', '')} | {row.get('threshold_ps', '')} | {row.get('false_fail_pass_points', '')} | {row.get('false_pass_fail_points', '')} | {interval} | {row.get('failure_free_pass_points_inside', '')} | `{row.get('feature', '')}` |"
        )
    readme.extend(
        [
            "",
            "## Files",
            "",
            "- `ranked_features.csv`: all univariate feature rankings across strata.",
            "- `cross_stratum_validation.csv`: whether seed1..30 top features repeat in seed31..60 and lock strata.",
            "- `feature_source_inventory.csv`: existing feature tables consumed.",
            "- `experiment_inventory.csv`: pass/fail/failure-class counts by layer/run group/variant.",
            "- `plots/*.dat`: auditable index-plot data.",
            "- `plots/*.gp`: index gnuplot scripts.",
            "- `plots/*.png`: rendered index graphs when gnuplot was available.",
            "- `distribution-plots/*.dat`: auditable pass/fail distribution point data.",
            "- `distribution-plots/*.summary.dat`: per-class median and IQR data.",
            "- `distribution-plots/*.gp`: distribution gnuplot scripts.",
            "- `distribution-plots/*.png`: rendered pass/fail distribution graphs.",
            "- `signed-skew-distribution-plots/*.dat`: auditable focused signed-skew point data.",
            "- `signed-skew-distribution-plots/*.summary.dat`: median and IQR data for focused signed-skew plots.",
            "- `signed-skew-distribution-plots/*.gp`: focused signed-skew gnuplot scripts.",
            "- `signed-skew-distribution-plots/*.png`: focused signed-skew/order hypothesis graphs; these exclude absolute-value metrics.",
            "- `signed_skew_threshold_report.csv`: pass/fail ranges, largest failure-free interval, and best one-sided threshold per focused signed-skew plot.",
            "",
            "This is hypothesis-generation evidence. A feature is not causal until a controlled intervention moves it and shifts held-out hardware outcomes.",
        ]
    )
    (args.out_dir / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
