# Animation Revert, Collision-Audio Midpoint, and Android Exit Fix

Date: 2026-08-18

## Scope

This corrective pass responds to daily-tester feedback that the preceding reward animation pass felt slow and that both contact sounds had become too soft. It restores the complete animation cadence from commit `5528ff6` while retaining the later exactly-once, authoritative-target, Home, Back, Privacy, and exit-confirmation safety work. No physics, collider, merge/target rule, reward, economy, gem, table, save, AdMob unit, UMP flow, or package identity changed.

## Animation revert

| Presentation value | Rejected slow pass | Restored tester-approved value |
| --- | ---: | ---: |
| Collision response | 140 ms | 110 ms |
| Merge total | 540 ms | 270 ms |
| Merge source pull | 200 ms | 60 ms |
| Result scale | `0.72 -> 1.18 -> 1.0` | `0.64 -> 1.26 -> 1.0` |
| Result pop | 180 ms after a 200 ms reveal delay | 140 ms immediately |
| Major merge effect | 620 ms | 360 ms |
| Target collection | 700 ms | 320 ms |
| Target pulse | 220 ms | 380 ms |
| Coin start delay | 260 ms | 0 ms |
| Coin flight | 550/620 ms | 540/600 ms |
| Coin flight/spawn stagger | 80/80 ms | 45/15 ms |
| Four-coin visible bound | about 980 ms | 855 ms |
| Next gem | 220 ms | 160 ms |
| Result hold | 420 ms | 240 ms |
| Final presentation bound | about 1.66 s | about 1.095 s |

The previous immediate merge cue is restored to the confirmed merge frame. Target travel starts as soon as the short merge finishes. The later safety architecture is deliberately retained: controller target progress advances at the confirmed result, HUD progress advances on collection arrival, target presentation is queued exactly once, and launcher state does not use presentation duration as gameplay authority. Thus the tester-approved pace does not restore the stale-target/double-reward race found in the slow-pass audit.

## Collision-audio midpoint

The harsh originals and over-softened v1 derivatives are both preserved. Two v2 runtime derivatives implement a genuine midpoint:

| Property | Previous/original | Rejected soft v1 | Midpoint v2 |
| --- | ---: | ---: | ---: |
| Gem gain | 0.28 | 0.18 | 0.23 |
| Rail gain | 0.32 | 0.16 | 0.24 |
| Gem threshold | 170 | 195 | 182.5 |
| Rail threshold | 220 | 250 | 235 |
| Gem global cooldown | 65 ms | 120 ms | 92.5 ms |
| Rail global cooldown | 90 ms | 140 ms | 115 ms |
| Per-contact cooldown | global only | 140 ms | 120 ms |
| Gem pitch | `0.96-1.04` | `0.94-1.00` | `0.95-1.02` |
| Rail pitch | `0.97-1.03` | `0.92-0.98` | `0.95-1.01` |

`gem_collision_medium_v2.ogg` is a 300 ms derivative with 160 Hz high-pass, 7 kHz low-pass, only -2 dB at 2.8 kHz, 8 ms attack fade, and 80 ms tail. `rail_collision_medium_v2.ogg` is a 320 ms derivative with 140 Hz high-pass, 6 kHz low-pass, -2.5 dB at 2.3 kHz, 10 ms attack fade, and 90 ms tail. These retain more transient and brightness than soft v1 while remaining less sharp than the originals.

FFmpeg `volumedetect` confirms that the derivative levels sit between both endpoints before service gain: gem original/medium/soft mean is `-19.3/-20.8/-22.8 dB` with peaks `-0.4/-3.2/-5.6 dB`; rail original/medium/soft mean is `-20.2/-22.4/-24.7 dB` with peaks `-0.4/-3.5/-5.2 dB`.

| Runtime asset | Size | SHA-256 |
| --- | ---: | --- |
| `assets/runtime/audio/gem_collision_medium_v2.ogg` | 9,135 bytes | `70F9879B2C1834D9574138D0C8271282EA1D45CE2ABA9369E1145CD39DD00575` |
| `assets/runtime/audio/rail_collision_medium_v2.ogg` | 8,932 bytes | `AFD0F5498E22DBFB8CFA075F57626E547BEB43C001ECA452AF308EB0ABC4E763` |

