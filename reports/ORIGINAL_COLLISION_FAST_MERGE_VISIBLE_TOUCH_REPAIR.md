# Original Collision Sound, Fast Merge/Push, and Visible-Touch Merge Repair

Date: 2026-08-18

## Requested behavior

- Restore the original gem-to-gem and gem-to-rail sounds at their original volume.
- Restore the previously approved faster merge and source-pull/push animation.
- Keep the current target collection and next-target speed; retain the slower coin reward motion.
- Resolve equal gems that visibly touch but previously did not merge.

## Delivered change

`AudioFeedbackService` now routes contact events back to the preserved original supplied streams: `gems-colide.mp3` and `gems-rail-colide.mp3`. `GameConfig` restores their original gains (0.34/0.39), thresholds (170/220 px/s), event cooldowns (65/90 ms), pitch ranges, and controller impact scaling. Existing exact merge-pair clink suppression and the bounded feedback service remain intact.

`GameConfig` restores the approved fast merge/push presentation: 270 ms total merge, 60 ms source pull, immediate audio/result reveal, `0.64 -> 1.26 -> 1.0` result pop, and 360 ms major effect. Target collection remains 700 ms and the target swap remains unchanged. Coins continue to start after 260 ms and retain the existing approximately 980 ms visible sequence.

The centralized `CONTACT_EPSILON` now matches the measured two-design-pixel `VISIBLE_CONTACT_TOLERANCE`. This recognizes visual body contact without changing any gem radius, rail, board bound, solver equation, momentum value, or merge result rule. A new regression proves matching gems inside the visible-touch band merge, while a 2.1-pixel visible separation still does not.

## Validation

- `REFERENCE_GAME_FEEL_V2_TESTS: PASS`
- `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS: PASS`
- `SOUND_PRIVACY_LINK_TESTS: PASS`
- `UI_SCALE_LAYOUT_TESTS: PASS`
- Godot editor import/parse: PASS after the final source edit.
- APK: `build/android/majestic-gems-original-contact-fast-merge-touch-fix.apk` — 82,227,624 bytes — SHA-256 `C3EAC8417D9566F4E10E011A7838BA514D15C5FD299B3B80E2B68AF757364A8C`.
- AAPT manifest, v2 signature, and ZIP checks for `AndroidManifest.xml`, `classes.dex`, and both ARM Godot libraries passed. No AAB was generated; `export_presets.cfg` was restored to its committed AAB configuration.

No physical device was connected during development; subjective listening and on-device touch confirmation are not claimed.
