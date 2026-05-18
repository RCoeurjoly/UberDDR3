#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VIVADO="${VIVADO:-/home/roland/Vivado/2025.2.1/Vivado/bin/vivado}"
YPCB_HACK_ROOT="${YPCB_HACK_ROOT:-/home/roland/ypcb_00338_1p1_hack}"
YPCB_VIVADO_PROJECT="${YPCB_VIVADO_PROJECT:-${YPCB_HACK_ROOT}/examples/YPCB_00338_1P1_systest/YPCB_00338_1P1_systest.xpr}"
OUT="${ROOT}/artifacts/task6/vivado-oracle/ypcb-systest-phaser-byte-lane"
PROBES="${ROOT}/scripts/task6/ypcb_phaser_byte_lane_oracle_probes.tcl"
SERIAL="${YPCB_VIVADO_HW_SERIAL:-210299BF3824}"

ACTION="${1:?Usage: $0 <build|program|read> [out_dir] [probe_map] [serial]}"
shift

case "${ACTION}" in
  build)
    if [[ "${#}" -ge 1 ]]; then
      OUT="$1"
      shift || true
    fi
    if [[ "${#}" -ge 1 ]]; then
      PROBES="$1"
    fi

    mkdir -p "${OUT}"
    export YPCB_VIVADO_PROJECT
    export YPCB_VIVADO_JOBS="${YPCB_VIVADO_JOBS:-8}"
    exec "${VIVADO}" -mode batch -nojournal -nolog \
      -source "${ROOT}/scripts/task6/build_vivado_ypcb_phaser_byte_lane_oracle.tcl" \
      -tclargs "${OUT}" "${PROBES}"
    ;;

  program | read)
    if [[ "${#}" -ge 1 ]]; then
      OUT="$1"
    fi
    if [[ "${#}" -ge 2 ]]; then
      SERIAL="$2"
    fi

    export YPCB_VIVADO_PROJECT
    export YPCB_VIVADO_ORACLE_OUT="${OUT}"
    export YPCB_VIVADO_HW_SERIAL="${SERIAL}"
    export YPCB_VIVADO_JOBS="1"

    if [[ "${ACTION}" == "program" ]]; then
      exec "${VIVADO}" -mode batch -nojournal -nolog \
        -source "${ROOT}/scripts/task6/ypcb_vivado_oracle.tcl" \
        -tclargs "program-debug"
    else
      exec "${VIVADO}" -mode batch -nojournal -nolog \
        -source "${ROOT}/scripts/task6/ypcb_vivado_oracle.tcl" \
        -tclargs "read-debug"
    fi
    ;;

  *)
    printf 'Usage: %s <action> [out_dir] [probe_map|serial]\n' "${0}" >&2
    printf '  action=build [out_dir] [probe_map]\n' >&2
    printf '  action=program [out_dir] [serial]\n' >&2
    printf '  action=read [out_dir] [serial]\n' >&2
    exit 2
    ;;
esac
