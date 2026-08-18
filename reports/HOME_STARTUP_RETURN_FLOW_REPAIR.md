# Home Startup and Return Flow Repair

Date: 2026-08-18

## Reported regression

The delivered APK could open directly into a level, and returning Home from gameplay did not reliably expose an interactive Home screen.

## Root cause

Production startup used `OS.has_feature("mobile")` as a flow decision. Its false branch explicitly set `AppFlowState.PLAYING` without presenting Home. That made app flow depend on export/runtime feature detection instead of the product requirement.

The previous regression tested `HomeOverlayLayer` only. It never instantiated `GameController`, so it could pass while production startup skipped the overlay. Level Ready Back also intentionally consumed navigation without returning Home, contradicting the current specification.

## Fix

- Startup always calls `_show_home()` after initialization.
- Pause HOME routes through `_on_pause_home_requested()`, clears Pause ownership, then presents Home.
- Level Ready Back emits `home_requested`; the controller performs the state transition.
- Added production-controller coverage for startup Home, Home -> Level Ready, Level Ready -> Home, START GAME -> Pause, and Pause -> Home.

## Regression audit

The preceding game-feel milestone changed simulation substeps, merge candidate consumption, feedback timing/drawing, and audio gains. Its diff contains no Home, result, scene, project, or export-flow file change. The startup bug was pre-existing but escaped the overlay-only test and became visible in the delivered build. The new controller-level test closes that gap.

Gameplay tuning, contact-only merging, target/reward rules, save data, UI design, ads/UMP, and Android identity remain unchanged.

## Validation

- Godot editor parse/import: PASS.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS, including production controller startup and Pause/Home navigation.
- `REFERENCE_GAME_FEEL_V2_TESTS`: PASS.
- `UI_SCALE_LAYOUT_TESTS`: PASS.
- `SOUND_PRIVACY_LINK_TESTS`: PASS.
- `SCENE_VARIETY_ASSETS_TESTS`: PASS.
- `BRANDING_PUSH_LINE_TESTS`: PASS.
- `ADMOB_INTEGRATION_TESTS`: PASS sentinel; the existing post-test Poing mock lambda teardown warning remains unrelated.
- Fresh debug APK audit: pending source milestone commit/export.
