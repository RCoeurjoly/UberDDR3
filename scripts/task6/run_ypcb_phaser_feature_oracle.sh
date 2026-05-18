#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VIVADO="${VIVADO:-/home/roland/Vivado/2025.2.1/Vivado/bin/vivado}"
VARIANT="${1:?usage: $0 <variant> [out-dir]}"
OUT="${2:-${ROOT}/artifacts/task6/phaser-feature-oracle/vivado-mini/${VARIANT}}"

exec "${VIVADO}" -mode batch -nojournal -nolog \
  -source "${ROOT}/scripts/task6/ypcb_phaser_feature_oracle.tcl" \
  -tclargs build "${VARIANT}" "${OUT}"
