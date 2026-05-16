#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

LITEX_ROOT="${LITEX_ROOT:-/home/roland/litex}"
LITEDRAM_ROOT="${LITEDRAM_ROOT:-/home/roland/litedram}"
LITEX_BOARDS_ROOT="${LITEX_BOARDS_ROOT:-/home/roland/litex-boards}"
MIGEN_ROOT="${MIGEN_ROOT:-/home/roland/migen}"
LITEPCIE_ROOT="${LITEPCIE_ROOT:-/home/roland/litepcie}"
LITEETH_ROOT="${LITEETH_ROOT:-/home/roland/liteeth}"
PYTHONDATA_COMPILER_RT_ROOT="${PYTHONDATA_COMPILER_RT_ROOT:-/home/roland/pythondata-software-compiler_rt}"
PYTHONDATA_VEXRISCV_ROOT="${PYTHONDATA_VEXRISCV_ROOT:-/home/roland/pythondata-cpu-vexriscv}"
PYTHONDATA_TAPCFG_ROOT="${PYTHONDATA_TAPCFG_ROOT:-/home/roland/pythondata-misc-tapcfg}"

OUT="${1:-${ROOT}/artifacts/task6/litedram-reference/stock-ypcb-openxc7}"

export PYTHONPATH="${MIGEN_ROOT}:${LITEX_ROOT}:${LITEDRAM_ROOT}:${LITEX_BOARDS_ROOT}:${LITEPCIE_ROOT}:${LITEETH_ROOT}:${PYTHONDATA_COMPILER_RT_ROOT}:${PYTHONDATA_VEXRISCV_ROOT}:${PYTHONDATA_TAPCFG_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

python3 "${LITEX_BOARDS_ROOT}/litex_boards/targets/ypcb_00338_1p1.py" \
  --toolchain openxc7 \
  --build \
  --no-compile-gateware \
  --no-compile-software \
  --cpu-type=None \
  --no-uart \
  --no-timer \
  --integrated-rom-size=0 \
  --integrated-sram-size=0 \
  --output-dir "${OUT}"

printf 'Generated YPCB LiteDRAM stock reference in %s\n' "${OUT}"
