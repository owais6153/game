# Sound + Haptics v1 Report

## Scope and baseline

- Starting verified baseline: `2dc007575457fec112acabc51b7d6dcfb9f06462` / `progression-hud-v1`.
- Scope: lightweight procedural one-shot feedback, Android haptics, compact session-only controls, and feedback routing tests.
- Preserved: physics, current-step merge eligibility, contact chains, scoring, launcher lifecycle, danger timing, outcomes, replay/retry, and HUD data ownership.

## Feedback design

- `AudioFeedbackService` routes procedural launch, material collision, four level-specific merge tones, chain accent, win, fail, and button cues. It uses three reusable `AudioStreamPlayer` nodes and short generated tones at 22,050 Hz; there are no external/copyrighted assets or background music.
- `HapticsService` routes mobile-only feedback behind a safe `OS.has_feature("mobile")` guard. Editor/headless use records the request for validation but never calls a platform vibrator.
- Feedback is driven only by confirmed controller events: a launch, measured physics impacts, confirmed merge events, confirmed chain depths, or one-time result transitions.
- Sound and vibration controls are session-only, default On, and survive Replay/Retry. `S` is sound; `V` is vibration.

## Tunable constants

- Collision sound threshold: `170 px/s`; collision cooldown: `0.09 s`.
- Max concurrent one-shot players: `3`; sample rate: `22,050 Hz`.
- Merge, chain, win, and fail cooldowns/tones live centrally in `GameConfig.AUDIO_COOLDOWN_BY_EVENT` and `GameConfig.AUDIO_TONES`.
- Vibration duration/amplitude mappings live centrally in `GameConfig.HAPTICS_BY_EVENT`.

## Files changed

- `scripts/audio_feedback_service.gd`
- `scripts/haptics_service.gd`
- `scripts/game_config.gd`
- `scripts/board_simulation.gd`
- `scripts/game_controller.gd`
- `scripts/hud_renderer.gd`
- `tools/run_clean_contact_tests.gd`
- Required project documentation and build provenance files.

## Validation / delivery

- Godot 4.6.3 parse/import/headless validation passed.
- Full headless controller/simulation/feedback suite passed: `CLEAN_CONTACT_TESTS: PASS`.
- Standalone Android export passed and `build/android/sound-haptics-v1.apk` was physically verified.
- APK: `D:\Owais\game\build\android\sound-haptics-v1.apk` — 27,744,897 bytes — 2026-07-29 07:59:11 +05:00.
- Milestone source commit/tag: `5245163722e2c34f86657aa25483f47d96e7fdfa` / `sound-haptics-v1`.
- `adb devices -l` found no connected device; installation and launch were not attempted.

## Phone checklist

- Verify launch, impact, merge, chain, win, and fail cues are audible but not noisy.
- Toggle `S` and `V`; confirm the change applies immediately and remains after Replay/Retry.
- Verify collision sounds do not chatter in a crowded cluster.
- Confirm game play remains unchanged when either feedback option is disabled.

## Gameplay UI Feel Finalization v1 update

- Exact gameplay source commit: `42c7b38085aa70bd422f35637b76758507acc7e9`; report: `GAMEPLAY_UI_FEEL_FINALIZATION_V1_REPORT.md`.
- The original procedural crystal design remains, but all 15 short `AudioStreamWAV` resources are now generated once during `AudioFeedbackService._ready()` and reused. Event playback no longer creates an `AudioStreamGenerator`, samples, or another resource during merge/contact gameplay.
- Confirmed L6, L7, and L8 results now route to their own rising merge tones. `target_collect` sound and haptic fire at the target-panel arrival pulse, after physics removal and proxy travel. Chain depth emits the chain haptic instead of duplicating merge plus chain haptics.
- No gameplay sound/vibration text controls were restored. Feedback remains service-owned and cannot influence physics, score, target state, launcher availability, or outcomes.
- Headless validation reports `cached_audio_streams=15`, zero gameplay resource loads after initialization, and zero persistent node delta. On-phone listening and haptic timing remain unverified because ADB enumeration did not return in this session.

## Physics + Reward Feedback v1 update

- Exact gameplay source: `4cde848`; milestone report: `PHYSICS_REWARD_FEEDBACK_V1_REPORT.md`; delivery tag: `physics-reward-feedback-v1`.
- The supplied current video measured about `-47.7 dB` mean with `92.6%` of analyzed windows below `-35 dB`, versus about `-19 dB` in the supplied reference. Central one-shot volumes are now `0.20-0.62`, gem/wall thresholds are `170/220 px/s`, and existing cooldown/concurrency guards remain in force.
- `AudioFeedbackService` now generates and caches one original six-second looping procedural crystal/beach ambience bed during `_ready()`. It uses a dedicated player, follows the existing session sound toggle, and never influences gameplay.
- Direct confirmed L6+ merges use the centralized `major_merge` haptic (`42 ms`, amplitude `0.66`). Chains still emit only the chain haptic, preventing duplicate vibration.
- Automated cache, routing, toggle, threshold, score, and bounded-effect tests pass. Physical-device listening, volume balance, and haptic feel remain unverified because `adb` is unavailable.

## Reference Gameplay + Coin Parity v1 update

- Exact gameplay source: `b9f15935174f8e52663fcf4c088cac92e0a35bc4`; milestone report: `REFERENCE_GAMEPLAY_COIN_PARITY_V1_REPORT.md`; delivery tag: `reference-gameplay-coin-parity-v1`.
- `coin_burst`, `coin_flight`, and `coin_collect` are original procedural metallic transients generated and cached during `AudioFeedbackService._ready()`. The one-shot cache is now 18 streams; the separate six-second ambience remains unchanged.
- Merge confirmation emits the burst, the first flight phase emits one travel cue per result, and staggered HUD arrivals emit throttled collection ticks. Only the final coin routes the light 16 ms / 0.20 haptic, preventing vibration chatter.
- Feedback still originates only from confirmed controller events or thresholded contact telemetry. Sound/haptic toggles cannot affect run coins, simulation, merge eligibility, targets, launcher flow, or outcomes.
- Automated routing/cache/cooldown/counter reconciliation tests pass. `adb devices -l` returned no connected device, so listening balance and haptic feel are not claimed.
