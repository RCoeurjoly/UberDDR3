#!/usr/bin/env python3
"""Small multivariate SDF/HIL causality analysis for UberDDR3.

This intentionally uses one row per hardware-tested bitstream. It avoids raw
feature-row train/test leakage and keeps models small enough to inspect.
"""

from __future__ import annotations

import argparse
import csv
import math
import shutil
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from scipy.optimize import minimize


FEATURE_TABLES = [
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

META_FIELDS = [
    "experiment_id",
    "hardware_pass",
    "seed",
    "run_group",
    "variant",
    "payload_version",
    "abort_reason",
    "abort_reason_name",
    "abort_lane",
    "calib_complete",
    "bist_done",
    "bitstream_sha256",
    "sdf_sha256",
    "nextpnr_json_sha256",
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
    norm = str(value).strip().lower()
    if norm in {"true", "1", "yes", "pass"}:
        return True
    if norm in {"false", "0", "no", "fail"}:
        return False
    return None


def fnum(value: float | None) -> float | str:
    if value is None or not np.isfinite(value):
        return ""
    return round(float(value), 6)


def safe_name(value: str, limit: int = 130) -> str:
    out = []
    for char in value:
        out.append(char if char.isalnum() or char in "._-" else "_")
    compact = "".join(out).strip("_")
    while "__" in compact:
        compact = compact.replace("__", "_")
    return (compact or "feature")[:limit]


def auc_score(y: np.ndarray, score: np.ndarray) -> float:
    pos = score[y == 1]
    neg = score[y == 0]
    total = len(pos) * len(neg)
    if total == 0:
        return float("nan")
    wins = 0.0
    for p in pos:
        wins += float(np.sum(p > neg))
        wins += 0.5 * float(np.sum(p == neg))
    return wins / total


def accuracy(y: np.ndarray, prob: np.ndarray) -> float:
    return float(np.mean((prob >= 0.5) == y)) if len(y) else float("nan")


def feature_key(layer: str, feature: str) -> str:
    return f"{layer}::{feature}"


def load_long_features() -> tuple[dict[str, dict[str, str]], dict[str, dict[str, float]], dict[str, dict[str, str]], list[dict[str, object]]]:
    meta: dict[str, dict[str, str]] = {}
    values: dict[str, dict[str, float]] = defaultdict(dict)
    feature_meta: dict[str, dict[str, str]] = {}
    inventory: list[dict[str, object]] = []
    seen = set()
    for layer, path in FEATURE_TABLES:
        if not path.exists():
            inventory.append({"feature_layer": layer, "path": str(path), "exists": False, "rows": 0, "experiments": 0})
            continue
        rows = read_csv(path)
        experiments = set()
        for row in rows:
            exp = row.get("experiment_id", "")
            if not exp:
                continue
            experiments.add(exp)
            if exp not in meta:
                meta[exp] = {field: row.get(field, "") for field in META_FIELDS}
            key = feature_key(layer, row.get("feature", ""))
            dedup = (exp, key)
            if dedup in seen:
                continue
            seen.add(dedup)
            try:
                values[exp][key] = float(row.get("value_ps", ""))
            except ValueError:
                continue
            if key not in feature_meta:
                feature_meta[key] = {
                    "feature_key": key,
                    "feature_layer": layer,
                    "feature": row.get("feature", ""),
                    "metric": row.get("metric", ""),
                    "family": row.get("family", ""),
                    "lane": row.get("lane", ""),
                    "bit": row.get("bit", ""),
                    "control_bit": row.get("control_bit", ""),
                    "scope": row.get("scope", ""),
                }
        inventory.append({"feature_layer": layer, "path": str(path), "exists": True, "rows": len(rows), "experiments": len(experiments)})
    return meta, values, feature_meta, inventory


def load_ranked_features(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    return read_csv(path)


def select_features(ranked: list[dict[str, str]], feature_meta: dict[str, dict[str, str]], max_features: int) -> list[str]:
    comparisons = [
        "baseline_seed_1_30",
        "baseline_abort2_vs_pass",
        "baseline_seed_31_60",
        "all_usable",
        "cntvaluein3_locked_only",
        "locked_abort2_vs_pass",
    ]
    selected: list[str] = []

    def add(key: str) -> None:
        if key in feature_meta and key not in selected:
            selected.append(key)

    for comparison in comparisons:
        rows = [r for r in ranked if r.get("comparison") == comparison]
        rows.sort(key=lambda r: float(r.get("support_score") or 0), reverse=True)
        for row in rows[:16]:
            add(feature_key(row.get("feature_layer", ""), row.get("feature", "")))
        signed = [r for r in rows if r.get("feature_layer") == "skew" and r.get("metric", "").startswith("signed_")]
        for row in signed[:10]:
            add(feature_key(row.get("feature_layer", ""), row.get("feature", "")))
        abs_skew = [r for r in rows if r.get("feature_layer") == "skew" and r.get("metric", "").startswith("abs_")]
        for row in abs_skew[:10]:
            add(feature_key(row.get("feature_layer", ""), row.get("feature", "")))

    threshold_path = Path("artifacts/statistical-sdf/global-ddr3-causality-analysis/signed_skew_threshold_report.csv")
    if threshold_path.exists():
        for row in read_csv(threshold_path)[:20]:
            add(feature_key(row.get("feature_layer", ""), row.get("feature", "")))

    return selected[:max_features]


def matrix_rows(meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]], features: list[str]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for exp, m in sorted(meta.items(), key=lambda kv: (kv[1].get("run_group", ""), int(kv[1].get("seed") or 0), kv[1].get("variant", ""), kv[0])):
        passed = parse_bool(m.get("hardware_pass", ""))
        if passed is None:
            continue
        row: dict[str, object] = dict(m)
        row["hardware_pass_int"] = 1 if passed else 0
        present = 0
        for key in features:
            val = values.get(exp, {}).get(key)
            col = safe_name(key, 180)
            if val is None:
                row[col] = ""
            else:
                row[col] = fnum(val)
                present += 1
        row["selected_features_present"] = present
        row["selected_features_total"] = len(features)
        row["selected_features_fraction"] = fnum(present / len(features) if features else 0.0)
        rows.append(row)
    return rows


def feature_inventory(values: dict[str, dict[str, float]], meta: dict[str, dict[str, str]], features: list[str], feature_meta: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    rows = []
    experiments = [exp for exp, m in meta.items() if parse_bool(m.get("hardware_pass", "")) is not None]
    for key in features:
        present = [exp for exp in experiments if key in values.get(exp, {})]
        passed = [values[exp][key] for exp in present if parse_bool(meta[exp].get("hardware_pass", "")) is True]
        failed = [values[exp][key] for exp in present if parse_bool(meta[exp].get("hardware_pass", "")) is False]
        fm = feature_meta.get(key, {})
        rows.append(
            {
                **fm,
                "column": safe_name(key, 180),
                "experiments_present": len(present),
                "present_fraction": fnum(len(present) / len(experiments) if experiments else 0.0),
                "pass_median_ps": fnum(float(np.median(passed)) if passed else None),
                "fail_median_ps": fnum(float(np.median(failed)) if failed else None),
                "fail_minus_pass_median_ps": fnum((float(np.median(failed)) - float(np.median(passed))) if passed and failed else None),
            }
        )
    return rows


def subset_experiments(meta: dict[str, dict[str, str]], name: str) -> list[str]:
    exps = [exp for exp, m in meta.items() if parse_bool(m.get("hardware_pass", "")) is not None]
    if name == "all":
        return exps
    if name == "baseline_1_30":
        return [e for e in exps if meta[e].get("run_group") == "baseline_no_lock_seed_1_30" and meta[e].get("variant") == "baseline-no-lock"]
    if name == "baseline_31_60":
        return [e for e in exps if meta[e].get("run_group") == "seed_31_60_baseline_cntvaluein3_lock_long_poll_500" and meta[e].get("variant") == "baseline-no-lock"]
    if name == "baseline_all":
        return [e for e in exps if meta[e].get("variant") == "baseline-no-lock"]
    if name == "locked_all":
        return [e for e in exps if meta[e].get("variant") == "cntvaluein3-skew-locked"]
    return []


def build_xy(exps: list[str], meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]], features: list[str], medians: dict[str, float] | None = None) -> tuple[np.ndarray, np.ndarray, dict[str, float]]:
    if medians is None:
        medians = {}
        for key in features:
            vals = [values.get(exp, {}).get(key) for exp in exps if values.get(exp, {}).get(key) is not None]
            medians[key] = float(np.median(vals)) if vals else 0.0
    x = np.zeros((len(exps), len(features)), dtype=float)
    y = np.zeros(len(exps), dtype=int)
    for i, exp in enumerate(exps):
        y[i] = 0 if parse_bool(meta[exp].get("hardware_pass", "")) is True else 1
        for j, key in enumerate(features):
            x[i, j] = values.get(exp, {}).get(key, medians[key])
    return x, y, medians


def standardize_train_test(x_train: np.ndarray, x_test: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    mean = x_train.mean(axis=0)
    std = x_train.std(axis=0)
    std[std == 0] = 1.0
    return (x_train - mean) / std, (x_test - mean) / std, mean, std


def fit_logistic(x: np.ndarray, y: np.ndarray, l2: float = 1.0) -> np.ndarray:
    x_aug = np.column_stack([np.ones(len(x)), x])

    def loss_grad(beta: np.ndarray) -> tuple[float, np.ndarray]:
        z = x_aug @ beta
        # stable logistic loss
        loss = float(np.sum(np.logaddexp(0.0, z) - y * z) + 0.5 * l2 * np.sum(beta[1:] ** 2))
        p = 1.0 / (1.0 + np.exp(-np.clip(z, -60, 60)))
        grad = x_aug.T @ (p - y)
        grad[1:] += l2 * beta[1:]
        return loss, grad

    result = minimize(lambda b: loss_grad(b), np.zeros(x_aug.shape[1]), jac=True, method="BFGS", options={"maxiter": 1000})
    return result.x


def predict_logistic(beta: np.ndarray, x: np.ndarray) -> np.ndarray:
    x_aug = np.column_stack([np.ones(len(x)), x])
    z = x_aug @ beta
    return 1.0 / (1.0 + np.exp(-np.clip(z, -60, 60)))


def logistic_reports(meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]], features: list[str], ranked: list[dict[str, str]]) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    feature_rank = {feature_key(r.get("feature_layer", ""), r.get("feature", "")): float(r.get("support_score") or 0) for r in ranked}
    model_features = sorted(features, key=lambda k: feature_rank.get(k, 0.0), reverse=True)[:10]
    specs = [
        ("train_baseline_1_30_test_baseline_31_60", "baseline_1_30", "baseline_31_60"),
        ("train_baseline_31_60_test_baseline_1_30", "baseline_31_60", "baseline_1_30"),
        ("train_baseline_all_test_locked_all", "baseline_all", "locked_all"),
    ]
    reports: list[dict[str, object]] = []
    coeffs: list[dict[str, object]] = []
    permutation_rows: list[dict[str, object]] = []
    rng = np.random.default_rng(0)
    for name, train_name, test_name in specs:
        train = subset_experiments(meta, train_name)
        test = subset_experiments(meta, test_name)
        if len(train) < 8 or len(test) < 4:
            continue
        x_train, y_train, medians = build_xy(train, meta, values, model_features)
        x_test, y_test, _ = build_xy(test, meta, values, model_features, medians)
        # A one-class train or test set cannot produce useful classification metrics.
        if len(set(y_train.tolist())) < 2 or len(set(y_test.tolist())) < 2:
            continue
        xs_train, xs_test, means, stds = standardize_train_test(x_train, x_test)
        beta = fit_logistic(xs_train, y_train, l2=1.0)
        p_train = predict_logistic(beta, xs_train)
        p_test = predict_logistic(beta, xs_test)
        reports.append(
            {
                "model": name,
                "features": len(model_features),
                "train_samples": len(train),
                "train_fail": int(y_train.sum()),
                "test_samples": len(test),
                "test_fail": int(y_test.sum()),
                "train_auc": fnum(auc_score(y_train, p_train)),
                "test_auc": fnum(auc_score(y_test, p_test)),
                "train_accuracy": fnum(accuracy(y_train, p_train)),
                "test_accuracy": fnum(accuracy(y_test, p_test)),
                "intercept": fnum(beta[0]),
            }
        )
        base_auc = auc_score(y_test, p_test)
        base_acc = accuracy(y_test, p_test)
        for feat_idx, key in enumerate(model_features):
            aucs = []
            accs = []
            for _ in range(64):
                shuffled = xs_test.copy()
                shuffled[:, feat_idx] = rng.permutation(shuffled[:, feat_idx])
                p_perm = predict_logistic(beta, shuffled)
                aucs.append(auc_score(y_test, p_perm))
                accs.append(accuracy(y_test, p_perm))
            permutation_rows.append(
                {
                    "model": name,
                    "feature_key": key,
                    "column": safe_name(key, 180),
                    "test_auc_drop_mean": fnum(base_auc - float(np.mean(aucs))),
                    "test_auc_drop_max": fnum(base_auc - float(np.min(aucs))),
                    "test_accuracy_drop_mean": fnum(base_acc - float(np.mean(accs))),
                    "test_accuracy_drop_max": fnum(base_acc - float(np.min(accs))),
                }
            )
        for key, coef, mean, std in sorted(zip(model_features, beta[1:], means, stds), key=lambda x: abs(x[1]), reverse=True):
            coeffs.append(
                {
                    "model": name,
                    "feature_key": key,
                    "column": safe_name(key, 180),
                    "coefficient_standardized": fnum(coef),
                    "train_mean_ps": fnum(mean),
                    "train_std_ps": fnum(std),
                }
            )
    return reports, coeffs, sorted(permutation_rows, key=lambda r: float(r.get("test_auc_drop_mean") or 0), reverse=True)


