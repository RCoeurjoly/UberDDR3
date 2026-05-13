# YPCB Rowstream Seed-Stability Plan

This is the live plan for removing seed dependence in the rowstream
calibration path while keeping changes upstreamable.

## Objective

- Start from the current pinned seed-3 artifact as a progress artifact only.
- Find a configuration (constraints + nextpnr knobs) that is stable across a
  declared seed set.
- Preserve a minimal, documented set of knobs/constraints for default flow.

## Constraints and Priority Order

1. **Clock/PHY physical locks are fixed first**:
   - `ddr3_clocks`
   - `ddr3_board_pins`
   - `uberddr3_phy`
2. **Clock and timing knobs next**:
   - `--no-tmdriv`
   - `--freq`
   - `--placer`
   - `--router`
3. **Soft-lock scope last**:
   - `full-controller-soft` -> `clocks-phy` -> `phy` -> `none`
4. **Do not force a single working seed**:
   - Any result that requires “seed=3 only” is provisional and remains marked
     brittle.

## Execution Procedure

1. Run matrix sweeps from:
   - `scripts/task6/task6_seed_stability_matrix.py`
   - default seed window: `0-5` (expand to `0-31` when stable candidates appear).
2. Save all runs in one sweep namespace, e.g.
   `artifacts/task6/calibration-sweeps/ypcb-rowstream-seed-stability/`.
3. Treat a row as stable when:
   - `build_status == built`
   - `calib_seen == true`
   - `calib_complete == true`
   - `state == 23`
   - `loader_ready == true`
   - `err_count == 0`
   - `ack_count > 0`
4. If no candidate is stable for all seeds:
   - broaden search with additional pnr knobs.
   - reduce/remove fewer constraints only after knobs are exhausted.
5. When a candidate is stable:
   - run hardware-only validation on that candidate for several iterations.
   - then shift to phase-5 BIST memory command contract tests and 64-byte probe plan.

## Current Status (snapshot)

- Provisional default (brittle): `full-controller-soft` with seed-3-derived oracle locks.
- Known gaps:
  - failing seeds observed at `0`, `2`, `4`, `5` under current lock set and tested knobs.
  - constrained-cluster crash in nextpnr-xilinx appears before a complete stable
    lock-minimization sweep can finish.
  - current matrix runs are also blocked intermittently by a `bbasm` crash in
    `nextpnr-xilinx` (`basic_string: construction from null is not valid`) during
    bitstream writeback.

## Open Work

- Replace provisional seed-3-only path with an any-seed stable candidate.
- Add one additional evidence pass for 0..31 seeds (build+program) once board loop is
  healthy.
- If required, create a narrowed seed-stability candidate set for nextpnr patching
  and file a minimally scoped upstream issue.
