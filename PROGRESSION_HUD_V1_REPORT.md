# Progression HUD v1 Report

## Baseline and scope

- Starting verified source: `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b` / `physics-pacing-parity-v1`.
- Scope: presentation-only progression preview, current/next gem cards, HUD cleanup, and overlay consistency.
- Explicitly preserved: simulation coordinates, physics, strict current-contact merging, chains, score calculation, launcher lifecycle, danger timing, win/fail behavior, and restart.

## Design

- The top HUD now uses a compact score/chain/shots block, two gem queue cards, a Pearl-to-Diamond evolution strip, and a smaller Restart control.
- The evolution strip uses existing procedural gem styles. Diamond is always highlighted as the target; the highest live gem has a brighter rendering only.
- `HudRenderer` draws from `GameController.hud_snapshot()` so UI state cannot duplicate or alter gameplay logic. It has no input handling, leaving all board drag input in `GameController`.
- The existing result overlay keeps its score and Replay/Retry controls and matches the same gold-edged jewelry panel treatment.

## Responsive checks

Safe-bound regression coverage verifies 720x1280, 1080x1920, 1080x2400, 1440x3200, and a 900x1280 wider/shorter portrait shape. The HUD remains above the board, the progression strip remains compact beside Restart, and the board input area is untouched.

## Files changed

- `scripts/hud_renderer.gd`
- `scripts/game_config.gd`
- `scripts/game_controller.gd`
- `tools/run_clean_contact_tests.gd`
- Required project documentation and build provenance files.

## Validation and delivery

- Godot parse/import validation: passed.
- Headless controller/simulation suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Android export, APK details, commit, tag, and device status: recorded after the delivery build completes.

## Known limitations / phone checklist

- This remains a procedural, asset-free HUD with no sounds, haptics, saves, ads, menus, or external final assets.
- On phone, check that the progression strip stays readable, current/next previews match each shot, Restart remains reachable, and dragging the launcher is not blocked by the HUD.