def candidate_thresholds(vals: list[float], max_thresholds: int = 24) -> list[float]:
    vals = sorted(set(vals))
    if len(vals) <= 2:
        return vals
    mids = [(a + b) / 2.0 for a, b in zip(vals, vals[1:])]
    if len(mids) <= max_thresholds:
        return mids
    qs = np.linspace(0.05, 0.95, max_thresholds)
    return sorted(set(float(np.quantile(mids, q)) for q in qs))


def rule_predict(x: np.ndarray, i: int, ti: float, di: str, j: int, tj: float, dj: str, op: str) -> np.ndarray:
    left = x[:, i] >= ti if di == "ge" else x[:, i] <= ti
    right = x[:, j] >= tj if dj == "ge" else x[:, j] <= tj
    return (left & right) if op == "and" else (left | right)


def pairwise_rules(meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]], features: list[str], ranked: list[dict[str, str]], feature_meta: dict[str, dict[str, str]]) -> list[dict[str, object]]:
    exps = subset_experiments(meta, "all")
    feature_rank = {feature_key(r.get("feature_layer", ""), r.get("feature", "")): float(r.get("support_score") or 0) for r in ranked}
    rule_features = sorted(features, key=lambda k: feature_rank.get(k, 0.0), reverse=True)[:28]
    x, y, _ = build_xy(exps, meta, values, rule_features)
    rows: list[dict[str, object]] = []
    dirs = ["ge", "le"]
    ops = ["and", "or"]
    for i in range(len(rule_features)):
        xi_thresholds = candidate_thresholds(x[:, i].tolist())
        for j in range(i + 1, len(rule_features)):
            xj_thresholds = candidate_thresholds(x[:, j].tolist())
            best = None
            for ti in xi_thresholds:
                for tj in xj_thresholds:
                    for di in dirs:
                        for dj in dirs:
                            for op in ops:
                                pred = rule_predict(x, i, ti, di, j, tj, dj, op).astype(int)
                                tp = int(np.sum((pred == 1) & (y == 1)))
                                tn = int(np.sum((pred == 0) & (y == 0)))
                                fp = int(np.sum((pred == 1) & (y == 0)))
                                fn = int(np.sum((pred == 0) & (y == 1)))
                                tpr = tp / max(1, tp + fn)
                                tnr = tn / max(1, tn + fp)
                                bal = 0.5 * (tpr + tnr)
                                errors = fp + fn
                                support = tp + fp
                                # Avoid rules that classify almost everything one way.
                                if support < 3 or support > len(y) - 3:
                                    continue
                                cand = (bal, -errors, tp, -fp, -fn, ti, tj, di, dj, op, tp, tn, fp, fn)
                                if best is None or cand > best:
                                    best = cand
            if best is None:
                continue
            bal, neg_errors, _tp_rank, _nfp_rank, _nfn_rank, ti, tj, di, dj, op, tp, tn, fp, fn = best
            key_i = rule_features[i]
            key_j = rule_features[j]
            rows.append(
                {
                    "feature_x_key": key_i,
                    "feature_y_key": key_j,
                    "feature_x": feature_meta.get(key_i, {}).get("feature", key_i),
                    "feature_y": feature_meta.get(key_j, {}).get("feature", key_j),
                    "x_direction": di,
                    "x_threshold_ps": fnum(ti),
                    "operator": op,
                    "y_direction": dj,
                    "y_threshold_ps": fnum(tj),
                    "balanced_accuracy": fnum(bal),
                    "accuracy": fnum((tp + tn) / len(y)),
                    "tp_fail_pred_fail": tp,
                    "tn_pass_pred_pass": tn,
                    "false_fail_pass_points": fp,
                    "false_pass_fail_points": fn,
                    "errors": fp + fn,
                    "samples": len(y),
                    "fails": int(y.sum()),
                    "passes": int(len(y) - y.sum()),
                }
            )
    return sorted(rows, key=lambda r: (float(r["balanced_accuracy"]), -int(r["errors"])), reverse=True)


