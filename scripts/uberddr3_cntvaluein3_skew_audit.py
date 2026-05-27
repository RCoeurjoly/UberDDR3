#!/usr/bin/env python3
"""Audit the lane1 DQS1 versus DQ14 CNTVALUEIN3 SDF/placement skew."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Iterable


PIN_PATTERN = r"IDELAYE2_(data|dqs)\.CNTVALUEIN3"
BEL_SITE_RE = re.compile(r"(?P<site>[A-Z0-9_]+_X(?P<x>\d+)Y(?P<y>\d+))/(?P<bel>.+)$")


def unescape_sdf_name(value: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(value):
        ch = value[i]
        if ch == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            out.append(nxt)
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def cell_from_pin(pin: str) -> str:
    return pin.rsplit(".", 1)[0]


def flatten_query_json(data: dict[str, object]) -> Iterable[dict[str, object]]:
    cells = data.get("cells")
    if not isinstance(cells, dict):
        return
    for design in cells.values():
        if not isinstance(design, dict):
            continue
        for instance in design.values():
            if not isinstance(instance, dict):
                continue
            for entry in instance.values():
                if isinstance(entry, dict):
                    yield entry


def delay_value(entry: dict[str, object], field: str, metric: str) -> float | None:
    paths = entry.get("delay_paths")
    if not isinstance(paths, dict):
        return None
    for candidate in (field, "slow", "fast", "nominal", "rise", "fall"):
        data = paths.get(candidate)
        if isinstance(data, dict) and data.get(metric) is not None:
            return float(data[metric])
    return None


def query_cntvaluein3(sdf_toolkit: str, sdf: Path, cache_json: Path | None, field: str, metric: str) -> list[dict[str, object]]:
    if cache_json is not None and cache_json.exists():
        data = json.loads(cache_json.read_text(encoding="utf-8"))
    else:
        cmd = [
            sdf_toolkit,
            "query",
            str(sdf),
            "--entry-type",
            "interconnect",
            "--pin-pattern",
            PIN_PATTERN,
            "--field",
            field,
            "--metric",
            metric,
            "--format",
            "json",
        ]
        proc = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE)
        if cache_json is not None:
            cache_json.parent.mkdir(parents=True, exist_ok=True)
            cache_json.write_text(proc.stdout, encoding="utf-8")
        data = json.loads(proc.stdout)

    records: list[dict[str, object]] = []
    for item in flatten_query_json(data):
        if item.get("type") != "interconnect":
            continue
        raw_from_pin = str(item.get("from_pin", ""))
        raw_to_pin = str(item.get("to_pin", ""))
        from_pin = unescape_sdf_name(raw_from_pin)
        to_pin = unescape_sdf_name(raw_to_pin)
        delay_ps = delay_value(item, field, metric)
        if delay_ps is None:
            continue
        if to_pin.endswith("genblk5[14].IDELAYE2_data.CNTVALUEIN3"):
            records.append({"role": "dq14", "from_pin": from_pin, "to_pin": to_pin, "delay_ps": delay_ps})
        elif to_pin.endswith("genblk7[1].IDELAYE2_dqs.CNTVALUEIN3"):
            records.append({"role": "dqs1", "from_pin": from_pin, "to_pin": to_pin, "delay_ps": delay_ps})
    return records


def top_module(data: dict[str, Any]) -> dict[str, Any]:
    modules = data.get("modules", {})
    return next(
        (m for m in modules.values() if m.get("attributes", {}).get("top") == "00000000000000000000000000000001"),
        next(iter(modules.values())),
    )


def load_cells(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return top_module(data).get("cells", {})


def cell_bel(cells: dict[str, Any], cell_name: str) -> str:
    cell = cells.get(cell_name)
    if not isinstance(cell, dict):
        return ""
    attrs = cell.get("attributes", {})
    if not isinstance(attrs, dict):
        return ""
    return str(attrs.get("NEXTPNR_BEL", ""))


def site_info(bel: str) -> dict[str, object]:
    match = BEL_SITE_RE.match(bel)
    if match is None:
        return {"site": "", "site_type": "", "x": "", "y": "", "bel_leaf": ""}
    site = match.group("site")
    site_type = site.split("_X", 1)[0]
    return {
        "site": site,
        "site_type": site_type,
        "x": int(match.group("x")),
        "y": int(match.group("y")),
        "bel_leaf": match.group("bel"),
    }


def same_type_delta(a: dict[str, object], b: dict[str, object], prefix: str) -> dict[str, object]:
    if not a.get("site_type") or a.get("site_type") != b.get("site_type"):
        return {
            f"{prefix}_same_site_type": False,
            f"{prefix}_dx": "",
            f"{prefix}_dy": "",
            f"{prefix}_manhattan": "",
        }
    dx = int(a["x"]) - int(b["x"])
    dy = int(a["y"]) - int(b["y"])
    return {
        f"{prefix}_same_site_type": True,
        f"{prefix}_dx": dx,
        f"{prefix}_dy": dy,
        f"{prefix}_manhattan": abs(dx) + abs(dy),
    }


def read_hardware_rows(path: Path, seeds: set[int] | None, variant: str | None) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    selected = []
    for row in rows:
        try:
            seed = int(row.get("seed", ""))
        except ValueError:
            continue
        if seeds is not None and seed not in seeds:
            continue
        if variant is not None and row.get("variant") != variant:
            continue
        if not row.get("cvc_sdf") or not row.get("nextpnr_json"):
            continue
        selected.append(row)
    return selected


def ffloat(value: float) -> float:
    return round(value, 6)


def audit_row(row: dict[str, str], sdf_toolkit: str, out_dir: Path, field: str, metric: str, reuse_cache: bool) -> dict[str, object]:
    experiment_id = row.get("experiment_id", f"seed-{row.get('seed', '')}")
    cache_json = out_dir / "query-json" / f"{experiment_id}.cntvaluein3.json"
    if not reuse_cache and cache_json.exists():
        cache_json.unlink()
    records = query_cntvaluein3(sdf_toolkit, Path(row["cvc_sdf"]), cache_json, field, metric)
    by_role = {str(record["role"]): record for record in records}
    dq = by_role.get("dq14")
    dqs = by_role.get("dqs1")
    if dq is None or dqs is None:
        raise RuntimeError(f"{experiment_id}: missing dq14/dqs1 CNTVALUEIN3 records")

    cells = load_cells(Path(row["nextpnr_json"]))
    dq_from_cell = cell_from_pin(str(dq["from_pin"]))
    dq_to_cell = cell_from_pin(str(dq["to_pin"]))
    dqs_from_cell = cell_from_pin(str(dqs["from_pin"]))
    dqs_to_cell = cell_from_pin(str(dqs["to_pin"]))

    dq_from_bel = cell_bel(cells, dq_from_cell)
    dq_to_bel = cell_bel(cells, dq_to_cell)
    dqs_from_bel = cell_bel(cells, dqs_from_cell)
    dqs_to_bel = cell_bel(cells, dqs_to_cell)

    dq_from_site = site_info(dq_from_bel)
    dqs_from_site = site_info(dqs_from_bel)
    dq_to_site = site_info(dq_to_bel)
    dqs_to_site = site_info(dqs_to_bel)

    dq_delay = float(dq["delay_ps"])
    dqs_delay = float(dqs["delay_ps"])
    out: dict[str, object] = {
        "experiment_id": experiment_id,
        "seed": row.get("seed", ""),
        "variant": row.get("variant", ""),
        "hardware_pass": row.get("pass", ""),
        "abort_reason": row.get("abort_reason", ""),
        "abort_reason_name": row.get("abort_reason_name", ""),
        "abort_lane": row.get("abort_lane", ""),
        "dq14_delay_ps": ffloat(dq_delay),
        "dqs1_delay_ps": ffloat(dqs_delay),
        "signed_dqs1_minus_dq14_ps": ffloat(dqs_delay - dq_delay),
        "abs_dqs1_minus_dq14_ps": ffloat(abs(dqs_delay - dq_delay)),
        "dq14_from_pin": dq["from_pin"],
        "dq14_to_pin": dq["to_pin"],
        "dqs1_from_pin": dqs["from_pin"],
        "dqs1_to_pin": dqs["to_pin"],
        "dq14_from_cell": dq_from_cell,
        "dq14_to_cell": dq_to_cell,
        "dqs1_from_cell": dqs_from_cell,
        "dqs1_to_cell": dqs_to_cell,
        "dq14_from_bel": dq_from_bel,
        "dq14_to_bel": dq_to_bel,
        "dqs1_from_bel": dqs_from_bel,
        "dqs1_to_bel": dqs_to_bel,
        "dq14_from_site": dq_from_site.get("site", ""),
        "dq14_to_site": dq_to_site.get("site", ""),
        "dqs1_from_site": dqs_from_site.get("site", ""),
        "dqs1_to_site": dqs_to_site.get("site", ""),
    }
    out.update(same_type_delta(dqs_from_site, dq_from_site, "source_dqs1_minus_dq14"))
    out.update(same_type_delta(dqs_to_site, dq_to_site, "sink_dqs1_minus_dq14"))
    return out


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields: list[str] = []
    for row in rows:
        for key in row:
            if key not in fields:
                fields.append(key)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hardware-csv", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--sdf-toolkit", default="sdf-toolkit")
    parser.add_argument("--seed", action="append", type=int, help="Restrict to one seed. Repeat for multiple seeds.")
    parser.add_argument("--variant", help="Restrict to a hardware CSV variant value.")
    parser.add_argument("--field", default="slow")
    parser.add_argument("--metric", default="max")
    parser.add_argument("--reuse-cache", action="store_true")
    args = parser.parse_args()

    seeds = set(args.seed) if args.seed else None
    hardware_rows = read_hardware_rows(args.hardware_csv, seeds, args.variant)
    if not hardware_rows:
        raise SystemExit("no hardware rows selected")

    rows: list[dict[str, object]] = []
    for row in hardware_rows:
        print(f"audit {row.get('experiment_id', '')}", file=sys.stderr)
        rows.append(audit_row(row, args.sdf_toolkit, args.out_dir, args.field, args.metric, args.reuse_cache))

    write_csv(args.out_dir / "cntvaluein3_dqs1_dq14_audit.csv", rows)
    (args.out_dir / "README.md").write_text(
        "# CNTVALUEIN3 DQS1/DQ14 Audit\n\n"
        "This report joins focused SDF query results for `IDELAYE2_data/dqs.CNTVALUEIN3` "
        "to nextpnr JSON BEL placement for the lane1 DQS1 versus DQ14 skew hypothesis.\n",
        encoding="utf-8",
    )
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
