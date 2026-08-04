# Reference Target Reward Correction v3 Report

## Outcome

This milestone corrects the last three reported mismatches: coin rewards are target-only, the contaminated music loop is inactive, and the vertical push guide is gone. It preserves the approved rigid gems, four-coin artwork/path, foreground layering, L5 -> L7 -> L8 target collection/handoff, physics, launcher, danger, and result flow.

## Reference-video findings

- Reference: `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`, 79.313 s, 1280 x 576, SHA-256 `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`.
- The entire video was reviewed at one-second cadence. The three reward intervals were then reviewed at `0.2 s` cadence: `13.0-17.8 s`, `45.0-49.8 s`, and `56.0-60.8 s`.
- Visible coins begin around `14.6 s`, `46.6 s`, and `58.0 s`. In all three cases the board result matches the current target and the target/card state advances. No coin flight appears on an ordinary merge between those events.
- The earlier report's "ordinary reward around 46.55-48.45 s" statement was incorrect; that window is the second target reward.
- The supplied MP4 exposes one mixed audio track. The extracted `25.05-26.90 s` loop contains embedded reward audio, so clean music and coin balance cannot be guaranteed by cutting that recording alone.

## Implemented behavior

- `GameController` awards run coins only when a unique confirmed result matches `active_target_tier()`. Ordinary merges award zero, register no pending HUD reward, and create no coin records.
- `GameplayEffectsLayer.begin_merge_feedback()` now creates impacts only. The separate `begin_target_coin_reward()` entry point creates exactly four compact foreground coins for a qualified target result. Arrival chunks still reconcile the visible counter to the exact authoritative integer; final victory still waits for the last coin.
- `AudioFeedbackService` no longer preloads the mixed loop or creates an ambience player. The preserved Ogg was not deleted. Fifteen bounded gem-event streams, contact thresholds/cooldowns, three-player reuse, sound toggle, and service-owned haptics remain.
- `_draw_aim_guide()` and `AIM_GUIDE_WIDTH` / `AIM_GUIDE_ALPHA` are removed. The horizontal danger line and every gameplay coordinate remain unchanged.

## Preserved values and boundaries

- Target order: L5, L7, L8; quantities remain one each.
- Target reward values remain the centralized tier table; chain multiplication and exactly-once result IDs remain.
- Coin count `4`, draw radius `14.5`, burst `0.38 s`, flight `1.70/1.75 s`, stagger `0.09 s`, cluster radius `44/48`, foreground layering, and record cap `32` remain.
- Launch `1160`, damping `185`, wall restitution `.24/.22/.12`, piece restitution `.30`, friction `.07`, merge momentum/cap `.62/420`, colliders, rails, contact rules, danger grace, collection duration, and target transitions remain unchanged.

## Validation and delivery

- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `CLEAN_CONTACT_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `MOTION_PROFILE: PASS`; `cached_audio_streams=15`, gameplay resource loads after initialization `0`, bounded effects after cleanup `0`, node delta `0`.
- `REFERENCE_TARGET_REWARD_CORRECTION_V3_CAPTURE: PASS` under Godot 4.6.3 Compatibility/ANGLE at 720 x 1600. Runtime proof: `ordinary_total=0`, `ordinary_coin_records=0`, `target_total=150`, `target_coin_records=4`, `push_guide=false`.
- The Windows certificate-store warning and known motion-profile exit warning were non-fatal; no relevant assertion failed.

Four reviewed production frames are stored under `reports/reference-target-reward-correction-v3/final-screenshots/`: ready board with no vertical guide; ordinary L6 impact with zero coins; active L5 target with exactly four coins; and the four target coins crossing the HUD foreground.

## Delivery provenance

- Source commit/tag: `77daaa0c69de40140f546217f004d37abc556473` / `reference-target-reward-correction-v3-source`.
- Delivery tag: `reference-target-reward-correction-v3` on the manifest/report delivery commit.
- APK: `build/android/reference-target-reward-correction-v3.apk`, 102,848,585 bytes, modified `2026-08-04 11:45:35 +05:00`, SHA-256 `7BEDDD928F29CAD89E05CDB410EFF6203E8DC6612D265614E84D4FBD440A4B7D`.
- Package validation: 379 ZIP entries; manifest, primary dex, and arm64 Godot runtime present; zero `reports/`, `tools/`, or `assets/generated/` entries; APK Signature Schemes v2/v3 verified with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device. Installation, on-phone launch/performance, audio listening, and haptics are not claimed.

## Manual audio requirement

Provide separate clean source files for continuous music and the coin effect. With those files, production can route, loop, gain-stage, toggle, and test the two layers independently. The mixed reference recording alone cannot guarantee that separation.