def eval_pair_rule(rule: dict[str, object], exps: list[str], meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]]) -> dict[str, object]:
    key_x = str(rule["feature_x_key"])
    key_y = str(rule["feature_y_key"])
    pred = []
    truth = []
    for exp in exps:
        vx = values.get(exp, {}).get(key_x)
        vy = values.get(exp, {}).get(key_y)
        passed = parse_bool(meta[exp].get("hardware_pass", ""))
        if vx is None or vy is None or passed is None:
            continue
        x_ok = vx >= float(rule["x_threshold_ps"]) if rule["x_direction"] == "ge" else vx <= float(rule["x_threshold_ps"])
        y_ok = vy >= float(rule["y_threshold_ps"]) if rule["y_direction"] == "ge" else vy <= float(rule["y_threshold_ps"])
        fail_pred = (x_ok and y_ok) if rule["operator"] == "and" else (x_ok or y_ok)
        pred.append(1 if fail_pred else 0)
        truth.append(0 if passed else 1)
    if not truth:
        return {"samples": 0}
    pred_a = np.array(pred, dtype=int)
    y = np.array(truth, dtype=int)
    tp = int(np.sum((pred_a == 1) & (y == 1)))
    tn = int(np.sum((pred_a == 0) & (y == 0)))
    fp = int(np.sum((pred_a == 1) & (y == 0)))
    fn = int(np.sum((pred_a == 0) & (y == 1)))
    tpr = tp / max(1, tp + fn)
    tnr = tn / max(1, tn + fp)
    return {
        "samples": len(y),
        "fails": int(y.sum()),
        "passes": int(len(y) - y.sum()),
        "balanced_accuracy": fnum(0.5 * (tpr + tnr)),
        "accuracy": fnum((tp + tn) / len(y)),
        "tp_fail_pred_fail": tp,
        "tn_pass_pred_pass": tn,
        "false_fail_pass_points": fp,
        "false_pass_fail_points": fn,
        "errors": fp + fn,
    }


