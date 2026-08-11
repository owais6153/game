# Post-AdMob Reward Flow and APK Size Fix

Date: 2026-08-11 (Asia/Karachi)

## Outcome

- Final Android application ID: `com.owais.majestygems`.
- Final debug APK: `build/android/majestic-gems-post-admob-fix-debug.apk`.
- Final size: **53,363,440 bytes (50.89 MiB)**.
- AdMob integration remains present: Google Mobile Ads SDK, Poing Android bridges, application ID, interstitial/rewarded registrations, Internet/network/AD_ID permissions, and Google debug test units all passed packaged-APK inspection.
- Only `arm64-v8a` is packaged. No armeabi-v7a, x86, or x86_64 payload is present.
- Gameplay, physics, gem motion, collisions, merge behavior, target generation/counts, difficulty, table geometry, and AdMob load/reload ownership were not changed.

## Size history and root cause

| Artifact | Bytes | MiB | Meaning |
|---|---:|---:|---|
| `mvp0.6.apk` | 55,322,821 | 52.76 | Earlier optimized size near the reported ~55 MB reference |
| `majestic-gems-branding-push-line-v1.apk` | 42,831,666 | 40.85 | Direct pre-AdMob milestone |
| `admob-integration-v1-debug.apk` | 108,146,729 | 103.14 | Regressed Gradle/AdMob build |
| `majestic-gems-post-admob-fix-debug.apk` | 53,363,440 | 50.89 | Final optimized Gradle/AdMob build |

The regression was not caused by additional ABIs or duplicated game assets. The regressed APK already contained only arm64. Its dominant cause was `gradle_build/compress_native_libraries=false`, which stored the 75,345,928-byte Godot arm64 runtime and 1,374,336-byte C++ runtime without compression. Restoring legacy/compressed native packaging reduces that category from 76,720,264 packaged bytes to 27,599,039 bytes.

The second cause was the upstream AdMob editor plugin registering its sample translations in the game project. That pulled optional `icudt_godot.dat` into the APK and also caused the all-resources export to package sample/editor assets. The export contained AdMob demo audio, a CJK font, demo icons, sample scenes/scripts, C# sources, iOS stubs, editor/install helpers, mocks, documentation, and skills. None are needed by the Android runtime bridge used by this game.

The final build is 54,783,289 bytes (50.66%) smaller than the regressed APK. It is 1,959,381 bytes below the reported ~55 MB reference. Compared with the direct 42.83 MB pre-AdMob milestone, the legitimate remaining 10.53 MB overhead is primarily Google Ads bytecode/resources plus Gradle's different native compression/alignment.

## Final packaged-size breakdown

Sizes below are compressed APK entry bytes. ZIP headers/alignment contribute the remaining 174,312 bytes.

| File/category | Current packaged size | Reason included | Required | Safe optimization |
|---|---:|---|---|---|
| arm64 Godot + C++ native libraries | 27,599,039 | Godot engine runtime for production arm64 devices | Yes | Kept arm64 only; restored safe APK compression |
| Imported game resources | 11,820,031 | Runtime textures, audio, fonts, scenes, and imported resources | Yes | No asset quality change |
| DEX / Java bytecode | 9,394,371 | Godot Java glue, Poing bridge, Google Mobile Ads SDK and transitive dependencies | Yes for AdMob/Android | No blind dependency removal; debug R8 shrinking is not used |
| Runtime game source assets | 2,588,835 | Active source resources retained by Godot export remaps | Yes in this export mode | No quality degradation |
| Android resources | 1,358,869 | App icons, AndroidX, Google Ads/consent resources | Yes | Resource shrinking was not enabled for debug because it could remove plugin-reflected resources |
| Godot runtime/project data | 276,722 | Compiled game scripts/scenes and Godot metadata | Yes | Tests, reports, docs, tools, and retired assets remain excluded |
| Other Android packaging | 75,291 | Kotlin metadata, protobuf/OkHttp metadata and packaging records | Dependency-owned | No safe material reduction identified |
| Required AdMob GDScript API | 66,700 | Runtime API/core/listener classes used by the manager | Yes | Samples, mocks, editor helpers, C#, iOS, docs, skills, and media excluded |
| Manifest | 4,768 | Package, activity, permissions, AdMob app ID and plugin registrations | Yes | None |
| Signature metadata | 4,502 | Debug APK v2 signature metadata | Yes | None |
| ZIP headers/alignment | 174,312 | APK container structure | Yes | Build-tool controlled |

No duplicate ABI was found. No duplicate AdMob AAR was found: the build contains one Poing Ads bridge and one Poing Core bridge. The dependency audit shows `ads-mobile-sdk:1.2.1`, its Google Play Services/UMP transitives, and `constraintlayout:2.2.0`; these explain the five DEX files and added Android resources. No Firebase configuration or placeholder exists in the project.

