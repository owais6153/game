# HUD Density and Collision Stability V1

Date: 2026-08-25

## Scope

Focused cleanup of the gameplay HUD and crowded-gem collision presentation. No table geometry, target rules, gem identity mapping, score/reward logic, launcher behavior, or Android configuration changed.

## HUD cleanup

- Reduced the eight-gem progression artwork from 64 px to 56 px inside its existing 620x88 strip. The strip's anchors, panel size, hierarchy, and level ordering are unchanged; the smaller artwork restores visible separation between silhouettes and arrows.
- Fixed the in-game settings cog sizing mismatch: its child control now matches the existing 64 px utility frame instead of requesting 88 px and overflowing the frame. The placement beside the Next card is unchanged.
- Existing dark-amethyst surfaces and the no-box-shadow rule remain intact.

## Collision stabilization

`BoardSimulation` now performs three bounded pair-separation sweeps per simulation substep. Only the first sweep captures merge contact and records impact telemetry. The remaining sweeps are physics-only, preventing a gem compressed by several neighbours from retaining visible penetration while preserving exactly-once merge/audio behavior.

## Validation

- `REFERENCE_GAME_FEEL_V2_TESTS: PASS` — includes a new three-gem dense-pile regression proving non-matching gems finish without overlap and without a merge.
- `UI_SCALE_LAYOUT_TESTS: PASS` — phone/tall-phone layout checks, safe bounds, non-overlap, centered target/progression, and cog-frame fit.
- `GEM_PATTERN_FEEDBACK_V1_TESTS: PASS` — confirms the 34-gem catalog, deterministic patterns, target feedback, and shadow-free HUD styles remain valid.

No Android export was run for this focused source/test milestone. No connected-device test is claimed.
