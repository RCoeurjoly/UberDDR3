#!/usr/bin/env python3
"""Render focused plots for the current UberDDR3 root-cause hypothesis."""

from __future__ import annotations

import argparse
import csv
import shutil
import subprocess
from pathlib import Path

import numpy as np


MATRIX = Path("artifacts/statistical-sdf/multivariate-ddr3-causality-analysis/bitstream_feature_matrix.csv")
OUT_DIR = Path("artifacts/statistical-sdf/root-cause-hypothesis-plots")

DQS_DQ = "skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq14_ctrl_3_dqs_vs_dq_bit_value_ps"
LD_CNT = "skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane1_no_bit_ctrl_0_ld_vs_cntvaluein_dq_lane_value_ps"
LANE_MISMATCH = "skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps"

FEATURE_LABELS = {
    DQS_DQ: "lane1 dq14 ctrl3 abs DQS-DQ skew",
    LD_CNT: "lane1 ctrl0 abs LD-CNTVALUEIN skew",
    LANE_MISMATCH: "ctrl2 signed lane1-lane0 DQ median skew",
}


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


def fnum(value: float) -> float:
    return round(float(value), 6)


def zscore(values: np.ndarray) -> np.ndarray:
    std = values.std()
    if std == 0:
        return np.zeros_like(values)
    return (values - values.mean()) / std


def load_points() -> list[dict[str, object]]:
    rows = read_csv(MATRIX)
    required = [DQS_DQ, LD_CNT, LANE_MISMATCH]
    missing = [name for name in required if name not in rows[0]] if rows else required
    if missing:
        raise SystemExit(f"missing matrix columns: {missing}")

    raw = []
    for row in rows:
        try:
            dqs_dq = float(row[DQS_DQ])
            ld_cnt = float(row[LD_CNT])
            lane_mismatch = float(row[LANE_MISMATCH])
        except ValueError:
            continue
        passed = row.get("hardware_pass", "").lower() == "true"
        raw.append((row, dqs_dq, ld_cnt, lane_mismatch, passed))

    dqs_z = zscore(np.array([item[1] for item in raw], dtype=float))
    ld_z = zscore(np.array([item[2] for item in raw], dtype=float))
    lane_z = zscore(np.array([item[3] for item in raw], dtype=float))
    ld_raw = np.array([item[2] for item in raw], dtype=float)
    ld_min = ld_raw.min()
    ld_span = max(1.0, ld_raw.max() - ld_min)

    out = []
    for idx, (item, dz, ldz, lmz) in enumerate(zip(raw, dqs_z, ld_z, lane_z)):
        row, dqs_dq, ld_cnt, lane_mismatch, passed = item
        capture_lane_score = dz + lmz
        combined_score = dz + ldz + lmz
        point_size = 0.7 + 1.8 * ((ld_cnt - ld_min) / ld_span)
        out.append(
            {
                "experiment_id": row.get("experiment_id", ""),
                "seed": row.get("seed", ""),
                "run_group": row.get("run_group", ""),
                "variant": row.get("variant", ""),
                "abort_reason": row.get("abort_reason", ""),
                "status": "pass" if passed else "fail",
                "lane_mismatch_ps": fnum(lane_mismatch),
                "dqs_dq_ps": fnum(dqs_dq),
                "ld_cntvaluein_ps": fnum(ld_cnt),
                "ld_point_size": fnum(point_size),
                "capture_lane_score_z": fnum(capture_lane_score),
                "ld_score_z": fnum(ldz),
                "combined_score_z": fnum(combined_score),
                "pass_lane_mismatch_ps": fnum(lane_mismatch) if passed else "",
                "pass_dqs_dq_ps": fnum(dqs_dq) if passed else "",
                "pass_ld_size": fnum(point_size) if passed else "",
                "fail_lane_mismatch_ps": fnum(lane_mismatch) if not passed else "",
                "fail_dqs_dq_ps": fnum(dqs_dq) if not passed else "",
                "fail_ld_size": fnum(point_size) if not passed else "",
                "pass_capture_lane_score_z": fnum(capture_lane_score) if passed else "",
                "pass_ld_score_z": fnum(ldz) if passed else "",
                "fail_capture_lane_score_z": fnum(capture_lane_score) if not passed else "",
                "fail_ld_score_z": fnum(ldz) if not passed else "",
                "pass_combined_score_z": fnum(combined_score) if passed else "",
                "fail_combined_score_z": fnum(combined_score) if not passed else "",
            }
        )
    return out


