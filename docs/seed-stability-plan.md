# YPCB Rowstream Seed-Stability Plan

This is the live plan for removing seed dependence in the rowstream
calibration path while keeping changes upstreamable.

This plan is now the active sequence we will execute on this branch:

1. Lock the layout as much as possible using generated BEL locks.
2. Validate whether it is seed-stable by sweeping a declared seed set.
3. If stable, shrink the lock set; if not stable, add deterministic PNR knobs
   (timing/placement/router) and retry.
4. Promote the smallest seed-stable configuration to the default and keep all
   non-stable attempts in `artifacts/task6/calibration-sweeps` for evidence.

## Objective

- Start from the current pinned seed-3 artifact as a progress artifact only.
- Find a configuration (constraints + nextpnr knobs) that is stable across a
  declared seed set.
- Preserve a minimal, documented set of knobs/constraints for default flow.

## Constraints and Priority Order

1. **Clock/PHY physical locks are fixed first**:
   - In this repo, `full` lock scope means: `ddr3_clocks + ddr3_board_pins + uberddr3_phy`.
   - `ddr3_clocks`
   - `ddr3_board_pins`
   - `uberddr3_phy`
   - `full-jtag-clocks` adds the seed-3 BSCAN/JTAG BUFGCTRL placements as a
     test knob, because full-lock seed 3 passes while seeds 0/1/2 do not start
     calibration.
   - `oracle-all` is the true maximal lock experiment: extract every placed BEL
     from the passing seed-3 routed JSON and lock all of them for another seed.
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
   - if rowstream command fields are present: `integrity == pass`
4. If no candidate is stable for all seeds:
   - broaden search with additional pnr knobs.
   - reduce/remove fewer constraints only after knobs are exhausted.
5. Before changing lock preset breadth, run scoped lock experiments:
   - generate scoped soft-lock JSON once (for example from a routed nextpnr JSON) and pass it with
     `--extra-locks-json`.
   - keep `--lock-sets` fixed (`none` or one baseline preset) so the scorecard compares only
     lock payload deltas.
   - prefer monotonic reduction from broad scopes toward narrower scope subsets.

   Example helper flow:

   ```sh
   python3 scripts/task6/extract_nextpnr_soft_bel_locks.py \
     --routed-json artifacts/task6/baselines/.../nextpnr-routed.json \
     --out-json artifacts/task6/baselines/ypcb-controller-soft-locks.json

   python3 scripts/task6/task6_lock_subset_generator.py \
     --locks-json artifacts/task6/baselines/ypcb-controller-soft-locks.json \
     --out-dir artifacts/task6/lock-subsets/$(date +%Y%m%dT%H%M%S) \
     --split-by-scope --split-by-type
   ```

   Then run matrix passes with one `--extra-locks-manifest` payload and one
   scoped variant row each at a time.
6. When a candidate is stable:
   - run hardware-only validation on that candidate for several iterations.
   - then shift to phase-5 BIST memory command contract tests and 64-byte probe plan.

## Maximalist-to-minimal protocol

Yes. The recommended flow is:

1. **Maximal lock first**: treat this as the oracle candidate and test all seeds.
2. **Observe** pass/fail results and keep both outcomes for evidence.
3. **Only if it passes all seeds** begin reducing lock scope.
4. **If it fails any seed**, then physical clocks/PHY/board-pin locks are not enough; move to PNR knobs or additional deterministic constraints.

Concrete seed-first command (build-only pass across 0–5, then 0–31 later):

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-maximality-check \
  --seeds 0-5 \
  --lock-sets full \
  --freqs 25 \
  --build-only
```

Concrete shrink command (only after full passes the declared seed set):

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-seed-stability \
  --seeds 0-31 \
  --lock-sets full-controller-soft,full,clocks-phy,phy,none \
  --freqs 25 \
  --extra-locks-json artifacts/task6/baselines/uberddr3-rowstream-loader-v40-physical-stability/known-good-packed-bel-locks.json \
  --build-only
```

That shrinking order is implemented by the scorecard:
`full-controller-soft -> full -> clocks-phy -> phy -> none`, and each row can be
accepted only when it is stable for all tested seeds (not just one seed).

## Rowstream Seed Build Runbook

Use the pinned `rowstream-v40-json` target with explicit seed/freq outputs:

```sh
make -C example_demo/ypcb_00338_1p1 rowstream-v40-json SEED=3 FREQ=25
make -C example_demo/ypcb_00338_1p1 rowstream-v40-json \
  SEED=3 FREQ=25 \
  ROWSTREAM_ROUTED_JSON=artifacts/manual-seed/seed3/rowstream_seed3_routed.json \
  ROWSTREAM_BITSTREAM_OUT=artifacts/manual-seed/seed3/rowstream_seed3.bit
```

Defaults are deterministic when `ROWSTREAM_ROUTED_JSON` / `ROWSTREAM_BITSTREAM_OUT` are unset:

- JSON: `artifacts/manual-seed/seed<SEED>/nextpnr-routed.seed<SEED>.freq<FREQ>.json`
- Bitstream: `artifacts/manual-seed/seed<SEED>/ypcb_00338_1p1_uberddr3_rowstream_loader_seed<SEED>_freq<FREQ>.bit`

