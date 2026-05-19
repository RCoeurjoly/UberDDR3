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
    "CMT_TOP_R_UPPER_B_X8Y31": {"baseaddr": "0x00460080", "offset": 53, "words": 22},
    "CMT_TOP_R_UPPER_B_X8Y239": {"baseaddr": "0x00000080", "offset": 53, "words": 22},
    "CMT_TOP_R_LOWER_T_X8Y18": {"baseaddr": "0x00460080", "offset": 34, "words": 7},
    "CMT_TOP_R_LOWER_T_X8Y226": {"baseaddr": "0x00000080", "offset": 34, "words": 7},
    "CMT_FIFO_R_X7Y8": {"baseaddr": "0x00460080", "offset": 14, "words": 4},
    "CMT_FIFO_R_X7Y241": {"baseaddr": "0x00000080", "offset": 14, "words": 4},
}

XC7K480T_TILECONN_EXTRA = (
    {
        "grid_deltas": [0, 26],
        "tile_types": ["HCLK_CMT", "BRKH_CMT"],
        "wire_pairs": [
            [f"HCLK_CMT_FREQ_REF_NS{i}", f"BRKH_CMT_FREQ_REF_NS{i}"]
            for i in range(4)
        ],
    },
    {
        "grid_deltas": [0, 26],
        "tile_types": ["BRKH_CMT", "HCLK_CMT"],
        "wire_pairs": [
            [f"BRKH_CMT_FREQ_REF_NS{i}", f"HCLK_CMT_FREQ_REF_NS{i}"]
            for i in range(4)
        ],
    },
)

PROVISIONAL_BIT_EXCLUDES = {
    (
        "segbits_cmt_fifo_r.db",
        "CMT_FIFO_R.IN_FIFO_X0Y0.IN_USE",
    ): {"1_29", "1_93", "24_105"},
    (
        "segbits_cmt_fifo_r.db",
        "CMT_FIFO_R.OUT_FIFO_X0Y0.IN_USE",
    ): {"1_21", "1_85"},
    (
        "segbits_cmt_top_r_lower_t.db",
        "CMT_TOP_R_LOWER_T.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE",
    ): {"24_155", "25_156", "25_162", "25_164", "25_174", "25_178", "25_180", "28_123", "28_155"},
    (
        "segbits_cmt_top_r_lower_t.db",
        "CMT_TOP_R_LOWER_T.PHASER_OUT_PHY_X0Y0.CLKOUT_DIV_4_IN_USE",
    ): {"24_59", "24_69", "24_73", "25_12", "25_44", "25_50", "25_52", "25_58", "25_60", "25_62", "25_74", "25_78", "28_64"},
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y0.IN_USE",
    ): {"1_597", "25_666", "25_702"},
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y0.IN_USE",
    ): {"28_16", "28_24"},
}

PROVISIONAL_ROW_ALIASES = {
    (
        "segbits_cmt_top_r_lower_t.db",
        "CMT_TOP_R_LOWER_T.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE",
    ): (
        "CMT_TOP_R_LOWER_T.PHASER_IN_PHY_X0Y17.CLKOUT_DIV_4_IN_USE",
    ),
    (
        "segbits_cmt_top_r_lower_t.db",
        "CMT_TOP_R_LOWER_T.PHASER_OUT_PHY_X0Y0.CLKOUT_DIV_4_IN_USE",
    ): (
        "CMT_TOP_R_LOWER_T.PHASER_OUT_PHY_X0Y16.CLKOUT_DIV_4_IN_USE",
    ),
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y0.IN_USE",
    ): (
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y4.IN_USE",
    ),
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y0.IN_USE",
    ): (
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y4.IN_USE",
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y7.IN_USE",
    ),
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE",
    ): (
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y7.CLOCKED_ORACLE_ROUTE",
    ),
    (
        "segbits_cmt_top_r_upper_b.db",
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y0.IN_USE",
    ): (
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y4.IN_USE",
        "CMT_TOP_R_UPPER_B.PHY_CONTROL_X0Y7.IN_USE",
    ),
}

