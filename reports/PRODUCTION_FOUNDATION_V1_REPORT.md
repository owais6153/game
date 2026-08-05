# Production Foundation v1 Report

## Scope

This milestone closes four production blockers: app-wide persistent settings, inconsistent gem silhouettes, an opening difficulty spike, and default Godot application branding.

## Delivered behavior

- Pause exposes independent Music, Sound FX, and Vibration switches. Changes apply immediately and persist through level transitions, Restart, Home, and app relaunch.
- Continuous music and confirmed-event sounds have separate gates. Existing target-only coin, merge, contact, result, cooldown, and concurrency routing is unchanged.
- Live table gems preserve the same catalog texture aspect ratio used by merge, collection, target, next, result, and path art. Collision radii and simulation are unchanged.
- Level 1 teaches the loop with one L5 target. Level 2 introduces L5 then L6. From Level 3, targets are unique ascending selections from L5-L8: three normally and two every fourth level.
- Launcher help decreases across INTRO, EASY, NORMAL, CHALLENGE, and capped EXPERT bands. Every template retains L3 and L4, launches remain unlimited, and difficulty never scales past the cap.
- Application title is `Gem Rush`; a dedicated GEM RUSH logo replaces the generic project icon and boot splash.

## Asset provenance

The built-in image-generation tool created `assets/generated/gem_rush_app_icon_source_v1.png`. The prompt requested the established GEM RUSH gold lettering, pearl and red/green/blue jewel cluster, leaves, teal/ocean background, coral/gold rim, Android-safe margins, and no Godot mark or extra words. The identical runtime mapping is `assets/runtime/ui/gem_rush_app_icon_v1.png`; both are 1254 x 1254 PNG files with SHA-256 `BB4D2AEDE4424EEAE8360A20E114B1290B6E1624EBC152346C57505C32051F67`.

## Architecture and safety

- Settings storage is isolated in `GameSettingsService`; UI emits intent and reads controller snapshots only.
- Difficulty remains data-owned by `LevelConfig`; no simulation or merge rule is duplicated.
- Gem shape correction is rendering-only in `GemSpriteLayer`; physics still uses centralized `GameConfig` radii.
- Package identifier remains unchanged to preserve the Android upgrade path and app data.

## Validation

- `tools/run_production_foundation_tests.gd`: PASS for branding, persistence, independent audio gates, shared gem texture/uniform scale, opening targets, two/three-target cadence, and capped reachability.
- `run_18_gem_chain_tests.gd`, `run_clean_contact_tests.gd`, `run_gameplay_ui_feel_tests.gd`, `run_infinite_level_tests.gd`, `run_level_1_flow_tests.gd`, and `run_production_ui_finalization_tests.gd`: PASS.
- `run_motion_profile.gd`: PASS with zero per-gem process callbacks, zero runtime gameplay resource loads, zero node delta, and 16 cached audio streams.
- Standalone APK: `build/android/production-foundation-v1.apk`, 122,878,070 bytes, SHA-256 `F93ADAF33DDA308D3B7F9FFE3E9210D7601B75ECEA77971EA260C8A9632ED1FD`.
- Package audit: 415 entries, zero packaged source/report/build paths, 24 launcher-icon resources, and APK Signature Scheme v2/v3 verification with one signer.
- Source commit/tag: `8fe30ea652b2ac49c3369fcc9013df64dcaf1692` / `production-foundation-v1-source`.
- `adb devices -l` returned no connected device. Installation, launcher icon/splash appearance, phone listening, and haptics are not claimed.
