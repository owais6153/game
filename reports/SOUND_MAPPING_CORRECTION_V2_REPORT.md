# Sound Mapping Correction v2

Date: 2026-08-16

## Scope and outcome

The prior eight-file supplied-sound pass was narrowed to the five replacements explicitly requested. Gameplay, physics, merge eligibility, target rules, scoring, animation timing, UI/privacy layout, ads/UMP, Android configuration, and asset bytes are unchanged.

## Active mapping and gain

| Event | Active identity | Linear gain | Behavior |
| --- | --- | ---: | --- |
| Background music | existing `supplied_background_music_v5.ogg` | `0.06` | Raised from `0.035`; continuous Music bus loop preserved. |
| Launch / push | original procedural cue | `0.48` | Unchanged. |
| Gem contact | `gems-colide.mp3` | `0.34 × impact intensity` | 65 ms cooldown; `0.96x..1.04x` pitch. |
| Rail contact | `gems-rail-colide.mp3` | `0.39 × impact intensity` | 90 ms cooldown; `0.97x..1.03x` pitch. |
| Ordinary merge | `merge-target.mp3` | `0.70` | Requested replacement; one cue per confirmed non-target merge. |
| Target-producing merge | original procedural `merge_<tier>` | `0.56..0.85` | Restored original tier identity. |
| Chain | original procedural cue | `0.70` | Restored for confirmed chained resolution. |
| Target arrival | original procedural cue | `0.82` | Restored at fly-to-HUD completion. |
| Objective completion | none separate | n/a | Supplied flute route removed. |
| Coin reward | existing `supplied_coin_reward_v4.ogg` | `1.00` | Original approved identity/gain restored. |
| UI tap | `mixkit-on-or-off-light-switch-tap-2585.wav` | `0.32` | 80 ms cooldown. |
| Final level success | `merge-basic.mp3` | `0.84` | Only after accepted victory presentation. |
| Lose/game over | none | n/a | No audio event routed. |

The supplied sparkle, flute, and success-alert files remain preserved under `assets/sound/` and `assets/runtime/audio/` for provenance but are not loaded or routed.

## Retained protection

- Five reusable priority-aware SFX voices; no event-time player allocation.
- Dedicated Music/SFX buses and SFX limiter.
- Typed confirmed-contact thresholds, collision cooldowns, and subtle pitch variation.
- Merge resolution occurs before contact-audio routing, suppressing only the exact collision pair consumed by a merge.
- Audio remains presentation-only and cannot influence physics or gameplay state.

## Validation

- Godot 4.6.3 headless editor import/parse: PASS, exit 0. The environment still reports its known root-certificate/editor-settings warnings, with no script/resource parse failure.
- `SOUND_PRIVACY_LINK_TESTS: PASS`: exact five replacement paths, restored procedural streams, music gain, event gains, buses/limiter, voice priority, collision cooldown/pitch, target/chain routing, no objective/lose route, success timing, and retained Home privacy placement.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`: merge/target/result flow remains intact.

Both script runners reached their PASS sentinels before the known Windows teardown exit 1/root-certificate message. Subjective speaker balance requires user testing in Godot/device audio.

## TEST APK delivery

- APK: `build/android/majestic-gems-sound-mapping-v2-test.apk`
- Size: 81,304,475 bytes (77.54 MiB)
- SHA-256: `A3A075124A1DF0F421FF4D87A693D087D618F506420338495C9C47FCBA1FDAC8`
- Source: `506e08b` / `sound-mapping-correction-v2-source`
- Package: `com.owais.majestygems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36
- Validation: v2 signature PASS with one RSA-2048 Godot debug signer; AAPT/ZIP PASS; both `arm64-v8a` and `armeabi-v7a`; 990 entries; one manifest and primary dex; zero report/test/source-audio leakage.
- Export note: the production AAB preset was restored exactly and no AAB was generated. The stable APK passed artifact validation although the outer Godot wrapper timed out after writing it. No export-owned Godot/Java process remained afterward.
- Device status: ADB did not return within its check window, so installation, launch, and subjective speaker listening are not claimed.
