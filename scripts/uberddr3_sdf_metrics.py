#!/usr/bin/env python3
"""Build DDR-focused SDF metrics from sdf-toolkit query output.

This is intentionally metric-first.  Raw SDF diffs are dominated by legal seed
churn: LUT input repinning, constant drivers, synthesized temporary names, and
packing changes.  This tool asks sdf-toolkit for DDR-relevant records, normalizes
those records into PHY endpoint families, and compares metric populations across
known passing, failing, and robust seeds.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
import json
from pathlib import Path
import re
import shlex
import statistics
import subprocess
import sys
from typing import Iterable, Iterator


@dataclass(frozen=True)
class QuerySpec:
    family: str
    pattern: str
    description: str


@dataclass(frozen=True)
class Sample:
    label: str
    status: str
    sdf: Path
    placed_json: Path | None = None


@dataclass(frozen=True)
class Entry:
    sample: str
    status: str
    family: str
    from_pin: str
    to_pin: str
    graph_from_pin: str
    graph_to_pin: str
    delay_ps: float
    lane: str
    bit: str
    control_bit: str
    endpoint: str


QUERY_SPECS = [
    QuerySpec("idelay_data_cntvaluein", r"IDELAYE2_data\.CNTVALUEIN", "DQ IDELAY CNTVALUEIN programming fanout"),
    QuerySpec("idelay_dqs_cntvaluein", r"IDELAYE2_dqs\.CNTVALUEIN", "DQS IDELAY CNTVALUEIN programming fanout"),
    QuerySpec("idelay_ld", r"IDELAYE2_(data|dqs)\.LD", "IDELAY load-strobe fanout"),
    QuerySpec("idelay_ce_inc", r"IDELAYE2_(data|dqs)\.(CE|INC)", "IDELAY CE/INC fanout"),
    QuerySpec("dq_iologic", r"(IOBUF_data|IDELAYE2_data|ISERDESE2_data|OSERDESE2_data)", "DQ IOLOGIC/IDELAY/SERDES paths"),
    QuerySpec("dqs_iologic", r"(IOBUFDS_dqs|IDELAYE2_dqs|ISERDESE2_dqs|OSERDESE2_dqs)", "DQS IOLOGIC/IDELAY/SERDES paths"),
    QuerySpec("idelayctrl", r"(IDELAYCTRL|CTRL_DUP|RDY)", "IDELAYCTRL/RDY paths"),
    QuerySpec("reset_release", r"delay_before_release_reset", "PHY reset-release delay chain"),
    QuerySpec("clocking", r"(MMCM|PLL|BUFG|BUFIO|BUFR|clk_wiz|controller_clk|ddr3_clk|clk_90|ref_clk)", "Generated DDR clocks and clock distribution"),
]

STATUS_COLUMNS = ["fail", "pass", "robust"]

DQ_RE = re.compile(r"(?:ddr3_dq|io_ddr3_dq)\[(\d+)\]|genblk5\[(\d+)\]")
DQS_RE = re.compile(r"(?:ddr3_dqs_[pn]|io_ddr3_dqs(?:_n)?)\[(\d+)\]|genblk7\[(\d+)\]")
CNT_RE = re.compile(r"CNTVALUEIN(\d+)")
CONTROL_PIN_RE = re.compile(r"\.(LD|CE|INC|RST|RDY|CLK|DATAIN|DATAOUT|CNTVALUEIN\d+|Q\d+|D\d+)$")
IDELAY_CONTROL_ENDPOINT_RE = re.compile(r"\.(CNTVALUEIN\d+|LD|CE|INC)$")
CONSTANT_DRIVER_RE = re.compile(r"PACKER_(GND|VCC)_(DRV|NET)")


def clean_pin(pin: str) -> str:
    return pin.replace("\\", "")


def first_int(groups: Iterable[str | None]) -> int | None:
    for group in groups:
        if group is not None:
            return int(group)
    return None


def lane_bit(text: str) -> tuple[str, str]:
    dq = DQ_RE.search(text)
    if dq:
        bit = first_int(dq.groups())
        if bit is not None:
            return f"lane{bit // 8}", f"dq{bit}"
    dqs = DQS_RE.search(text)
    if dqs:
        lane = first_int(dqs.groups())
        if lane is not None:
            return f"lane{lane}", f"dqs{lane}"
    return "all", ""


def control_bit(text: str) -> str:
    match = CNT_RE.search(text)
    return match.group(1) if match else ""


def endpoint_name(to_pin: str) -> str:
    pin = clean_pin(to_pin)
    lane, bit = lane_bit(pin)
    cnt = control_bit(pin)
    ctrl = CONTROL_PIN_RE.search(pin)
    suffix = ctrl.group(1).lower() if ctrl else "endpoint"
    if cnt:
        suffix = f"cntvaluein{cnt}"
    if bit:
        return f"{bit}.{suffix}"
    return f"{lane}.{suffix}" if lane != "all" else suffix


def delay_value(entry: dict[str, object], field: str, metric: str) -> float | None:
    paths = entry.get("delay_paths")
    if not isinstance(paths, dict):
        return None
    candidates = [field, "slow", "fast", "nominal", "rise", "fall"]
    for candidate in candidates:
        data = paths.get(candidate)
        if isinstance(data, dict) and data.get(metric) is not None:
            return float(data[metric])
    return None


def flatten_query_json(data: dict[str, object]) -> Iterator[dict[str, object]]:
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


def stats(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {
            "count": 0,
            "min_ps": None,
            "median_ps": None,
            "p95_ps": None,
            "max_ps": None,
            "spread_ps": None,
        }
    ordered = sorted(values)
    p95_index = min(len(ordered) - 1, int(round((len(ordered) - 1) * 0.95)))
    return {
        "count": len(ordered),
        "min_ps": ordered[0],
        "median_ps": statistics.median(ordered),
        "p95_ps": ordered[p95_index],
        "max_ps": ordered[-1],
        "spread_ps": ordered[-1] - ordered[0],
    }


def metric_value(row: dict[str, object]) -> float | None:
    if row["metric"].endswith("_spread") or row["metric"].endswith("_skew"):
        value = row.get("spread_ps")
    else:
        value = row.get("max_ps")
    return float(value) if value not in (None, "") else None


def parse_sample(spec: str) -> Sample:
    parts = spec.split(":")
    if len(parts) not in (3, 4):
        raise argparse.ArgumentTypeError("sample must be LABEL:STATUS:SDF_OR_DIR[:PLACED_JSON]")
    label, status, sdf_arg = parts[:3]
    path = Path(sdf_arg)
    sdf = resolve_sdf(path)
    placed = Path(parts[3]) if len(parts) == 4 else resolve_placed_json(path)
    return Sample(label=label, status=status, sdf=sdf, placed_json=placed)


def resolve_sdf(path: Path) -> Path:
    if path.is_file():
        return path
    if path.is_dir():
        cvc = sorted(path.glob("*.cvc.sdf"))
        if cvc:
            return cvc[0]
        sdf = sorted(path.glob("*.sdf"))
        if sdf:
            return sdf[0]
    return path


def resolve_placed_json(path: Path) -> Path | None:
    if path.is_dir():
        placed = sorted(path.glob("*.placed.json"))
        if placed:
            return placed[0]
    return None


def run_query(
    sdf_toolkit: str,
    sample: Sample,
    spec: QuerySpec,
    out_dir: Path,
    field: str,
    metric: str,
    reuse_cache: bool,
) -> list[Entry]:
    query_dir = out_dir / "query-json"
    query_dir.mkdir(parents=True, exist_ok=True)
    query_path = query_dir / f"{sample.label}.{spec.family}.json"

    if reuse_cache and query_path.exists():
        data = json.loads(query_path.read_text(encoding="utf-8"))
    else:
        cmd = [
            sdf_toolkit,
            "query",
            str(sample.sdf),
            "--entry-type",
            "interconnect",
            "--pin-pattern",
            spec.pattern,
            "--field",
            field,
            "--metric",
            metric,
            "--format",
            "json",
        ]
        proc = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE)
        query_path.write_text(proc.stdout, encoding="utf-8")
        data = json.loads(proc.stdout)

    entries: list[Entry] = []
    seen: set[tuple[str, str, str, float]] = set()
    for item in flatten_query_json(data):
        if item.get("type") != "interconnect":
            continue
        raw_from = str(item.get("from_pin", ""))
        raw_to = str(item.get("to_pin", ""))
        value = delay_value(item, field, metric)
        if value is None:
            continue
        from_pin = clean_pin(raw_from)
        to_pin = clean_pin(raw_to)
        combined_pins = f"{from_pin} {to_pin}"
        if CONSTANT_DRIVER_RE.search(combined_pins):
            continue
        if spec.family in ("dq_iologic", "dqs_iologic") and IDELAY_CONTROL_ENDPOINT_RE.search(to_pin):
            continue
        key = (spec.family, from_pin, to_pin, value)
        if key in seen:
            continue
        seen.add(key)
        lane, bit = lane_bit(combined_pins)
        entries.append(
            Entry(
                sample=sample.label,
                status=sample.status,
                family=spec.family,
                from_pin=from_pin,
                to_pin=to_pin,
                graph_from_pin=raw_from,
                graph_to_pin=raw_to,
                delay_ps=value,
                lane=lane,
                bit=bit,
                control_bit=control_bit(combined_pins),
                endpoint=endpoint_name(to_pin),
            )
        )
    return entries


def direct_rows(entries: list[Entry]) -> list[dict[str, object]]:
    return [
        {
            "sample": entry.sample,
            "status": entry.status,
            "family": entry.family,
            "lane": entry.lane,
            "bit": entry.bit,
            "control_bit": entry.control_bit,
            "endpoint": entry.endpoint,
            "delay_ps": entry.delay_ps,
            "from_pin": entry.from_pin,
            "to_pin": entry.to_pin,
            "graph_from_pin": entry.graph_from_pin,
            "graph_to_pin": entry.graph_to_pin,
        }
        for entry in sorted(entries, key=lambda item: (item.sample, item.family, item.lane, item.bit, item.control_bit, item.delay_ps))
    ]


def add_metric_row(
    rows: list[dict[str, object]],
    sample: str,
    status: str,
    metric: str,
    family: str,
    lane: str,
    bit: str,
    control: str,
    scope: str,
    values: list[float],
) -> None:
    row = {
        "sample": sample,
        "status": status,
        "metric": metric,
        "family": family,
        "lane": lane,
        "bit": bit,
        "control_bit": control,
        "scope": scope,
    }
    row.update(stats(values))
    row["value_ps"] = metric_value(row)
    rows.append(row)


def build_semantic_metrics(entries: list[Entry]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    groups: dict[tuple[str, str, str, str, str, str, str, str], list[float]] = {}

    for entry in entries:
        key = (entry.sample, entry.status, "direct_max", entry.family, entry.lane, entry.bit, entry.control_bit, "endpoint")
        groups.setdefault(key, []).append(entry.delay_ps)

        lane_key = (entry.sample, entry.status, "lane_spread", entry.family, entry.lane, "", "", "lane")
        groups.setdefault(lane_key, []).append(entry.delay_ps)

        if entry.control_bit:
            fanout_key = (entry.sample, entry.status, "control_fanout_spread", entry.family, entry.lane, "", entry.control_bit, "lane_control_bit")
            groups.setdefault(fanout_key, []).append(entry.delay_ps)

    for key, values in groups.items():
        sample, status, metric, family, lane, bit, control, scope = key
        add_metric_row(rows, sample, status, metric, family, lane, bit, control, scope, values)

    bus_groups: dict[tuple[str, str, str, str, str, str, str, str], list[float]] = {}
    for entry in entries:
        if entry.family not in ("idelay_data_cntvaluein", "idelay_dqs_cntvaluein"):
            continue
        metric = "cntvaluein_bus_skew"
        key = (entry.sample, entry.status, metric, entry.family, entry.lane, entry.bit, "", entry.endpoint.split(".")[0])
        bus_groups.setdefault(key, []).append(entry.delay_ps)
    for key, values in bus_groups.items():
        if len(values) < 2:
            continue
        sample, status, metric, family, lane, bit, control, scope = key
        add_metric_row(rows, sample, status, metric, family, lane, bit, control, scope, values)

    return sorted(rows, key=lambda row: (str(row["metric"]), str(row["family"]), str(row["lane"]), str(row["bit"]), str(row["control_bit"]), str(row["sample"])))


def population_summary(metric_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    grouped: dict[tuple[str, str, str, str, str, str], dict[str, list[float]]] = {}
    for row in metric_rows:
        value = metric_value(row)
        if value is None:
            continue
        key = (
            str(row["metric"]),
            str(row["family"]),
            str(row["lane"]),
            str(row["bit"]),
            str(row["control_bit"]),
            str(row["scope"]),
        )
        grouped.setdefault(key, {}).setdefault(str(row["status"]), []).append(value)

    rows: list[dict[str, object]] = []
    for key, by_status in grouped.items():
        metric, family, lane, bit, control, scope = key
        out: dict[str, object] = {
            "metric": metric,
            "family": family,
            "lane": lane,
            "bit": bit,
            "control_bit": control,
            "scope": scope,
        }
        status_stats: dict[str, dict[str, float | int | None]] = {}
        for status in sorted(set(STATUS_COLUMNS) | set(by_status)):
            s = stats(by_status.get(status, []))
            status_stats[status] = s
            out[f"{status}_count"] = s["count"]
            out[f"{status}_min_ps"] = s["min_ps"]
            out[f"{status}_median_ps"] = s["median_ps"]
            out[f"{status}_max_ps"] = s["max_ps"]

        fail_median = status_stats.get("fail", {}).get("median_ps")
        pass_median = status_stats.get("pass", {}).get("median_ps")
        robust_median = status_stats.get("robust", {}).get("median_ps")
        fail_min = status_stats.get("fail", {}).get("min_ps")
        pass_max = status_stats.get("pass", {}).get("max_ps")
        if isinstance(fail_median, (int, float)) and isinstance(pass_median, (int, float)):
            out["fail_minus_pass_median_ps"] = fail_median - pass_median
        else:
            out["fail_minus_pass_median_ps"] = None
        if isinstance(fail_min, (int, float)) and isinstance(pass_max, (int, float)):
            out["fail_min_minus_pass_max_ps"] = fail_min - pass_max
        else:
            out["fail_min_minus_pass_max_ps"] = None
        if isinstance(robust_median, (int, float)) and isinstance(fail_median, (int, float)):
            out["robust_minus_fail_median_ps"] = robust_median - fail_median
        else:
            out["robust_minus_fail_median_ps"] = None
        rows.append(out)

    return sorted(
        rows,
        key=lambda row: (
            abs(float(row["fail_minus_pass_median_ps"])) if row.get("fail_minus_pass_median_ps") not in (None, "") else -1.0,
            abs(float(row["fail_min_minus_pass_max_ps"])) if row.get("fail_min_minus_pass_max_ps") not in (None, "") else -1.0,
        ),
        reverse=True,
    )


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def shell_quote(value: str | Path) -> str:
    return shlex.quote(str(value))


def rank_path_lines(entries: list[Entry], samples: list[Sample], sdf_toolkit: str, header: str) -> list[str]:
    sample_by_label = {sample.label: sample for sample in samples}
    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        "# Generated from DDR-focused SDF query results.",
        f"# {header}",
        "",
    ]
    for index, entry in enumerate(entries, start=1):
        sample = sample_by_label[entry.sample]
        lines.append(f"echo '## {index}: {entry.sample} {entry.status} {entry.family} {entry.lane} {entry.bit} {entry.control_bit} {entry.delay_ps} ps'")
        lines.append(
            " ".join(
                [
                    shell_quote(sdf_toolkit),
                    "rank-paths",
                    shell_quote(sample.sdf),
                    shell_quote(entry.graph_from_pin),
                    shell_quote(entry.graph_to_pin),
                    "--limit",
                    "10",
                ]
            )
        )
        lines.append("")
    return lines


def write_rank_path_commands(out_dir: Path, entries: list[Entry], samples: list[Sample], sdf_toolkit: str, limit: int) -> None:
    selected = sorted(entries, key=lambda item: item.delay_ps, reverse=True)[:limit]
    script = out_dir / "rank_path_outliers.sh"
    script.write_text(
        "\n".join(rank_path_lines(selected, samples, sdf_toolkit, "Highest-delay selected endpoint records.")),
        encoding="utf-8",
    )
    script.chmod(0o755)


def write_fail_slower_rank_path_commands(
    out_dir: Path,
    entries: list[Entry],
    samples: list[Sample],
    sdf_toolkit: str,
    candidates: list[dict[str, object]],
    limit: int,
) -> None:
    selected: list[Entry] = []
    seen: set[tuple[str, str, str, str]] = set()
    for candidate in candidates:
        if candidate.get("metric") != "direct_max":
            continue
        family = str(candidate.get("family", ""))
        lane = str(candidate.get("lane", ""))
        bit = str(candidate.get("bit", ""))
        control = str(candidate.get("control_bit", ""))
        matches = [
            entry for entry in entries
            if entry.status == "fail"
            and entry.family == family
            and entry.lane == lane
            and entry.bit == bit
            and entry.control_bit == control
        ]
        for entry in sorted(matches, key=lambda item: item.delay_ps, reverse=True):
            key = (entry.sample, entry.from_pin, entry.to_pin, entry.family)
            if key in seen:
                continue
            seen.add(key)
            selected.append(entry)
            if len(selected) >= limit:
                break
        if len(selected) >= limit:
            break
    script = out_dir / "rank_path_fail_slower.sh"
    script.write_text(
        "\n".join(rank_path_lines(selected, samples, sdf_toolkit, "Strict fail-slower candidate endpoints.")),
        encoding="utf-8",
    )
    script.chmod(0o755)


def write_readme(out_dir: Path, samples: list[Sample], population_rows: list[dict[str, object]], direct_count: int) -> None:
    top = population_rows[:20]
    lines = [
        "# UberDDR3 SDF Metrics",
        "",
        "This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.",
        "",
        "## Inputs",
        "",
    ]
    for sample in samples:
        lines.append(f"- `{sample.label}` status `{sample.status}`: `{sample.sdf}`")
    lines.extend(
        [
            "",
            "## Outputs",
            "",
            "- `query-json/`: raw first-stage `sdf-toolkit query` JSON per sample/family.",
            "- `direct_entries.csv`: normalized DDR-relevant interconnect entries.",
            "- `semantic_metrics.csv`: per-sample endpoint, lane, fanout, and bus-skew metrics.",
            "- `population_summary.csv`: pass/fail/robust population comparison by semantic metric key.",
            "- `candidate_separators.csv`: population rows with both fail and pass samples, sorted by separation.",
            "- `candidate_fail_slower.csv`: candidates where failing seeds have higher median delay/skew than passing seeds.",
            "- `candidate_strict_fail_slower.csv`: fail-slower candidates where every failing value is above every passing value.",
            "- `rank_path_outliers.sh`: exact `sdf-toolkit rank-paths` commands for the highest-delay selected endpoints.",
            "- `rank_path_fail_slower.sh`: exact `sdf-toolkit rank-paths` commands for strict fail-slower endpoint candidates.",
            "",
            f"Normalized direct entries: `{direct_count}`",
            "",
            "## Top Fail-Slower Candidate Separators",
            "",
        ]
    )
    for row in top:
        delta = row.get("fail_minus_pass_median_ps")
        if delta in (None, ""):
            continue
        lines.append(
            f"- `{row['metric']}` `{row['family']}` `{row['lane']}` `{row['bit']}` "
            f"`ctrl={row['control_bit']}` fail-pass median `{delta}` ps"
        )
    (out_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample", action="append", type=parse_sample, required=True, help="LABEL:STATUS:SDF_OR_DIR[:PLACED_JSON]. Repeat for each seed.")
    parser.add_argument("--out-dir", type=Path, default=Path("artifacts/sdf-metrics"))
    parser.add_argument("--sdf-toolkit", default="sdf-toolkit")
    parser.add_argument("--field", default="slow")
    parser.add_argument("--metric", default="max")
    parser.add_argument("--reuse-cache", action="store_true")
    parser.add_argument("--rank-limit", type=int, default=60)
    args = parser.parse_args()

    samples: list[Sample] = args.sample

    args.out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema": "uberddr3-sdf-metrics-v1",
        "field": args.field,
        "metric": args.metric,
        "samples": [
            {
                "label": sample.label,
                "status": sample.status,
                "sdf": str(sample.sdf),
                "placed_json": str(sample.placed_json) if sample.placed_json else None,
            }
            for sample in samples
        ],
        "queries": [spec.__dict__ for spec in QUERY_SPECS],
    }
    (args.out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    all_entries: list[Entry] = []
    for sample in samples:
        if not sample.sdf.exists():
            raise FileNotFoundError(sample.sdf)
        print(f"query {sample.label} ({sample.status}) {sample.sdf}", file=sys.stderr)
        for spec in QUERY_SPECS:
            entries = run_query(args.sdf_toolkit, sample, spec, args.out_dir, args.field, args.metric, args.reuse_cache)
            print(f"  {spec.family}: {len(entries)} entries", file=sys.stderr)
            all_entries.extend(entries)

    direct = direct_rows(all_entries)
    semantic = build_semantic_metrics(all_entries)
    population = population_summary(semantic)
    candidates = [row for row in population if row.get("fail_count", 0) and row.get("pass_count", 0)]
    fail_slower = [
        row for row in candidates
        if row.get("fail_minus_pass_median_ps") not in (None, "") and float(row["fail_minus_pass_median_ps"]) > 0
    ]
    strict_fail_slower = [
        row for row in fail_slower
        if row.get("fail_min_minus_pass_max_ps") not in (None, "") and float(row["fail_min_minus_pass_max_ps"]) > 0
    ]

    write_csv(
        args.out_dir / "direct_entries.csv",
        direct,
        ["sample", "status", "family", "lane", "bit", "control_bit", "endpoint", "delay_ps", "from_pin", "to_pin", "graph_from_pin", "graph_to_pin"],
    )
    write_csv(
        args.out_dir / "semantic_metrics.csv",
        semantic,
        [
            "sample",
            "status",
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
            "value_ps",
        ],
    )
    pop_fields = [
        "metric",
        "family",
        "lane",
        "bit",
        "control_bit",
        "scope",
    ]
    for status in sorted(set(STATUS_COLUMNS) | {sample.status for sample in samples}):
        pop_fields.extend([f"{status}_count", f"{status}_min_ps", f"{status}_median_ps", f"{status}_max_ps"])
    pop_fields.extend(["fail_minus_pass_median_ps", "fail_min_minus_pass_max_ps", "robust_minus_fail_median_ps"])
    write_csv(args.out_dir / "population_summary.csv", population, pop_fields)
    write_csv(args.out_dir / "candidate_separators.csv", candidates, pop_fields)
    write_csv(args.out_dir / "candidate_fail_slower.csv", fail_slower, pop_fields)
    write_csv(args.out_dir / "candidate_strict_fail_slower.csv", strict_fail_slower, pop_fields)
    write_rank_path_commands(args.out_dir, all_entries, samples, args.sdf_toolkit, args.rank_limit)
    write_fail_slower_rank_path_commands(args.out_dir, all_entries, samples, args.sdf_toolkit, strict_fail_slower or fail_slower, args.rank_limit)
    write_readme(args.out_dir, samples, strict_fail_slower or fail_slower or candidates, len(direct))

    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
