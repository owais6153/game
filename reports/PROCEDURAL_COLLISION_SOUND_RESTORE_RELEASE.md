# Original Procedural Gem/Rail Collision Sound Restore

Date: 2026-08-18

## Diagnosis

The previously restored `gems-colide.mp3` and `gems-rail-colide.mp3` files were still part of the newer supplied-sound integration. History review identified the older, player-requested contact identities in the pre-supplied-audio cached procedural `AudioFeedbackService` implementation.

## Delivered behavior

- Gem-to-gem contact uses the original generated crystal stream: 1240 Hz, 55 ms, gain 0.46, brightness 0.82, fall 0.64, deterministic seed 2.
- Gem-to-rail contact uses the original generated crystal stream: 760 Hz, 65 ms, gain 0.32, brightness 0.34, fall 0.58, deterministic seed 3.
- Original global cooldowns are 75 ms and 110 ms; both contacts retain fixed pitch.
- The later MP3 and Ogg files remain preserved but are not preloaded or routed for collision playback.

No collision telemetry, contact threshold, merge suppression, voice-pool, bus, limiter, settings, haptic, physics, rail, collider, merge, target, or reward behavior changes.

## Release identity and validation

The AAB/APK release uses versionCode 6 and versionName 1.0.4, strictly newer than all recorded prior releases. The exact artifact metadata, bundle/APK audits, and device status are recorded in `BUILD_MANIFEST.md` after export.

Focused checks: `SOUND_PRIVACY_LINK_TESTS`, `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`, and `REFERENCE_GAME_FEEL_V2_TESTS`.

Manual listening checklist: compare normal gem-to-gem and rail hits against the earlier game build; confirm they sound procedural/crystalline rather than the supplied MP3 assets, remain distinct from one another, do not chatter in a cluster, and respect the Sound FX toggle.
