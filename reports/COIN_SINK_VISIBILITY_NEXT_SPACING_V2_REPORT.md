# Coin Sink Visibility and Next Spacing V2

## Requested refinement

Match the supplied gameplay reference more closely by making Switch Gem unmistakable and by reducing excess space in Next so Settings remains visually independent.

## Changes

- Switch Gem retains its 112 x 112 touch target but changes from a circular dice treatment to a deep-purple 32 px-radius squircle with a four-pixel lavender-white rim.
- The icon is now a large pure-white clockwise-arrows glyph derived from `addons/at-icons/node/arrows_clockwise.svg`; the former dice runtime derivative is removed.
- The action is intentionally seated 36 design pixels across the table's lower outer edge, matching the supplied composition while remaining beneath the physical board and respecting the lower safe-area clamp.
- Next changes from `141.075 x 172` to `128 x 150`; its gem preview changes from 54 to 48 px. The explicit container gap before Settings changes from 8 to 12 px.

## Safety boundary

This is presentation-only. It changes no controller snapshot fields, coin prices, spend rules, launcher behavior, board coordinates, rails, collision, danger line, target rules, score, rewards, or result flow. The full @icons editor addon and picker remain excluded from Android exports.

## Validation

- Godot asset import/whole-project script parse: PASS. The Windows environment emitted its existing root-certificate/editor-settings warnings; neither affected import or parsing.
- `UI_SCALE_LAYOUT_TESTS: PASS` across all eight portrait/cutout viewports, including the new compact-Next and minimum Settings-gap assertions.
- `git diff --check`: PASS.
- Standalone APK existence: `build/android/majestic-gems-bigger-buttons-v4-test-debug.apk` exists (87,458,361 bytes; 2026-08-28 14:44:34 +05:00). It predates this V2 refinement; no APK/AAB was rebuilt or delivered.
- Connected-device status: `adb devices -l` returned no device. No installation or physical visual acceptance is claimed.
