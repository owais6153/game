# Merge Animation Revert + L1-L8 Size Calibration v1

## Requested correction

The v4 filled result-color splash was an incorrect interpretation and is removed. The merge animation is restored to the immediately previous production implementation while every unrelated v4 improvement remains intact. Active Level 1 gems now grow consistently from L1 through L8, with rendering and circular physics changing together.

## Delivered behavior

- Merge presentation restored to `0.50 s` total and `0.10 s` source pull.
- Result art remains rigid and centered, using uniform scale `0.62 -> 1.20 -> 1.0` with the prior damped settle.
- The filled irregular polygon and four droplets are absent. The prior short flash, expanding ring, and eight ray sparks are restored; L6+ uses the prior `0.56 s` duration and `1.16x` effect scale.
- Target-only four-coin choreography, target check/handoff, supplied coin cue, continuous soft supplied music, push-guide removal, reward integers, and L5 -> L7 -> L8 progression are unchanged.

## Visual/physics size calibration

The runtime textures were checked against `assets/runtime/gems18/calibrated/calibration_manifest.json` before geometry changed. L1-L8 derivatives are already non-destructively alpha-trimmed at threshold 128 with one antialias-padding pixel; their recorded opaque-body bounds range from 191 to 254 px wide and 218 to 254 px high. No source or runtime raster was modified.

| Tier | Before radius | Delivered radius |
| --- | ---: | ---: |
| L1 | 42 | 36 |
| L2 | 42 | 38 |
| L3 | 33 | 40 |
| L4 | 42 | 42 |
| L5 | 42 | 44 |
| L6 | 42 | 46 |
| L7 | 42 | 48 |
| L8 | 32 | 50 |

The approved safe range for this current-level ladder is 36-50 design px with a 2 px increase per tier. `GameConfig.GEM_COLLISION_RADIUS` supplies `GemPiece.base_radius`; `GemSpriteLayer` maps the texture body diameter from that base radius; `GemPiece.apply_perspective_scale()` applies the same depth scalar to the live physical radius and visual root. Upgraded merge results request the next tier radius directly from `GameConfig`. L9-L18 retain their prior 42 px fallback because they are outside the requested level scope.

## Regression evidence

- `run_18_gem_chain_tests.gd`: PASS - full tier chain, exact L1-L8 ladder, monotonic growth, shared perspective/radius behavior.
- `run_clean_contact_tests.gd`: PASS - contact-only merge, upgraded-result radius, visible diameter linkage, wall containment, contact-audio boundary, motion and lifecycle rules.
- `run_gameplay_ui_feel_tests.gd`: PASS - restored merge record/timing, rigid uniform result art, unchanged four target-only coins and target/audio flow.
- `run_level_1_flow_tests.gd`: PASS - unlimited launcher and exact L5 -> L7 -> L8 sequence.
- `run_production_ui_finalization_tests.gd`: PASS - responsive production UI unaffected.
- `run_motion_profile.gd`: PASS - crowded-board average `1.171 ms`, worst `2.477 ms`; zero per-gem callbacks, zero gameplay resource loads after initialization, zero node delta.

The Windows runner requires an explicit per-suite `--log-file` because simultaneous Godot instances collided on the default timestamped log. The initial parallel attempt crashed before suite execution; all reported results above come from clean sequential reruns. The recurring Windows root-certificate warning is environmental and did not change suite exit codes.

## Delivery

- Baseline tag: `merge-animation-size-calibration-v1-baseline` at `ce34f6e16a2e041f3fc53fc4625c8c4d79f60268`.
- Source commit/tag: `c5487a5d` / `merge-animation-size-calibration-v1-source`.
- Clean export source commit/tag: `5d5e7867d4e465a75dbead63c5aefdef584f4e17` / `merge-animation-size-calibration-v1-export-source`.
- Delivery tag: `merge-animation-size-calibration-v1`.
- APK: `build/android/merge-animation-size-calibration-v1.apk`, 104,471,551 bytes, SHA-256 `93B8FD867E9389CAC584007EE22523B05F5211A953E01E7AA29D7C3408D41565`; 387 entries, manifest/dex/arm64 present, forbidden build/report/tool/generated-source entries absent, v2/v3 signature verified with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; install, launch, phone feel, listening, and haptics are not claimed.