Impact-based gain now uses midpoint ranges of `0.30-0.84` for gem contacts and `0.26-0.67` for rails. Exact merge-pair suppression, per-contact keys, the five-voice pool, Music/SFX buses, limiter, settings, and all reward sounds remain intact. Physical phone listening is still required for final subjective approval.

## Proper Android exit

The exit confirmation is retained. The failing path synchronously called `SceneTree.quit()` from the Exit button signal after destroying cached Java ad objects. The tester's Android device reported that termination as an app stop/crash. Without device logcat the exact native frame cannot be proven, but this was the only new confirmed-Exit path and it forced engine teardown inside the input callback.

The Android path no longer calls `SceneTree.quit()`. It now:

1. invalidates delayed AdMob retries/fullscreen callbacks without destroying Java objects in the button callback;
2. obtains Godot's supported built-in `AndroidRuntime` singleton and current Activity;
3. posts `Activity.finishAndRemoveTask()` to Android's UI thread;
4. lets the normal Activity lifecycle perform engine/plugin teardown.

Desktop/debug fallback defers the normal `SceneTree.quit()` call outside the button callback. `AdManager.prepare_for_exit()` is idempotent and separates callback invalidation from resource destruction; the existing `_exit_tree()` remains the lifecycle cleanup owner. Godot's official Android integration documents `AndroidRuntime.getActivity()` and posting callables with `runOnUiThread`: [Integrating with Android APIs](https://docs.godotengine.org/en/4.7/tutorials/platform/android/javaclasswrapper_and_androidruntimeplugin.html). Godot 4.6's Android library documents Activity-hosted lifecycle ownership: [Godot Android library](https://docs.godotengine.org/en/4.6/tutorials/platform/android/android_library.html).

## Regression evidence

Godot 4.6.3 import/parse completed successfully, including both new audio imports. All eight repository suites reached their PASS sentinels:

- `ADMOB_INTEGRATION_TESTS: PASS`
- `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS: PASS`
- `BRANDING_PUSH_LINE_TESTS: PASS`
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`
- `REFERENCE_GAME_FEEL_V2_TESTS: PASS`
- `SCENE_VARIETY_ASSETS_TESTS: PASS`
- `SOUND_PRIVACY_LINK_TESTS: PASS`
- `UI_SCALE_LAYOUT_TESTS: PASS`

Coverage verifies exact restored timing constants, exact-once rewards, immediate authoritative/arrival-timed displayed target state, later-merge classification, launcher independence, midpoint asset routing/gains/thresholds/cooldowns/pitch, AndroidRuntime Activity finish contract, UI-thread dispatch, ad callback invalidation, exit-confirmation priority, Home/Back state, Privacy alignment, and unchanged reward/ad contracts. The Windows 4.6.3 runner retains its known post-PASS teardown access violation; no assertion failed.

## Android build

`build/android/majestic-gems-animation-revert-audio-midpoint-exit-fix.apk` exported cleanly from source commit/tag `32794fb` / `animation-revert-audio-midpoint-android-exit-source`. It is 82,226,968 bytes with SHA-256 `371F47693B0019696152E0C1CB0E753522160BB9B6CBD2123D4CD9237E020FE2`.

AAPT reports package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36, game category, and both ARM ABIs. APK Signature Scheme v2 passes with the established RSA-2048 Godot debug signer. The 1,004-entry archive contains five DEX files, both Godot/C++ ARM pairs, both midpoint audio imports, existing target/coin imports, production AdMob App ID `ca-app-pub-4605895178658062~1516881747`, and zero report/test/source-audio entries. The committed AAB preset was restored exactly; no AAB or version change was made.

`adb devices -l` returned no attached device, then the daemon was stopped. Local tests cannot prove subjective phone loudness or that the tester's OEM exit dialog is gone; installation, Exit, and listening are the explicit daily-tester acceptance items for this APK.
