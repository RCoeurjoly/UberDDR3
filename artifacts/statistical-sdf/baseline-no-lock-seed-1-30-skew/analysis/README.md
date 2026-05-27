# UberDDR3 Statistical SDF Analysis

- feature table: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-skew/skew_features_long.csv`
- experiments: `30`
- pass experiments: `22`
- fail experiments: `8`
- ranked univariate features: `276`
- Pairwise score models written for `300` feature pairs.

This is hypothesis-generation evidence only. A feature becomes causal only after an intervention moves that feature and improves held-out hardware outcomes.

## Outputs

- `univariate_features.csv`: all pass/fail feature rankings.
- `top_fail_higher.csv`: features where higher values predict failure.
- `top_fail_lower.csv`: features where lower values predict failure.
- `strata_summary.csv`: pass/fail counts by experiment covariate.
- `pairwise_score_models.csv`: simple two-feature score models when enough samples exist.
