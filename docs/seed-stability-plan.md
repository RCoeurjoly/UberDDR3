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
   - The YPCB PLL in `example_demo/ypcb_00338_1p1/clk_wiz.v` derives the real
     rowstream DDR3 clocks from a 50 MHz input:
     - `controller_clk`: 125 MHz
     - `ddr3_clk`: 500 MHz
     - `ddr3_clk_90`: 500 MHz
     - `ref_clk`: 200 MHz
   - The AMD/Xilinx Kintex-7 note on external memory interfaces says DDR3/DDR2
     Phaser divide-by-two mode is not operational from 303-399 MHz; DDR3 must
     use a memory clock of 400 MHz or higher so the Phaser block is in 1:1 mode.
     In this flow, that means the actual generated DDR3 clock must remain at or
     above 400 MHz. It does **not** mean blindly setting nextpnr `--freq 400`,
     because `--freq` is nextpnr's global timing target/fallback, not MIG's
     memory-clock selector.
   - `scripts/task6/nextpnr_ypcb_uberddr3_clock_constraints.py` must therefore
     constrain nextpnr with the actual YPCB clock rates above. Older seed data
     that used `controller_clk=25 MHz` and `ddr3_clk=100 MHz` is useful only as
     historical evidence; it was underconstrained for the real hardware.
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

## Oracle-All Shrinking Protocol

`oracle-all` is now the passing upper bound. Reduce it using delta debugging,
but start with semantic groups rather than raw file order.

1. Generate complement candidates:

```sh
python3 scripts/task6/task6_lock_reducer.py \
  --locks-json artifacts/task6/lock-experiments/seed3-all-bel-locks.json \
  --out-dir artifacts/task6/lock-experiments/oracle-all-category-complements \
  --group-by category
```

Each candidate is `oracle-all` minus one group. Test the largest removable
groups first:

- `without-other_soft_logic`
- `without-ddr3_controller_soft_logic`
- `without-jtag_soft_logic`
- `without-uberddr3_other_soft_logic`
- `without-ddr3_phy_soft_logic`
- `without-clock_io_phy_primitives`

2. For each candidate:

```sh
python3 scripts/task6/task6_calibration_sweep.py \
  --sweep ypcb-rowstream-lock-shrink \
  --seed 0 \
  --lock-set oracle-all \
  --freq 25 \
  --extra-locks-json <candidate.json> \
  --build-only
```

If build succeeds, run hardware:

```sh
python3 scripts/task6/task6_calibration_sweep.py \
  --sweep ypcb-rowstream-lock-shrink-hw \
  --seed 0 \
  --lock-set oracle-all \
  --freq 25 \
  --bitstream <candidate-built-bitstream> \
  --rowstream-check \
  --rowstream-readback-after-write \
  --rowstream-command-byte 0xa5 \
  --rowstream-expected-byte 0xa5
```

3. Shrink rule:

- If removing a group still passes seeds `0,1,2,3`, permanently remove it.
- If removing a group fails, keep it and split that group by `category-type`.
- If a `category-type` group still fails when removed, split it with ddmin:
  halves, quarters, then individual locks only where necessary.
- If complement tests become non-monotonic or hit nextpnr crashes, switch to
  add-back mode: start from the smallest candidate that builds, then add one
  subgroup back at a time until the failing seed passes.

Add-back example for the current first shrink:

```sh
python3 scripts/task6/task6_lock_reducer.py \
  --locks-json artifacts/task6/lock-experiments/seed3-all-bel-locks.json \
  --out-dir artifacts/task6/lock-experiments/oracle-all-other-soft-addbacks \
  --mode addback \
  --base-without-category other_soft_logic \
  --group-by category-type
```

4. Expansion rule:

- First pass set: seeds `0,1,2,3`.
- After a candidate survives: seeds `0..7`.
- Then `0..15`.
- Then `0..31`.
- Any new failing seed is added to the permanent regression seed set.

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

## PNR-Only Sweep Loop