EXTRA_SEGBIT_ROWS = {
    "segbits_cmt_top_r_lower_b.db": (
        "CMT_TOP_R_LOWER_B.MMCM_CLK_FREQ_BB_REBUF0_NS.MMCM_CLK_FREQ_BB_NS0 "
        "28_1058 28_1069 28_1077 28_1081 28_1596 "
        "28_2372 28_2412 28_2448 28_2451 28_2459 "
        "28_2496 28_2499 28_2507 28_2512 28_2515 "
        "28_2523 28_2528 28_2531 28_2539 28_2592 "
        "28_2594 28_2605 28_2613 28_3028 29_1068 "
        "29_1072 29_1076 29_2606 29_2614",
        "CMT_TOP_R_LOWER_B.MMCM_CLK_FREQ_BB_REBUF2_NS.MMCM_CLK_FREQ_BB_NS2 "
        "28_1058 28_1068 28_1069 28_1076 28_1077 "
        "28_1080 28_1081 28_1596 28_2372 28_2412 "
        "28_2448 28_2451 28_2459 28_2496 28_2499 "
        "28_2507 28_2512 28_2515 28_2523 28_2528 "
        "28_2531 28_2539 28_2592 28_2594 28_2605 "
        "28_2613 28_3028 29_1057 29_1067 29_1068 "
        "29_1071 29_1072 29_1075 29_1076 29_2606 "
        "29_2614 29_1596 29_2371 29_2397 29_2412",
        "CMT_TOP_R_LOWER_B.MMCM_CLK_FREQ_BB_REBUF3_NS.MMCM_CLK_FREQ_BB_NS3 "
        "28_1058 28_1068 28_1069 28_1076 28_1077 "
        "28_1080 28_1081 28_1596 28_2372 28_2412 "
        "28_2448 28_2451 28_2459 28_2496 28_2499 "
        "28_2507 28_2512 28_2515 28_2523 28_2528 "
        "28_2531 28_2539 28_2592 28_2594 28_2605 "
        "28_2613 28_3028 29_1057 29_1067 29_1068 "
        "29_1071 29_1072 29_1075 29_1076 29_2606 "
        "29_2614 29_1596 29_2371 29_2397 29_2412",
        "CMT_TOP_R_LOWER_B.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE "
        "28_1058 28_1068 28_1069 28_1076 28_1077 29_1057",
    ),
    "segbits_cmt_top_r_upper_b.db": (
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE "
        "28_674 28_677 28_685 28_693 28_697 "
        "29_676 29_677 29_684 29_688 29_692",
        "CMT_TOP_R_UPPER_B.PHASER_REF_X0Y4.CLOCKED_ORACLE_ROUTE "
        "28_674 28_677 28_685 28_693 28_697 "
        "29_676 29_677 29_684 29_688 29_692",
    ),
    "segbits_hclk_cmt.db": (
        "HCLK_CMT.PHASER_REF_X0Y0.CLOCKED_ORACLE_ROUTE 28_156 29_156",
    ),
    "segbits_cmt_top_r_upper_t.db": (
        "CMT_TOP_R_UPPER_T.PLL_CLK_FREQ_BB2_NS.PLL_CLK_FREQ_BB_BUFOUT_NS2 "
        "28_9 28_12 28_20 28_24 28_26 28_27 "
        "29_1 29_8 29_11 29_15 29_19 29_25",
        "CMT_TOP_R_UPPER_T.PLL_CLK_FREQ_BB3_NS.PLL_CLK_FREQ_BB_BUFOUT_NS3 "
        "28_9 28_12 28_20 28_24 28_26 28_27 "
        "29_1 29_8 29_11 29_15 29_19 29_25",
    ),
}

PPIP_EXTRA_ROWS = {
    "ppips_cmt_top_r_lower_b.db": (
        "CMT_TOP_R_LOWER_B.MMCM_CLK_FREQ_BB_REBUF1_NS.MMCM_CLK_FREQ_BB_NS1 always",
    ),
    "ppips_cmt_top_r_upper_b.db": (
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN0 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN1 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFIN2 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT1.PLLOUT_CLK_FREQ_BB_REBUFIN0 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT1.PLLOUT_CLK_FREQ_BB_REBUFIN1 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFIN0 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFIN1 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT3.PLLOUT_CLK_FREQ_BB_REBUFIN0 always",
        "CMT_TOP_R_UPPER_B.PLLOUT_CLK_FREQ_BB_REBUFOUT3.PLLOUT_CLK_FREQ_BB_REBUFIN1 always",
        "CMT_TOP_R_UPPER_B.PLL_CLK_FREQBB_REBUFOUT0.PLLOUT_CLK_FREQ_BB_REBUFOUT0 always",
        "CMT_TOP_R_UPPER_B.PLL_CLK_FREQBB_REBUFOUT1.PLLOUT_CLK_FREQ_BB_REBUFOUT1 always",
        "CMT_TOP_R_UPPER_B.PLL_CLK_FREQBB_REBUFOUT2.PLLOUT_CLK_FREQ_BB_REBUFOUT2 always",
        "CMT_TOP_R_UPPER_B.PLL_CLK_FREQBB_REBUFOUT3.PLLOUT_CLK_FREQ_BB_REBUFOUT3 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.PLLOUT_CLK_FREQ_BB_REBUFIN0 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.PLLOUT_CLK_FREQ_BB_REBUFIN1 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN0 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN1 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN2 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_0.CMT_FREQ_BB_PREF_IN3 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN0 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN1 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN2 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_1.CMT_FREQ_BB_PREF_IN3 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN0 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN1 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN2 always",
        "CMT_TOP_R_UPPER_B.CMT_FREQ_PHASER_REFMUX_2.CMT_FREQ_BB_PREF_IN3 always",
    ),
    "ppips_cmt_top_r_upper_t.db": (
        "CMT_TOP_R_UPPER_T.PLL_CLK_FREQ_BB0_NS.PLL_CLK_FREQ_BB_BUFOUT_NS0 always",
        "CMT_TOP_R_UPPER_T.PLL_CLK_FREQ_BB1_NS.PLL_CLK_FREQ_BB_BUFOUT_NS1 always",
    ),
}

