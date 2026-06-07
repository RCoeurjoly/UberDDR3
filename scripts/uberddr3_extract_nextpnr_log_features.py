#!/usr/bin/env python3
"""Extract nextpnr timing/warning features from Nix build logs for UberDDR3 sweeps."""

from __future__ import annotations

import argparse
import csv
import re
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Any

DRV_RE = re.compile(r"/nix/store/[^\s']+-ypcb-ddr3-nextpnr-json[^\s']+\.drv")
MAX_FREQ_RE = re.compile(r"Max frequency for clock\s+'?([^':]+)'?:\s+([0-9.]+) MHz \((PASS|FAIL) at ([0-9.]+) MHz\)")
MAX_DELAY_RE = re.compile(r"Max delay\s+(.+?):\s+([0-9.]+) ns")
WIRELEN_RE = re.compile(r"wirelen =\s*([0-9]+)")
CRIT_RE = re.compile(r"Critical path report for (.+):")


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
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


def find_nextpnr_drv(build_log: Path) -> str:
    if not build_log.exists():
        return ""
    text = build_log.read_text(encoding="utf-8", errors="replace")
    matches = DRV_RE.findall(text)
    return matches[0] if matches else ""


def nix_log(drv: str) -> str:
    if not drv:
        return ""
    completed = subprocess.run(["nix", "log", drv], check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return completed.stdout


def safe_clock(clock: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", clock.strip()).strip("_")


def section_lines(lines: list[str], start_index: int) -> list[str]:
    out = []
    for line in lines[start_index + 1:]:
        if "Info: Critical path report for " in line or "Info: Max frequency" in line or "Info: Slack histogram" in line:
            break
        out.append(line)
    return out


def extract_features(log: str) -> dict[str, Any]:
    lines = log.splitlines()
    features: dict[str, Any] = {
        "nextpnr_log_available": bool(log),
        "log_warning_count": sum(1 for line in lines if "Warning:" in line or "warning:" in line),
        "log_error_count": sum(1 for line in lines if "ERROR" in line or "Error:" in line or "error:" in line),
        "log_timing_fail_count": sum(1 for line in lines if "Max frequency for clock" in line and "(FAIL" in line),
        "log_ddr_mention_count": sum(1 for line in lines if "ddr3" in line.lower()),
        "log_idelay_mention_count": sum(1 for line in lines if "idelay" in line.lower()),
        "log_dqs_mention_count": sum(1 for line in lines if "dqs" in line.lower()),
        "log_dq_mention_count": sum(1 for line in lines if "dq" in line.lower()),
    }

    freqs: dict[str, list[tuple[float, str, float]]] = defaultdict(list)
    for line in lines:
        m = MAX_FREQ_RE.search(line)
        if m:
            clock = safe_clock(m.group(1))
            freqs[clock].append((float(m.group(2)), m.group(3), float(m.group(4))))
    for clock, values in freqs.items():
        first = values[0]
        last = values[-1]
        features[f"clock_{clock}_pre_mhz"] = first[0]
        features[f"clock_{clock}_pre_status"] = first[1]
        features[f"clock_{clock}_post_mhz"] = last[0]
        features[f"clock_{clock}_post_status"] = last[1]
        features[f"clock_{clock}_target_mhz"] = last[2]
        features[f"clock_{clock}_post_margin_mhz"] = round(last[0] - last[2], 6)

    delays = []
    for line in lines:
        m = MAX_DELAY_RE.search(line)
        if m:
            delays.append((m.group(1).strip(), float(m.group(2))))
    if delays:
        first = delays[0]
        last = delays[-1]
        features["max_delay_pre_name"] = first[0]
        features["max_delay_pre_ns"] = first[1]
        features["max_delay_post_name"] = last[0]
        features["max_delay_post_ns"] = last[1]

    wirelens = [int(m.group(1)) for line in lines for m in [WIRELEN_RE.search(line)] if m]
    if wirelens:
        features["placer_wirelen_first"] = wirelens[0]
        features["placer_wirelen_last"] = wirelens[-1]
        features["placer_wirelen_delta"] = wirelens[-1] - wirelens[0]

    critical_sections = []
    for index, line in enumerate(lines):
        m = CRIT_RE.search(line)
        if not m:
            continue
        name = m.group(1).strip()
        body = section_lines(lines, index)
        lower = "\n".join(body).lower()
        critical_sections.append(name)
        key = safe_clock(name)[:80]
        features[f"critical_{key}_line_count"] = len(body)
        features[f"critical_{key}_ddr_mentions"] = lower.count("ddr3")
        features[f"critical_{key}_idelay_mentions"] = lower.count("idelay")
        features[f"critical_{key}_dqs_mentions"] = lower.count("dqs")
        features[f"critical_{key}_dq_mentions"] = lower.count("dq")
    features["critical_section_count"] = len(critical_sections)
    features["critical_sections"] = ";".join(critical_sections)
    return features


def representative_rows(status_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    by_seed: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in status_rows:
        by_seed[row.get("seed", "")].append(row)
    reps = []
    for seed, rows in sorted(by_seed.items(), key=lambda kv: int(kv[0]) if kv[0].isdigit() else 0):
        reps.append(rows[0])
    return reps


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sweep_dir", type=Path)
    parser.add_argument("--status-csv", type=Path, help="Defaults to sweep_dir/sweep_status.csv")
    parser.add_argument("--out", type=Path, help="Defaults to sweep_dir/analysis/nextpnr_log_features.csv")
    args = parser.parse_args()

    status_path = args.status_csv or args.sweep_dir / "sweep_status.csv"
    out_path = args.out or args.sweep_dir / "analysis" / "nextpnr_log_features.csv"
    rows = representative_rows(read_csv(status_path))
    out_rows = []
    for row in rows:
        build_log = Path(row.get("build_log", ""))
        drv = find_nextpnr_drv(build_log)
        log = nix_log(drv)
        out_rows.append({
            "seed": row.get("seed", ""),
            "variant": row.get("variant", ""),
            "package": row.get("package", ""),
            "build_log": str(build_log),
            "nextpnr_drv": drv,
            "status_first_repeat": row.get("status", ""),
            "coarse_family_first_repeat": row.get("coarse_family_id", ""),
            "exact_family_first_repeat": row.get("exact_family_id", ""),
            **extract_features(log),
        })
        print(f"seed {row.get('seed', '')}: {drv or 'missing nextpnr drv'}")
    write_csv(out_path, out_rows)
    print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