Seed, frequency, router, placer, clock constraints, and BEL-lock changes are PNR
knobs. They do not need a fresh Yosys run if the RTL and synthesis flags are
unchanged. For lock shrinking, build or reuse one rowstream synth JSON, then
reuse it with `--pnr-only --synth-json`.

Known reusable synth JSON from the current artifacts:

```sh
SYNTH_JSON=artifacts/task6/calibration-sweeps/ypcb-rowstream-oracle-all-seed0/2026-05-14T08-03-04+0200-oracle-all-seed0/build-artifacts/ypcb_00338_1p1_uberddr3_rowstream_loader.json
```

Single-candidate smoke:

```sh
python3 scripts/task6/task6_calibration_sweep.py \
  --sweep ypcb-rowstream-pnr-only-smoke \
  --seed 0 \
  --lock-set oracle-all \
  --freq 25 \
  --extra-locks-json artifacts/task6/lock-experiments/oracle-all-other-soft-addbacks/base-without-other_soft_logic_add-other_soft_logic_type_slice_ffx.json \
  --build-only \
  --pnr-only \
  --synth-json "$SYNTH_JSON"
```

Matrix form:

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-lock-shrink-pnr-only \
  --seeds 0-3 \
  --lock-sets oracle-all \
  --freqs 25 \
  --extra-locks-json artifacts/task6/lock-experiments/oracle-all-other-soft-addbacks/base-without-other_soft_logic_add-other_soft_logic_type_slice_ffx.json \
  --build-only \
  --pnr-only \
  --synth-json "$SYNTH_JSON"
```

Verification rule: the build log must contain `rowstream-v40-json-pnr-only`,
`touch ypcb_00338_1p1_uberddr3_rowstream_loader.json`, and `nextpnr-xilinx`;
it must not contain a `yosys -p` invocation. The smoke run on
2026-05-14 used this path and applied 8,726 locks for the current FFX add-back
candidate.

## Seed Coverage Policy

Do not use nextpnr `--randomize-seed` as the primary exploration path. It hides
the actual seed unless every log parser records the resolved value. Instead,
generate random coverage in the matrix runner and pass every nextpnr invocation
an explicit `--seed N`.

Use three seed tiers:

- Regression tier: every candidate must pass `0..7`; seeds `5` and `7` are now
  critical regressions because they fail before calibration.
- Confidence tier: after passing `0..7`, run `0..31`.
- Random tier: after passing `0..31`, append reproducible random explicit seeds:

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-random-explicit-seeds \
  --seeds 0-31 \
  --random-seeds 32 \
  --random-seed 12345 \
  --lock-sets oracle-all \
  --freqs 25 \
  --pnr-only \
  --synth-json "$SYNTH_JSON" \
  --build-only
```

The matrix writes `seed-manifest.json` in the sweep directory with the exact
`nextpnr_seeds` list. Treat that manifest as the reproducibility source of truth.

Because seed 5 fails even under full `oracle-all`, the immediate work is not
lock shrinking. The next basis-finding step is a focused seed-5 non-BEL knob
sweep, then compare routed JSON/FASM/logs against passing seeds:

```sh
python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-seed5-flow-knobs \
  --seeds 5 \
  --lock-sets oracle-all \
  --freqs 25,50,100 \
  --pnr-extra-args "" \
  --pnr-extra-args "--no-tmdriv" \
  --pnr-extra-args "--router router1" \
  --pnr-extra-args "--placer-budgets" \
  --extra-locks-json artifacts/task6/lock-experiments/oracle-all-other-soft-addbacks/base-without-other_soft_logic_add-other_soft_logic_type_slice_ffx.json \
  --pnr-only \
  --synth-json "$SYNTH_JSON" \
  --build-only
```

## Post-Route Simulation Probe

Hardware remains the calibration oracle because plain RTL simulation does not
model nextpnr placement, routing, clock skew, or interconnect delay. Verilator is
therefore insufficient for the seed-5/seed-7 failures.

The only plausible simulation-side oracle is post-route gate/timing simulation:

