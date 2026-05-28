# UberDDR3 Statistical SDF Analysis

- feature table: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-analysis/skew_seed12_features_long.csv`
- experiments: `7`
- pass experiments: `6`
- fail experiments: `1`
- ranked univariate features: `220`
- Pairwise score models skipped because at least `3` pass and fail experiments are required.

This is hypothesis-generation evidence only. A feature becomes causal only after an intervention moves that feature and improves held-out hardware outcomes.

## Outputs

- `univariate_features.csv`: all pass/fail feature rankings.
- `top_fail_higher.csv`: features where higher values predict failure.
- `top_fail_lower.csv`: features where lower values predict failure.
- `strata_summary.csv`: pass/fail counts by experiment covariate.
- `pairwise_score_models.csv`: simple two-feature score models when enough samples exist.
