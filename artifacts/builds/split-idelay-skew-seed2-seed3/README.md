# Split IDELAY skew seed2/seed3 builds

This manifest records the exact committed Nix outputs for the separated experiments:

- `idelay-stable-before-ld`: RTL robustness hypothesis; CNTVALUEIN and LD are pipelined locally in the PHY so CNTVALUEIN is stable before LD reaches IDELAYE2.
- `cntvaluein3-skew-locked`: physical diagnostic; current `phy_idelay_*_cntvaluein[3]` cells are locked to the original low-skew seed-3 BELs.

Hardware result JSONs are recorded separately under `artifacts/hardware/split-idelay-skew-seed2-seed3/`.
