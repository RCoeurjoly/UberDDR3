#!/usr/bin/env python3
"""Rank semantic DDR SDF features against hardware pass/fail outcomes."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from itertools import combinations
from pathlib import Path
import statistics
from typing import Iterable


STRATA_COLUMNS = [
    "metrics_group",
    "run_group",
    "variant",
    "payload_version",
    "seed",
    "metric_status",
    "abort_reason_name",
    "abort_lane",
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


def format_float(value: float | None) -> float | str:
    if value is None:
        return ""
    return round(value, 6)


def feature_stats(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    grouped: dict[str, dict[str, object]] = {}
    for row in rows:
        outcome = parse_bool(row.get("hardware_pass", ""))
        if outcome is None:
            continue
        try:
            value = float(row["value_ps"])
        except (KeyError, ValueError):
            continue
        feature = row["feature"]
        group = grouped.setdefault(
            feature,
            {
                "feature": feature,
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
        key = "pass_values" if outcome else "fail_values"
        group[key].append(value)

    out: list[dict[str, object]] = []
    for group in grouped.values():
        pass_values = sorted(group.pop("pass_values"))
        fail_values = sorted(group.pop("fail_values"))
        if not pass_values or not fail_values:
            continue
        pass_median = median(pass_values)
        fail_median = median(fail_values)
        auc_high = auc_fail_higher(pass_values, fail_values)
        assert auc_high is not None
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
        out.append(
            {
                **group,
                "n_pass": len(pass_values),
                "n_fail": len(fail_values),
                "pass_min_ps": pass_values[0],
                "pass_median_ps": format_float(pass_median),
                "pass_max_ps": pass_values[-1],
                "fail_min_ps": fail_values[0],
                "fail_median_ps": format_float(fail_median),
                "fail_max_ps": fail_values[-1],
                "fail_minus_pass_median_ps": format_float((fail_median or 0.0) - (pass_median or 0.0)),
                "fail_min_minus_pass_max_ps": format_float(fail_min_minus_pass_max),
                "pass_min_minus_fail_max_ps": format_float(pass_min_minus_fail_max),
                "auc_fail_higher": format_float(auc_high),
                "auc_best_direction": direction,
                "auc_best": format_float(max(auc_high, 1.0 - auc_high)),
                "cliffs_delta_fail_higher": format_float(2.0 * auc_high - 1.0),
                "strict_separation": strict,
                "strict_margin_ps": format_float(strict_margin),
            }
        )
    return sorted(
        out,
        key=lambda row: (
            float(row["auc_best"]),
            1 if row["strict_separation"] != "overlap" else 0,
            abs(float(row["fail_minus_pass_median_ps"])),
        ),
        reverse=True,
    )


def unique_experiments(rows: Iterable[dict[str, str]]) -> dict[str, dict[str, str]]:
    experiments: dict[str, dict[str, str]] = {}
    for row in rows:
        experiment_id = row.get("experiment_id", "")
        if experiment_id and experiment_id not in experiments:
            experiments[experiment_id] = row
    return experiments


def strata_summary(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    experiments = unique_experiments(rows)
    out: list[dict[str, object]] = []
    for column in STRATA_COLUMNS:
        grouped: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "pass": 0, "fail": 0, "unknown": 0})
        for row in experiments.values():
            value = row.get(column, "") or "<blank>"
            outcome = parse_bool(row.get("hardware_pass", ""))
            grouped[value]["total"] += 1
            if outcome is True:
                grouped[value]["pass"] += 1
            elif outcome is False:
                grouped[value]["fail"] += 1
            else:
                grouped[value]["unknown"] += 1
        for value, counts in sorted(grouped.items()):
            out.append(
                {
                    "stratum": column,
                    "value": value,
                    "total": counts["total"],
                    "pass": counts["pass"],
                    "fail": counts["fail"],
                    "unknown": counts["unknown"],
                }
            )
    return out


def pairwise_scores(rows: list[dict[str, str]], univariate: list[dict[str, object]], top_k: int, min_each: int) -> list[dict[str, object]]:
    experiments = unique_experiments(rows)
    outcomes = {
        experiment_id: parse_bool(row.get("hardware_pass", ""))
        for experiment_id, row in experiments.items()
    }
    if sum(outcome is True for outcome in outcomes.values()) < min_each:
        return []
    if sum(outcome is False for outcome in outcomes.values()) < min_each:
        return []

    values_by_feature: dict[str, dict[str, float]] = defaultdict(dict)
    for row in rows:
        feature = row.get("feature", "")
        experiment_id = row.get("experiment_id", "")
        if not feature or not experiment_id:
            continue
        try:
            values_by_feature[feature][experiment_id] = float(row["value_ps"])
        except ValueError:
            continue

    selected = [row for row in univariate if row.get("auc_best_direction") in {"fail_higher", "fail_lower"}][:top_k]
    out: list[dict[str, object]] = []
    for left, right in combinations(selected, 2):
        feature_a = str(left["feature"])
        feature_b = str(right["feature"])
        shared = [
            experiment_id
            for experiment_id in outcomes
            if outcomes[experiment_id] is not None
            and experiment_id in values_by_feature[feature_a]
            and experiment_id in values_by_feature[feature_b]
        ]
        pass_scores: list[float] = []
        fail_scores: list[float] = []
        for experiment_id in shared:
            a = values_by_feature[feature_a][experiment_id]
            b = values_by_feature[feature_b][experiment_id]
            if left["auc_best_direction"] == "fail_lower":
                a = -a
            if right["auc_best_direction"] == "fail_lower":
                b = -b
            score = a + b
            if outcomes[experiment_id] is True:
                pass_scores.append(score)
            else:
                fail_scores.append(score)
        auc_high = auc_fail_higher(pass_scores, fail_scores)
        if auc_high is None:
            continue
        out.append(
            {
                "feature_a": feature_a,
                "feature_b": feature_b,
                "n_pass": len(pass_scores),
                "n_fail": len(fail_scores),
                "auc_pair_score_fail_higher": format_float(auc_high),
                "auc_best": format_float(max(auc_high, 1.0 - auc_high)),
                "fail_minus_pass_median_score": format_float((median(fail_scores) or 0.0) - (median(pass_scores) or 0.0)),
            }
        )
    return sorted(out, key=lambda row: (float(row["auc_best"]), abs(float(row["fail_minus_pass_median_score"]))), reverse=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--features-long", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--top-k-pairs", type=int, default=25)
    parser.add_argument("--min-each-for-pairs", type=int, default=3)
    args = parser.parse_args()

    rows = read_csv(args.features_long)
    univariate = feature_stats(rows)
    strata = strata_summary(rows)
    pairs = pairwise_scores(rows, univariate, args.top_k_pairs, args.min_each_for_pairs)

    fields = [
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
        "fail_min_minus_pass_max_ps",
        "pass_min_minus_fail_max_ps",
        "auc_fail_higher",
        "auc_best_direction",
        "auc_best",
        "cliffs_delta_fail_higher",
        "strict_separation",
        "strict_margin_ps",
    ]
    write_csv(args.out_dir / "univariate_features.csv", univariate, fields)
    write_csv(
        args.out_dir / "top_fail_higher.csv",
        [row for row in univariate if row["auc_best_direction"] == "fail_higher"],
        fields,
    )
    write_csv(
        args.out_dir / "top_fail_lower.csv",
        [row for row in univariate if row["auc_best_direction"] == "fail_lower"],
        fields,
    )
    write_csv(args.out_dir / "strata_summary.csv", strata, ["stratum", "value", "total", "pass", "fail", "unknown"])
    write_csv(
        args.out_dir / "pairwise_score_models.csv",
        pairs,
        ["feature_a", "feature_b", "n_pass", "n_fail", "auc_pair_score_fail_higher", "auc_best", "fail_minus_pass_median_score"],
    )

    experiments = unique_experiments(rows)
    pass_n = sum(parse_bool(row.get("hardware_pass", "")) is True for row in experiments.values())
    fail_n = sum(parse_bool(row.get("hardware_pass", "")) is False for row in experiments.values())
    pair_note = (
        f"Pairwise score models written for `{len(pairs)}` feature pairs."
        if pairs
        else f"Pairwise score models skipped because at least `{args.min_each_for_pairs}` pass and fail experiments are required."
    )
    lines = [
        "# UberDDR3 Statistical SDF Analysis",
        "",
        f"- feature table: `{args.features_long}`",
        f"- experiments: `{len(experiments)}`",
        f"- pass experiments: `{pass_n}`",
        f"- fail experiments: `{fail_n}`",
        f"- ranked univariate features: `{len(univariate)}`",
        f"- {pair_note}",
        "",
        "This is hypothesis-generation evidence only. A feature becomes causal only after an intervention moves that feature and improves held-out hardware outcomes.",
        "",
        "## Outputs",
        "",
        "- `univariate_features.csv`: all pass/fail feature rankings.",
        "- `top_fail_higher.csv`: features where higher values predict failure.",
        "- `top_fail_lower.csv`: features where lower values predict failure.",
        "- `strata_summary.csv`: pass/fail counts by experiment covariate.",
        "- `pairwise_score_models.csv`: simple two-feature score models when enough samples exist.",
        "",
    ]
    (args.out_dir / "README.md").write_text("\n".join(lines), encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
