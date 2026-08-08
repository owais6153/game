# Transparent Purple Glass HUD v1 Report

Date: 2026-08-08

## Outcome

The professional HUD now has a clearly visible transparent purple-glass effect. Tropical palms, sky, and cloud values show subtly through the beveled header, merge tray, Coins, Target, and Next cards, while lavender rims, short shadows, and white outlined values preserve game-ready contrast.

Gem names and gem-name tooltips remain absent.

## Implementation

- Lowered and purple-tinted the cached header/card/path/Target style alpha values in `UiDesignSystem`.
- Switched Coins and target progress values to outlined white and changed path connectors to lavender.
- Kept the existing professional hierarchy, dimensions, icon slots, style cache, and bounded tweens.
- Added explicit purple-hue/opacity assertions and a dedicated deterministic capture route.

No raster panel, blur shader, viewport capture, per-frame resource, or gameplay dependency was introduced.

## Gameplay boundary

This is a color/opacity presentation patch only. HUD hierarchy, snapshot data, icon mapping, collection destinations, table/background assets, physics, launcher, contact/merge rules, targets, progression, rewards, audio/haptics, danger, reset, and results are unchanged.

## Validation

- `GEM18_CHAIN_TESTS`: PASS
- `CLEAN_CONTACT_TESTS`: PASS
- `GAMEPLAY_UI_FEEL_TESTS`: PASS
- `INFINITE_LEVEL_TESTS`: PASS
- `LEVEL_1_FLOW_TESTS`: PASS
- `PRODUCTION_FOUNDATION_TESTS`: PASS
- `PRODUCTION_UI_FINALIZATION_TESTS`: PASS
- `MOTION_PROFILE`: PASS; crowded-board average/worst `2.148/5.184 ms`, Pause average/worst `0.002/0.004 ms`, zero per-gem callbacks, zero post-initialization resource loads, bounded effects `0`, and final node delta `0`.
- `TRANSPARENT_PURPLE_GLASS_HUD_V1_CAPTURE`: PASS using Godot 4.6.3 Compatibility/ANGLE.

Evidence covers 576x1312, 720x1600, 1080x1920, 1080x2340, 1080x2400, and 540x1320, plus notch, Pause, target transition, reward flight, crowded board, and danger states.

## APK delivery

- Source: `adab9e8813d8bc7b20b7e7023e2a4870e6b469e9` / `transparent-purple-glass-hud-v1-source`
- APK: `build/android/transparent-purple-glass-hud-v1.apk`
- Size: 122,882,166 bytes
- SHA-256: `6BE8A23787D9187D86E2A9BD66E0504C3FF30793037F2B3916D4007C82248966`
- Export: Godot 4.6.3 headless Android debug preset; export, alignment, signing, and Godot verification completed successfully.
- Package audit: 415 entries, one Android manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths.
- Signature audit: APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: `adb devices -l` did not complete within the validation window. Installation, launch, physical transparency/readability, safe-area/touch behavior, phone performance, listening, and haptics are not claimed.

## Evidence

See [transparent-purple-glass-hud-v1/README.md](transparent-purple-glass-hud-v1/README.md).
