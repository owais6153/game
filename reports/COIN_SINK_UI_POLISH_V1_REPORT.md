# Coin Sink UI Polish V1

## Scope

This milestone refines the two existing coin sinks without changing their prices or transaction authority. Live gameplay contains one Switch Gem action; Skip Level is available only from Level Ready, Pause, and Failed overlays.

## Presentation and layout

- Switch Gem is a 112 x 112 design-pixel true-circle button with a four-pixel amethyst rim, distinct normal/hover/pressed fills, 18 px internal icon padding, and a centered caption.
- The supplied @icons dice glyph identifies Switch Gem. Its 100-coin price appears only in the existing transient spend popup.
- Skip Level uses the supplied @icons fast-forward glyph and displays `200 COINS` in Level Ready, Pause, and Failed decision surfaces. Successful Level Complete does not show Skip.
- The table composition remains lifted 64 design pixels as one authoritative transform. Table art, physical rails, board bounds, danger line, launcher, drag clamp, and containment retain their relative geometry.

## Asset and package boundary

- Source: `addons/at-icons/node/dice.svg` -> runtime `assets/runtime/ui/icons/dice_lavender.svg`.
- Source: `addons/at-icons/node/fast_forward.svg` -> runtime `assets/runtime/ui/icons/fast_forward_lavender.svg`.
- The supplied `addons/at-icons/` editor library contains 7,422 files / 5,717,830 source bytes. `export_presets.cfg` excludes the complete addon and `@icons picker.html`; runtime UI loads only the selected small SVG derivatives.

## Authority and safety

All UI layers emit `skip_level_requested`; only `GameController` may validate balance, persist spending, advance the deterministic level/seed, and reset into Level Ready. Skip never produces a win, reward, interstitial, or `level_complete` event. HUD and overlays remain snapshot consumers and do not duplicate economy logic.

## Validation

- `git diff --check`: PASS.
- `FIREBASE_ANALYTICS_PIPELINE_TESTS: PASS` (rerun with normal `user://` access after the sandboxed run correctly failed persistence writes).
- `UI_SCALE_LAYOUT_TESTS: PASS`.
- `RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS: PASS`.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- Standalone APK existence check: `build/android/majestic-gems-bigger-buttons-v4-test-debug.apk` exists (87,458,361 bytes; 2026-08-28 14:44:34 +05:00). It predates this final UI placement correction and was not rebuilt or delivered by this task.
- Connected-device status: `adb devices -l` returned no connected device. No installation, launch, or physical visual acceptance is claimed.
