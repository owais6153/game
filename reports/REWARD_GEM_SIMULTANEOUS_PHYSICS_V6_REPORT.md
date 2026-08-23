# Reward Gem Simultaneous Physics V6 Report

Date: 2026-08-23  
Baseline: `2fb8d15` / `reward-gem-split-readability-v5`  
Scope: generated reward reveal synchronization and first-visible-frame physics

## Requested correction

The observed merge could show the result gem first while another generated gem slid out later or appeared from behind. Physics also waited for the visual extraction to finish. The requested contract is that the result and all generated gems appear together in the same way, then behave as real physics bodies immediately.

## Root cause

The result used the confirmed merge timeline and revealed at 100-120 ms. Generated gems used an independent 280 ms delay, then a 780 ms presentation offset from the merge origin to a separate collision-safe body. Their velocity was stored behind `bonus_activation_delay_remaining`, and pair/bounds integration was skipped until the visual trip completed. The two outputs therefore had different reveal times, different transforms, and different physics start times by design.

## Delivered behavior

- The pending reward stores the exact confirmed result timeline and schedules at `timeline.reveal + depth * CHAIN_PRESENTATION_STAGGER`.
- All siblings for one event are created inside the same `_spawn_bonus_reward()` call with one shared frame-overshoot value.
- `_bonus_result_scale_for()` samples the result's own scale timeline, so result and siblings start at the same pop phase. Normal reveal is 0.65 and its shared peak is 1.24; combo/final tiers retain their configured result scales.
- Each reward renders at its real collision-safe position. The visual origin offset, extraction tether, elevation, and source recoil have been removed.
- The 135 px/s launch velocity is assigned immediately. Pending rewards update before the same frame's simulation, so integration, rails, gem collision, separation, restitution, and contact telemetry are live when the gem appears.
- The 650 ms grace remains only around merge-candidate capture. It prevents an unreadable instant follow-up merge without making the body nonphysical.
- Reward outputs remain persistent ordinary `GemPiece` objects, use distinct eligible tiers when possible, and retain all cascade limits.

## Central tuning record

| Setting | Before V6 | V6 | Guardrail |
|---|---:|---:|---:|
| Generated reward reveal | 280 ms + depth stagger | result timeline reveal (100-120 ms) + depth stagger | same frame as result, within one render-frame overshoot |
| Generated reward visual duration | 780 ms | 300 ms normal/combo reveal-to-settle | 280-360 ms if later retuned |
| Generated reward start scale | fixed 0.48 | result timeline 0.60-0.65 | must equal selected result timeline |
| Generated reward peak | fixed 1.12 | result timeline 1.24-1.40 | must equal selected result timeline while shared |
| Physics activation delay | 780 ms | 0 ms; field/path removed | fixed at zero |
| Launch impulse | 135 px/s | 135 px/s | 110-155 px/s |
| Merge-only grace | 650 ms | 650 ms | 500-750 ms |
| Chain visual spacing | 260 ms/depth | 260 ms/depth | 220-300 ms/depth |

## Preserved systems

No score, target, coin, launcher, collision geometry, radius, containment, save, audio, haptic, shadow, HUD, or final-celebration rule changed. Cascade bounds remain three generated pieces per shot, generation through COMBO 2, and 24 live-plus-pending pieces.

## Files changed

- `scripts/game_config.gd`
- `scripts/game_controller.gd`
- `scripts/board_simulation.gd`
- `scripts/gem_piece.gd`
- `scripts/gem_sprite_layer.gd`
- `tests/run_reward_feedback_v3_tests.gd`
- `tests/capture_reward_feedback_v3.gd`
- Required state, architecture, knowledge-base, changelog, sound-routing, report-index, report, and build-manifest documentation

## Validation evidence

- All nine Godot 4.6.3 headless suites printed their PASS sentinel: reward feedback, reference feel, animation/audio/back/privacy, UI/layout, game flow/reward/splash, sound/privacy, branding/push line, scene variety/assets, and AdMob integration.
- Each process then returned the repository's previously recorded Windows Godot teardown access-violation code `-1073741819`; no suite assertion failed, and acceptance is based on the explicit PASS sentinel as in prior milestones.
- The regression asserts reveal-frame scheduling, same elapsed/duration for multi-gem siblings, immediate nonzero velocity, movement on the first isolated step, physical collision during merge grace, later ordinary merge eligibility, persistence, distinct tiers, and the existing cascade caps.
- GL Compatibility/ANGLE production-controller capture: PASS, 33 PNGs in `reports/reward-gem-simultaneous-physics-v6/screenshots/`.
- Reviewed normal 150 ms versus 280 ms and COMBO 2 670 ms versus 800 ms: every result/reward output is visible together first, then visibly separated by real physics. No tether, behind-result travel, or visual slide remains.

- Standalone debug APK exists: `build/android/majestic-gems-reward-gem-simultaneous-physics-v6.apk`, 82,273,288 bytes (78.46 MiB), exported 2026-08-23 13:23:58 +05:00, SHA-256 `25347DE379C63F0EF3E537A8462599527365E7DF83A4A4B136C17018DDE8D82A`.
- AAPT: package `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36, portrait/game configuration.
- APK Signature Scheme v2: PASS; one Godot RSA-2048 debug signer, certificate SHA-256 `3b2933181e64f32dae1d52a01642be2c469b36ec05ead7313cde0d6d672ad10f`.
- ZIP audit: 1,004 entries, both `arm64-v8a` and `armeabi-v7a`, all five changed compiled gameplay/rendering scripts present, zero packaged `tests/` or `reports/` entries.
- `export_presets.cfg` was temporarily switched to debug APK output and restored byte-for-byte to the committed AAB preset. No AAB was generated and no version value changed.
- `adb devices -l` started the daemon and listed no device. Installation, touch feel, frame pacing, listening, haptics, and physical-device acceptance are not claimed.

Source milestone: `6fcdb44` / `reward-gem-simultaneous-physics-v6-source`. Delivery provenance is committed and tagged as `reward-gem-simultaneous-physics-v6`.

## Release AAB v1.0.5 / versionCode 7

- A signed Play AAB was exported from `ef49309` / `reward-gem-simultaneous-physics-v1.0.5-vc7-source`: `build/android/majestic-gems-reward-gem-simultaneous-physics-v1.0.5-vc7.aab`.
- Size: 70,113,786 bytes (66.87 MiB); timestamp: 2026-08-23 13:47:05 +05:00; SHA-256: `337ADB0ED1EC07B27CC8F775EC700516A88CA5A82B9A5525186713F2430EB38F`.
- `export_presets.cfg` now persistently contains versionCode 7 / versionName 1.0.5 and the versioned AAB path. Both values are strictly newer than the prior release identity 6 / 1.0.4.
- Bundletool 1.18.3 validates the bundle and confirms its embedded manifest contains versionCode 7 / versionName 1.0.5. Both ARM architectures, base DEX, the five V6 compiled scripts in the install-time asset pack, and zero packaged tests/reports were verified.
- `jarsigner -verify -certs` reports `jar verified`; the configured local upload certificate is self-signed and untimestamped. `REWARD_FEEDBACK_V3_TESTS: PASS` was rerun after preparing the release version. No device was connected and no Play upload is claimed.
