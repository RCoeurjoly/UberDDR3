#!/usr/bin/env python3
"""Run focused sdf-toolkit rank-paths checks for semantic DDR SDF candidates."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
from typing import Iterable


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


def status_is_direct(candidate: dict[str, str]) -> bool:
    return candidate.get("metric") == "direct_max"


def parse_manifest(metrics_dir: Path) -> dict[str, Path]:
    manifest_path = metrics_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    samples = manifest.get("samples", [])
    out: dict[str, Path] = {}
    for sample in samples:
        label = str(sample["label"])
        out[label] = Path(str(sample["sdf"]))
    return out


def safe_name(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", text).strip("_")


def semantic_key(row: dict[str, str]) -> tuple[str, str, str, str]:
    return (
        row.get("family", ""),
        row.get("lane", ""),
        row.get("bit", ""),
        row.get("control_bit", ""),
    )


def candidate_label(candidate: dict[str, str]) -> str:
    family, lane, bit, control = semantic_key(candidate)
    parts = [family, lane]
    if bit:
        parts.append(bit)
    if control:
        parts.append(f"ctrl{control}")
    return " ".join(parts)


def row_delay(row: dict[str, str]) -> float:
    return float(row.get("delay_ps", "nan"))


def match_direct_entries(
    direct_entries: Iterable[dict[str, str]],
    candidate: dict[str, str],
) -> list[dict[str, str]]:
    family, lane, bit, control = semantic_key(candidate)
    matches = []
    for row in direct_entries:
        if row.get("family", "") != family:
            continue
        if row.get("lane", "") != lane:
            continue
        if row.get("bit", "") != bit:
            continue
        if row.get("control_bit", "") != control:
            continue
        matches.append(row)
    return matches


def worst_by_sample(rows: Iterable[dict[str, str]]) -> list[dict[str, str]]:
    best: dict[str, dict[str, str]] = {}
    for row in rows:
        sample = row["sample"]
        if sample not in best or row_delay(row) > row_delay(best[sample]):
            best[sample] = row
    return [best[key] for key in sorted(best)]


def select_candidates(
    candidates: list[dict[str, str]],
    families: set[str],
    limit: int,
) -> list[dict[str, str]]:
    selected = []
    seen: set[tuple[str, str, str, str]] = set()
    for candidate in candidates:
        if not status_is_direct(candidate):
            continue
        if families and candidate.get("family", "") not in families:
            continue
        key = semantic_key(candidate)
        if key in seen:
            continue
        seen.add(key)
        selected.append(candidate)
        if len(selected) >= limit:
            break
    return selected


def run_rank_path(
    sdf_toolkit: list[str],
    sdf: Path,
    source: str,
    sink: str,
    limit: int,
) -> subprocess.CompletedProcess[str]:
    cmd = [*sdf_toolkit, "rank-paths", str(sdf), source, sink, "--limit", str(limit)]
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metrics-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--candidate-csv", type=Path)
    parser.add_argument("--direct-entries", type=Path)
    parser.add_argument("--sdf-toolkit", default="sdf-toolkit", help="Executable or command prefix, for example 'nix run .#sdf-toolkit --'.")
    parser.add_argument("--family", action="append", default=[])
    parser.add_argument("--limit-candidates", type=int, default=8)
    parser.add_argument("--rank-limit", type=int, default=10)
    args = parser.parse_args()

    candidate_csv = args.candidate_csv or args.metrics_dir / "candidate_strict_fail_slower.csv"
    direct_entries_path = args.direct_entries or args.metrics_dir / "direct_entries.csv"
    candidates = read_csv(candidate_csv)
    direct_entries = read_csv(direct_entries_path)
    sample_sdfs = parse_manifest(args.metrics_dir)
    sdf_toolkit = shlex.split(args.sdf_toolkit)

    selected = select_candidates(candidates, set(args.family), args.limit_candidates)
    if not selected:
        raise SystemExit("no matching direct_max candidates selected")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    summary_rows: list[dict[str, object]] = []
    selected_rows: list[dict[str, object]] = []

    for candidate_index, candidate in enumerate(selected, start=1):
        label = candidate_label(candidate)
        selected_rows.append(
            {
                "candidate_index": candidate_index,
                "label": label,
                "family": candidate.get("family", ""),
                "lane": candidate.get("lane", ""),
                "bit": candidate.get("bit", ""),
                "control_bit": candidate.get("control_bit", ""),
                "fail_minus_pass_median_ps": candidate.get("fail_minus_pass_median_ps", ""),
                "fail_min_minus_pass_max_ps": candidate.get("fail_min_minus_pass_max_ps", ""),
            }
        )

        rows = worst_by_sample(match_direct_entries(direct_entries, candidate))
        for row in rows:
            sample = row["sample"]
            sdf = sample_sdfs[sample]
            out_name = safe_name(f"{candidate_index:02d}_{sample}_{label}.txt")
            out_path = args.out_dir / out_name
            proc = run_rank_path(
                sdf_toolkit,
                sdf,
                row["graph_from_pin"],
                row["graph_to_pin"],
                args.rank_limit,
            )
            command_text = " ".join(
                shlex.quote(part)
                for part in [
                    *sdf_toolkit,
                    "rank-paths",
                    str(sdf),
                    row["graph_from_pin"],
                    row["graph_to_pin"],
                    "--limit",
                    str(args.rank_limit),
                ]
            )
            out_path.write_text(
                "\n".join(
                    [
                        f"# candidate: {candidate_index} {label}",
                        f"# sample: {sample} ({row['status']})",
                        f"# direct_delay_ps: {row['delay_ps']}",
                        f"# from_pin: {row['from_pin']}",
                        f"# to_pin: {row['to_pin']}",
                        f"# command: {command_text}",
                        "",
                        proc.stdout,
                        "## stderr",
                        proc.stderr,
                    ]
                ),
                encoding="utf-8",
            )
            summary_rows.append(
                {
                    "candidate_index": candidate_index,
                    "label": label,
                    "sample": sample,
                    "status": row["status"],
                    "direct_delay_ps": row["delay_ps"],
                    "returncode": proc.returncode,
                    "output_file": out_name,
                    "from_pin": row["from_pin"],
                    "to_pin": row["to_pin"],
                }
            )
            print(f"{candidate_index}: {sample} {label} {row['delay_ps']} ps rc={proc.returncode}", file=sys.stderr)

    write_csv(
        args.out_dir / "selected_candidates.csv",
        selected_rows,
        [
            "candidate_index",
            "label",
            "family",
            "lane",
            "bit",
            "control_bit",
            "fail_minus_pass_median_ps",
            "fail_min_minus_pass_max_ps",
        ],
    )
    write_csv(
        args.out_dir / "rank_summary.csv",
        summary_rows,
        [
            "candidate_index",
            "label",
            "sample",
            "status",
            "direct_delay_ps",
            "returncode",
            "output_file",
            "from_pin",
            "to_pin",
        ],
    )
    readme_lines = [
        "# Exact-Abort Seed3 Focused SDF Rankings",
        "",
        "This artifact runs `sdf-toolkit rank-paths` only for strict fail-slower DDR candidates from the exact-abort seed3 pass/pass/fail matrix.",
        "",
        "Each candidate is a semantic key from `candidate_strict_fail_slower.csv`. For every sample, the ranked source/sink is that sample's own worst direct entry for the same semantic key, so the comparison survives synthesized temporary name churn.",
        "",
        "## Files",
        "",
        "- `selected_candidates.csv`: semantic candidates selected for ranking.",
        "- `rank_summary.csv`: sample-specific ranked endpoints and direct SDF delays.",
        "- `*.txt`: raw `sdf-toolkit rank-paths` output for each candidate/sample pair.",
        "",
        "## Interpretation Rule",
        "",
        "Use these outputs to identify the internal cells and route segments behind a semantic delay correlate. The direct delay value remains the cross-sample metric; rank output is the explanation of which graph path produced it.",
        "",
    ]
    (args.out_dir / "README.md").write_text("\n".join(readme_lines), encoding="utf-8")
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
