#!/usr/bin/env python3
"""Analyze paired pre/post signed skew features by hardware transition."""

from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
from pathlib import Path
from statistics import median


SIGNED_METRICS = {
    "signed_dqs_minus_dq_bit",
    "signed_dqs_minus_dq_median",
    "signed_dqs_bus_skew_minus_dq_median",
    "signed_lane1_minus_lane0_dq_median",
    "signed_lane1_minus_lane0_dqs",
    "signed_ld_dqs_minus_dq_median",
    "signed_ld_minus_cntvaluein_dq_median",
    "signed_ld_minus_cntvaluein_dqs",
}
FAMILIES = {
    "idelay_cntvaluein_skew",
    "idelay_ld_skew",
    "idelay_ld_cntvaluein_skew",
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def fnum(value: str) -> float:
    return float(value)


def fmt(value: float | int) -> str:
    if isinstance(value, int):
        return str(value)
    return f"{value:.6f}".rstrip("0").rstrip(".")


def sign(value: float) -> int:
    if value > 0:
        return 1
    if value < 0:
        return -1
    return 0


def sign_label(value: float) -> str:
    return {1: "positive", -1: "negative", 0: "zero"}[sign(value)]


def transition(base_pass: str, locked_pass: str) -> str:
    left = "pass" if base_pass == "True" else "fail"
    right = "pass" if locked_pass == "True" else "fail"
    return f"{left}_to_{right}"


def row_rank(row: dict[str, str]) -> tuple[int, str]:
    return (1 if row.get("experiment_id", "").endswith("-long-poll") else 0, row.get("experiment_id", ""))


def experiment_by_seed(rows: list[dict[str, str]]) -> dict[str, str]:
    by_seed: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        by_seed[row["seed"]].append(row)
    return {seed: sorted(seed_rows, key=row_rank)[-1]["experiment_id"] for seed, seed_rows in by_seed.items()}


def feature_index(rows: list[dict[str, str]]) -> dict[str, dict[str, dict[str, str]]]:
    out: dict[str, dict[str, dict[str, str]]] = defaultdict(dict)
    for row in rows:
        if row.get("metric") not in SIGNED_METRICS:
            continue
        if row.get("family") not in FAMILIES:
            continue
        out[row["experiment_id"]][row["feature"]] = row
    return out


def meta_index(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    for row in rows:
        out.setdefault(row["experiment_id"], row)
    return out


def paired_rows(baseline_rows: list[dict[str, str]], locked_rows: list[dict[str, str]]) -> list[dict[str, object]]:
    baseline_by_seed = experiment_by_seed(baseline_rows)
    locked_by_seed = experiment_by_seed(locked_rows)
    baseline_features = feature_index(baseline_rows)
    locked_features = feature_index(locked_rows)
    baseline_meta = meta_index(baseline_rows)
    locked_meta = meta_index(locked_rows)

    rows: list[dict[str, object]] = []
    for seed in sorted(set(baseline_by_seed) & set(locked_by_seed), key=lambda item: int(item)):
        base_exp = baseline_by_seed[seed]
        lock_exp = locked_by_seed[seed]
        base_meta = baseline_meta[base_exp]
        lock_meta = locked_meta[lock_exp]
        common_features = sorted(set(baseline_features[base_exp]) & set(locked_features[lock_exp]))
        for feature in common_features:
            base = baseline_features[base_exp][feature]
            lock = locked_features[lock_exp][feature]
            base_value = fnum(base["value_ps"])
            lock_value = fnum(lock["value_ps"])
            delta = lock_value - base_value
            base_sign = sign(base_value)
            lock_sign = sign(lock_value)
            abs_delta = abs(lock_value) - abs(base_value)
            rows.append(
                {
                    "seed": seed,
                    "hardware_transition": transition(base_meta.get("hardware_pass", ""), lock_meta.get("hardware_pass", "")),
                    "baseline_experiment_id": base_exp,
                    "locked_experiment_id": lock_exp,
                    "baseline_pass": base_meta.get("hardware_pass", ""),
                    "locked_pass": lock_meta.get("hardware_pass", ""),
                    "baseline_abort_reason": base_meta.get("abort_reason", ""),
                    "locked_abort_reason": lock_meta.get("abort_reason", ""),
                    "locked_abort_reason_name": lock_meta.get("abort_reason_name", ""),
                    "feature": feature,
                    "metric": base.get("metric", ""),
                    "family": base.get("family", ""),
                    "lane": base.get("lane", ""),
                    "bit": base.get("bit", ""),
                    "control_bit": base.get("control_bit", ""),
                    "scope": base.get("scope", ""),
                    "baseline_value_ps": fmt(base_value),
                    "locked_value_ps": fmt(lock_value),
                    "delta_ps": fmt(delta),
                    "baseline_abs_ps": fmt(abs(base_value)),
                    "locked_abs_ps": fmt(abs(lock_value)),
                    "delta_abs_ps": fmt(abs_delta),
                    "baseline_sign": sign_label(base_value),
                    "locked_sign": sign_label(lock_value),
                    "sign_flip": base_sign != 0 and lock_sign != 0 and base_sign != lock_sign,
                    "abs_improved": abs_delta < 0,
                    "abs_worsened": abs_delta > 0,
                }
            )
    return rows


def transition_summary(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    by_feature: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        by_feature[str(row["feature"])].append(row)

    out: list[dict[str, object]] = []
    transitions = ["fail_to_pass", "fail_to_fail", "pass_to_fail", "pass_to_pass"]
    for feature, feature_rows in by_feature.items():
        first = feature_rows[0]
        item: dict[str, object] = {
            "feature": feature,
            "metric": first["metric"],
            "family": first["family"],
            "lane": first["lane"],
            "bit": first["bit"],
            "control_bit": first["control_bit"],
            "scope": first["scope"],
            "n_total": len(feature_rows),
            "sign_flip_total": sum(1 for row in feature_rows if row["sign_flip"]),
            "abs_improved_total": sum(1 for row in feature_rows if row["abs_improved"]),
            "abs_worsened_total": sum(1 for row in feature_rows if row["abs_worsened"]),
        }
        for name in transitions:
            group = [row for row in feature_rows if row["hardware_transition"] == name]
            item[f"{name}_n"] = len(group)
            if group:
                deltas = [float(row["delta_ps"]) for row in group]
                abs_deltas = [float(row["delta_abs_ps"]) for row in group]
                item[f"{name}_median_delta_ps"] = fmt(median(deltas))
                item[f"{name}_median_delta_abs_ps"] = fmt(median(abs_deltas))
                item[f"{name}_sign_flip_count"] = sum(1 for row in group if row["sign_flip"])
                item[f"{name}_abs_improved_count"] = sum(1 for row in group if row["abs_improved"])
                item[f"{name}_abs_worsened_count"] = sum(1 for row in group if row["abs_worsened"])
            else:
                item[f"{name}_median_delta_ps"] = ""
                item[f"{name}_median_delta_abs_ps"] = ""
                item[f"{name}_sign_flip_count"] = ""
                item[f"{name}_abs_improved_count"] = ""
                item[f"{name}_abs_worsened_count"] = ""

        if item["fail_to_pass_n"] and item["pass_to_fail_n"]:
            item["passfail_minus_failpass_median_delta_ps"] = fmt(
                float(item["pass_to_fail_median_delta_ps"]) - float(item["fail_to_pass_median_delta_ps"])
            )
            item["passfail_minus_failpass_sign_flip_rate"] = fmt(
                (int(item["pass_to_fail_sign_flip_count"]) / int(item["pass_to_fail_n"]))
                - (int(item["fail_to_pass_sign_flip_count"]) / int(item["fail_to_pass_n"]))
            )
            item["contrast_score"] = fmt(
                abs(float(item["passfail_minus_failpass_median_delta_ps"]))
                + 100.0 * abs(float(item["passfail_minus_failpass_sign_flip_rate"]))
            )
        else:
            item["passfail_minus_failpass_median_delta_ps"] = ""
            item["passfail_minus_failpass_sign_flip_rate"] = ""
            item["contrast_score"] = ""
        out.append(item)

    return sorted(out, key=lambda row: float(row["contrast_score"] or 0.0), reverse=True)


def seed_summary(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    by_seed: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        by_seed[str(row["seed"])].append(row)
    out: list[dict[str, object]] = []
    for seed in sorted(by_seed, key=lambda item: int(item)):
        group = by_seed[seed]
        transitions = Counter(str(row["hardware_transition"]) for row in group)
        out.append(
            {
                "seed": seed,
                "hardware_transition": group[0]["hardware_transition"],
                "features": len(group),
                "sign_flip_count": sum(1 for row in group if row["sign_flip"]),
                "abs_improved_count": sum(1 for row in group if row["abs_improved"]),
                "abs_worsened_count": sum(1 for row in group if row["abs_worsened"]),
                "median_delta_abs_ps": fmt(median(float(row["delta_abs_ps"]) for row in group)),
                "transition_row_count_check": ";".join(f"{k}:{v}" for k, v in sorted(transitions.items())),
            }
        )
    return out


def readme(out_dir: Path, paired: list[dict[str, object]], summary: list[dict[str, object]], seeds: list[dict[str, object]]) -> str:
    transitions = Counter(str(row["hardware_transition"]) for row in seeds)
    lines = [
        "# Pre/Post Signed Skew Analysis",
        "",
        "This analysis joins `baseline-no-lock` and `cntvaluein3-skew-locked` by seed, then compares signed derived skew features for IDELAY CNTVALUEIN, IDELAY LD, and LD-vs-CNTVALUEIN timing.",
        "",
        "The sample unit is the paired bitstream seed. Feature count does not increase the statistical sample count.",
        "",
        "## Samples",
        "",
        "| transition | samples |",
        "| --- | ---: |",
    ]
    for name in ["fail_to_pass", "fail_to_fail", "pass_to_fail", "pass_to_pass"]:
        lines.append(f"| {name} | {transitions.get(name, 0)} |")
    lines.extend(
        [
            f"| total | {len(seeds)} |",
            "",
            "## Outputs",
            "",
            "- `paired_signed_skew_long.csv`: one row per seed-pair and signed feature.",
            "- `feature_transition_summary.csv`: per-feature medians and sign-flip counts by transition.",
            "- `top_transition_contrasts.csv`: top features where pass-to-fail differs from fail-to-pass.",
            "- `seed_transition_summary.csv`: aggregate sign-flip and absolute-change counts by seed.",
            "",
            "## Top Pass-To-Fail Versus Fail-To-Pass Contrasts",
            "",
            "| feature | pass_to_fail median delta ps | fail_to_pass median delta ps | pass_to_fail flips | fail_to_pass flips |",
            "| --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in summary[:20]:
        lines.append(
            f"| `{row['feature']}` | {row['pass_to_fail_median_delta_ps']} | {row['fail_to_pass_median_delta_ps']} | "
            f"{row['pass_to_fail_sign_flip_count']}/{row['pass_to_fail_n']} | {row['fail_to_pass_sign_flip_count']}/{row['fail_to_pass_n']} |"
        )
    lines.extend(
        [
            "",
            "Interpretation rule: this is hypothesis refinement. A feature becomes causal only if a later intervention intentionally moves that signed timing relation and hardware pass rate moves with it.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-skew-long", required=True, type=Path)
    parser.add_argument("--locked-skew-long", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    paired = paired_rows(read_csv(args.baseline_skew_long), read_csv(args.locked_skew_long))
    summary = transition_summary(paired)
    seeds = seed_summary(paired)
    top = [row for row in summary if row.get("pass_to_fail_n") and row.get("fail_to_pass_n")][:50]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "paired_signed_skew_long.csv", paired)
    write_csv(args.out_dir / "feature_transition_summary.csv", summary)
    write_csv(args.out_dir / "top_transition_contrasts.csv", top)
    sign_flip_enriched = [
        row for row in summary
        if row.get("pass_to_fail_n") == 2
        and row.get("fail_to_pass_n") == 5
        and row.get("pass_to_fail_sign_flip_count") == 2
        and int(row.get("fail_to_pass_sign_flip_count") or 0) <= 1
    ]
    write_csv(args.out_dir / "pass_to_fail_sign_flip_enriched.csv", sign_flip_enriched)
    write_csv(args.out_dir / "seed_transition_summary.csv", seeds)
    (args.out_dir / "README.md").write_text(readme(args.out_dir, paired, top, seeds), encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
