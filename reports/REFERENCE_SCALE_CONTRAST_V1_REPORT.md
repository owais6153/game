# Reference Scale Contrast v1

## Reference finding

The supplied reference was rechecked at normal cluster frames (`13.8-14.4 s`, `45.8-46.5 s`) and target-result/reward frames (`14.8-16.0 s`, `47.0-47.8 s`). The important distinction is:

- higher board tiers have substantially stronger size contrast than the prior two-pixel ladder;
- the active-target preview is presentation-only;
- the achieved target becomes temporarily larger during result/collection presentation, not through a permanently enlarged physics body.

The prior production path also contained a concrete scale-continuity bug: live gems mapped texture width and height independently to the collider diameter, but the target collection proxy used one `diameter / max_texture_dimension` scalar. Narrow textures therefore shrank and changed silhouette as soon as their physics body became the collection proxy.

## Delivered correction

| Tier | Prior radius | Delivered radius |
| --- | ---: | ---: |
| L1 | 36 | 30 |
| L2 | 38 | 33 |
| L3 | 40 | 36 |
| L4 | 42 | 39 |
| L5 | 44 | 42 |
| L6 | 46 | 45 |
| L7 | 48 | 48 |
| L8 | 50 | 51 |

The result is a moderate 3 px step and `1.70x` L8/L1 ratio. L1 remains readable, L8 remains bounded at 51 px, and both render and physics consume the same values.

Target collection now starts from the exact live-gem per-axis texture scale, after its physics body has been removed. A uniform `1.18x` early collection pop makes the qualified target visibly larger than an ordinary same-tier gem without changing its shape or collision footprint. The normal merge pop remains `1.20x`; the TARGET HUD slot remains 80 x 80.

## Visual evidence

- [L1-L8 board scale ladder](reference-scale-contrast-v1/final-screenshots/01-l1-l8-board-scale-ladder.png)
- [Ordinary L5 versus target reward pop](reference-scale-contrast-v1/final-screenshots/02-normal-l5-vs-target-reward-pop.png)

Both are real 720 x 1600 Compatibility/ANGLE renders driven through production scene APIs. The second frame proves the target proxy is larger than the ordinary same-tier gem while the target physics body is absent.

## Validation

- `run_18_gem_chain_tests.gd`: PASS - exact ladder, monotonic tiers, complete L1-L18 chain.
- `run_clean_contact_tests.gd`: PASS - radius-derived contact fixtures, upgraded size, collision/containment/audio boundary.
- `run_gameplay_ui_feel_tests.gd`: PASS - exact proxy X/Y mapping, `1.18x` target pop, body removal, unchanged target/coin/result flow.
- `run_level_1_flow_tests.gd`: PASS - unlimited launcher and L5 -> L7 -> L8 sequence.
- `run_production_ui_finalization_tests.gd`: PASS - responsive HUD including unchanged target slot.
- `run_motion_profile.gd`: PASS - zero per-gem callbacks, zero runtime resource loads, bounded effects, zero node delta.
- `capture_reference_scale_contrast_v1.gd`: PASS - two reviewed ANGLE proof frames.

The recurring Windows root-certificate/exit resource warnings do not change successful suite exit codes. No connected-device result is inferred from desktop validation.

## Delivery

- Baseline tag: `reference-scale-contrast-v1-baseline` at `1137fdc50e36e6a0392e8684a2b02ea35350248d`.
- Source/export/delivery identifiers and APK audit are recorded after the single final export.
