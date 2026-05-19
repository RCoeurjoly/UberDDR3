#!/usr/bin/env python3
"""Classify missing PHASER route-oracle features into reduction buckets."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path


def classify(feature: str, route_class: str) -> tuple[str, str]:
    if "_DB_" in feature:
        return (
            "db_or_multilane_context",
            "DB-lane route from the SYSTEST oracle; keep as context until a reduced CA-only oracle still locks.",
        )

    if "CMT_FREQ_BB_PREF_IN0.PLL_CLK_FREQBB_REBUFOUT0" in feature:
        return (
            "clock_source_topology_delta",
            "SYSTEST direct PREF_IN0 source route; compare against the accepted PREF_IN0/1/2 OpenXC7 topology before patching.",
        )

    if route_class == "dedicated-clock" and "_CA_" in feature:
        return (
            "candidate_required_ca_clock",
            "CA-lane dedicated clock/control fanout present in downstream-locking SYSTEST; highest-priority reduced-oracle candidate.",
        )

    if route_class == "hard-macro-control" and "_CA_" in feature:
        return (
            "candidate_ca_control_needs_reduction",
            "CA-lane control route present in SYSTEST; only patch after reduced oracle proves it is not compact-only noise.",
        )

    if "PHYCTLMSTREMPTY" in feature or "PHASER_TOP_SYNC_BB" in feature:
        return (
            "phy_control_topology_context",
            "PHY_CONTROL/PHASER top-level internal route; needs separate topology proof before row changes.",
        )

    return (
        "unclassified_active_tile_delta",
        "Active-tile SYSTEST delta not matched by the coarse rules; inspect manually before any patch.",
    )


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, payload: dict) -> None:
    lines = [
        "# PHASER Missing Route Classification",
        "",
        "## Summary",
        "",
    ]
    for bucket, count in payload["bucket_counts"].items():
        lines.append(f"- `{bucket}`: `{count}`")
    lines.extend(["", "## Buckets", ""])
    for bucket in payload["buckets"]:
        lines.append(f"### {bucket['bucket']}")
        lines.append("")
        lines.append(bucket["reason"])
        lines.append("")
        for item in bucket["routes"]:
            lines.append(f"- `{item['class']}` `{item['feature']}`")
        lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--comparison-json", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--md-out", type=Path, required=True)
    args = parser.parse_args()

    comparison = json.loads(args.comparison_json.read_text(encoding="utf-8"))
    classified = []
    bucket_reasons: dict[str, str] = {}
    counts: Counter[str] = Counter()
    for route in comparison["missing_routes"]:
        bucket, reason = classify(route["feature"], route["class"])
        item = dict(route)
        item["bucket"] = bucket
        item["bucket_reason"] = reason
        classified.append(item)
        bucket_reasons.setdefault(bucket, reason)
        counts[bucket] += 1

    buckets = []
    for bucket in sorted(counts):
        buckets.append(
            {
                "bucket": bucket,
                "count": counts[bucket],
                "reason": bucket_reasons[bucket],
                "routes": [item for item in classified if item["bucket"] == bucket],
            }
        )

    payload = {
        "input": str(args.comparison_json),
        "total_missing_routes": len(classified),
        "bucket_counts": dict(sorted(counts.items())),
        "buckets": buckets,
        "routes": classified,
    }
    write_json(args.json_out, payload)
    write_markdown(args.md_out, payload)
    print(f"wrote {args.json_out}")
    print(f"wrote {args.md_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
