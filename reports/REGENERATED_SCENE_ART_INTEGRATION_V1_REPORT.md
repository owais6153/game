# Regenerated Scene Art Integration v1

Date: 2026-08-16

## Request

Integrate the user's updated backgrounds and tables, remove the previous scene assets, make the variants change by level, and verify that the new table artwork matches the existing danger line and physics without changing gameplay behavior. Do not create an APK or AAB before Godot review.

## Delivered state

- Replaced the prior canonical scene sources with 19 new opaque 941x1672 background PNGs and 10 new transparent 1343x1171 table PNGs.
- Canonicalized the supplied files as `scene_bg_01_source.png` through `scene_bg_19_source.png` and `table_01_source.png` through `table_10_source.png` under `assets/source/`.
- Created optimized 720x1280 background WebPs and transparent 920x810 table WebPs under `assets/runtime/` using `tests/prepare_regenerated_scene_assets.gd`.
- Deleted the temporary single-table runtime asset `assets/runtime/table/new_table_v1.png` and removed `AssetCatalog.ORIGINAL_TABLE`.
- Restored `GameController` selection through each generated level's deterministic `background_index` and `table_index`. Restarting the same level/seed retains the same pair.

## Geometry and physics verification

No production geometry changed. Every table uses the existing shared transform and fixed `GameConfig` landmarks:

| Landmark | Fixed value |
| --- | ---: |
| Outer table Y | `400..1185` |
| Board Y | `440..1110` |
| Back rail X | `188..532` |
| Front rail X | `62..658` |
| Danger Y | `960` |
| Launcher Y | `1042` |
| Texture center Y | `792.5` |
| Texture render scale | `0.7391304 x 0.9691358` |

The ten normalized images were measured at the board-top and danger-line rows before runtime integration. After applying the production transform, every visible back-field edge and danger-height inner edge is within 10 design pixels of the corresponding fixed physical edge or the intentionally inset danger-line endpoint. These measurements are stored only in `run_ui_scale_layout_tests.gd`; production does not read image pixels or apply per-table offsets.

Twenty real Godot Compatibility/ANGLE proofs were generated—each table at 720x1280 and 720x1600—and visually reviewed. The proof pieces touch the legal back/side limits, the dashed danger line terminates at the visible inner rails, transparent corners remain clean, and no table requires a physics or aspect-ratio adjustment. Evidence is under `reports/regenerated-scene-art-integration-v1/final-screenshots/`.

## Optimization

| Set | Previous bytes | New bytes | Change |
| --- | ---: | ---: | ---: |
| Runtime backgrounds | 2,194,412 | 1,252,320 | -942,092 |
| Runtime tables | 873,750 | 893,444 | +19,694 |
| Total runtime scene art | 3,068,162 | 2,145,764 | -922,398 (30.06%) |

The replacement source set totals 50,976,866 bytes, 9,214,096 bytes below the replaced source set. Sources remain export-excluded; only runtime derivatives are production dependencies.

## Validation actually run

- Asset preparation: `REGENERATED_SCENE_ASSET_PREPARATION: PASS`.
- Godot editor import/parse: completed successfully.
- Scene catalog/runtime dimensions/transparency/retry coverage: `SCENE_VARIETY_ASSETS_TESTS: PASS`.
- Fixed physics, all-ten-table measurement, and responsive HUD geometry: `UI_SCALE_LAYOUT_TESTS: PASS`.
- Branding and draggable push-line regression: `BRANDING_PUSH_LINE_TESTS: PASS`.
- Reward and game-flow regression: `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- All-table visual capture: `TABLE_ART_CONTAINMENT_HUD_CAPTURE: PASS`; 20 outputs visually reviewed.

On Windows, several script-runner processes returned exit code 1 during known engine teardown after printing their PASS sentinel; the editor import/parse run exited 0. An optional additional six background/table pairing capture was not rerun because the execution approval service reached its usage limit. Existing catalog determinism tests and the completed 20-table renders are the acceptance evidence for this source milestone.

## Scope boundaries

No gem radius, collision response, solver, rail coordinate, movement, launch, input, merge, target, queue, reward, scoring, audio/haptic, ad, result, or HUD behavior changed. No APK or AAB was created, as requested.
