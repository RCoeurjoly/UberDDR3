#!/usr/bin/env python3
"""Matched same-seed delta causality analysis for UberDDR3 SDF and JSON features."""

from __future__ import annotations

import argparse
import csv
import math
import shutil
import statistics
import subprocess
from collections import Counter, defaultdict
from pathlib import Path


DEFAULT_TABLES = [
    ("sdf", Path("artifacts/statistical-sdf/baseline-no-lock-seed-1-30/features_long.csv")),
    ("sdf", Path("artifacts/statistical-sdf/seed-31-60-baseline-no-lock/features_long.csv")),
    ("sdf", Path("artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock/features_long.csv")),
    ("sdf", Path("artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll/features_long.csv")),
    ("sdf", Path("artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost/features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/baseline-no-lock-seed-1-30-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/seed-31-60-baseline-no-lock-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-skew/skew_features_long.csv")),
    ("skew", Path("artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost-skew/skew_features_long.csv")),
    ("json", Path("artifacts/statistical-sdf/json-physical-features/json_physical_features_long.csv")),
]
META = [
    "experiment_id", "hardware_pass", "seed", "run_group", "variant", "payload_version", "fail_reasons", "calib_complete", "bist_done", "wrong_read_data",
    "abort_seen", "abort_reason", "abort_reason_name", "abort_lane", "abort_state", "abort_instruction", "abort_start_index_check",
    "abort_lane_write_dq_late", "abort_lane_read_dq_early", "abort_dq_target_index", "abort_data_start_index",
    "bitstream_sha256", "sdf_sha256", "nextpnr_json_sha256", "result_json", "nextpnr_json", "cvc_sdf", "interpretation",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if fieldnames is None:
        fieldnames = []
        for row in rows:
            for key in row:
                if key not in fieldnames:
                    fieldnames.append(key)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def parse_bool(value: str) -> bool | None:
    v = str(value).strip().lower()
    if v in {"true", "1", "yes", "pass"}:
        return True
    if v in {"false", "0", "no", "fail"}:
        return False
    return None


def fnum(value: float | int | None) -> float | str:
    if value is None or not math.isfinite(float(value)):
        return ""
    return round(float(value), 6)


def median(values: list[float]) -> float | None:
    return statistics.median(values) if values else None


def failure_class(meta: dict[str, str]) -> str:
    if parse_bool(meta.get("hardware_pass", "")) is True:
        return "pass"
    if meta.get("abort_reason") == "2" or meta.get("abort_reason_name") == "check_starting_data_search_exhausted":
        lane = meta.get("abort_lane", "") or "unknown"
        return f"fail_abort2_lane{lane}"
    if meta.get("wrong_read_data", "") not in {"", "0", "False", "false"}:
        return "fail_bist_or_wrong_read"
    if meta.get("abort_seen", "").lower() == "false" or meta.get("abort_reason", "") in {"", "0"}:
        return "fail_no_abort_or_startup"
    if parse_bool(meta.get("calib_complete", "")) is False:
        return "fail_other_calibration"
    return "fail_other"


def transition(before: dict[str, str], after: dict[str, str]) -> str:
    b = "pass" if parse_bool(before.get("hardware_pass", "")) is True else "fail"
    a = "pass" if parse_bool(after.get("hardware_pass", "")) is True else "fail"
    return f"{b}_to_{a}"


def feature_key(layer: str, row: dict[str, str]) -> str:
    return f"{layer}::{row.get('feature', '')}"


def load_rows(paths: list[tuple[str, Path]]) -> tuple[dict[str, dict[str, str]], dict[str, dict[str, dict[str, object]]], dict[str, dict[str, str]], list[dict[str, object]]]:
    meta: dict[str, dict[str, str]] = {}
    values: dict[str, dict[str, dict[str, object]]] = defaultdict(dict)
    feature_meta: dict[str, dict[str, str]] = {}
    inventory = []
    seen = set()
    for layer, path in paths:
        if not path.exists():
            inventory.append({"layer": layer, "path": str(path), "exists": False, "rows": 0, "experiments": 0})
            continue
        rows = read_csv(path)
        exps = set()
        for row in rows:
            exp = row.get("experiment_id", "")
            if not exp:
                continue
            exps.add(exp)
            meta.setdefault(exp, {k: row.get(k, "") for k in META})
            key = feature_key(layer, row)
            if (exp, key) in seen:
                continue
            seen.add((exp, key))
            try:
                value = float(row.get("value_ps", ""))
            except ValueError:
                continue
            values[exp][key] = {"value": value, "row": row, "layer": layer}
            feature_meta.setdefault(
                key,
                {
                    "feature_key": key,
                    "feature_layer": layer,
                    "feature": row.get("feature", ""),
                    "metric": row.get("metric", ""),
                    "family": row.get("family", ""),
                    "lane": row.get("lane", ""),
                    "bit": row.get("bit", ""),
                    "control_bit": row.get("control_bit", ""),
                    "scope": row.get("scope", ""),
                },
            )
        inventory.append({"layer": layer, "path": str(path), "exists": True, "rows": len(rows), "experiments": len(exps)})
    return meta, values, feature_meta, inventory


def choose_experiment(rows: list[str], meta: dict[str, dict[str, str]]) -> str:
    def rank(exp: str) -> tuple[int, int, str]:
        m = meta[exp]
        long_poll = 1 if "long" in exp or "long" in m.get("run_group", "") else 0
        present = sum(1 for k in ["sdf_sha256", "nextpnr_json_sha256", "bitstream_sha256"] if m.get(k))
        return (long_poll, present, exp)
    return sorted(rows, key=rank)[-1]


def build_pairs(meta: dict[str, dict[str, str]], values: dict[str, dict[str, dict[str, object]]]) -> list[dict[str, object]]:
    by_seed_variant: dict[tuple[str, str], list[str]] = defaultdict(list)
    for exp, m in meta.items():
        if parse_bool(m.get("hardware_pass", "")) is None:
            continue
        if not values.get(exp):
            continue
        by_seed_variant[(m.get("seed", ""), m.get("variant", ""))].append(exp)
    pairs = []
    for seed in sorted({k[0] for k in by_seed_variant if k[0]}, key=lambda x: int(x)):
        baseline = by_seed_variant.get((seed, "baseline-no-lock"), [])
        if not baseline:
            continue
        before = choose_experiment(baseline, meta)
        for after_variant in ["cntvaluein3-skew-locked", "cntvaluein_only", "cntvaluein_plus_ld_parent", "idelay-stable-before-ld"]:
            afters = by_seed_variant.get((seed, after_variant), [])
            if not afters:
                continue
            after = choose_experiment(afters, meta)
            bm = meta[before]
            am = meta[after]
            pairs.append(
                {
                    "pair_id": f"seed{seed}__baseline-no-lock__to__{after_variant}",
                    "seed": seed,
                    "before_experiment_id": before,
                    "after_experiment_id": after,
                    "before_variant": "baseline-no-lock",
                    "after_variant": after_variant,
                    "before_pass": bm.get("hardware_pass", ""),
                    "after_pass": am.get("hardware_pass", ""),
                    "hardware_transition": transition(bm, am),
                    "before_failure_class": failure_class(bm),
                    "after_failure_class": failure_class(am),
                    "before_abort_reason": bm.get("abort_reason", ""),
                    "after_abort_reason": am.get("abort_reason", ""),
                    "before_abort_lane": bm.get("abort_lane", ""),
                    "after_abort_lane": am.get("abort_lane", ""),
                }
            )
    return pairs


def delta_rows(pairs: list[dict[str, object]], values: dict[str, dict[str, dict[str, object]]], feature_meta: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    out = []
    for pair in pairs:
        before = str(pair["before_experiment_id"])
        after = str(pair["after_experiment_id"])
        common = sorted(set(values[before]) & set(values[after]))
        for key in common:
            bv = float(values[before][key]["value"])
            av = float(values[after][key]["value"])
            fm = feature_meta[key]
            out.append(
                {
                    **pair,
                    **fm,
                    "before_value": fnum(bv),
                    "after_value": fnum(av),
                    "delta": fnum(av - bv),
                    "before_abs": fnum(abs(bv)),
                    "after_abs": fnum(abs(av)),
                    "delta_abs": fnum(abs(av) - abs(bv)),
                    "abs_improved": abs(av) < abs(bv),
                    "abs_worsened": abs(av) > abs(bv),
                    "sign_flip": (bv > 0 > av) or (bv < 0 < av),
                }
            )
    return out


def summary_rows(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    groups: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        groups[str(row["feature_key"])].append(row)
    transitions = ["fail_to_pass", "pass_to_fail", "fail_to_fail", "pass_to_pass"]
    out = []
    for key, grp in groups.items():
        first = grp[0]
        row = {k: first.get(k, "") for k in ["feature_key", "feature_layer", "feature", "metric", "family", "lane", "bit", "control_bit", "scope"]}
        row["n_pairs"] = len({g["pair_id"] for g in grp})
        for t in transitions:
            tg = [g for g in grp if g["hardware_transition"] == t]
            row[f"{t}_n"] = len(tg)
            row[f"{t}_median_delta"] = fnum(median([float(g["delta"]) for g in tg])) if tg else ""
            row[f"{t}_median_delta_abs"] = fnum(median([float(g["delta_abs"]) for g in tg])) if tg else ""
            row[f"{t}_abs_improved"] = sum(1 for g in tg if g["abs_improved"])
            row[f"{t}_abs_worsened"] = sum(1 for g in tg if g["abs_worsened"])
            row[f"{t}_sign_flip"] = sum(1 for g in tg if g["sign_flip"])
        if row["fail_to_pass_n"] and row["pass_to_fail_n"]:
            row["transition_delta_contrast"] = fnum(float(row["pass_to_fail_median_delta"] or 0) - float(row["fail_to_pass_median_delta"] or 0))
            row["transition_abs_delta_contrast"] = fnum(float(row["pass_to_fail_median_delta_abs"] or 0) - float(row["fail_to_pass_median_delta_abs"] or 0))
            row["contrast_score"] = fnum(abs(float(row["transition_delta_contrast"])) + 0.5 * abs(float(row["transition_abs_delta_contrast"])))
        else:
            row["transition_delta_contrast"] = ""
            row["transition_abs_delta_contrast"] = ""
            row["contrast_score"] = ""
        out.append(row)
    return sorted(out, key=lambda r: float(r.get("contrast_score") or 0), reverse=True)


def failure_class_summary(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    groups: dict[tuple[str, str], list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        groups[(str(row["after_failure_class"]), str(row["feature_key"]))].append(row)
    out = []
    for (klass, key), grp in groups.items():
        if klass == "pass":
            continue
        first = grp[0]
        deltas = [float(g["delta"]) for g in grp]
        abs_deltas = [float(g["delta_abs"]) for g in grp]
        out.append(
            {
                "failure_class": klass,
                "feature_key": key,
                "feature_layer": first.get("feature_layer", ""),
                "feature": first.get("feature", ""),
                "metric": first.get("metric", ""),
                "family": first.get("family", ""),
                "lane": first.get("lane", ""),
                "bit": first.get("bit", ""),
                "control_bit": first.get("control_bit", ""),
                "n": len(grp),
                "median_delta": fnum(median(deltas)),
                "median_delta_abs": fnum(median(abs_deltas)),
                "abs_improved": sum(1 for g in grp if g["abs_improved"]),
                "abs_worsened": sum(1 for g in grp if g["abs_worsened"]),
                "sign_flip": sum(1 for g in grp if g["sign_flip"]),
                "score": fnum(abs(median(deltas) or 0) + abs(median(abs_deltas) or 0)),
            }
        )
    return sorted(out, key=lambda r: (str(r["failure_class"]), -float(r["score"] or 0)))


def seed_summary(pairs: list[dict[str, object]], rows: list[dict[str, object]]) -> list[dict[str, object]]:
    by_pair: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        by_pair[str(row["pair_id"])].append(row)
    out = []
    for pair in pairs:
        grp = by_pair[str(pair["pair_id"])]
        out.append({**pair, "features": len(grp), "median_delta_abs": fnum(median([float(g["delta_abs"]) for g in grp])) if grp else "", "abs_improved": sum(1 for g in grp if g["abs_improved"]), "abs_worsened": sum(1 for g in grp if g["abs_worsened"]), "sign_flip": sum(1 for g in grp if g["sign_flip"])})
    return out


def threshold_rules(rows: list[dict[str, object]], summaries: list[dict[str, object]], limit: int = 80) -> list[dict[str, object]]:
    top_keys = [str(r["feature_key"]) for r in summaries if r.get("fail_to_pass_n") and r.get("pass_to_fail_n")][:limit]
    by_feature: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        if row["feature_key"] in top_keys and row["hardware_transition"] in {"fail_to_pass", "pass_to_fail"}:
            by_feature[str(row["feature_key"])].append(row)
    rules = []
    for key, grp in by_feature.items():
        vals = sorted(set(float(g["delta"]) for g in grp))
        if len(vals) < 2:
            continue
        thresholds = [(a + b) / 2 for a, b in zip(vals, vals[1:])]
        best = None
        for direction in ["ge_pass_to_fail", "le_pass_to_fail"]:
            for th in thresholds:
                fp = fn = tp = tn = 0
                for g in grp:
                    pred_ptf = float(g["delta"]) >= th if direction == "ge_pass_to_fail" else float(g["delta"]) <= th
                    actual_ptf = g["hardware_transition"] == "pass_to_fail"
                    if pred_ptf and actual_ptf: tp += 1
                    elif pred_ptf and not actual_ptf: fp += 1
                    elif not pred_ptf and actual_ptf: fn += 1
                    else: tn += 1
                tpr = tp / max(1, tp + fn)
                tnr = tn / max(1, tn + fp)
                bal = 0.5 * (tpr + tnr)
                cand = (bal, -(fp + fn), tp, tn, fp, fn, th, direction)
                if best is None or cand > best:
                    best = cand
        if best:
            bal, negerr, tp, tn, fp, fn, th, direction = best
            first = grp[0]
            rules.append({"feature_key": key, "feature_layer": first["feature_layer"], "feature": first["feature"], "metric": first["metric"], "family": first["family"], "lane": first["lane"], "bit": first["bit"], "control_bit": first["control_bit"], "rule": direction, "threshold_delta": fnum(th), "balanced_accuracy": fnum(bal), "errors": fp + fn, "tp_pass_to_fail": tp, "tn_fail_to_pass": tn, "false_pass_to_fail": fp, "false_fail_to_pass": fn, "samples": len(grp)})
    return sorted(rules, key=lambda r: (float(r["balanced_accuracy"]), -int(r["errors"])), reverse=True)


def intervention_for(row: dict[str, object]) -> str:
    layer = str(row.get("feature_layer", ""))
    family = str(row.get("family", ""))
    metric = str(row.get("metric", ""))
    feature = str(row.get("feature", ""))
    if "startup" in family or "reset" in feature or "idelayctrl" in feature:
        return "Constrain or instrument IDELAYCTRL/reset release sequencing; verify reset leaves calibration only after IDELAYCTRL ready is stable."
    if "ld_cntvaluein" in family or "ld_minus_cntvaluein" in metric:
        return "RTL stable-before-LD intervention: shadow CNTVALUEIN locally and assert LD only after a fixed stable window."
    if "idelay_cntvaluein" in family or "cntvaluein" in feature:
        return "Localize IDELAY programming cone or add high-level RTL/registering to reduce CNTVALUEIN fanout and skew sensitivity."
    if layer == "json":
        return "Translate physical locality signal into floorplan/LOC/BEL/locality constraint candidate, then verify SDF/JSON feature moves."
    if "iologic" in family or "dqs" in feature or "dq" in feature:
        return "Inspect lane/DQ/DQS placement and calibration tap observability; consider lane-local placement constraints only after delta validation."
    return "Use as hypothesis-generation evidence; design a targeted intervention only after confirming failure-class specificity."


def hypothesis_ledger(summaries: list[dict[str, object]], rules: list[dict[str, object]], failure_summaries: list[dict[str, object]]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    seen = set()
    for source, items in [("transition_delta", summaries[:40]), ("delta_threshold_rule", rules[:25]), ("failure_class_delta", failure_summaries[:40])]:
        for item in items:
            key = (source, item.get("feature_key"), item.get("failure_class", ""))
            if key in seen:
                continue
            seen.add(key)
            evidence = ""
            if source == "transition_delta":
                evidence = f"fail_to_pass median {item.get('fail_to_pass_median_delta')} vs pass_to_fail median {item.get('pass_to_fail_median_delta')}; contrast {item.get('transition_delta_contrast')}"
            elif source == "delta_threshold_rule":
                evidence = f"{item.get('rule')} threshold {item.get('threshold_delta')}; balanced_accuracy {item.get('balanced_accuracy')}; errors {item.get('errors')}/{item.get('samples')}"
            else:
                evidence = f"after failure class {item.get('failure_class')}; median_delta {item.get('median_delta')}; median_delta_abs {item.get('median_delta_abs')}; n {item.get('n')}"
            rows.append(
                {
                    "hypothesis_id": f"HD-{len(rows)+1:03d}",
                    "source": source,
                    "failure_class": item.get("failure_class", "transition_specific"),
                    "feature_layer": item.get("feature_layer", ""),
                    "feature": item.get("feature", ""),
                    "metric": item.get("metric", ""),
                    "family": item.get("family", ""),
                    "lane": item.get("lane", ""),
                    "bit": item.get("bit", ""),
                    "control_bit": item.get("control_bit", ""),
                    "evidence": evidence,
                    "matched_pair_support": item.get("n_pairs", item.get("samples", item.get("n", ""))),
                    "recommended_intervention": intervention_for(item),
                    "status": "hypothesis_generated",
                }
            )
    return rows


def write_plot(out_dir: Path, rows: list[dict[str, object]], feature_key: str, name: str) -> dict[str, str] | None:
    pts = [r for r in rows if r["feature_key"] == feature_key]
    if not pts:
        return None
    dat = out_dir / f"{name}.dat"
    gp = out_dir / f"{name}.gp"
    png = out_dir / f"{name}.png"
    plot_rows = []
    for i, r in enumerate(sorted(pts, key=lambda x: (str(x["hardware_transition"]), int(x["seed"])))):
        x = {"fail_to_pass": 1, "pass_to_fail": 2, "fail_to_fail": 3, "pass_to_pass": 4}.get(str(r["hardware_transition"]), 5)
        jitter = ((int(r["seed"]) * 37) % 100 / 100 - 0.5) * 0.18
        plot_rows.append({"x": fnum(x + jitter), "delta": r["delta"], "fail_to_pass_delta": r["delta"] if r["hardware_transition"] == "fail_to_pass" else "", "pass_to_fail_delta": r["delta"] if r["hardware_transition"] == "pass_to_fail" else "", "other_delta": r["delta"] if r["hardware_transition"] not in {"fail_to_pass", "pass_to_fail"} else "", "transition": r["hardware_transition"], "seed": r["seed"], "feature": r["feature"]})
    write_csv(dat, plot_rows, ["x", "delta", "fail_to_pass_delta", "pass_to_fail_delta", "other_delta", "transition", "seed", "feature"])
    title = str(pts[0]["feature"])[:115].replace("'", "_")
    gp.write_text("\n".join([
        "set terminal pngcairo size 1200,780 enhanced font 'DejaVu Sans,10'",
        f"set output '{png.name}'",
        "set datafile separator comma",
        "set key outside right top",
        "set grid ytics",
        "set xrange [0.45:4.55]",
        "set xtics ('fail->pass' 1, 'pass->fail' 2, 'fail->fail' 3, 'pass->pass' 4)",
        "set ylabel 'after - before feature delta'",
        f"set title '{title}'",
        "plot \\",
        f"  '{dat.name}' using 1:3 with points pt 7 ps 1.25 lc rgb '#1a9850' title 'fail->pass', \\",
        f"  '{dat.name}' using 1:4 with points pt 7 ps 1.25 lc rgb '#d73027' title 'pass->fail', \\",
        f"  '{dat.name}' using 1:5 with points pt 7 ps 1.1 lc rgb '#666666' title 'other'",
        "",
    ]), encoding="utf-8")
    return {"plot": name, "feature_key": feature_key, "dat": str(dat), "gp": str(gp), "png": str(png)}


def render(plot_dir: Path, plots: list[dict[str, str]], gnuplot: str | None) -> int:
    if not gnuplot:
        return 0
    n = 0
    for p in plots:
        subprocess.run([gnuplot, Path(p["gp"]).name], cwd=plot_dir, check=True)
        n += 1
    return n


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/statistical-sdf/matched-delta-causality-analysis"))
    parser.add_argument("--render-plots", action="store_true")
    parser.add_argument("--gnuplot", default=shutil.which("gnuplot") or "")
    args = parser.parse_args()
    meta, values, feature_meta, inventory = load_rows(DEFAULT_TABLES)
    pairs = build_pairs(meta, values)
    deltas = delta_rows(pairs, values, feature_meta)
    summaries = summary_rows(deltas)
    failure_summaries = failure_class_summary(deltas)
    seeds = seed_summary(pairs, deltas)
    rules = threshold_rules(deltas, summaries)
    ledger = hypothesis_ledger(summaries, rules, failure_summaries)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "source_inventory.csv", inventory)
    write_csv(args.out_dir / "matched_pairs.csv", pairs)
    write_csv(args.out_dir / "matched_feature_deltas_long.csv", deltas)
    write_csv(args.out_dir / "transition_delta_summary.csv", summaries)
    write_csv(args.out_dir / "failure_class_delta_summary.csv", failure_summaries)
    write_csv(args.out_dir / "seed_delta_summary.csv", seeds)
    write_csv(args.out_dir / "delta_threshold_rules.csv", rules)
    write_csv(args.out_dir / "root_cause_hypothesis_ledger.csv", ledger)
    plot_dir = args.out_dir / "delta-plots"
    plot_dir.mkdir(exist_ok=True)
    plots = []
    for i, row in enumerate(summaries[:16], 1):
        if not row.get("contrast_score"):
            continue
        p = write_plot(plot_dir, deltas, str(row["feature_key"]), f"delta_{i:02d}")
        if p:
            plots.append(p)
    rendered = render(plot_dir, plots, args.gnuplot if args.render_plots else None)
    write_csv(args.out_dir / "delta_plot_manifest.csv", plots)
    transitions = Counter(str(p["hardware_transition"]) for p in pairs)
    readme = [
        "# Matched Delta Causality Analysis",
        "",
        "This analysis matches same-seed baseline bitstreams against intervention variants and compares SDF/skew/JSON physical features in delta space.",
        "",
        "## Samples",
        "",
        "| transition | pairs |",
        "|---|---:|",
    ]
    for t in ["fail_to_pass", "pass_to_fail", "fail_to_fail", "pass_to_pass"]:
        readme.append(f"| {t} | {transitions.get(t, 0)} |")
    readme.extend([
        f"| total | {len(pairs)} |",
        "",
        "## Outputs",
        "",
        "- `matched_pairs.csv`: one row per same-seed baseline/intervention pair.",
        "- `matched_feature_deltas_long.csv`: one row per pair and common feature.",
        "- `transition_delta_summary.csv`: per-feature transition deltas.",
        "- `failure_class_delta_summary.csv`: per-feature deltas grouped by after-failure class.",
        "- `delta_threshold_rules.csv`: one-feature delta thresholds for fail->pass vs pass->fail.",
        "- `root_cause_hypothesis_ledger.csv`: ranked generated hypotheses with recommended interventions.",
        "- `delta-plots/*.png`: transition-separated delta distributions.",
        "",
        f"Hypotheses generated: `{len(ledger)}`.",
        "",
        "## Top Transition Delta Contrasts",
        "",
        "| feature | layer | contrast | fail->pass median | pass->fail median |",
        "|---|---|---:|---:|---:|",
    ])
    for row in summaries[:12]:
        readme.append(f"| `{row['feature']}` | {row['feature_layer']} | {row.get('transition_delta_contrast', '')} | {row.get('fail_to_pass_median_delta', '')} | {row.get('pass_to_fail_median_delta', '')} |")
    readme.extend([
        "",
        f"Plots rendered: `{rendered}`.",
        "",
        "Interpretation: features here are matched-pair hypotheses. They become causal only if a later intervention intentionally moves the delta and held-out hardware outcomes move with it.",
    ])
    (args.out_dir / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
