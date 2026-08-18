# Sound + Haptics v1 Report

## Original collision mapping restoration — 2026-08-18

- Gem and rail impacts again preload the original supplied `gems-colide.mp3` and `gems-rail-colide.mp3` streams. The midpoint derivative files remain preserved but are not active.
- Central original settings are gem/rail gains `0.34` / `0.39`, thresholds `170` / `220 px/s`, global cooldowns 65 / 90 ms, pitch ranges `0.96..1.04` / `0.97..1.03`, and impact scalars `0.35..1.00` / `0.30..0.75`.
- Contact telemetry, exact confirmed-merge suppression, bounded priority voices, buses/limiter, settings, and haptic routing remain unchanged and never affect gameplay decisions.
- Automated `SOUND_PRIVACY_LINK_TESTS` passed. A connected-device listening pass remains required to confirm subjective speaker volume.

> Current sound routing is superseded by [Supplied Sound Integration + Home Privacy Link v1](SOUND_INTEGRATION_PRIVACY_LINK_V1_REPORT.md). The dedicated feedback-service/controller boundary and existing haptic behavior remain intact; supplied SFX, priority voices, Music/SFX buses, and no-lose routing are now authoritative.

> Current background-music routing is superseded by [New Background Music v1](NEW_BACKGROUND_MUSIC_V1_REPORT.md): the user-supplied v5 derivative loops continuously at `0.10`. Existing confirmed-event gem, coin, and haptic boundaries remain unchanged.

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

## Production Gameplay Parity Final v1 update

- The user recording measured about `-34 dBFS` overall with a `-34.5 dBFS` median 100 ms window, versus about `-19.6 dBFS` overall and `-26.5 dBFS` median in the supplied reference. This is a comparison target, not a claim of perceptual equality on an Android speaker.
- Central ambience gain is `0.34` (`0.16` previously). Event linear gains are now launch `0.48`, gem/wall contact `0.46/0.32`, merge L2-L8 `0.56..0.85`, chain `0.70`, target `0.82`, win/fail `0.90/0.58`, and coin burst/flight/collect `0.72/0.42/0.58`.
- The cached six-second ambience remains fully original and procedural, but now combines a restrained tonal bed with 120 BPM crystal-mallet pulses, off-beat glass answers, and bounded shaker ticks. No reference audio was sampled or copied.
- The 18 one-shots, three-player cap, typed gem/wall thresholds, cooldowns, sound toggle, and haptic mappings remain intact. `run_clean_contact_tests.gd` verifies cache completeness and minimum production mix values; the motion profile reports `cached_audio_streams=18` and no gameplay resource loads.

Manual phone listening checklist: confirm speech-free ambience is clearly present but below merge/coin events; confirm repeated contacts do not chatter; confirm L5, L7, and L8 merge pitches rise without clipping; confirm coin burst/flight/arrival read as one sequence; test a quiet room and typical media volume; then verify final-coin and merge haptics on hardware. No connected device means these listening/haptic items remain open.

## Reference Feedback Match v1 update

- Production now instantiates `ReferenceAudioFeedbackService`; the earlier procedural service remains only as a silent compatibility source for historical tools. No ambience player is created, so the crystal/mallet/shaker music is absent.
- Four Ogg streams are preloaded from the user-supplied reference recording: launch `5.98-6.38 s`, contact `6.90-7.32 s`, ordinary merge/reward `46.55-48.45 s`, and target merge/reward `14.45-17.10 s`. Conversion retained mono 48 kHz content without gain, EQ, pitch, or synthesis.
- Merge confirmation routes one combined `merge_reward` or `target_reward` sample. Separate `coin_burst`, `coin_flight`, `coin_collect`, level-pitched merge, chain, target-arrival, and win-overlay sounds are not layered over it.
- Gem/wall contact still requires confirmed physical contact, typed strength thresholds, cooldowns, and the three-player cap. Haptics remain dedicated and unchanged; only final coin emits the light coin haptic.
- Automated cache/resource/no-ambience, threshold/cooldown, rigid-contact, reward routing, target ordering, and reset checks pass in the focused suites. Phone-speaker balance and haptic feel remain pending a connected Android device.

