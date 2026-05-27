# UberDDR3 Statistical SDF Analysis

- feature table: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-seed16/features_long.csv`
- experiments: `23`
- pass experiments: `22`
- fail experiments: `1`
- ranked univariate features: `200`
- Pairwise score models skipped because at least `3` pass and fail experiments are required.

This is hypothesis-generation evidence only. A feature becomes causal only after an intervention moves that feature and improves held-out hardware outcomes.

## Outputs

- `univariate_features.csv`: all pass/fail feature rankings.
- `top_fail_higher.csv`: features where higher values predict failure.
- `top_fail_lower.csv`: features where lower values predict failure.
- `strata_summary.csv`: pass/fail counts by experiment covariate.
- `pairwise_score_models.csv`: simple two-feature score models when enough samples exist.
