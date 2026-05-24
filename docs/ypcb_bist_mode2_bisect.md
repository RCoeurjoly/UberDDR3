# YPCB BIST_MODE=2 / 2-byte-lane bisect

Goal: find the minimum RTL changes needed for `example_demo/ypcb_00338_1p1` to pass BIST with `BIST_MODE=2` and `BYTE_LANES=2` on OpenXC7.

LED convention from board tests:

- PASS: `led0 on, led1 off, led2 on`
- FAIL: `led0 off, led1 on, led2 on`

## Change axes from 523284a

| Axis | Change vs 8b21e46                                                                  | Status                | Notes                                                                                 |
|------|------------------------------------------------------------------------------------|-----------------------|---------------------------------------------------------------------------------------|
| A    | `BYTE_LANES` 1 -> 2 and derived Wishbone/DQ widths                                 | Required target       | Needed because we are testing 2 byte lanes.                                           |
| B    | `BIST_MODE` 1 -> 2                                                                 | Required target       | Needed because we are testing full BIST mode 2.                                       |
| I    | `BIST_TEST_DATAMASK` 1 -> 0                                                        | Suspected required    | Board appears not to support DM; `ddr3_top` default is 1.                             |
| J    | Explicit `BIST_LIMIT_BITS=0`                                                       | Likely redundant      | `ddr3_top` default is already 0.                                                      |
| C    | Add `o_debug8[63:0]` into a 960-bit `jtag_debug_bscan` payload at bits `[511:448]` | Suspected required    | Removing BSCAN fails; zeroed BSCAN fails; 512-bit BSCAN preserving `[511:448]` fails. |
| D    | Expose/connect `o_debug2`..`o_debug7`                                              | Probably not required | Cleanup that opened them passed earlier.                                              |
| E    | Keep/use `ddr3_dm` instead of opening `.o_ddr3_dm()`                               | Probably not required | Cleanup that opened DM passed earlier.                                                |
| F    | `ODELAY_SUPPORTED` macro wrapper instead of hardcoded `0`                          | Probably not required | Both tested pass in broader combinations.                                             |
| G    | Remove ``default_nettype none`` and change timescale to `1ns / 1ps`                | Not required          | Removing default_nettype passed earlier.                                              |
| H    | Formatting, instance/wire names, `sys_clk` alias, literal widths                   | Not expected          | `ad6fec2` restored wrapper shape and passed.                                          |

## Experiments

| Commit              | Experiment                                         | Bitstream SHA                                                      | LED result | Conclusion                                                                   |
|---------------------|----------------------------------------------------|--------------------------------------------------------------------|------------|------------------------------------------------------------------------------|
| `ad6fec2`           | Restore wrapper shape from `523284a`               | `a05ae91a4297283a6b97a29cf37f3c9ed68489d708978c645f2e6afa958c884d` | PASS       | Wrapper cleanup from `b8f903e` is not required.                              |
| `0cce2f6`           | Remove 960-bit BSCAN anchor                        | `f5cd902860654e7c68469d0cc89b63ee17eff860299fe72be144a2c8eb9f260d` | FAIL       | Some form of BSCAN anchor is required.                                       |
| `587d5fd`           | Restore 960-bit BSCAN but drive `960'd0`           | `39d85b792ee90c963009779e1e6c49a9328c28d1fde68f2b39416cf747cc5a57` | FAIL       | The `o_debug8[63:0]` payload connection is required, not just BSCAN ballast. |
| `70a66fc`           | Original `8b21e46` wrapper plus A+B+C+I+J          | `e1ee8f2f71fece3f4a252834953487c7c1b4f5c602de320b2785afceab5a3544` | PASS       | Original wrapper plus target settings and debug8 BSCAN anchor is sufficient. |
| uncommitted earlier | 512-bit BSCAN with `o_debug8[63:0]` at `[511:448]` | `79dc071be09794225b2fc4fc30db377974f37c4e23dbaaaaf6afa10f11844343` | FAIL       | The 960-bit width/upper padding matters for placement/routing.               |

## Next formal candidate

Start from `8b21e46` wrapper style and add only:

1. `BYTE_LANES=2` with derived DQ/DQS/DM slices.
2. `BIST_MODE=2`, `BIST_LIMIT_BITS=0`, `BIST_TEST_DATAMASK=0`.
3. `o_debug8[63:0]` routed through the 960-bit BSCAN payload at `[511:448]`.

This passed at `70a66fc`. Continue reducing J and then I to check whether the explicit BIST limit and datamask override are part of the minimum passing set.
