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

To be updated after the Android export and Git tag are completed in this same milestone.

## Phone checklist

- Verify launch, impact, merge, chain, win, and fail cues are audible but not noisy.
- Toggle `S` and `V`; confirm the change applies immediately and remains after Replay/Retry.
- Verify collision sounds do not chatter in a crowded cluster.
- Confirm game play remains unchanged when either feedback option is disabled.
