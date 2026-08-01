# Production UI Corrective Pass v2 Report

## Delivery

- Baseline: `5bd9e00fb0e06aeb5a53da1d6e235cd534e486ac`, tag `production-ui-finalization-v1`.
- Exact corrected UI source: `baae6488874174811207437d2b84f5daa6b148fa` (`fix: correct production HUD visual composition`).
- Delivery tag: `production-ui-finalization-v2`.
- Engine/render review: Godot 4.6.3 stable, Compatibility/ANGLE.
- APK: `D:\Owais\game\build\android\production-ui-finalization-v2.apk`.
- Size: 100,793,853 bytes; modified 2026-08-01 07:44:38 +05:00.
- SHA-256: `53CEF1A789A91956B80CF8EB627BCE066899C1445919104A366D162F23E61A38`.

This corrective pass fixes the defects still visible in the user's 576 x 1312 gameplay screenshot. It does not reinterpret the approved gameplay feel.

## Problems verified and fixed

| Area | Verified problem | Corrective result |
| --- | --- | --- |
| SCORE | Value sat low with weak bottom spacing; card read softer than its text | Equal 170 x 150 clipped card, crisp inner cream well, 58 px value row, adaptive 40/34/29 px type, and protected bottom breathing room |
| NEXT | Gem was oversized, crossed the card boundary, and outweighed SCORE | Contained 68 px aspect slot with larger internal margins; equal outer dimensions and matching content well |
| MERGE PATH | Tiny label/icons floated on the sky | 296 x 104 cream/gold panel, outlined heading, five readable 50 px catalog slots, consistent connectors and current/reached styling |
| Target | Ruby escaped the panel; name, count, and bar lacked a grid | 412 x 116 clipped card with 56 px inset icon, aligned detail column, `PROGRESS  n / n`, and visible 12 px track |
| Objective hierarchy | Level and Settings looked detached | 116 x 58 Level badge, target, and 88 px Settings control centered in one 120 px objective row |
| Design system | Mixed transparency, softness, borders, and shadows fragmented the HUD | Shared cached cream/coral/gold/teal surfaces, consistent borders/radii, and short shadows |
| Danger readability | Pale dashes disappeared against aqua felt | Same geometry rendered as coral dashes over a translucent dark backing; behavior and threshold unchanged |
| Safe area | The wider center group initially overconstrained a notched 720-wide layout | Final top-row minimum is 652 design px; 24 px side insets plus padding fit and remain asserted |

Pause, Win, and Fail were re-rendered after the correction. Their hierarchy, dimming, touch states, centering, and input blockers remain production-ready and required no structural change.

## Final hierarchy and tokens

```text
GameplayHud (CanvasLayer)
`- GameplayUIRoot (shared cached Theme)
   |- HudDesignCanvas / SafeHudMargin / HudRows
   |  |- MainRow
   |  |  |- ScorePanel / BodySkin / ContentSurface / Header / value
   |  |  |- ProgressionCenter / ProgressionPanel / five slots
   |  |  `- NextPanel / BodySkin / ContentSurface / Header / aspect icon
   |  `- ObjectiveRow
   |     |- LevelSlot / LevelChip
   |     |- TargetSlot / ActiveTargetPanel
   |     |  |- TargetBodySkin / TargetContentSurface / TargetHeaderSkin
   |     |  `- TargetContentMargin / icon + detail VBox + ProgressBar
   |     `- SettingsSlot / SettingsButton
   `- PauseInputBlocker / dimmer / safe-area-centered PausePanel
ResultOverlay (CanvasLayer) / dimmer / safe-area-centered Win or Fail panel
```

`UiDesignSystem` remains the single reusable authority. v2 adds cached HUD-content, progression-panel, level-badge, and progress-track styles. Existing palette, typography, spacing, touch sizes, button states, safe padding, shadows, radii, and animation durations remain centralized. No texture, font, or theme is loaded or created per frame.

Score formatting remains display-only: full grouped values through 9,999, compact K from 10,000, then M/B/T/Q/Qi; the controller integer remains exact. NEXT, merge-path, target, and result icons/names still come only from `AssetCatalog`.

## Assets

No new production raster was needed. The approved atlas, UI references, gem catalog, background, table, shadows, and popup references are unchanged. Native Godot panels, NinePatch slices, containers, labels, and aspect slots create the corrected composition. Evidence PNGs are development-only and excluded from export.

## Responsive and visual validation

Real renders passed at 576 x 1312, 720 x 1600, 1080 x 1920, 1080 x 2340, 1080 x 2400, and 540 x 1320. The 1080 x 2400 notch capture uses simulated 24/72/24/48 insets. No panel overlap, icon escape, score/target clipping, popup drift, or HUD/table overlap was found.

Evidence: `reports/production-ui-corrective-pass-v2/final-screenshots/`. The exact reported-state proof is `576x1312/details/screenshot-reproduction-score-1490.png`. The set also covers empty/crowded boards, score 0/9,999/125.5K/12.5M, both targets, identity changes, collection arrival, Settings pressed, Pause, Win, Fail, and restart.

## Tests and performance

Passed: `PRODUCTION_UI_FINALIZATION_TESTS`, `GAMEPLAY_UI_FEEL_TESTS`, `LEVEL_1_FLOW_TESTS`, `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE`.

The UI suite now asserts NEXT/target icon insets, score bottom breathing room, objective center alignment, all bounds, notch clearance, popup state, catalog mapping, maximum signed-score fit, cached resources, and 500 rapid updates. Final profile reported zero UI node delta, zero per-gem process callbacks, zero gameplay resource loads after initialization, 15 cached audio streams, and zero residual effects. Average process samples were 0.074 ms empty, 1.165 ms at 20 active gems, and 0.942 ms crowded; Pause UI idle averaged 0.001 ms.

## APK verification

The APK is a fresh signed debug export because the project has no configured release keystore; an attempted release export correctly stopped rather than produce a falsely claimed release artifact. ZIP validation found 355 entries, required manifest/dex/arm64 Godot runtime, and zero `reports/` or `tools/` entries. `apksigner` verifies v2/v3 signatures with one RSA-2048 signer. `adb devices -l` returned no devices, so installation and physical-device performance are not claimed.

## Gameplay freeze confirmation

Unchanged: table position; physical rails and following; table/gem perspective; collider scaling; gem motion and physics constants; merge behavior/eligibility; target difficulty/order/quantity/collection; score formula; launcher weights and active Level 1 gems; unlimited pushes; danger threshold/rule; reward, sound, and haptic timing; and core win/fail sequencing.

The only `GameController` edit changes the already-drawn danger line's presentation color/width. It still reads the identical `GameConfig.danger_line_y()`, `table_left_at()`, and `table_right_at()` coordinates and writes no gameplay state.
