#!/usr/bin/env python3
"""Run YPCB DDR3 board tests for each row in a build manifest."""

from __future__ import annotations

import argparse
import csv
import subprocess
from pathlib import Path


STATUS_FIELDS = [
    "experiment_id",
    "seed",
    "variant",
    "bitstream",
    "result_json",
    "log",
    "returncode",
    "status",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_status(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATUS_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in STATUS_FIELDS})


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--board-test", type=Path, default=Path("example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py"))
    parser.add_argument("--poll-count", type=int, default=500)
    parser.add_argument("--poll-interval", type=float, default=0.1)
    parser.add_argument("--skip-existing", action="store_true")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    status_rows: list[dict[str, object]] = []
    status_path = args.out_dir / "sweep_status.csv"

    for row in read_csv(args.manifest):
        experiment_id = row["experiment_id"]
        result_json = args.out_dir / f"{experiment_id}.json"
        log_path = args.out_dir / f"{experiment_id}.log"
        bitstream = row["bitstream_file"]

        if args.skip_existing and result_json.exists():
            status_rows.append(
                {
                    "experiment_id": experiment_id,
                    "seed": row["seed"],
                    "variant": row["variant"],
                    "bitstream": bitstream,
                    "result_json": result_json,
                    "log": log_path,
                    "returncode": "",
                    "status": "skipped_existing",
                }
            )
            write_status(status_path, status_rows)
            continue

        command = [
            "python3",
            str(args.board_test),
            "--bitstream",
            bitstream,
            "--output",
            str(result_json),
            "--poll-count",
            str(args.poll_count),
            "--poll-interval",
            str(args.poll_interval),
        ]
        completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        log_path.write_text(completed.stdout, encoding="utf-8")
        status_rows.append(
            {
                "experiment_id": experiment_id,
                "seed": row["seed"],
                "variant": row["variant"],
                "bitstream": bitstream,
                "result_json": result_json,
                "log": log_path,
                "returncode": completed.returncode,
                "status": "pass" if completed.returncode == 0 else "fail",
            }
        )
        write_status(status_path, status_rows)
        print(f"{experiment_id}: rc={completed.returncode}")

    (args.out_dir / "README.md").write_text(
        "\n".join(
            [
                "# Seed 31..60 Baseline/CNTVALUEIN3-Lock Hardware Sweep",
                "",
                "This directory contains one board-test JSON result and log per manifest row.",
                "",
                f"- manifest: `{args.manifest}`",
                f"- poll count: `{args.poll_count}`",
                f"- poll interval seconds: `{args.poll_interval}`",
                f"- rows attempted: `{len(status_rows)}`",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(status_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