- Ask nextpnr to emit SDF with `--sdf <file>`.
- Use `--sdf-cvc` if targeting the CVC simulator.
- Simulate a gate-level/post-synthesis netlist plus SDF using Xilinx primitive
  simulation models.

This is worth investigating, but it is not yet a replacement for HIL:

- CVC is not currently present in the devShell.
- We still need a Verilog netlist that matches the routed JSON/FASM naming well
  enough for SDF back-annotation.
- We need the relevant 7-series primitive simulation models in a form CVC can
  elaborate.
- We need a rowstream/calibration testbench at that gate level.

Treat this as a secondary oracle-building track. The immediate seed-stability
track remains PNR-only build sweeps followed by rowstream HIL.

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
    - seed 5 control on 2026-05-14: fails before calibration,
      `calib_seen_cycle=0`, `loader_state=1`.
  - conclusion: absolute BEL placement is sufficient to rescue failing seeds in
    the tested 0..3 window, but not sufficient for all seeds. Seed 5 failing
    even with `oracle-all` means the remaining instability is not just missing
    BEL locks from the current seed-3 routed JSON.
  - first shrink result:
    - removing all `other_soft_logic` keeps 870 locks and passes seeds 0 and 1.
    - seed 2 fails before calibration with that 870-lock candidate.
    - removing individual large `other_soft_logic` type groups from full
      `oracle-all` currently triggers a nextpnr `unordered_map::at` crash, so the
      next minimization step uses add-back candidates from the 870-lock base.
    - adding back `other_soft_logic` `SLICE_FFX` produces an 8,726-lock
      candidate. Hardware results on 2026-05-14:
      - seeds 0, 1, 2, 3, 4, and 6 pass: `DONE_CALIBRATE`,
        `integrity_pass`, `ack_count=11`, `err_count=0`, readback `0xa5`.
      - seeds 5 and 7 fail before calibration with `calib_seen_cycle=0`,
        `loader_state=1`.
      - seed 5 was retried and failed the same way.
    - with `SLICE_FFX` required, adding one more `other_soft_logic` type group
      (`CARRY4`, `SELMUX2_1`, or `SLICE_LUTX`) currently fails during nextpnr
      constrained placement with `unordered_map::at`, so those groups cannot yet
      be tested independently as add-backs.
    - adding `--no-tmdriv` to the 8,726-lock seed 5 build does not rescue it;
      the bitstream still fails before calibration with `calib_seen_cycle=0`,
      `loader_state=1`.
    - `--router router1` at `--freq 25` also does not rescue seed 5.
    - raising placement timing pressure to `--freq 50` rescues seed 5 with the
      8,726-lock candidate: `DONE_CALIBRATE`, `integrity_pass`,
      `ack_count=11`, `err_count=0`, readback `0xa5`.
    - the same `--freq 50` policy does not rescue seed 7, and `--freq 100`
      also fails seed 7 before calibration.
  - comparison reports for seed 5 freq-25 fail, seed 5 freq-50 pass, seed 7
    freq-50 fail, and seed 7 freq-100 fail are in
    `artifacts/task6/comparisons/seed5-seed7-freq-pressure/`.
    - high-risk DDR3 primitives are placed identically across all four builds:
      BUFGCTRL, PLL, IDELAYCTRL, IDELAYE2, I/O buffers, ISERDES, OSERDES, and
      PADs are all stable.
    - placement variation is concentrated in controller/JTAG/general soft logic;
      `ddr3_controller_soft_logic` has 0/215 cells equal across all four builds.
    - routed-net variation is also concentrated outside the hard PHY: only
      17/7532 `ddr3_controller` routes are equal across all four builds, while
      298/380 `ddr3_phy` routes are equal.
    - current hypothesis: the missing seed-stability basis is soft-controller
      and command/control routing/placement pressure, not gross DDR3 IO/PLL/PHY
      primitive placement.
- Known gaps:
  - failing seeds observed at `5` and `7` under the 8,726-lock FFX add-back
    candidate.
  - seed 5 also fails under full `oracle-all`, so additional knobs beyond the
    current absolute BEL lock set are required.
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
