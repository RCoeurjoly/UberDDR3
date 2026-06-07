#!/usr/bin/env python3
"""Extract semantic nextpnr JSON physical features for UberDDR3 HIL samples."""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import statistics
from collections import defaultdict
from pathlib import Path
from typing import Any


DEFAULT_FEATURE_TABLES = [
    Path("artifacts/statistical-sdf/baseline-no-lock-seed-1-30/features_long.csv"),
    Path("artifacts/statistical-sdf/seed-31-60-baseline-no-lock/features_long.csv"),
    Path("artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock/features_long.csv"),
    Path("artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll/features_long.csv"),
    Path("artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost/features_long.csv"),
    Path("artifacts/statistical-sdf/exact-abort-seed3-lock-matrix/features_long.csv"),
]

METADATA_COLUMNS = [
    "experiment_id", "metrics_group", "metric_sample", "metric_status", "hardware_pass", "seed", "run_group", "variant",
    "payload_version", "fail_reasons", "state_calibrate", "instruction_address", "calib_complete", "bist_done", "wrong_read_data",
    "abort_seen", "abort_reason", "abort_reason_name", "abort_lane", "abort_state", "abort_instruction", "abort_start_index_check",
    "abort_lane_write_dq_late", "abort_lane_read_dq_early", "abort_dq_target_index", "abort_data_start_index",
    "idelay_data_tap_mismatch_seen", "idelay_dqs_tap_mismatch_seen", "data_mismatch_lane_mask", "dqs_mismatch_lane_mask",
    "bitstream_sha256", "sdf_sha256", "nextpnr_json_sha256", "result_json", "nextpnr_json", "cvc_sdf", "interpretation",
]
FEATURE_COLUMNS = ["feature", "value_ps", "metric", "family", "lane", "bit", "control_bit", "scope", "count", "min_ps", "median_ps", "p95_ps", "max_ps", "spread_ps"]
LONG_FIELDS = [*METADATA_COLUMNS, *FEATURE_COLUMNS]
BEL_RE = re.compile(r"(?P<site_type>[A-Z0-9_]+)_X(?P<x>-?\d+)Y(?P<y>-?\d+)(?:/(?P<bel>.*))?$")
GENBLK_RE = re.compile(r"genblk5\[(?P<dq>\d+)\]|genblk7\[(?P<dqs>\d+)\]")
CTRL_RE = re.compile(r"cntvaluein\[(?P<ctrl>\d+)\]")


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
    return next((m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"), next(iter(modules.values())))


def parse_bel(value: str) -> dict[str, object] | None:
    if not value:
        return None
    site = value.split("/", 1)[0]
    m = BEL_RE.match(site)
    if not m:
        return None
    return {"site": site, "site_type": m.group("site_type"), "x": int(m.group("x")), "y": int(m.group("y")), "bel": value.split("/", 1)[1] if "/" in value else ""}


def fnum(value: float | int | None) -> float | str:
    if value is None:
        return ""
    return round(float(value), 6)


def safe(value: str, default: str = "all") -> str:
    value = value or default
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def feature_name(metric: str, family: str, lane: str, bit: str, control_bit: str, scope: str) -> str:
    return "__".join([safe(metric, "metric"), safe(family, "family"), safe(lane, "all"), safe(bit, "no_bit"), f"ctrl_{safe(control_bit, 'none')}", safe(scope, "scope"), "value_ps"])


def stats(values: list[float]) -> dict[str, object]:
    if not values:
        return {"count": 0, "min_ps": "", "median_ps": "", "p95_ps": "", "max_ps": "", "spread_ps": ""}
    vals = sorted(values)
    p95 = vals[min(len(vals) - 1, int(round((len(vals) - 1) * 0.95)))]
    return {"count": len(vals), "min_ps": fnum(vals[0]), "median_ps": fnum(statistics.median(vals)), "p95_ps": fnum(p95), "max_ps": fnum(vals[-1]), "spread_ps": fnum(vals[-1] - vals[0])}


def add_feature(rows: list[dict[str, object]], meta: dict[str, str], metric: str, family: str, lane: str, bit: str, control_bit: str, scope: str, value: float, sources: list[float] | None = None) -> None:
    row = {col: meta.get(col, "") for col in METADATA_COLUMNS}
    vals = sources if sources is not None else [value]
    row.update({"feature": feature_name(metric, family, lane, bit, control_bit, scope), "value_ps": fnum(value), "metric": metric, "family": family, "lane": lane, "bit": bit, "control_bit": control_bit, "scope": scope})
    row.update(stats(vals))
    rows.append(row)


def classify_cell(name: str, cell: dict[str, Any]) -> dict[str, str] | None:
    typ = str(cell.get("type", ""))
    lname = name.lower()
    kind = ""
    if "idelaye2" in typ.lower() and "_data" in lname:
        kind = "idelay_data"
    elif "idelaye2" in typ.lower() and "_dqs" in lname:
        kind = "idelay_dqs"
    elif "iserdes" in typ.lower() and "_data" in lname:
        kind = "iserdes_data"
    elif "iserdes" in typ.lower() and "_dqs" in lname:
        kind = "iserdes_dqs"
    elif "oserdes" in typ.lower() and "_data" in lname:
        kind = "oserdes_data"
    elif "oserdes" in typ.lower() and "_dqs" in lname:
        kind = "oserdes_dqs"
    elif "idelayctrl" in typ.lower():
        kind = "idelayctrl"
    elif "idelay_data_cntvaluein" in lname and "lut" in typ.lower():
        kind = "cntvaluein_data_lut"
    elif "idelay_dqs_cntvaluein" in lname and "lut" in typ.lower():
        kind = "cntvaluein_dqs_lut"
    elif "delay_before_release_reset" in lname and "lut" in typ.lower():
        kind = "reset_release_lut"
    elif "dq_target_index" in lname or "data_start_index" in lname or "dqs_start_index" in lname:
        kind = "calibration_index_lut"
    if not kind:
        return None
    lane = "all"
    bit = ""
    m = GENBLK_RE.search(name)
    if m and m.group("dq") is not None:
        dq = int(m.group("dq"))
        lane = "lane0" if dq < 8 else "lane1"
        bit = f"dq{dq}"
    elif m and m.group("dqs") is not None:
        dqs = int(m.group("dqs"))
        lane = f"lane{dqs}"
        bit = f"dqs{dqs}"
    ctrl = ""
    c = CTRL_RE.search(name)
    if c:
        ctrl = c.group("ctrl")
    return {"kind": kind, "lane": lane, "bit": bit, "control_bit": ctrl}


def load_metadata(paths: list[Path]) -> dict[str, dict[str, str]]:
    meta: dict[str, dict[str, str]] = {}
    for path in paths:
        if not path.exists():
            continue
        for row in read_csv(path):
            exp = row.get("experiment_id", "")
            if exp and exp not in meta:
                meta[exp] = {col: row.get(col, "") for col in METADATA_COLUMNS}
    return meta


def centroid(points: list[dict[str, object]]) -> tuple[float, float] | None:
    if not points:
        return None
    return (sum(float(p["x"]) for p in points) / len(points), sum(float(p["y"]) for p in points) / len(points))


def manhattan(a: dict[str, object], b: dict[str, object]) -> float:
    return float(abs(int(a["x"]) - int(b["x"])) + abs(int(a["y"]) - int(b["y"])))


def distance_group(a: list[dict[str, object]], b: list[dict[str, object]]) -> list[float]:
    return [manhattan(x, y) for x in a for y in b if x.get("site_type") == y.get("site_type")]


def cell_features(meta: dict[str, str]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    path = Path(meta.get("nextpnr_json", ""))
    if not path.exists():
        return [], []
    data = json.loads(path.read_text(encoding="utf-8"))
    cells = top_module(data).get("cells", {})
    groups: dict[tuple[str, str, str, str], list[dict[str, object]]] = defaultdict(list)
    direct: list[dict[str, object]] = []
    for name, cell in cells.items():
        if not isinstance(cell, dict):
            continue
        cls = classify_cell(name, cell)
        if cls is None:
            continue
        bel = str(cell.get("attributes", {}).get("NEXTPNR_BEL", ""))
        parsed = parse_bel(bel)
        if parsed is None:
            continue
        item = {"cell": name, "type": cell.get("type", ""), "bel": bel, **parsed, **cls}
        groups[(cls["kind"], cls["lane"], cls["bit"], cls["control_bit"])].append(item)
        direct.append({"experiment_id": meta.get("experiment_id", ""), **item})

    rows: list[dict[str, object]] = []
    by_kind: dict[str, list[dict[str, object]]] = defaultdict(list)
    for (kind, lane, bit, ctrl), items in groups.items():
        by_kind[kind].extend(items)
        xs = [float(i["x"]) for i in items]
        ys = [float(i["y"]) for i in items]
        add_feature(rows, meta, "json_cell_count", kind, lane, bit, ctrl, "cells", float(len(items)), [float(len(items))])
        add_feature(rows, meta, "json_site_x_spread", kind, lane, bit, ctrl, "sites", max(xs) - min(xs), xs)
        add_feature(rows, meta, "json_site_y_spread", kind, lane, bit, ctrl, "sites", max(ys) - min(ys), ys)
        add_feature(rows, meta, "json_site_y_median", kind, lane, bit, ctrl, "sites", statistics.median(ys), ys)
        add_feature(rows, meta, "json_unique_site_count", kind, lane, bit, ctrl, "sites", float(len({i["site"] for i in items})), [float(len({i["site"] for i in items}))])

    pairs = [
        ("cntvaluein_data_lut", "idelay_data", "cntvaluein_to_idelay_data"),
        ("cntvaluein_dqs_lut", "idelay_dqs", "cntvaluein_to_idelay_dqs"),
        ("cntvaluein_data_lut", "cntvaluein_dqs_lut", "cntvaluein_data_to_dqs_lut"),
        ("idelay_data", "iserdes_data", "idelay_to_iserdes_data"),
        ("idelay_dqs", "iserdes_dqs", "idelay_to_iserdes_dqs"),
        ("idelayctrl", "idelay_data", "idelayctrl_to_idelay_data"),
        ("idelayctrl", "idelay_dqs", "idelayctrl_to_idelay_dqs"),
        ("reset_release_lut", "idelayctrl", "reset_release_to_idelayctrl"),
        ("calibration_index_lut", "cntvaluein_data_lut", "cal_index_to_cntvaluein_data"),
    ]
    for a, b, fam in pairs:
        distances = distance_group(by_kind.get(a, []), by_kind.get(b, []))
        if distances:
            add_feature(rows, meta, "json_manhattan_median", fam, "all", "", "", "pair", statistics.median(distances), distances)
            add_feature(rows, meta, "json_manhattan_max", fam, "all", "", "", "pair", max(distances), distances)
            add_feature(rows, meta, "json_manhattan_spread", fam, "all", "", "", "pair", max(distances) - min(distances), distances)
    # Lane centroid mismatch for major PHY groups.
    for kind in ["idelay_data", "iserdes_data", "oserdes_data", "cntvaluein_data_lut"]:
        l0 = [i for i in by_kind.get(kind, []) if i.get("lane") == "lane0"]
        l1 = [i for i in by_kind.get(kind, []) if i.get("lane") == "lane1"]
        c0 = centroid(l0)
        c1 = centroid(l1)
        if c0 and c1:
            d = abs(c0[0] - c1[0]) + abs(c0[1] - c1[1])
            add_feature(rows, meta, "json_lane_centroid_manhattan", kind, "all", "", "", "lane1_vs_lane0", d, [d])
            add_feature(rows, meta, "json_lane_centroid_y_delta", kind, "all", "", "", "lane1_minus_lane0", c1[1] - c0[1], [c1[1] - c0[1]])
    return rows, direct


def wide_rows(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    by_exp: dict[str, dict[str, object]] = {}
    for row in rows:
        exp = str(row["experiment_id"])
        if exp not in by_exp:
            by_exp[exp] = {col: row.get(col, "") for col in METADATA_COLUMNS}
        by_exp[exp][str(row["feature"])] = row.get("value_ps", "")
    return list(by_exp.values())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/statistical-sdf/json-physical-features"))
    parser.add_argument("--features-long", type=Path, action="append")
    args = parser.parse_args()
    paths = args.features_long or DEFAULT_FEATURE_TABLES
    metadata = load_metadata(paths)
    rows: list[dict[str, object]] = []
    direct: list[dict[str, object]] = []
    skipped: list[dict[str, object]] = []
    for exp, meta in sorted(metadata.items(), key=lambda kv: (kv[1].get("run_group", ""), int(kv[1].get("seed") or 0), kv[1].get("variant", ""), kv[0])):
        features, direct_rows = cell_features(meta)
        if not features:
            skipped.append({"experiment_id": exp, "nextpnr_json": meta.get("nextpnr_json", ""), "reason": "no_json_or_no_classified_cells"})
        rows.extend(features)
        direct.extend(direct_rows)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.out_dir / "json_physical_features_long.csv", rows, LONG_FIELDS)
    wide = wide_rows(rows)
    wide_fields = list(METADATA_COLUMNS)
    for row in rows:
        if row["feature"] not in wide_fields:
            wide_fields.append(str(row["feature"]))
    write_csv(args.out_dir / "json_physical_features_wide.csv", wide, wide_fields)
    write_csv(args.out_dir / "json_physical_cells.csv", direct, ["experiment_id", "cell", "type", "bel", "site", "site_type", "x", "y", "kind", "lane", "bit", "control_bit"])
    write_csv(args.out_dir / "skipped_json_physical_samples.csv", skipped, ["experiment_id", "nextpnr_json", "reason"])
    readme = [
        "# JSON Physical Features",
        "",
        "Semantic physical features extracted from nextpnr placed JSON for DDR3-relevant cells and cones.",
        "",
        f"- experiments with features: `{len({r['experiment_id'] for r in rows})}`",
        f"- feature rows: `{len(rows)}`",
        f"- classified cell rows: `{len(direct)}`",
        f"- skipped samples: `{len(skipped)}`",
        "",
        "Outputs: `json_physical_features_long.csv`, `json_physical_features_wide.csv`, `json_physical_cells.csv`.",
        "",
        "Units are physical-site distances or counts, but the column is named `value_ps` for compatibility with existing SDF statistical scripts.",
    ]
    (args.out_dir / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
