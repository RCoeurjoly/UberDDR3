# Temporary code snapshots preserved from /tmp

This directory preserves code-like artifacts that were previously only under
`/tmp`. Logs, bitstreams, frames, routed outputs, and build products were not
copied here.

Contents:

- `uberddr3-head-control/`: source snapshot from `/tmp/UberDDR3-head-control`.
- `angelo-uberddr3-history/`: source snapshot from `/tmp/angelo-uberddr3-history`, without `.git` history.
- `generated-gateware/`: generated LiteX/LiteDRAM gateware Verilog and CSR JSON snapshots.
- `phaser-probe-db/`: PHASER site-type JSON probe data preserved as code/data inputs, not logs.

These are preservation snapshots, not the active implementation path. Promote
individual files into the main source tree only after reviewing the delta.