Manual phone checklist for this superseding audio path: confirm there is no continuous music; compare launch/contact/ordinary merge/target reward directly with the supplied recording; verify repeated contacts do not chatter; confirm the combined reward sample does not double with coin arrivals; verify final-coin and target haptics remain singular.

## Reference Audio + Reward Layering v2 update

- The supplied reference comparison proved that the musical content inside the earlier four event slices was continuous background material, not a movement/contact cue. Production now instantiates `AudioFeedbackService`, starts `assets/runtime/audio/reference_music_loop.ogg` once during `_ready()`, loops it continuously, and never restarts it from controller events.
- The loop is a documented `1.80 s`, mono 48 kHz derivative of reference window `25.05-26.90 s`, with a 50 ms circular seam crossfade and no gain, EQ, pitch, or synthesis. Central music gain is `0.34` and follows the existing session sound toggle.
- Earlier cached gem sounds are restored for launch, typed gem/wall contact, tiered L2-L8 merges, chain, target collection, win, fail, and button. Three reusable players and centralized cooldowns remain. Separate coin burst/flight/arrival audio stays disabled, and the four prior extracted event slices are inactive.
- Target collection emits one `target_collect` tone at confirmed arrival; the final overlay emits one bounded `win` tone. Haptics remain unchanged and service-owned.
- Focused `GAMEPLAY_UI_FEEL_TESTS` and `CLEAN_CONTACT_TESTS` pass, including music-loop readiness, cache completeness, movement-independent routing, contact throttling, tiered merge tones, singular result audio, and no coin-audio layering. Full suite/export and physical-device listening status are recorded in `REFERENCE_AUDIO_LAYERING_V2_REPORT.md`.

Manual phone checklist: verify the reference music is continuous with no audible restart on launch/contact; confirm gem impacts are short and do not chatter; compare L5/L7/L8 merge and target cues at normal media volume; confirm there are no coin ticks; test sound toggle; then verify target/final haptics on hardware.

## Reference Target Reward Correction v3 update

- The `25.05-26.90 s` derivative was not clean music: the supplied recording is one mixed track and the chosen window contains embedded reward audio. Production therefore no longer preloads `reference_music_loop.ogg` or creates an ambience player. The file remains preserved for provenance.
- Reliable independent music/coin balance cannot be produced from that mixed recording alone. Separate clean continuous-music and coin-effect files are required before either layer is restored.
- The 15 initialization-cached launch/contact/tiered-merge/chain/target/result/button gem tones remain active through three reusable players. Separate coin audio remains disabled; haptic routing is unchanged.
- Frame review also corrects the prior `46.55-48.45 s` label: that sequence is the second target reward, not an ordinary merge reward. Coins and the final light coin haptic now occur only on active-target rewards.

Manual phone checklist for this superseding path: confirm there is no background loop or captured coin contamination; verify short gem contacts/merges remain audible without chatter; confirm ordinary merges emit no coin sound/haptic; then supply clean separated music and coin files for final listening calibration.

## Production Foundation v1 settings update

- `GameSettingsService` persists Music, Sound FX, and Vibration independently in `user://game_settings.cfg` and restores them before feedback startup.
- `AudioFeedbackService.music_enabled` controls only continuous background music; `sfx_enabled` controls only confirmed-event one-shots. Vibration remains owned by `HapticsService`.
- Pause uses controller-backed switches. Restart, Home, Next Level, and process relaunch do not reset preferences, and settings never participate in gameplay decisions.
- Automated validation covers persistence, independent routing, immediate application, and restoration. Hardware loudness and vibration still require a connected Android device.

## Reference Animation + Supplied Audio Polish v4 update

