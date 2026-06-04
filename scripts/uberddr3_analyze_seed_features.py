#!/usr/bin/env python3
"""Analyze UberDDR3 seed sensitivity from board JSON plus nextpnr JSON/log features."""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import statistics as st
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

BEL_RE = re.compile(r"(?P<site>[A-Z0-9_]+_X(?P<x>-?\d+)Y(?P<y>-?\d+))")
RESULT_RE = re.compile(r"seed-(\d+)-repeat-(\d+)\.json$")
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


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for row in rows:
            w.writerow({k: row.get(k, "") for k in fields})


def num(v: Any) -> float | None:
    try:
        if v == "" or v is None:
            return None
        return float(v)
    except Exception:
        return None


def median(values: list[float]) -> float | str:
    return round(st.median(values), 6) if values else ""


def mean(values: list[float]) -> float | str:
    return round(st.mean(values), 6) if values else ""


def span(values: list[float]) -> float | str:
    return round(max(values) - min(values), 6) if values else ""


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    for mod in modules.values():
        if mod.get("attributes", {}).get("top") == "00000000000000000000000000000001":
            return mod
    return next(iter(modules.values()))


def parse_sites(text: str) -> list[tuple[int, int]]:
    out = []
    for m in BEL_RE.finditer(text or ""):
        out.append((int(m.group("x")), int(m.group("y"))))
    return out


def matching_groups(name: str) -> list[str]:
    low = name.lower()
    return [group for group, needles in FOCUS.items() if any(n in low for n in needles)]


def specific_groups(name: str) -> list[str]:
    low = name.lower()
    return [f"sig_{s}" for s in SPECIFIC if s in low]


def add_group_features(prefix: str, groups: dict[str, list[dict[str, Any]]], row: dict[str, Any]) -> None:
    for group, items in groups.items():
        xs = [float(i["x"]) for i in items if i.get("x") is not None]
        ys = [float(i["y"]) for i in items if i.get("y") is not None]
        fan = [float(i["fanout"]) for i in items if i.get("fanout") is not None]
        seg = [float(i["segments"]) for i in items if i.get("segments") is not None]
        route = [float(i["route_chars"]) for i in items if i.get("route_chars") is not None]
        row[f"{prefix}_{group}_count"] = len(items)
        row[f"{prefix}_{group}_x_med"] = median(xs)
        row[f"{prefix}_{group}_y_med"] = median(ys)
        row[f"{prefix}_{group}_x_span"] = span(xs)
        row[f"{prefix}_{group}_y_span"] = span(ys)
        if fan:
            row[f"{prefix}_{group}_fanout_med"] = median(fan)
            row[f"{prefix}_{group}_fanout_max"] = max(fan)
        if seg:
            row[f"{prefix}_{group}_segments_med"] = median(seg)
            row[f"{prefix}_{group}_segments_max"] = max(seg)
        if route:
            row[f"{prefix}_{group}_route_chars_med"] = median(route)
            row[f"{prefix}_{group}_route_chars_max"] = max(route)