Compare passing vs failing seed runs against each other and inspect lock deltas:

```sh
python3 scripts/task6/compare_routed_placements.py \
  --seed-json 3:artifacts/manual-seed/seed3/nextpnr-routed.seed3.freq25.json \
  --seed-json 0:artifacts/manual-seed/seed0/nextpnr-routed.seed0.freq25.json \
  --pass-seed 3 --fail-seed 0
```

When you mutate a knob (seed, `--freq`, `--no-tmdriv`, `--placer`, `--router`, or lock scope), regenerate both JSON artifacts first and only then compare.

## Current Sweep Command (seed sweep + optional scoped locks)

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-seed-stability \
  --seeds 0-5 \
  --lock-sets full-controller-soft \
  --freqs 25 \
  --extra-locks-json artifacts/task6/baselines/uberddr3-rowstream-loader-v40-physical-stability/known-good-packed-bel-locks.json \
  --build-only
```

If you need a no-lock delta run, omit `--extra-locks-json` and keep the same command.

## Execution Protocol (today)

Run this sequence exactly in order before changing any lock payload:

```sh
# 1) Build baseline candidates (custom outputs are now deterministic)
make -C example_demo/ypcb_00338_1p1 rowstream-v40-json \
  SEED=3 FREQ=25 CHIPDB=/nix/store/<CHIPDB_STORE_PATH>/nextpnr-xilinx-chipdb-0.8.2 \
  ROWSTREAM_ROUTED_JSON=artifacts/manual-seed/seed3/nextpnr-routed.seed3.freq25.json \
  ROWSTREAM_BITSTREAM_OUT=artifacts/manual-seed/seed3/rowstream_seed3_freq25.bit

make -C example_demo/ypcb_00338_1p1 rowstream-v40-json \
  SEED=2 FREQ=25 CHIPDB=/nix/store/<CHIPDB_STORE_PATH>/nextpnr-xilinx-chipdb-0.8.2 \
  ROWSTREAM_ROUTED_JSON=artifacts/manual-seed/seed2/nextpnr-routed.seed2.freq25.json \
  ROWSTREAM_BITSTREAM_OUT=artifacts/manual-seed/seed2/rowstream_seed2_freq25.bit

# 2) Compare routed placements for seed-invariant / seed-specific deltas
python3 scripts/task6/compare_routed_placements.py \
  --seed-json 3:artifacts/manual-seed/seed3/nextpnr-routed.seed3.freq25.json \
  --seed-json 2:artifacts/manual-seed/seed2/nextpnr-routed.seed2.freq25.json \
  --pass-seed 3 --fail-seed 2

# 3) Run seed sweep automatically (build-only first, then hardware rowstream contract)
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-maximality-check \
  --seeds 0-5 \
  --lock-sets full \
  --freqs 25 \
  --build-only

python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-maximality-check-hw \
  --seeds 0-5 \
  --lock-sets full \
  --freqs 25 \
  --rowstream-check \
  --rowstream-readback-after-write \
  --rowstream-command-byte 0xa5 \
  --rowstream-expected-byte 0xa5
```

Use `--rowstream-check` for board confirmation. This path programs with OpenOCD
through `task6_ddr3_experiment_runner.py`, waits for rowstream calibration, sends
a low-byte rowstream write, optionally sends a readback command, and records
`calibration`, `command_gate`, `integrity`, `ack_count`, `err_count`, and the
decoded calibration state in the matrix row.

## Current Status (snapshot)

- Provisional default (brittle): `full-controller-soft` with seed-3-derived oracle locks.
- The matrix now has a rowstream-aware hardware check path; passive JTAG polling
  is not sufficient for rowstream-loader success because it does not exercise the
  command/readback contract.
- Latest hardware evidence:
  - `full` seed 3 passes: `DONE_CALIBRATE`, `integrity_pass`, `ack_count=11`,
    `err_count=0`, readback `0xa5`.
  - `full` seeds 0, 1, and 2 fail before calibration starts:
    `calib_seen_cycle=0`, `loader_state=1`.
  - placement comparison shows DDR3 IO/IDELAY/ISERDES/OSERDES primitives stable
    across seeds, but three auto-generated BSCAN/JTAG `BUFGCTRL` cells vary.
  - `full-jtag-clocks` seed 0 still fails before calibration, so those BUFGs are
    not sufficient.
  - `oracle-all` applies all 26,697 placed BELs from the passing seed-3 routed
    JSON. Hardware results:
    - seed 0: pass, `DONE_CALIBRATE`, `integrity_pass`, `ack_count=11`,
      `err_count=0`, readback `0xa5`.
    - seed 1: pass, `DONE_CALIBRATE`, `integrity_pass`, `ack_count=11`,
      `err_count=0`, readback `0xa5`.
    - seed 2: pass, `DONE_CALIBRATE`, `integrity_pass`, `ack_count=11`,
      `err_count=0`, readback `0xa5`.
  - conclusion: absolute BEL placement is sufficient to rescue failing seeds in
    the tested 0..3 window. The next phase is shrink/minimize from `oracle-all`.
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