## Reward and level-transition flow

The Level Complete popup now has two controller-owned states:

1. Unresolved: it shows the base reward, pre-collection total, `COLLECT`, and `DOUBLE COINS`.
2. Resolved: it animates the displayed total, marks the reward collected, removes the two reward choices, and shows `NEXT LEVEL`.

`COLLECT` banks the already controller-authoritative level earnings exactly once and leaves the popup visible. `DOUBLE COINS` starts one rewarded session. Only `OnUserEarnedRewardListener` can add one additional copy of the base reward. Duplicate, stale, resumed, or repeated callbacks are rejected by the manager and controller guards. The popup keeps its state while Android owns the fullscreen ad activity.

Dismissal/failure without an earned callback clears the pending state, grants nothing, keeps normal Collect usable, and allows one safe rewarded retry when inventory is available. Rewarded dismissal never advances the level.

After reward resolution, `NEXT LEVEL` is the only forward action. It is also the clean transition point for the existing every-two-completed-level interstitial rule. The controller then prepares the generated next level, pauses it behind the existing Level Intro modal, and requires the player to press `START GAME`/Play before gameplay resumes. Rewarded and interstitial sessions therefore cannot be triggered by the same button/ad callback or overlap during reward animation.

## Package migration

The Godot Android export preset now passes `com.owais.majestygems` as Gradle's `applicationId`. The generated manifest and dynamic receiver permission use that exact ID. `com.godot.game` remains only the Godot template Java namespace/activity class and is not the installed application ID. All tracked references to the former application ID were removed. The output filename was updated to the Majestic Gems delivery name.

Package-migration files: `export_presets.cfg`, `BUILD_MANIFEST.md`, `reports/ADMOB_INTEGRATION_V1_REPORT.md`, `reports/BLANK_ANDROID_BASELINE_REPORT.md`, and `reports/PRODUCTION_UI_POLISH_V4_REPORT.md`. Generated Android intermediates were regenerated by the successful export rather than hand-edited.

## Files changed

- `scripts/game_controller.gd`: explicit reward-resolution state, exactly-once Collect/bonus handling, Next-only progression, interstitial placement, and Level Start handoff.
- `scripts/result_overlay_layer.gd`: unresolved/resolved actions, duplicate-tap guard, reward/total animation, and Next Level state.
- `scripts/home_overlay_layer.gd`: reuse of the existing Level Intro popup for the next-level Ready/Play gate.
- `scripts/ad_manager.gd`: unchanged; existing initialization, loading, retry, callback, destruction, and fullscreen ownership are preserved.
- `tests/run_admob_integration_tests.gd`: Collect, double-tap, retry, exactly-once, resolved popup, and Next action coverage.
- `export_presets.cfg`: arm64-only compressed native packaging, focused AdMob runtime exclusions, package ID, and output name.
- `project.godot` and `addons/admob/internal/services/project_settings_service.gd`: removed editor-sample translation registration that forced optional ICU/sample payloads.
- Central project documentation, build manifest, changelog, and report index.

## Verification results

- Godot 4.6.3 whole-project import/parse: PASS, exit 0.
- `ADMOB_INTEGRATION_TESTS: PASS`; the known Windows Godot teardown fault occurs after the PASS marker and returns process exit 1.
- `BRANDING_PUSH_LINE_TESTS: PASS`; the same known post-PASS teardown fault occurs.
- Short main-scene headless smoke emitted no script/runtime error before the same teardown exit.
- Final Godot/Gradle debug export: PASS, exit 0.
- APK SHA-256: `7EEF183F5F7CB068292BFB1B588CD8ED271B9873AC5466D3AD471FBBC3E7DBD4`.
- Package inspection: `com.owais.majestygems`, minSdk 24, target/compile SDK 36.
- ABI inspection: only `arm64-v8a/libgodot_android.so` and `arm64-v8a/libc++_shared.so`.
- Forbidden payload inspection: zero AdMob sample/editor/iOS/C#/mock/doc/skill files, zero ICU data, zero tests/reports/docs.
- AdMob inspection: application ID, interstitial/rewarded plugin registrations, required permissions, and both Google debug test unit IDs present.
- Signature: APK Signature Scheme v2 PASS, one RSA-2048 debug signer.

## Known limitations

ADB returned an empty device list. The APK could not be physically installed or launched, and live Google test-ad rendering, earned/early-close callbacks, Android background/resume, and on-device interstitial cadence could not be exercised in this session. Those checks are not claimed. The built artifact and automated state tests pass, but final physical-device acceptance remains required when a phone is connected.

The APK is debug-signed and the two release ad-unit constants remain intentionally blank. A production release still requires release IDs, release signing, consent/privacy review, and the manual device checklist above.