def pairwise_validation_rows(rules: list[dict[str, object]], meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]], limit: int = 50) -> list[dict[str, object]]:
    subsets = ["all", "baseline_1_30", "baseline_31_60", "baseline_all", "locked_all"]
    rows: list[dict[str, object]] = []
    for rank, rule in enumerate(rules[:limit], 1):
        for subset in subsets:
            stats = eval_pair_rule(rule, subset_experiments(meta, subset), meta, values)
            rows.append({"rule_rank": rank, "subset": subset, **rule, **{f"eval_{k}": v for k, v in stats.items()}})
    return rows


def write_pair_plot(plot_dir: Path, index: int, rule: dict[str, object], meta: dict[str, dict[str, str]], values: dict[str, dict[str, float]]) -> dict[str, object] | None:
    key_x = str(rule["feature_x_key"])
    key_y = str(rule["feature_y_key"])
    points = []
    for exp in subset_experiments(meta, "all"):
        vx = values.get(exp, {}).get(key_x)
        vy = values.get(exp, {}).get(key_y)
        passed = parse_bool(meta[exp].get("hardware_pass", ""))
        if vx is None or vy is None or passed is None:
            continue
        points.append(
            {
                "x_ps": fnum(vx),
                "y_ps": fnum(vy),
                "pass_x_ps": fnum(vx) if passed else "",
                "pass_y_ps": fnum(vy) if passed else "",
                "fail_x_ps": fnum(vx) if not passed else "",
                "fail_y_ps": fnum(vy) if not passed else "",
                "seed": meta[exp].get("seed", ""),
                "run_group": meta[exp].get("run_group", ""),
                "variant": meta[exp].get("variant", ""),
                "abort_reason": meta[exp].get("abort_reason", ""),
                "experiment_id": exp,
            }
        )
    if not points:
        return None
    name = safe_name(f"pair_{index:02d}_{key_x}_VS_{key_y}", 160)
    dat = plot_dir / f"{name}.dat"
    gp = plot_dir / f"{name}.gp"
    png = plot_dir / f"{name}.png"
    write_csv(dat, points, ["x_ps", "y_ps", "pass_x_ps", "pass_y_ps", "fail_x_ps", "fail_y_ps", "seed", "run_group", "variant", "abort_reason", "experiment_id"])
    title = f"rule {index}: bal_acc={rule['balanced_accuracy']} errors={rule['errors']}".replace("'", "_")
    xlabel = str(rule["feature_x"])[:110].replace("'", "_")
    ylabel = str(rule["feature_y"])[:110].replace("'", "_")
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid",
                f"set title '{title}'",
                f"set xlabel '{xlabel} (ps)'",
                f"set ylabel '{ylabel} (ps)'",
                f"set arrow 1 from {rule['x_threshold_ps']}, graph 0 to {rule['x_threshold_ps']}, graph 1 nohead lw 2 lc rgb '#666666' dt 2",
                f"set arrow 2 from graph 0, {rule['y_threshold_ps']} to graph 1, {rule['y_threshold_ps']} nohead lw 2 lc rgb '#666666' dt 2",
                "plot \\",
                f"  '{dat.name}' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {"plot": name, "dat": str(dat), "gp": str(gp), "png": str(png), **rule}


