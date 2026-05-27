# CNTVALUEIN3 lock held-out seed builds

This build batch tests the two-cell CNTVALUEIN3 physical intervention against remaining known baseline failures `6, 11, 12, 16, 20, 23, 27` and pass controls `1, 5, 28, 30`.

All rows use variant `cntvaluein3-skew-locked`, which locks current `phy_idelay_*_cntvaluein[3]` cells to the original low-source-distance seed3 BEL pair.