- The requested separate originals now exist: `assets/sound/gem_merge_music_loop.wav` is the clean 29.72-second music source and `assets/sound/coin-sound.mp3` is the clean 1.30-second coin source. Both originals are preserved unchanged; documented Ogg derivatives live under `assets/runtime/audio/`.
- `AudioFeedbackService` owns one independent looping music player at linear gain `0.14` and three reusable one-shot players. Music starts during service initialization, is never triggered/restarted by movement, and follows the existing audio toggle.
- The supplied coin cue is a single unpitched `coin_reward` cache entry. `GameController` emits it once only when a unique confirmed result qualifies the current target. Ordinary merges retain their earlier tiered gem sounds and emit no coin cue.
- Runtime analysis measured the Ogg music at `-15.5 dBFS` mean / `-1.0 dBFS` max before the service gain; expected playback is approximately `-32.6/-18.1 dBFS`. The coin derivative measures `-27.5/-6.9 dBFS` and plays at unity event gain, while merge L2-L8 event gains remain `0.56-0.85`.
- Automated validation covers independent resource paths, continuous-player readiness, toggle stop/resume, bounded cache/player count, target-only coin routing, ordinary-merge exclusion, and unchanged contact cooldowns. Dummy-audio tests do not prove phone-speaker loudness.

Manual phone checklist: listen through one full 29.72-second loop and seam; confirm music stays soft and does not restart on launch/drag/contact/merge; confirm ordinary merges use only gem cues; confirm one coin cue on each L5/L7/L8 reward; confirm coin and high-tier merge cues dominate the music without clipping; verify the audio toggle stops/resumes both layers. Haptic feel remains unchanged and still requires hardware validation.
# Superseding audio note - 2026-08-16

Current active audio mappings and gains are documented in `SOUND_MAPPING_CORRECTION_V2_REPORT.md`. This historical report remains authoritative only for its original milestone evidence and haptics behavior.
# Immediate merge synchronization note - 2026-08-16

The current merge-attack timing is documented in `MERGE_SOUND_SYNC_FIX_V3_REPORT.md`. The supplied source's half-second lead-in is removed only in a runtime derivative; controller routing remains confirmed-event-only and haptics are unchanged.
# Reference-driven game feel v2 audio update - 2026-08-18

- Existing supplied music and all active event assets are retained; no reference audio was copied.
- Relative hierarchy changed only through centralized gains: gem contact `0.34 -> 0.28`, rail contact `0.39 -> 0.32`, ordinary merge `0.70 -> 0.78`, target arrival `0.82 -> 0.90`, and final success `0.84 -> 0.92`. Music remains `0.06`.
- Immediate merge routing, contact cooldowns/pitch variation, five-voice priority pool, buses/limiter, settings, and haptics remain unchanged.

# Animation/audio production-polish superseding note - 2026-08-18

`ANIMATION_AUDIO_BACK_PRIVACY_POLISH.md` now supersedes the contact/target timing and mix values above. Gem/rail contacts use softened runtime derivatives at gains `0.18/0.16`, thresholds `195/250`, global cooldowns `120/140 ms`, and a `140 ms` per-contact cooldown. Normal merge audio now aligns to the 200 ms result reveal; target arrival uses a distinct soft crystal chime; completed target quantity uses the trimmed sparkle cue; coins tick per staggered arrival with the full cue on the final arrival. Haptic ownership and values are unchanged. A manual Android speaker listening pass remains required.

# Tester midpoint superseding note - 2026-08-18

The over-softened contact mix and slow merge timing above are rejected. Active gem/rail files are now `gem_collision_medium_v2.ogg` / `rail_collision_medium_v2.ogg` at gains `0.23/0.24`, thresholds `182.5/235`, global cooldowns `92.5/115 ms`, per-contact cooldown `120 ms`, and midpoint pitch/impact scaling. Immediate confirmed-frame merge audio is restored with the 270 ms tester-approved merge. Target/coin/result identities and all haptics remain unchanged. See `ANIMATION_REVERT_AUDIO_MIDPOINT_ANDROID_EXIT_FIX.md`.
