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

OUT="${OUT:-${ROOT}/artifacts/task6/litedram-reference/ypcb-bist-openxc7}"

export PYTHONPATH="${MIGEN_ROOT}:${LITEX_ROOT}:${LITEDRAM_ROOT}:${LITEX_BOARDS_ROOT}:${LITEPCIE_ROOT}:${LITEETH_ROOT}:${PYTHONDATA_COMPILER_RT_ROOT}:${PYTHONDATA_VEXRISCV_ROOT}:${PYTHONDATA_TAPCFG_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

python3 "${ROOT}/scripts/task6/ypcb_litedram_bist.py" \
  --output-dir "${OUT}" \
  "$@"

printf 'Generated YPCB LiteDRAM BIST reference in %s\n' "${OUT}"