def write_raw_scatter(out_dir: Path, rows: list[dict[str, object]]) -> dict[str, str]:
    dat = out_dir / "root_cause_raw_3factor.dat"
    gp = out_dir / "root_cause_raw_3factor.gp"
    png = out_dir / "root_cause_raw_3factor.png"
    write_csv(
        dat,
        rows,
        [
            "lane_mismatch_ps",
            "dqs_dq_ps",
            "ld_point_size",
            "pass_lane_mismatch_ps",
            "pass_dqs_dq_ps",
            "pass_ld_size",
            "fail_lane_mismatch_ps",
            "fail_dqs_dq_ps",
            "fail_ld_size",
            "ld_cntvaluein_ps",
            "seed",
            "variant",
            "abort_reason",
            "experiment_id",
        ],
    )
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1300,880 enhanced font 'DejaVu Sans,10'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid",
                "set xlabel 'signed lane1-lane0 DQ median skew, ctrl2 (ps)'",
                "set ylabel 'lane1 dq14 ctrl3 abs DQS-DQ skew (ps)'",
                "set title 'UberDDR3 root-cause hypothesis: lane mismatch + DQS/DQ skew; point size = LD-CNTVALUEIN skew'",
                "plot \\",
                f"  '{dat.name}' using 4:5:6 with points pt 7 ps variable lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 7:8:9 with points pt 7 ps variable lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {"plot": "root_cause_raw_3factor", "dat": str(dat), "gp": str(gp), "png": str(png)}


def write_score_scatter(out_dir: Path, rows: list[dict[str, object]]) -> dict[str, str]:
    dat = out_dir / "root_cause_combined_score.dat"
    gp = out_dir / "root_cause_combined_score.gp"
    png = out_dir / "root_cause_combined_score.png"
    write_csv(
        dat,
        rows,
        [
            "capture_lane_score_z",
            "ld_score_z",
            "pass_capture_lane_score_z",
            "pass_ld_score_z",
            "fail_capture_lane_score_z",
            "fail_ld_score_z",
            "combined_score_z",
            "seed",
            "variant",
            "abort_reason",
            "experiment_id",
        ],
    )
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1300,880 enhanced font 'DejaVu Sans,10'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid",
                "set xlabel 'capture/lane score z = z(DQS-DQ) + z(lane mismatch)'",
                "set ylabel 'LD-CNTVALUEIN score z'",
                "set title 'UberDDR3 combined IDELAY programming/capture margin hypothesis'",
                "set arrow 1 from 0, graph 0 to 0, graph 1 nohead lw 2 lc rgb '#777777' dt 2",
                "set arrow 2 from graph 0, 0 to graph 1, 0 nohead lw 2 lc rgb '#777777' dt 2",
                "plot \\",
                f"  '{dat.name}' using 3:4 with points pt 7 ps 1.25 lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 5:6 with points pt 7 ps 1.25 lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {"plot": "root_cause_combined_score", "dat": str(dat), "gp": str(gp), "png": str(png)}


