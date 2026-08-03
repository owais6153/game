# Physics + Reward Feedback v1 Report

## Decision and scope

- Compared `WhatsApp Video 2026-08-03 at 12.45.32 PM.mp4` with the reference `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`.
- The user's first recommendation, changing Level 1 progression/length, is deliberately deferred until more levels are created. `scripts/level_config.gd` is untouched: Level 1 still uses the L1-L4 mixed launch bag, unlimited launches, and sequential L7 then L8 targets.
- This milestone addresses the remaining causes of flat pacing: weak collision redirection, excessive repeated energy loss, unrewarded high-tier merges, undersized high-tier celebration, and very quiet audio feedback.
- Starting milestone: `1810341` / `production-ui-polish-v4`. Exact gameplay source: `4cde848` (`feat: enliven physics and high-tier rewards`). Delivery tag: `physics-reward-feedback-v1`.

## Video findings

- Launch motion was already fast; `LAUNCH_SPEED` remains `1160 px/s`.
- The current capture's mean audio level measured about `-47.7 dB`, with `92.6%` of analyzed windows below `-35 dB`. The reference measured about `-19 dB` and did not have comparable long quiet sections. These measurements describe the supplied recordings, not a phone loudness guarantee.
- The old equal-mass contact response multiplied inward relative speed by only `0.34`, leaving bodies still moving into one another after correction. Tangential friction was also reapplied on persistent contacts, so redirects quickly became sticky, low-energy clusters.
- L6-L8 results had no score value. The most important objective merges therefore produced zero score and used nearly the same short visual cadence as ordinary low-tier merges.

## Centralized tuning

All gameplay-feel values remain in `GameConfig` and the simulation remains delta-based.

| Setting | Before | After | Approved range / rule |
|---|---:|---:|---|
| Launch speed | 1160 | 1160 | 1120-1200; unchanged |
| Velocity damping / second | 235 | 210 | 190-230 |
| Sleep speed | 11 | 9 | 8-11 |
| Side-wall restitution | 0.16 | 0.20 | 0.16-0.24 |
| Top-wall restitution | 0.10 | 0.16 | 0.12-0.20 |
| Bottom-wall restitution | 0.08 | 0.10 | 0.08-0.12 |
| Piece restitution | 0.34 legacy impulse multiplier | 0.22 true coefficient | 0.18-0.28 |
| Tangential friction | 0.18 on every contact pass | 0.10 once on approach | 0.06-0.14 |
| Merge momentum transfer | 0.35 | 0.45 | bounded source average |
| Merge spawn speed cap | 260 | 300 | containment cap |

For equal masses, approaching contact now uses `impulse = -relative_speed * (1 + restitution) * 0.5`. This creates a controlled separating velocity instead of retaining inward motion. Tangential damping runs only during that approaching impact; resting overlap correction does not repeatedly drain sideways motion.

Table rail anchors, calibrated gem radii, contact epsilon, separation epsilon, perspective mapping, maximum piece speed, merge eligibility, chain cap, and danger behavior are unchanged.

## Reward, score, sound, and haptics

- Confirmed L6, L7, and L8 results now score `350`, `800`, and `1,800`. Existing L2-L5 values remain `10`, `25`, `60`, and `150`; score still comes only from confirmed merge events and still uses the existing chain multiplier.
- L6+ is a major reward tier: a bounded `0.78 s` double-ring/spark effect, `1.05 s` score popup, `58 px` rise, `1.55` effect scale, and 16 sparks. Ordinary rewards remain `0.27 s`, `0.62 s`, `36 px`, and 8 sparks.
- High-tier feedback is presentation-only. It never changes a gem root, radius, collider, physics coordinate, target rule, or launcher state.
- Procedural one-shot volumes are now centrally audible across `0.20-0.62`; gem/wall contact thresholds are `170/220 px/s` with cooldown and the existing three-player concurrency cap.
- `AudioFeedbackService` caches one original procedural six-second looping crystal/beach ambience stream at startup. It contains no external or copyrighted audio asset and follows the existing session sound toggle.
- Direct L6+ results route the centralized `major_merge` haptic (`42 ms`, amplitude `0.66`). Chain merges continue to use the stronger chain event without duplicate merge vibration.

## Validation performed

- Godot 4.6.3 editor parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed, including true contact separation, approach-only tangent damping, and resting-contact retention.
- `GAMEPLAY_UI_FEEL_TESTS`: passed, including major reward duration/scale/count, cached ambience, high-tier audio, and haptic routing.
- `LEVEL_1_FLOW_TESTS`: passed; Level 1 target and unlimited launcher behavior remain intact.
- `GEM18_CHAIN_TESTS`: passed; L6-L8 scoring and the complete catalog chain remain valid.
- `PRODUCTION_UI_FINALIZATION_TESTS`: passed before export.
- `MOTION_PROFILE`: passed. Average frame cost ranged from `0.074 ms` empty to `1.174 ms` in the measured 20-gem case; the six-reward chain averaged `0.336 ms`. Cached audio streams remained 15 one-shots plus the separate ambience, bounded effects returned to zero, and persistent node delta was zero.
- Godot emitted its existing post-test ObjectDB leak warnings after successful headless exits; no suite failed.

## Visual evidence

- `reports/physics-reward-feedback-v1/major-l6-reward.png`
- `reports/physics-reward-feedback-v1/major-l7-target-reward.png`
- `reports/physics-reward-feedback-v1/major-l8-target-reward.png`

These deterministic ANGLE captures show the bounded major merge treatment and exact `+350`, `+800`, and `+1,800` score feedback without changing live gem geometry.

## APK delivery

- File: `build/android/physics-reward-feedback-v1.apk`
- Size: `100,793,853 bytes`
- Modified: `2026-08-03 13:42:55 +05:00`
- SHA-256: `AE1189E5E8AC21EA95497182F90F05B4F81383573222A74886BAD13453861594`
- Export: fresh Godot 4.6.3 debug-signed Android build; this is not a store-release signing claim.
- Package validation: 355 ZIP entries; manifest, primary dex, and arm64 Godot runtime present; zero `reports/` and zero `tools/` entries. `apksigner` verifies v2/v3 signatures with one RSA-2048 signer.
- Device status: `adb` is not installed or discoverable in the validation environment. Installation, physical-device performance, listening, and haptic feel are not claimed.

## Phone checklist

- Confirm impacts redirect visibly without producing pinball-like rebounds or rail escapes.
- Confirm L6-L8 score/celebration reads clearly and never blocks the next launcher.
- Listen for ambience and launch/contact/merge balance at normal media volume; ensure crowded contact remains free of chatter.
- Toggle sound and verify ambience plus one-shots mute together and resume immediately.
- Confirm major merges feel stronger than normal merges, while chains do not double-vibrate.
