#!/usr/bin/env python3
"""Create a build manifest for baseline/CNTVALUEIN3-lock seed pairs."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


VARIANTS = {
    "baseline-no-lock": {
        "suffix": "",
        "lock_set": "none",
        "experiment_prefix": "baseline-no-lock",
    },
    "cntvaluein3-skew-locked": {
        "suffix": "-cntvaluein3-skew-locked",
        "lock_set": "cntvaluein3_two_cell_bel_lock",
        "experiment_prefix": "cntvaluein3-skew-locked",
    },
}

FIELDS = [
    "experiment_id",
    "variant",
    "seed",
    "lock_set",
    "observer_payload",
    "repo_branch",
    "repo_commit_at_build",
    "build_completed_at_utc",
    "bitstream_attr",
    "bitstream_store_path",
    "bitstream_file",
    "bitstream_sha256",
    "nextpnr_json_attr",
    "nextpnr_json_store_path",
    "nextpnr_json_file",
    "nextpnr_json_sha256",
    "cvc_sdf_attr",
    "cvc_sdf_store_path",
    "cvc_sdf_file",
    "cvc_sdf_sha256",
    "cvc_sdf_nextpnr_json_file",
    "cvc_sdf_nextpnr_json_sha256",
]


def run(args: list[str]) -> str:
    return subprocess.check_output(args, text=True).strip()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_path(attr: str) -> Path:
    return Path(run(["nix", "build", "--no-link", "--print-out-paths", attr]))


def first_existing(directory: Path, names: list[str]) -> Path:
    for name in names:
        path = directory / name
        if path.exists():
            return path
    raise FileNotFoundError(f"none of {names} in {directory}")


def row_for(seed: int, variant: str, timestamp: str, branch: str, commit: str) -> dict[str, str]:
    spec = VARIANTS[variant]
    suffix = spec["suffix"]
    experiment_id = f"{spec['experiment_prefix']}-seed-{seed}"
    bit_attr = f".#ypcb-ddr3-bitstream-seed-{seed}{suffix}"
    json_attr = f".#ypcb-ddr3-nextpnr-json-seed-{seed}{suffix}"
    sdf_attr = f".#ypcb-ddr3-cvc-sdf-seed-{seed}{suffix}"

    bit_store = build_path(bit_attr)
    json_store = build_path(json_attr)
    sdf_store = build_path(sdf_attr)

    bit_file = first_existing(bit_store, ["ypcb_00338_1p1_ddr3_openxc7.bit"])
    json_file = first_existing(json_store, ["ypcb_00338_1p1_ddr3.placed.json"])
    sdf_file = first_existing(sdf_store, ["ypcb_00338_1p1_ddr3.cvc.sdf"])
    sdf_json_file = first_existing(sdf_store, ["ypcb_00338_1p1_ddr3.placed.json"])

    return {
        "experiment_id": experiment_id,
        "variant": variant,
        "seed": str(seed),
        "lock_set": spec["lock_set"],
        "observer_payload": "payload_v3_exact_abort",
        "repo_branch": branch,
        "repo_commit_at_build": commit,
        "build_completed_at_utc": timestamp,
        "bitstream_attr": bit_attr,
        "bitstream_store_path": str(bit_store),
        "bitstream_file": str(bit_file),
        "bitstream_sha256": sha256_file(bit_file),
        "nextpnr_json_attr": json_attr,
        "nextpnr_json_store_path": str(json_store),
        "nextpnr_json_file": str(json_file),
        "nextpnr_json_sha256": sha256_file(json_file),
        "cvc_sdf_attr": sdf_attr,
        "cvc_sdf_store_path": str(sdf_store),
        "cvc_sdf_file": str(sdf_file),
        "cvc_sdf_sha256": sha256_file(sdf_file),
        "cvc_sdf_nextpnr_json_file": str(sdf_json_file),
        "cvc_sdf_nextpnr_json_sha256": sha256_file(sdf_json_file),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--first-seed", type=int, required=True)
    parser.add_argument("--last-seed", type=int, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()

    branch = run(["git", "branch", "--show-current"])
    commit = run(["git", "rev-parse", "HEAD"])
    timestamp = datetime.now(timezone.utc).isoformat()

    rows = []
    for seed in range(args.first_seed, args.last_seed + 1):
        for variant in VARIANTS:
            rows.append(row_for(seed, variant, timestamp, branch, commit))

    args.out_dir.mkdir(parents=True, exist_ok=True)
    csv_path = args.out_dir / "build_manifest.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    (args.out_dir / "build_manifest.json").write_text(
        json.dumps({"schema": "uberddr3-seed-pair-build-manifest-v1", "rows": rows}, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (args.out_dir / "README.md").write_text(
        "\n".join(
            [
                "# Seed 31..60 Baseline/CNTVALUEIN3-Lock Build Manifest",
                "",
                "This manifest records the exact Nix store artifacts for the paired baseline and CNTVALUEIN3-lock experiment matrix.",
                "",
                f"- seed range: `{args.first_seed}..{args.last_seed}`",
                "- variants: `baseline-no-lock`, `cntvaluein3-skew-locked`",
                f"- rows: `{len(rows)}`",
                f"- repo commit at manifest generation: `{commit}`",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(csv_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
