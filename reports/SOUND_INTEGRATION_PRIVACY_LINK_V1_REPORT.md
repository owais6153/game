# Supplied Sound Integration + Home Privacy Link v1

Date: 2026-08-16

## Request and scope

Integrate and balance the eight supplied SFX, lower but preserve the current background music, retain the approved launch/push and coin identities, prevent collision chatter and merge layering, add no lose sound, produce a TEST APK only, and relocate Privacy Policy from Settings to a bottom-centered Home link. Gameplay logic, physics, gem/table/background assets, target rules, animation durations, ads/UMP configuration, package identity, and production signing are out of scope.

## Event mapping and final mix

| Event | Active stream | Linear gain | Gate / timing |
| --- | --- | ---: | --- |
| Background music | existing `supplied_background_music_v5.ogg` | `0.035` | Starts once, loops independently; 35% of prior `0.10` service gain (-9.12 dB relative). |
| Launch / push | existing procedural launch stream | `0.48` | Confirmed launch only. |
| Gem contact | `gems-colide.mp3` | `0.40 × impact intensity` | Confirmed gem contact above 170 px/s; 65 ms cooldown; `0.96x..1.04x` pitch. |
| Rail contact | `gems-rail-colide.mp3` | `0.46 × impact intensity` | Confirmed rail contact above 220 px/s; 90 ms cooldown; `0.97x..1.03x` pitch. |
| Normal merge | `merge-basic.mp3` | `0.80` | One confirmed non-target merge only. |
| Target merge | `merge-target.mp3` | `0.96` | One confirmed result matching the current target; replaces normal merge cue. |
| Existing coin reward | existing `supplied_coin_reward_v4.ogg` | `0.86` | Unique confirmed active-target reward only; identity unchanged. |
| Target arrival sparkle | `mixkit-fairy-arcade-sparkle-866.wav` | `0.76` | At the end of target fly-to-HUD animation, immediately before progress updates. |
| Objective completion | `mixkit-game-flute-bonus-2313.wav` | `0.96` | Only after the current target's full quantity completes. |
| Level success | `mixkit-game-success-alert-2039.wav` | `1.00` | Only after final qualification and accepted victory-overlay presentation. |
| UI tap | `mixkit-on-or-off-light-switch-tap-2585.wav` | `0.40` | One layer intent per standard button/toggle; 80 ms cooldown. |
| Lose/game over | none | n/a | No audio event is routed. Existing fail haptic remains unchanged. |

All non-collision supplied streams play at `1.0x` pitch. The supplied source files are preserved byte-for-byte under `assets/sound/`; identical active runtime copies remain under `assets/runtime/audio/`.

## Spam, priority, and clipping protection

- Simulation still produces read-only typed contact telemetry after confirmed narrow-phase contact.
- The controller now retains the current frame's impacts, resolves merges, then removes only the exact gem-pair collision cue consumed by a confirmed merge. Physics step order and merge decisions are unchanged.
- Normal and target merges are mutually exclusive; the old tier and chain audio layers are not emitted. Chain haptics remain.
- Five reusable initialization-created SFX voices enforce priority: success > objective > target merge > normal merge > coin > sparkle > launch > gem > rail > UI. A lower-priority event cannot steal a fully occupied higher-priority pool.
- `default_bus_layout.tres` routes continuous music to Music and one-shots to SFX. SFX owns one limiter with threshold `-4.0 dB` and ceiling `-0.8 dB`.
- Turning Music off affects only the music player. Turning Sound FX off stops the shared one-shot pool; neither setting can affect gameplay state.

## Privacy Policy relocation

- Removed `HomePrivacyPolicy` from Home Settings and `PausePrivacyPolicy` from Pause Settings.
- Added an underlined `HomePrivacyPolicyLink` in a dedicated bottom-wide safe-area container centered on Home.
- The link emits the existing Home privacy intent and continues through `AdManager.open_privacy_policy()` to the unchanged published URL.
- Conditional `HomePrivacyOptions` and `PausePrivacyOptions` remain hidden until UMP says they are required.

## Validation actually run

- Godot editor import/parse: PASS, exit 0; all source/runtime audio files imported.
- `SOUND_PRIVACY_LINK_TESTS: PASS`: exact stream paths, playable durations, music gain, Music/SFX buses, limiter, five-voice cap, priority stealing, collision cooldown/pitch, exclusive merge routing, collision suppression order, target/success timing order, no fail sound, real LinkButton ownership, bottom-center geometry, one-tap behavior, and Settings removal.
- `ADMOB_INTEGRATION_TESTS: PASS` before its known late mocked rewarded-callback error; published policy URL and conditional UMP actions remain valid.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- `UI_SCALE_LAYOUT_TESTS: PASS`.
- `BRANDING_PUSH_LINE_TESTS: PASS`.

Godot script runners on this Windows setup commonly return exit 1 during teardown after printing their PASS sentinel. Two optional ANGLE screenshot attempts timed out before producing frames; their exact stale Godot processes were stopped. Bottom-center/safe-area layout is therefore validated programmatically, while final phone appearance and subjective listening remain part of the APK checklist.

## Manual APK checklist

Test launch, gem contact, rail contact, ordinary merge, target merge, target arrival, objective completion, coin reward, standard UI taps, and final level success. Confirm music remains ambient, collisions do not chatter, merge cues are exclusive and clear, no lose sound plays, Settings contain no Privacy Policy button, the Home link is centered/clear of navigation areas, and audio survives Restart/Home/Next Level. Listen at normal and low device volume for source-specific balance; automated routing and limiter checks do not replace speaker listening.

## Delivery status

- Source: `6470a69` / `sound-integration-privacy-link-v1-source`
- Supplied-file baseline: `ec0f497` / `supplied-sound-assets-baseline`
- APK: `build/android/majestic-gems-sound-pass-test.apk`
- Size: 81,303,547 bytes (77.54 MiB)
- SHA-256: `8CB63641D116907647A1C81161E59686EA6008901DF36B79622CB0EDB6EC08D3`
- Package: `com.owais.majestygems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36
- Signature: APK Signature Scheme v2 PASS; one RSA-2048 Godot debug signer
- Native support: `arm64-v8a` and `armeabi-v7a`, each with Godot and C++ shared libraries
- Payload: 990 ZIP entries; one manifest; eight supplied runtime-audio imports; preserved existing music/coin resources; compiled bus layout; zero source/report/test leakage

The production AAB preset was restored exactly and no AAB was generated. The APK was fully written and validated before the outer Windows Godot wrapper reached its known silent five-minute timeout; no Godot or Java process remained. ADB returned no device entry, so installation, launch, speaker balance, perceived distortion, haptics, and physical safe-area acceptance remain for device testing.
# Corrective sound mapping v2 addendum

The mapping below records the original v1 delivery and is superseded by `SOUND_MAPPING_CORRECTION_V2_REPORT.md`. The active correction keeps only five supplied replacements, raises music to `0.06`, lowers those replacement gains, restores target merge/chain/target-arrival identities, and removes the distinct objective-completion cue. The delivered v1 APK has not been rebuilt and therefore does not contain this correction.
# Corrective sound mapping v2 addendum

The mapping below records the original v1 delivery and is superseded by `SOUND_MAPPING_CORRECTION_V2_REPORT.md`. The active correction keeps only five supplied replacements, raises music to `0.06`, lowers those replacement gains, restores target merge/chain/target-arrival identities, and removes the distinct objective-completion cue. The delivered v1 APK has not been rebuilt and therefore does not contain this correction.