def write_score_distribution(out_dir: Path, rows: list[dict[str, object]]) -> dict[str, str]:
    dat = out_dir / "root_cause_score_distribution.dat"
    gp = out_dir / "root_cause_score_distribution.gp"
    png = out_dir / "root_cause_score_distribution.png"
    points = []
    for row in rows:
        x = 1 if row["status"] == "pass" else 2
        # deterministic jitter from experiment_id
        jitter = ((sum((i + 1) * ord(c) for i, c in enumerate(str(row["experiment_id"]))) % 1000) / 1000.0 - 0.5) * 0.24
        points.append({**row, "x": round(x + jitter, 6), "pass_score": row["combined_score_z"] if row["status"] == "pass" else "", "fail_score": row["combined_score_z"] if row["status"] == "fail" else ""})
    write_csv(dat, points, ["x", "combined_score_z", "pass_score", "fail_score", "status", "seed", "variant", "abort_reason", "experiment_id"])
    gp.write_text(
        "\n".join(
            [
                "set terminal pngcairo size 1100,760 enhanced font 'DejaVu Sans,10'",
                f"set output '{png.name}'",
                "set datafile separator comma",
                "set key outside right top",
                "set grid ytics",
                "set xrange [0.45:2.55]",
                "set xtics ('pass' 1, 'fail' 2)",
                "set xlabel 'Hardware outcome'",
                "set ylabel 'combined margin-loss score z'",
                "set title 'UberDDR3 root-cause hypothesis combined score distribution'",
                "plot \\",
                f"  '{dat.name}' using 1:3 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \\",
                f"  '{dat.name}' using 1:4 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {"plot": "root_cause_score_distribution", "dat": str(dat), "gp": str(gp), "png": str(png)}


def write_readme(out_dir: Path, rows: list[dict[str, object]], plots: list[dict[str, str]]) -> None:
    pass_scores = [float(r["combined_score_z"]) for r in rows if r["status"] == "pass"]
    fail_scores = [float(r["combined_score_z"]) for r in rows if r["status"] == "fail"]
    readme = [
        "# UberDDR3 Root-Cause Hypothesis Plots",
        "",
        "Hypothesis visualized here: DDR3 failures are caused by combined IDELAY programming/capture margin loss: CNTVALUEIN/LD timing quality plus DQS/DQ skew plus lane-to-lane mismatch.",
        "",
        "## Features",
        "",
        f"- DQS/DQ skew: `{DQS_DQ}`",
        f"- LD/CNTVALUEIN skew: `{LD_CNT}`",
        f"- lane mismatch: `{LANE_MISMATCH}`",
        "",
        "## Combined Score",
        "",
        "The combined score is `z(DQS/DQ skew) + z(LD-CNTVALUEIN skew) + z(lane mismatch)`, with signs chosen from the current strongest failure-direction hypotheses. Higher is interpreted as worse combined margin.",
        "",
        f"- pass median score: `{np.median(pass_scores):.3f}`",
        f"- fail median score: `{np.median(fail_scores):.3f}`",
        f"- samples: `{len(rows)}`",
        "",
        "## Plots",
        "",
    ]
    for plot in plots:
        readme.append(f"- `{Path(plot['png']).name}`")
    readme.extend(
        [
            "",
            "Interpretation: these plots visualize the current root-cause hypothesis. They are not causal proof; the proof requires an intervention that moves these features and changes held-out hardware outcomes.",
        ]
    )
    (out_dir / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    parser.add_argument("--render-plots", action="store_true")
    parser.add_argument("--gnuplot", default=shutil.which("gnuplot") or "")
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = load_points()
    write_csv(
        args.out_dir / "root_cause_hypothesis_points.csv",
        rows,
        [
            "experiment_id",
            "seed",
            "run_group",
            "variant",
            "abort_reason",
            "status",
            "lane_mismatch_ps",
            "dqs_dq_ps",
            "ld_cntvaluein_ps",
            "capture_lane_score_z",
            "ld_score_z",
            "combined_score_z",
        ],
    )
    plots = [write_raw_scatter(args.out_dir, rows), write_score_scatter(args.out_dir, rows), write_score_distribution(args.out_dir, rows)]
    if args.render_plots and args.gnuplot:
        for plot in plots:
            subprocess.run([args.gnuplot, Path(plot["gp"]).name], cwd=args.out_dir, check=True)
    write_csv(args.out_dir / "plot_manifest.csv", plots, ["plot", "dat", "gp", "png"])
    write_readme(args.out_dir, rows, plots)
    print(args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