def nextpnr_paths(seed: int) -> tuple[Path | None, Path | None, str]:
    attr = f".#ypcb-ddr3-nextpnr-json-panopticon-seed-{seed}"
    cp = subprocess.run(["nix", "path-info", attr], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    if cp.returncode != 0:
        return None, None, cp.stdout.strip()
    out = Path(cp.stdout.strip().splitlines()[-1])
    return out / "ypcb_00338_1p1_ddr3.placed.json", out / "metadata" / "nextpnr.log", ""


def log_features(path: Path | None) -> dict[str, Any]:
    row: dict[str, Any] = {}
    if not path or not path.exists():
        row["log_available"] = 0
        return row
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    row["log_available"] = 1
    row["log_warning_count"] = sum(1 for l in lines if "Warning:" in l or "warning:" in l)
    row["log_error_count"] = sum(1 for l in lines if "Error:" in l or "error:" in l)
    row["log_ddr_mentions"] = sum(1 for l in lines if "ddr" in l.lower())
    row["log_dqs_mentions"] = sum(1 for l in lines if "dqs" in l.lower())
    row["log_idelay_mentions"] = sum(1 for l in lines if "idelay" in l.lower())
    freqs = []
    for line in lines:
        m = MAX_FREQ_RE.search(line)
        if m:
            freqs.append((m.group(1), float(m.group(2)), m.group(3), float(m.group(4))))
    if freqs:
        clock, mhz, status, target = freqs[-1]
        row["fmax_clock"] = clock
        row["fmax_mhz"] = mhz
        row["fmax_target_mhz"] = target
        row["fmax_margin_mhz"] = round(mhz - target, 6)
        row["fmax_status_pass"] = 1 if status == "PASS" else 0
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
    row: dict[str, Any] = {}
    if not path or not path.exists():
        row["json_available"] = 0
        return row
    data = json.loads(path.read_text(encoding="utf-8"))
    mod = top_module(data)
    row["json_available"] = 1
    row["json_cell_count_total"] = len(mod.get("cells", {}))
    row["json_net_count_total"] = len(mod.get("netnames", {}))
    cell_groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for name, cell in mod.get("cells", {}).items():
        attrs = cell.get("attributes", {}) if isinstance(cell, dict) else {}
        bel = str(attrs.get("NEXTPNR_BEL", ""))
        sites = parse_sites(bel)
        if not sites:
            continue
        x, y = sites[0]
        item = {"x": x, "y": y}
        for group in matching_groups(name) + specific_groups(name):
            cell_groups[group].append(item)
    add_group_features("cell", cell_groups, row)

    net_groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for name, net in mod.get("netnames", {}).items():
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


def classify_result(d: dict[str, Any]) -> tuple[str, str, str]:
    if d.get("pass"):
        return "pass", "pass", "pass"
    reasons = d.get("fail_reasons", []) if isinstance(d.get("fail_reasons"), list) else []
    fields = d.get("fields", {}) if isinstance(d.get("fields"), dict) else {}
    calib = fields.get("calib_debug", {}) if isinstance(fields.get("calib_debug"), dict) else {}
    init = fields.get("init_reset_debug", {}) if isinstance(fields.get("init_reset_debug"), dict) else {}
    bist = fields.get("bist_debug", {}) if isinstance(fields.get("bist_debug"), dict) else {}
    state = fields.get("state_calibrate")
    instr = calib.get("instruction_address")
    if "programming_failed" in reasons:
        return "fail", "programming", "programming"
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
    for d in sweep_dirs:
        for p in sorted(d.glob("*seed-*-repeat-*.json")):
            m = RESULT_RE.search(p.name)
            if not m:
                continue
            seed, repeat = int(m.group(1)), int(m.group(2))
            try:
                data = json.loads(p.read_text(encoding="utf-8"))
            except Exception:
                continue
            status, family, exact = classify_result(data)
            by_seed[seed].append({"seed": seed, "repeat": repeat, "status": status, "family": family, "exact_family": exact, "result_json": str(p), "attempts": data.get("attempts", ""), "poll_stop_reason": data.get("poll_stop_reason", "")})
    return by_seed


def seed_outcome(seed: int, rows: list[dict[str, Any]]) -> dict[str, Any]:
    rows = sorted(rows, key=lambda r: int(r["repeat"]))
    status_counts = Counter(r["status"] for r in rows)
    family_counts = Counter(r["family"] for r in rows if r["status"] != "pass")
    exact_counts = Counter(r["exact_family"] for r in rows if r["status"] != "pass")
    if status_counts.get("pass"):
        outcome = "pass"
        family = "pass"
        exact = "pass"
    else:
        family = family_counts.most_common(1)[0][0] if family_counts else "unknown"
        exact = exact_counts.most_common(1)[0][0] if exact_counts else "unknown"
        outcome = "fail"
    return {"seed": seed, "outcome": outcome, "family": family, "exact_family": exact, "repeat_count": len(rows), "pass_repeats": status_counts.get("pass", 0), "fail_repeats": len(rows) - status_counts.get("pass", 0), "mixed_families": len(family_counts) > 1, "families_seen": ";".join(f for f, _ in family_counts.most_common())}


def common_language(pos: list[float], neg: list[float]) -> float:
    if not pos or not neg:
        return math.nan
    wins = ties = total = 0
    for a in pos:
        for b in neg:
            total += 1
            if a > b:
                wins += 1
            elif a == b:
                ties += 1
    return (wins + 0.5 * ties) / total


def rank_features(rows: list[dict[str, Any]], comparison: str, pred_pos, pred_neg) -> list[dict[str, Any]]:
    pos_rows = [r for r in rows if pred_pos(r)]
    neg_rows = [r for r in rows if pred_neg(r)]
    meta = {"seed", "outcome", "family", "exact_family", "repeat_count", "pass_repeats", "fail_repeats", "mixed_families", "families_seen", "nextpnr_json", "nextpnr_log"}
    feats = sorted({k for r in rows for k, v in r.items() if k not in meta and num(v) is not None})
    out = []
    for feat in feats:
        pos = [num(r.get(feat)) for r in pos_rows]
        neg = [num(r.get(feat)) for r in neg_rows]
        pos = [v for v in pos if v is not None]
        neg = [v for v in neg if v is not None]
        if len(pos) < 3 or len(neg) < 3:
            continue
        eff = common_language(pos, neg)
        out.append({
            "comparison": comparison,
            "feature": feat,
            "pos_n": len(pos),
            "neg_n": len(neg),
            "pos_median": median(pos),
            "neg_median": median(neg),
            "median_delta": round(float(median(pos)) - float(median(neg)), 6),
            "common_language_effect_pos_gt_neg": round(eff, 6),
            "abs_effect_from_0_5": round(abs(eff - 0.5), 6),
        })
    return sorted(out, key=lambda r: r["abs_effect_from_0_5"], reverse=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--sweep-dir", action="append", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    by_seed = load_seed_results(args.sweep_dir)
    seed_rows = []
    feature_rows = []
    for seed in sorted(by_seed):
        if not (1 <= seed <= 200):
            continue
        row = seed_outcome(seed, by_seed[seed])
        next_json, next_log, err = nextpnr_paths(seed)
        row["nextpnr_json"] = str(next_json or "")
        row["nextpnr_log"] = str(next_log or "")
        if err:
            row["nextpnr_error"] = err
        feat = dict(row)
        feat.update(log_features(next_log))
        feat.update(json_features(next_json))
        seed_rows.append(row)
        feature_rows.append(feat)
        print(f"seed {seed}: {row['family']} {row['exact_family']}")
    rankings = []
    rankings.extend(rank_features(feature_rows, "fail_vs_pass", lambda r: r["outcome"] == "fail", lambda r: r["outcome"] == "pass"))
    for fam in ["init", "dqs", "bist"]:
        rankings.extend(rank_features(feature_rows, f"{fam}_vs_pass", lambda r, fam=fam: r["family"] == fam, lambda r: r["outcome"] == "pass"))
        rankings.extend(rank_features(feature_rows, f"{fam}_vs_other", lambda r, fam=fam: r["family"] == fam, lambda r, fam=fam: r["family"] != fam))
    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "seed_outcomes.csv", seed_rows)
    write_csv(args.out_dir / "seed_feature_matrix.csv", feature_rows)
    write_csv(args.out_dir / "feature_rankings.csv", rankings)
    summary = []
    for label, rows in [("all", seed_rows), ("1_60", [r for r in seed_rows if int(r["seed"]) <= 60]), ("61_120", [r for r in seed_rows if 61 <= int(r["seed"]) <= 120])]:
        c = Counter(r["family"] for r in rows)
        summary.append({"subset": label, "seeds": len(rows), "pass": c.get("pass", 0), "fail": len(rows) - c.get("pass", 0), **{f"family_{k}": v for k, v in sorted(c.items())}})
    write_csv(args.out_dir / "summary.csv", summary)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
