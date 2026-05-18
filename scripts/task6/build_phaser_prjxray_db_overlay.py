#!/usr/bin/env python3
"""Build a local prjxray-db overlay with provisional YPCB PHASER segbits."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil


OVERLAY_ROWS = {
    "segbits_cmt_top_r_upper_b.db": (
        53,
        (
            "vivado-mini/phaser_ref/provisional-segbits-phaser-ref.db",
            "vivado-mini/phy_control/provisional-segbits-phy_control.db",
        ),
    ),
    "segbits_cmt_top_r_lower_t.db": (
        34,
        (
            "vivado-mini/phaser_in_div4/provisional-segbits-phaser_in_div4.db",
            "vivado-mini/phaser_in_div2/provisional-segbits-phaser_in_div2.db",
            "vivado-mini/phaser_out_div4/provisional-segbits-phaser_out_div4.db",
        ),
    ),
    "segbits_cmt_fifo_r.db": (
        14,
        (
            "vivado-mini/in_fifo/provisional-segbits-in_fifo.db",
            "vivado-mini/out_fifo/provisional-segbits-out_fifo.db",
        ),
    ),
}

XC7K480T_TILE_BITS = {
    "CMT_TOP_R_UPPER_B_X8Y31": {"offset": 53, "words": 22},
    "CMT_TOP_R_LOWER_T_X8Y18": {"offset": 34, "words": 7},
    "CMT_FIFO_R_X7Y8": {"offset": 14, "words": 4},
}

BIT_BLOCK = "CLB_IO_CLK"
SEGMENT_BASEADDR = "0x00460080"
SEGMENT_FRAMES = 30


def clean_row(line: str, word_offset: int) -> str | None:
    line = line.strip()
    if not line or line.startswith("#"):
        return None
    fields = []
    for field in line.split():
        if field.startswith("origin:"):
            continue
        if "_" in field:
            frame_text, bit_text = field.split("_", 1)
            if frame_text.isdigit() and bit_text.isdigit():
                frame = int(frame_text)
                bit_index = int(bit_text)
                word = bit_index // 32
                bit = bit_index % 32
                if word < word_offset:
                    raise ValueError(f"{field} is before tile word offset {word_offset}")
                fields.append(f"{frame}_{(word - word_offset) * 32 + bit}")
                continue
        fields.append(field)
    return " ".join(fields)


def add_symlink_tree(source_db: Path, overlay_db: Path) -> None:
    overlay_db.mkdir(parents=True, exist_ok=True)
    for source in source_db.iterdir():
        target = overlay_db / source.name
        if target.exists() or target.is_symlink():
            continue
        target.symlink_to(source)


def write_overlay_file(
    *,
    source_db: Path,
    overlay_db: Path,
    oracle_root: Path,
    filename: str,
    word_offset: int,
    row_paths: tuple[str, ...],
) -> int:
    rows: list[str] = []
    source_file = source_db / filename
    if source_file.exists():
        rows.extend(source_file.read_text(encoding="utf-8").splitlines())

    for relative_path in row_paths:
        row_file = oracle_root / relative_path
        for line in row_file.read_text(encoding="utf-8").splitlines():
            row = clean_row(line, word_offset)
            if row is not None:
                rows.append(row)

    target = overlay_db / filename
    if target.is_symlink():
        target.unlink()
    target.write_text("\n".join(rows) + "\n", encoding="utf-8")
    return len(rows)


def replace_symlinked_dir(target_dir: Path, source_dir: Path) -> None:
    if target_dir.is_symlink():
        target_dir.unlink()
    target_dir.mkdir(parents=True, exist_ok=True)
    for source in source_dir.iterdir():
        target = target_dir / source.name
        if target.exists() or target.is_symlink():
            continue
        target.symlink_to(source)


def write_xc7k480t_tilegrid(source_db: Path, overlay_db: Path) -> None:
    source_device_dir = source_db / "xc7k480t"
    overlay_device_dir = overlay_db / "xc7k480t"
    replace_symlinked_dir(overlay_device_dir, source_device_dir)

    tilegrid_path = overlay_device_dir / "tilegrid.json"
    if tilegrid_path.is_symlink():
        tilegrid_path.unlink()

    tilegrid = json.loads((source_device_dir / "tilegrid.json").read_text(encoding="utf-8"))
    for tile_name, window in XC7K480T_TILE_BITS.items():
        tile = tilegrid[tile_name]
        tile["bits"] = {
            BIT_BLOCK: {
                "baseaddr": SEGMENT_BASEADDR,
                "frames": SEGMENT_FRAMES,
                "offset": window["offset"],
                "words": window["words"],
            }
        }

    tilegrid_path.write_text(
        json.dumps(tilegrid, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-db",
        required=True,
        type=Path,
        help="Pinned prjxray family DB directory, for example $PRJXRAY_DB_DIR/kintex7.",
    )
    parser.add_argument(
        "--oracle-root",
        default=Path("artifacts/task6/phaser-feature-oracle"),
        type=Path,
    )
    parser.add_argument(
        "--out-db",
        default=Path("artifacts/task6/phaser-feature-oracle/db-overlay/kintex7"),
        type=Path,
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the overlay directory before rebuilding it.",
    )
    args = parser.parse_args()

    source_db = args.source_db.resolve()
    oracle_root = args.oracle_root.resolve()
    out_db = args.out_db.resolve()

    if args.clean and out_db.exists():
        shutil.rmtree(out_db)
    add_symlink_tree(source_db, out_db)
    write_xc7k480t_tilegrid(source_db, out_db)

    for filename, (word_offset, row_paths) in OVERLAY_ROWS.items():
        row_count = write_overlay_file(
            source_db=source_db,
            overlay_db=out_db,
            oracle_root=oracle_root,
            filename=filename,
            word_offset=word_offset,
            row_paths=row_paths,
        )
        print(f"{out_db / filename}: {row_count} rows")

    print(out_db)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
