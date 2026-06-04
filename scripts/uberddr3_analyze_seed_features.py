#!/usr/bin/env python3
"""Family-specific UberDDR3 seed sensitivity analysis.

Inputs are board-test result JSON files from one or more sweep directories.  The
script reconstructs seed outcomes from JSON, attaches nextpnr log/placed-JSON
features, ranks features separately per failure family, validates feature
direction across 1..60 vs 61..120, and renders PNG plots for top features.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import random
import re
import statistics as st
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Callable

try:
    from scipy.stats import mannwhitneyu
except Exception:  # pragma: no cover - optional dependency fallback
    mannwhitneyu = None

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except Exception:  # pragma: no cover - optional dependency fallback
    plt = None

BEL_RE = re.compile(r"(?P<site>[A-Z0-9_]+_X(?P<x>-?\d+)Y(?P<y>-?\d+))")
RESULT_RE = re.compile(r"seed-(\d+)-repeat-(\d+)\.json$")
STORE_JSON_RE = re.compile(r"/nix/store/[^\s']+-ypcb-ddr3-nextpnr-json[^\s']*(?:/ypcb_00338_1p1_ddr3\.placed\.json)?")
MAX_FREQ_RE = re.compile(r"Max frequency for clock\s+'?([^':]+)'?:\s+([0-9.]+) MHz \((PASS|FAIL) at ([0-9.]+) MHz\)")
MAX_DELAY_RE = re.compile(r"Max delay\s+(.+?):\s+([0-9.]+) ns")

FOCUS = {
    "init": ["instruction", "delay_counter", "reset_done", "init_advance", "init_timer", "cmd_reset_n", "cmd_ck_en", "cmd_odt", "sync_rst_controller"],
    "dqs": ["dqs", "bitslip", "analyze_dqs", "dqs_start_index", "dqs_target_index"],
    "idelay_data": ["idelay_data_cntvaluein", "o_phy_idelay_data_cntvaluein"],
    "idelay_dqs": ["idelay_dqs_cntvaluein", "o_phy_idelay_dqs_cntvaluein"],
    "read_align": ["data_start_index", "late_dq", "added_read_pipe", "delay_read_pipe", "index_wb_data", "read_lane_data", "read_data_store", "o_wb_data_q", "iserdes_data"],
    "bist": ["bist", "correct_read_data", "wrong_read_data", "write_pattern", "byte_mismatch"],
}

SPECIFIC = [
    "init_advance_now", "init_advance_pending", "delay_counter_is_zero", "delay_counter_is_zero_d",
    "instruction_address", "reset_done", "data_start_index", "late_dq", "added_read_pipe",
    "delay_read_pipe", "idelay_data_cntvaluein", "idelay_dqs_cntvaluein", "write_pattern_matches",
]

META_COLUMNS = {
    "seed", "outcome", "family", "exact_family", "repeat_count", "pass_repeats", "fail_repeats",
    "mixed_families", "families_seen", "nextpnr_json", "nextpnr_log", "nextpnr_error",
}


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def num(value: Any) -> float | None:
    try:
        if value in (None, ""):
            return None
        return float(value)
    except Exception:
        return None


def med(values: list[float]) -> float | str:
    return round(st.median(values), 6) if values else ""


def quantile(values: list[float], q: float) -> float | str:
    if not values:
        return ""
    vals = sorted(values)
    idx = min(len(vals) - 1, max(0, int(round((len(vals) - 1) * q))))
    return round(vals[idx], 6)


def common_language(pos: list[float], neg: list[float]) -> float:
    wins = ties = total = 0
    for a in pos:
        for b in neg:
            total += 1
            if a > b:
                wins += 1
            elif a == b:
                ties += 1
    return (wins + 0.5 * ties) / total if total else math.nan


def cliffs_delta(pos: list[float], neg: list[float]) -> float:
    effect = common_language(pos, neg)
    return 2.0 * effect - 1.0 if not math.isnan(effect) else math.nan


def permutation_pvalue(pos: list[float], neg: list[float], observed_auc: float, rounds: int = 1000) -> float | str:
    if len(pos) < 3 or len(neg) < 3:
        return ""
    combined = pos + neg
    n_pos = len(pos)
    observed = abs(observed_auc - 0.5)
    seed = int(hashlib.sha256((str(pos[:8]) + str(neg[:8])).encode()).hexdigest()[:8], 16)
    rng = random.Random(seed)
    count = 0
    for _ in range(rounds):
        sample = combined[:]
        rng.shuffle(sample)
        auc = common_language(sample[:n_pos], sample[n_pos:])
        if abs(auc - 0.5) >= observed:
            count += 1
    return round((count + 1) / (rounds + 1), 6)


def bh_fdr(rows: list[dict[str, Any]], p_key: str, out_key: str) -> None:
    valid = [(i, num(row.get(p_key))) for i, row in enumerate(rows)]
    valid = [(i, p) for i, p in valid if p is not None]
    m = len(valid)
    if not m:
        return
    ranked = sorted(valid, key=lambda x: x[1])
    adjusted = [1.0] * m
    running = 1.0
    for rank_from_end, (idx, p) in enumerate(reversed(ranked), start=1):
        rank = m - rank_from_end + 1
        running = min(running, p * m / rank)
        adjusted[rank - 1] = running
    for (idx, _), q in zip(ranked, adjusted):
        rows[idx][out_key] = round(min(q, 1.0), 6)


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("_")[:140]


def parse_sites(text: str) -> list[tuple[int, int]]:
    return [(int(m.group("x")), int(m.group("y"))) for m in BEL_RE.finditer(text or "")]


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    for module in modules.values():
        if module.get("attributes", {}).get("top") == "00000000000000000000000000000001":
            return module
    return next(iter(modules.values()))


def matching_groups(name: str) -> list[str]:
    low = name.lower()
    return [group for group, needles in FOCUS.items() if any(needle in low for needle in needles)]


def specific_groups(name: str) -> list[str]:
    low = name.lower()
    return [f"sig_{needle}" for needle in SPECIFIC if needle in low]


def add_group_features(prefix: str, groups: dict[str, list[dict[str, Any]]], row: dict[str, Any]) -> None:
    for group, items in groups.items():
        xs = [float(item["x"]) for item in items if item.get("x") is not None]
        ys = [float(item["y"]) for item in items if item.get("y") is not None]
        fanout = [float(item["fanout"]) for item in items if item.get("fanout") is not None]
        segments = [float(item["segments"]) for item in items if item.get("segments") is not None]
        route_chars = [float(item["route_chars"]) for item in items if item.get("route_chars") is not None]
        row[f"{prefix}_{group}_count"] = len(items)
        row[f"{prefix}_{group}_x_med"] = med(xs)
        row[f"{prefix}_{group}_y_med"] = med(ys)
        row[f"{prefix}_{group}_x_iqr"] = round(float(quantile(xs, 0.75)) - float(quantile(xs, 0.25)), 6) if xs else ""
        row[f"{prefix}_{group}_y_iqr"] = round(float(quantile(ys, 0.75)) - float(quantile(ys, 0.25)), 6) if ys else ""
        row[f"{prefix}_{group}_x_span"] = round(max(xs) - min(xs), 6) if xs else ""
        row[f"{prefix}_{group}_y_span"] = round(max(ys) - min(ys), 6) if ys else ""
        if fanout:
            row[f"{prefix}_{group}_fanout_med"] = med(fanout)
            row[f"{prefix}_{group}_fanout_max"] = max(fanout)
        if segments:
            row[f"{prefix}_{group}_segments_med"] = med(segments)
            row[f"{prefix}_{group}_segments_max"] = max(segments)
        if route_chars:
            row[f"{prefix}_{group}_route_chars_med"] = med(route_chars)
            row[f"{prefix}_{group}_route_chars_max"] = max(route_chars)


def load_artifact_map(paths: list[Path]) -> dict[int, tuple[Path, Path | None]]:
    out: dict[int, tuple[Path, Path | None]] = {}
    for path in paths:
        for row in read_csv(path):
            if row.get("variant") and row.get("variant") != "current":
                continue
            seed = row.get("seed", "")
            json_path = row.get("nextpnr_json", "")
            if not seed.isdigit() or not json_path:
                continue
            jp = Path(json_path)
            if jp.exists():
                log = jp.parent / "metadata" / "nextpnr.log"
                out[int(seed)] = (jp, log if log.exists() else None)
    return out


def artifact_from_build_logs(seed: int, sweep_dirs: list[Path]) -> tuple[Path | None, Path | None]:
    for sweep in sweep_dirs:
        log_path = sweep / f"build-seed-{seed}.log"
        if not log_path.exists():
            continue
        text = log_path.read_text(encoding="utf-8", errors="replace")
        matches = STORE_JSON_RE.findall(text)
        for match in reversed(matches):
            base = Path(match)
            jp = base if base.name.endswith(".json") else base / "ypcb_00338_1p1_ddr3.placed.json"
            if jp.exists():
                lp = jp.parent / "metadata" / "nextpnr.log"
                return jp, lp if lp.exists() else None
    return None, None



def artifact_from_store_references(seed: int, sweep_dirs: list[Path]) -> tuple[Path | None, Path | None]:
    for sweep in sweep_dirs:
        link = sweep / f"build-seed-{seed}"
        if not link.exists():
            continue
        cp = subprocess.run(["nix-store", "-q", "--references", str(link)], check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if cp.returncode != 0:
            continue
        for line in cp.stdout.splitlines():
            if f"ypcb-ddr3-nextpnr-json-panopticon-seed-{seed}" not in line:
                continue
            base = Path(line.strip())
            jp = base / "ypcb_00338_1p1_ddr3.placed.json"
            lp = base / "metadata" / "nextpnr.log"
            if jp.exists():
                return jp, lp if lp.exists() else None
    return None, None

def artifact_from_current_flake(seed: int) -> tuple[Path | None, Path | None]:
    attr = f".#ypcb-ddr3-nextpnr-json-panopticon-seed-{seed}"
    cp = subprocess.run(["nix", "path-info", attr], check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if cp.returncode != 0:
        return None, None
    base = Path(cp.stdout.strip().splitlines()[-1])
    jp = base / "ypcb_00338_1p1_ddr3.placed.json"
    lp = base / "metadata" / "nextpnr.log"
    return (jp if jp.exists() else None), (lp if lp.exists() else None)


def log_features(path: Path | None) -> dict[str, Any]:
    row: dict[str, Any] = {"log_available": 0}
    if not path or not path.exists():
        return row
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    row.update({
        "log_available": 1,
        "log_warning_count": sum(1 for line in lines if "Warning:" in line or "warning:" in line),
        "log_error_count": sum(1 for line in lines if "Error:" in line or "error:" in line),
        "log_ddr_mentions": sum(1 for line in lines if "ddr" in line.lower()),
        "log_dqs_mentions": sum(1 for line in lines if "dqs" in line.lower()),
        "log_idelay_mentions": sum(1 for line in lines if "idelay" in line.lower()),
    })
    freqs = []
    for line in lines:
        m = MAX_FREQ_RE.search(line)
        if m:
            freqs.append((m.group(1), float(m.group(2)), m.group(3), float(m.group(4))))
    if freqs:
        clock, mhz, status, target = freqs[-1]
        row.update({"fmax_clock": clock, "fmax_mhz": mhz, "fmax_target_mhz": target, "fmax_margin_mhz": round(mhz - target, 6), "fmax_status_pass": int(status == "PASS")})
    delays = []
    for line in lines:
        m = MAX_DELAY_RE.search(line)
        if m:
            delays.append((m.group(1), float(m.group(2))))
    if delays:
        row["max_delay_name"] = delays[-1][0]
        row["max_delay_ns"] = delays[-1][1]
    return row


def json_features(path: Path | None) -> dict[str, Any]:
    row: dict[str, Any] = {"json_available": 0}
    if not path or not path.exists():
        return row
    data = json.loads(path.read_text(encoding="utf-8"))
    module = top_module(data)
    row.update({"json_available": 1, "json_cell_count_total": len(module.get("cells", {})), "json_net_count_total": len(module.get("netnames", {}))})
    cell_groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for name, cell in module.get("cells", {}).items():
        attrs = cell.get("attributes", {}) if isinstance(cell, dict) else {}
        sites = parse_sites(str(attrs.get("NEXTPNR_BEL", "")))
        if not sites:
            continue
        x, y = sites[0]
        item = {"x": x, "y": y}
        for group in matching_groups(name) + specific_groups(name):
            cell_groups[group].append(item)
    add_group_features("cell", cell_groups, row)
    net_groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for name, net in module.get("netnames", {}).items():
        attrs = net.get("attributes", {}) if isinstance(net, dict) else {}
        routing = str(attrs.get("ROUTING", ""))
        sites = parse_sites(routing)
        xs = [x for x, _ in sites]
        ys = [y for _, y in sites]
        item = {
            "x": st.median(xs) if xs else None,
            "y": st.median(ys) if ys else None,
            "fanout": len(net.get("bits", [])) if isinstance(net, dict) else None,
            "segments": routing.count(";") + 1 if routing else 0,
            "route_chars": len(routing),
        }
        for group in matching_groups(name) + specific_groups(name):
            net_groups[group].append(item)
    add_group_features("net", net_groups, row)
    return row


def classify_result(data: dict[str, Any]) -> tuple[str, str, str]:
    if data.get("pass"):
        return "pass", "pass", "pass"
    reasons = data.get("fail_reasons", []) if isinstance(data.get("fail_reasons"), list) else []
    fields = data.get("fields", {}) if isinstance(data.get("fields"), dict) else {}
    calib = fields.get("calib_debug", {}) if isinstance(fields.get("calib_debug"), dict) else {}
    init = fields.get("init_reset_debug", {}) if isinstance(fields.get("init_reset_debug"), dict) else {}
    bist = fields.get("bist_debug", {}) if isinstance(fields.get("bist_debug"), dict) else {}
    state = fields.get("state_calibrate")
    instr = calib.get("instruction_address")
    if "programming_failed" in reasons:
        return "fail", "harness", "programming"
    if "wrong_read_data_nonzero" in reasons:
        return "fail", "bist", f"bist_mismatch.byte_mask_{bist.get('byte_mismatch_mask','')}.byte_{bist.get('fail_byte_index','')}.slot_{bist.get('fail_burst_slot','')}"
    if isinstance(state, int):
        if state == 0 and isinstance(instr, int) and instr < 13:
            return "fail", "init", f"init_before_calibration.addr_1_2.reset_done_{init.get('controller_reset_done','')}"
        if 1 <= state <= 6:
            return "fail", "dqs", f"dqs_read_leveling.instr_{instr}"
        if 17 <= state <= 23:
            return "fail", "late_bist", "late_calibration_or_bist"
    return "fail", "unknown", f"unknown.state_{state}.instr_{instr}"


def load_seed_results(sweep_dirs: list[Path]) -> dict[int, list[dict[str, Any]]]:
    by_seed: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for sweep in sweep_dirs:
        for path in sorted(sweep.glob("*seed-*-repeat-*.json")):
            m = RESULT_RE.search(path.name)
            if not m:
                continue
            seed, repeat = int(m.group(1)), int(m.group(2))
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except Exception:
                continue
            status, family, exact = classify_result(data)
            by_seed[seed].append({"seed": seed, "repeat": repeat, "status": status, "family": family, "exact_family": exact, "result_json": str(path), "attempts": data.get("attempts", ""), "poll_stop_reason": data.get("poll_stop_reason", "")})
    return by_seed


def seed_outcome(seed: int, rows: list[dict[str, Any]]) -> dict[str, Any]:
    rows = sorted(rows, key=lambda r: int(r["repeat"]))
    status_counts = Counter(r["status"] for r in rows)
    families = Counter(r["family"] for r in rows if r["status"] != "pass" and r["family"] not in {"harness", "unknown", "late_bist"})
    exact = Counter(r["exact_family"] for r in rows if r["status"] != "pass" and r["family"] not in {"harness", "unknown", "late_bist"})
    if status_counts.get("pass"):
        outcome, family, exact_family = "pass", "pass", "pass"
    elif families:
        outcome, family, exact_family = "fail", families.most_common(1)[0][0], exact.most_common(1)[0][0]
    else:
        outcome, family, exact_family = "exclude", "exclude", "exclude"
    return {"seed": seed, "outcome": outcome, "family": family, "exact_family": exact_family, "repeat_count": len(rows), "pass_repeats": status_counts.get("pass", 0), "fail_repeats": len(rows) - status_counts.get("pass", 0), "mixed_families": len(families) > 1, "families_seen": ";".join(k for k, _ in families.most_common())}


def numeric_features(rows: list[dict[str, Any]]) -> list[str]:
    return sorted(k for k in {key for row in rows for key in row} if k not in META_COLUMNS and any(num(row.get(k)) is not None for row in rows))


def compare_feature(rows: list[dict[str, Any]], feature: str, pos_pred: Callable[[dict[str, Any]], bool], neg_pred: Callable[[dict[str, Any]], bool]) -> dict[str, Any] | None:
    pos = [num(r.get(feature)) for r in rows if pos_pred(r)]
    neg = [num(r.get(feature)) for r in rows if neg_pred(r)]
    pos = [v for v in pos if v is not None]
    neg = [v for v in neg if v is not None]
    if len(pos) < 3 or len(neg) < 3:
        return None
    auc = common_language(pos, neg)
    p_mwu = ""
    if mannwhitneyu is not None:
        try:
            p_mwu = round(float(mannwhitneyu(pos, neg, alternative="two-sided").pvalue), 8)
        except Exception:
            p_mwu = ""
    return {
        "feature": feature,
        "pos_n": len(pos), "neg_n": len(neg),
        "pos_min": min(pos), "pos_q1": quantile(pos, 0.25), "pos_median": med(pos), "pos_q3": quantile(pos, 0.75), "pos_max": max(pos),
        "neg_min": min(neg), "neg_q1": quantile(neg, 0.25), "neg_median": med(neg), "neg_q3": quantile(neg, 0.75), "neg_max": max(neg),
        "median_delta": round(float(med(pos)) - float(med(neg)), 6),
        "common_language_effect_pos_gt_neg": round(auc, 6),
        "cliffs_delta_pos_gt_neg": round(cliffs_delta(pos, neg), 6),
        "abs_effect_from_0_5": round(abs(auc - 0.5), 6),
        "mannwhitney_p": p_mwu,
        "permutation_p": permutation_pvalue(pos, neg, auc),
    }


def rank_features(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    comparisons: list[tuple[str, Callable[[dict[str, Any]], bool], Callable[[dict[str, Any]], bool]]] = [
        ("fail_vs_pass", lambda r: r["outcome"] == "fail", lambda r: r["family"] == "pass"),
    ]
    for fam in ["init", "dqs", "bist"]:
        comparisons.append((f"{fam}_vs_pass", lambda r, fam=fam: r["family"] == fam, lambda r: r["family"] == "pass"))
        comparisons.append((f"{fam}_vs_other", lambda r, fam=fam: r["family"] == fam, lambda r, fam=fam: r["family"] not in {fam, "exclude"}))
    out = []
    feats = numeric_features(rows)
    for comp, pos_pred, neg_pred in comparisons:
        comp_rows = []
        for feat in feats:
            result = compare_feature(rows, feat, pos_pred, neg_pred)
            if result:
                result["comparison"] = comp
                comp_rows.append(result)
        bh_fdr(comp_rows, "mannwhitney_p", "mannwhitney_fdr")
        bh_fdr(comp_rows, "permutation_p", "permutation_fdr")
        out.extend(sorted(comp_rows, key=lambda r: r["abs_effect_from_0_5"], reverse=True))
    return out


def split_validation(rows: list[dict[str, Any]], rankings: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out = []
    by_comp = defaultdict(list)
    for row in rankings:
        by_comp[row["comparison"]].append(row)
    pred: dict[str, tuple[Callable[[dict[str, Any]], bool], Callable[[dict[str, Any]], bool]]] = {
        "fail_vs_pass": (lambda r: r["outcome"] == "fail", lambda r: r["family"] == "pass"),
    }
    for fam in ["init", "dqs", "bist"]:
        pred[f"{fam}_vs_pass"] = (lambda r, fam=fam: r["family"] == fam, lambda r: r["family"] == "pass")
        pred[f"{fam}_vs_other"] = (lambda r, fam=fam: r["family"] == fam, lambda r, fam=fam: r["family"] not in {fam, "exclude"})
    for comp, ranked in by_comp.items():
        pos_pred, neg_pred = pred[comp]
        for base in ranked[:80]:
            feat = base["feature"]
            a = compare_feature([r for r in rows if int(r["seed"]) <= 60], feat, pos_pred, neg_pred)
            b = compare_feature([r for r in rows if 61 <= int(r["seed"]) <= 120], feat, pos_pred, neg_pred)
            if not a or not b:
                continue
            out.append({
                "comparison": comp, "feature": feat,
                "effect_1_60": a["common_language_effect_pos_gt_neg"],
                "effect_61_120": b["common_language_effect_pos_gt_neg"],
                "delta_1_60": a["median_delta"], "delta_61_120": b["median_delta"],
                "stable_direction": (float(a["common_language_effect_pos_gt_neg"]) - 0.5) * (float(b["common_language_effect_pos_gt_neg"]) - 0.5) > 0,
                "n_pos_1_60": a["pos_n"], "n_neg_1_60": a["neg_n"],
                "n_pos_61_120": b["pos_n"], "n_neg_61_120": b["neg_n"],
            })
    return out


def plot_feature(rows: list[dict[str, Any]], feature: str, comparison: str, out_dir: Path) -> None:
    if plt is None:
        return
    families = ["pass", "init", "dqs", "bist"]
    data = []
    labels = []
    for fam in families:
        vals = [num(r.get(feature)) for r in rows if r["family"] == fam]
        vals = [v for v in vals if v is not None]
        if vals:
            data.append(vals)
            labels.append(f"{fam}\n(n={len(vals)})")
    if len(data) < 2:
        return
    out_dir.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.violinplot(data, showmedians=True, showextrema=True)
    ax.boxplot(data, widths=0.18, showfliers=False)
    rng = random.Random(1234)
    for i, vals in enumerate(data, start=1):
        xs = [i + (rng.random() - 0.5) * 0.18 for _ in vals]
        ax.scatter(xs, vals, s=14, alpha=0.65)
    ax.set_xticks(range(1, len(labels) + 1))
    ax.set_xticklabels(labels)
    ax.set_title(f"{comparison}: {feature}")
    ax.grid(True, axis="y", alpha=0.25)
    fig.tight_layout()
    fig.savefig(out_dir / f"{safe_name(feature)}.png", dpi=140)
    plt.close(fig)


def render_plots(rows: list[dict[str, Any]], rankings: list[dict[str, Any]], out_dir: Path, top_n: int) -> None:
    for fam in ["init", "dqs", "bist"]:
        comp = f"{fam}_vs_pass"
        candidates = [r for r in rankings if r["comparison"] == comp]
        for ranked in candidates[:top_n]:
            plot_feature(rows, ranked["feature"], comp, out_dir / "plots" / f"{fam}_top_features")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sweep-dir", action="append", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--artifact-csv", action="append", type=Path, default=[])
    parser.add_argument("--plot-top", type=int, default=10)
    args = parser.parse_args()

    artifact_map = load_artifact_map(args.artifact_csv)
    by_seed = load_seed_results(args.sweep_dir)
    seed_rows = []
    feature_rows = []
    for seed in sorted(by_seed):
        if not (1 <= seed <= 200):
            continue
        row = seed_outcome(seed, by_seed[seed])
        if seed in artifact_map:
            next_json, next_log = artifact_map[seed]
        else:
            next_json, next_log = artifact_from_build_logs(seed, args.sweep_dir)
            if next_json is None:
                next_json, next_log = artifact_from_store_references(seed, args.sweep_dir)
            if next_json is None:
                next_json, next_log = artifact_from_current_flake(seed)
        row["nextpnr_json"] = str(next_json or "")
        row["nextpnr_log"] = str(next_log or "")
        feat = dict(row)
        feat.update(log_features(next_log))
        feat.update(json_features(next_json))
        seed_rows.append(row)
        feature_rows.append(feat)
        print(f"seed {seed}: {row['family']} {row['exact_family']} json={1 if next_json else 0}")

    usable_rows = [r for r in feature_rows if r["family"] != "exclude"]
    rankings = rank_features(usable_rows)
    validation = split_validation(usable_rows, rankings)

    summary = []
    for label, rows in [("all", seed_rows), ("1_60", [r for r in seed_rows if int(r["seed"]) <= 60]), ("61_120", [r for r in seed_rows if 61 <= int(r["seed"]) <= 120])]:
        c = Counter(r["family"] for r in rows)
        summary.append({"subset": label, "seeds": len(rows), "pass": c.get("pass", 0), "fail": sum(v for k, v in c.items() if k not in {"pass", "exclude"}), **{f"family_{k}": v for k, v in sorted(c.items())}})

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "seed_outcomes.csv", seed_rows)
    write_csv(args.out_dir / "seed_feature_matrix.csv", feature_rows)
    write_csv(args.out_dir / "family_summary.csv", summary)
    write_csv(args.out_dir / "summary.csv", summary)
    write_csv(args.out_dir / "feature_rankings_by_family.csv", rankings)
    write_csv(args.out_dir / "feature_rankings.csv", rankings)
    write_csv(args.out_dir / "feature_validation_1_60_vs_61_120.csv", validation)
    render_plots(usable_rows, rankings, args.out_dir, args.plot_top)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
