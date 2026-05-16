#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

VIVADO="${VIVADO:-/home/roland/Vivado/2025.2.1/Vivado/bin/vivado}"
YPCB_HACK_ROOT="${YPCB_HACK_ROOT:-/home/roland/ypcb_00338_1p1_hack}"
YPCB_VIVADO_PROJECT="${YPCB_VIVADO_PROJECT:-${YPCB_HACK_ROOT}/examples/YPCB_00338_1P1_systest/YPCB_00338_1P1_systest.xpr}"
YPCB_BOARD_REPO="${YPCB_BOARD_REPO:-${YPCB_HACK_ROOT}}"
OUT="${OUT:-${ROOT}/artifacts/task6/vivado-oracle/ypcb-systest}"
JOBS="${JOBS:-$(nproc)}"

ACTION="${1:-check}"
shift || true

case "${ACTION}" in
  check|prepare-ip|build|export|debug-nets|debug-build|program|program-debug|read-debug)
    ;;
  *)
    printf 'Usage: %s [check|prepare-ip|build|export|debug-nets|debug-build|program|program-debug|read-debug]\n' "$0" >&2
    exit 2
    ;;
esac

mkdir -p "${OUT}"

export YPCB_VIVADO_PROJECT
export YPCB_BOARD_REPO
export YPCB_VIVADO_ORACLE_OUT="${OUT}"
export YPCB_VIVADO_JOBS="${JOBS}"
export YPCB_VIVADO_HW_SERIAL="${YPCB_VIVADO_HW_SERIAL:-210299BF3824}"

exec "${VIVADO}" -mode batch -nojournal -nolog -source "${ROOT}/scripts/task6/ypcb_vivado_oracle.tcl" -tclargs "${ACTION}" "$@"