def render_plots(plot_dir: Path, plots: list[dict[str, object]], gnuplot: str | None) -> int:
    if not gnuplot:
        return 0
    rendered = 0
    for plot in plots:
        subprocess.run([gnuplot, Path(str(plot["gp"])).name], cwd=plot_dir, check=True)
        rendered += 1
    return rendered


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/statistical-sdf/multivariate-ddr3-causality-analysis"))
    parser.add_argument("--max-features", type=int, default=72)
    parser.add_argument("--top-pair-plots", type=int, default=12)
    parser.add_argument("--render-plots", action="store_true")
    parser.add_argument("--gnuplot", default=shutil.which("gnuplot") or "")
    args = parser.parse_args()

    ranked = load_ranked_features(Path("artifacts/statistical-sdf/global-ddr3-causality-analysis/ranked_features.csv"))
    meta, values, feature_meta, source_inventory = load_long_features()
    features = select_features(ranked, feature_meta, args.max_features)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "source_inventory.csv", source_inventory)
    write_csv(args.out_dir / "selected_features.csv", feature_inventory(values, meta, features, feature_meta))

    matrix = matrix_rows(meta, values, features)
    matrix_fields = META_FIELDS + ["hardware_pass_int", "selected_features_present", "selected_features_total", "selected_features_fraction"] + [safe_name(k, 180) for k in features]
    write_csv(args.out_dir / "bitstream_feature_matrix.csv", matrix, matrix_fields)

    logit_rows, coeff_rows, permutation_rows = logistic_reports(meta, values, features, ranked)
    write_csv(args.out_dir / "logistic_report.csv", logit_rows)
    write_csv(args.out_dir / "logistic_coefficients.csv", coeff_rows)
    write_csv(args.out_dir / "logistic_permutation_importance.csv", permutation_rows)

    rules = pairwise_rules(meta, values, features, ranked, feature_meta)
    write_csv(args.out_dir / "pairwise_threshold_rules.csv", rules[:200])
    pair_validation = pairwise_validation_rows(rules, meta, values, 50)
    write_csv(args.out_dir / "pairwise_rule_validation.csv", pair_validation)

    plot_dir = args.out_dir / "pairwise-scatter-plots"
    plot_dir.mkdir(parents=True, exist_ok=True)
    plots: list[dict[str, object]] = []
    for idx, rule in enumerate(rules[: args.top_pair_plots], 1):
        plot = write_pair_plot(plot_dir, idx, rule, meta, values)
        if plot:
            plots.append(plot)
    rendered = render_plots(plot_dir, plots, args.gnuplot if args.render_plots else None)
    write_csv(args.out_dir / "pairwise_scatter_plot_manifest.csv", plots)

    exp_counts = Counter((m.get("variant", ""), str(parse_bool(m.get("hardware_pass", "")))) for m in meta.values())
    readme = [
        "# Multivariate DDR3 SDF/HIL Causality Analysis",
        "",
        "This no-rebuild analysis collapses SDF-derived feature tables to one row per hardware-tested bitstream, then runs small multivariate models. It is hypothesis generation, not proof of causality.",
        "",
        "## Inventory",
        "",
        f"- bitstream rows: `{len(matrix)}`",
        f"- selected semantic SDF features: `{len(features)}`",
        f"- logistic model rows: `{len(logit_rows)}`",
        f"- logistic coefficient rows: `{len(coeff_rows)}`",
        f"- logistic permutation importance rows: `{len(permutation_rows)}`",
        f"- pairwise threshold rules evaluated: `{len(rules)}`",
        f"- pairwise validation rows: `{len(pair_validation)}`",
        f"- pairwise scatter plots generated: `{len(plots)}`",
        f"- pairwise scatter PNGs rendered: `{rendered}`",
        "",
        "## Outcome Counts",
        "",
        "| variant | hardware_pass | experiments |",
        "|---|---:|---:|",
    ]
    for (variant, passed), count in sorted(exp_counts.items()):
        if passed == "None":
            continue
        readme.append(f"| {variant} | {passed} | {count} |")
    readme.extend(["", "## Logistic Models", "", "| model | train fail/samples | test fail/samples | train AUC | test AUC | test acc |", "|---|---:|---:|---:|---:|---:|"])
    for row in logit_rows:
        readme.append(
            f"| {row['model']} | {row['train_fail']}/{row['train_samples']} | {row['test_fail']}/{row['test_samples']} | {row['train_auc']} | {row['test_auc']} | {row['test_accuracy']} |"
        )
    readme.extend(["", "## Top Pairwise Threshold Rules", "", "| rank | balanced acc | errors | rule | feature x | feature y |", "|---:|---:|---:|---|---|---|"])
    for idx, row in enumerate(rules[:10], 1):
        rule = f"x {row['x_direction']} {row['x_threshold_ps']} {row['operator']} y {row['y_direction']} {row['y_threshold_ps']} => fail"
        readme.append(f"| {idx} | {row['balanced_accuracy']} | {row['errors']} | `{rule}` | `{row['feature_x']}` | `{row['feature_y']}` |")
    readme.extend(
        [
            "",
            "## Files",
            "",
            "- `bitstream_feature_matrix.csv`: one row per hardware-tested bitstream with selected SDF features as columns.",
            "- `selected_features.csv`: semantic features selected for multivariate analysis and their coverage.",
            "- `logistic_report.csv`: regularized logistic model train/test metrics.",
            "- `logistic_coefficients.csv`: standardized logistic coefficients for inspecting feature direction.",
            "- `logistic_permutation_importance.csv`: test-set permutation importance for the logistic models.",
            "- `pairwise_threshold_rules.csv`: exhaustive two-feature threshold rules ranked by balanced accuracy.",
            "- `pairwise_rule_validation.csv`: top rule performance split by all, baseline seed groups, baseline-all, and locked-all subsets.",
            "- `pairwise-scatter-plots/*.png`: 2D pass/fail scatter plots for top threshold-rule pairs.",
            "",
            "Interpretation rule: a multivariate pattern is useful only if it generalizes across held-out seed groups and then survives intervention. High in-sample pairwise accuracy alone is not causal evidence.",
        ]
    )
    (args.out_dir / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
