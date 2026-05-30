# Baseline No-Lock Hardware Repeatability Sweep

This is a hardware-only repeatability pass using prebuilt seeds (no SDF regeneration) on baseline no-lock RTL, using an extended poll window.

- manifest: `artifacts/builds/repeat-baseline-no-lock-seed-1-60-current2-poll200/build_manifest.csv`
- poll_count: `200`
- poll_interval: `0.1`
- rows: `22`
- hardware pass/fail matrix: `artifacts/hardware/repeat-baseline-no-lock-seed-1-60-current2-poll200/matrix.csv`

| run | purpose |
|---|---|
| `matrix.csv` | per-seed board-test outcomes for this run |
| `matrix.json` | same in machine-readable JSON |
| `sweep_status.csv` | live status + return codes |
| `summary.md` | cross-run determinism summary |

## Key outcome

- total rows: `22`
- passing: `10`
- failing: `12`
- changed outcomes vs `artifacts/hardware/baseline-no-lock-seed-1-60-current2/matrix.csv`: seeds `3` and `32`