BIT_BLOCK = "CLB_IO_CLK"
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


def filter_provisional_bits(filename: str, row: str) -> str:
    fields = row.split()
    if not fields:
        return row
    excluded = PROVISIONAL_BIT_EXCLUDES.get((filename, fields[0]), set())
    if not excluded:
        return row
    return " ".join(field for field in fields if field not in excluded)


def provisional_alias_rows(filename: str, row: str) -> list[str]:
    fields = row.split()
    if not fields:
        return []
    aliases = PROVISIONAL_ROW_ALIASES.get((filename, fields[0]), ())
    return [" ".join((alias, *fields[1:])) for alias in aliases]


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
                row = filter_provisional_bits(filename, row)
                rows.append(row)
                rows.extend(provisional_alias_rows(filename, row))

    existing = set(rows)
    for row in EXTRA_SEGBIT_ROWS.get(filename, ()):
        if row not in existing:
            rows.append(row)
            existing.add(row)

    target = overlay_db / filename
    if target.is_symlink():
        target.unlink()
    target.write_text("\n".join(rows) + "\n", encoding="utf-8")
    return len(rows)


def write_ppip_overlay_file(source_db: Path, overlay_db: Path, filename: str) -> int:
    rows: list[str] = []
    source_file = source_db / filename
    if source_file.exists():
        rows.extend(source_file.read_text(encoding="utf-8").splitlines())

    existing = set(rows)
    for row in PPIP_EXTRA_ROWS[filename]:
        if row not in existing:
            rows.append(row)
            existing.add(row)

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
                "baseaddr": window["baseaddr"],
                "frames": SEGMENT_FRAMES,
                "offset": window["offset"],
                "words": window["words"],
            }
        }

    tilegrid_path.write_text(
        json.dumps(tilegrid, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def write_xc7k480t_tileconn(source_db: Path, overlay_db: Path) -> None:
    source_device_dir = source_db / "xc7k480t"
    overlay_device_dir = overlay_db / "xc7k480t"
    tileconn_path = overlay_device_dir / "tileconn.json"
    if tileconn_path.is_symlink():
        tileconn_path.unlink()

    tileconn = json.loads((source_device_dir / "tileconn.json").read_text(encoding="utf-8"))
    existing = {
        (
            tuple(entry["grid_deltas"]),
            tuple(entry["tile_types"]),
            tuple(tuple(pair) for pair in entry["wire_pairs"]),
        )
        for entry in tileconn
    }
    for entry in XC7K480T_TILECONN_EXTRA:
        key = (
            tuple(entry["grid_deltas"]),
            tuple(entry["tile_types"]),
            tuple(tuple(pair) for pair in entry["wire_pairs"]),
        )
        if key not in existing:
            tileconn.append(entry)

    tileconn_path.write_text(
        json.dumps(tileconn, indent=2, sort_keys=True) + "\n",
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
    write_xc7k480t_tileconn(source_db, out_db)

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

    for filename in sorted(set(EXTRA_SEGBIT_ROWS) - set(OVERLAY_ROWS)):
        row_count = write_overlay_file(
            source_db=source_db,
            overlay_db=out_db,
            oracle_root=oracle_root,
            filename=filename,
            word_offset=0,
            row_paths=(),
        )
        print(f"{out_db / filename}: {row_count} rows")

    for filename in PPIP_EXTRA_ROWS:
        row_count = write_ppip_overlay_file(source_db, out_db, filename)
        print(f"{out_db / filename}: {row_count} rows")

    print(out_db)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
