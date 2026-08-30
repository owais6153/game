# Majestic UI Kit debug APK v1.0.15 (versionCode 17) - 2026-08-29

- APK: `build/android/majestic-gems-ui-kit-v1.0.15-vc17-debug.apk`
- Size: 99,153,624 bytes (94.6 MiB)
- Built: 2026-08-29 08:08 local, Godot 4.6.3-stable, Gradle build, arm64-v8a + armeabi-v7a
- Source commit: **uncommitted working tree** on `main` at `c62b388`. This build carries the supplied-art UI kit, typography, retention defect fixes, level briefings, and the nine-patch re-authoring, none of which are committed yet. Not reproducible from a commit hash until that work is committed.
- Version decision: versionCode `17` / versionName `1.0.15`, strictly greater than every previously recorded identity (highest prior: 15/1.0.13; 16/1.0.14 was consumed by a superseded local APK during this task and must not be reused).
- Export preset: new `[preset.1] "Android APK"` (`gradle_build/export_format=0`), added so the release AAB preset keeps its own settings. The AAB preset remains at 15/1.0.13 and its next export must use versionCode >= 18.
- **Signing: DEBUG keystore** (`CN=Godot, OU=Godot Engine, O=Stichting Godot`), verified with `apksigner verify --print-certs`. This is a test build for device verification only. **It cannot be uploaded to Play**, and it is not a release candidate. A release build needs `majestic-gems-upload-key.jks` plus its password, which was not available in this task.
- Validation performed: `aapt2 dump badging` confirms package `com.owais.majestygems`, versionCode 17, versionName 1.0.15, minSdk 24, targetSdk 36, and the unchanged AdMob/Firebase permission set. `apksigner verify` passes. All fifteen Godot regression suites pass.
- Device status: **not installed or run on a device.** No Android device was available in this task. Firebase DebugView unverified. Animations, transitions, and touch feel are covered by tests and screenshots only and still need a real device pass.

# Build Manifest

## Final Pre-Launch Production Candidate RELEASE AAB v1.0.13 (versionCode 15)

- Status: **device-verified fix.** Custom Firebase events now reach Firebase's own logging pipeline on the authorized V2149 device; this is the first candidate confirmed to actually forward `level_start` end to end.
- AAB: `build/android/majestic-gems-production-candidate-v1.0.13-vc15.aab`
- Size/timestamp: 75,104,741 bytes; 2026-08-28 09:44 +05:00.
- SHA-256: `DD398E1201CC2A9CC60DEEF48AC8A34410AB917F3F82A7B237CA981A39273633`.
- Source commit: pending (this build's source is committed in the same task as this manifest entry). See `git log` for the exact commit that pairs `scripts/services/analytics_service.gd`, this manifest, and `export_presets.cfg` versionCode 15/versionName 1.0.13.
- Version decision: versionCode `15` / versionName `1.0.13`, strictly newer than every recorded/uploaded/delivered identity, including the superseded 14/1.0.12 and 13/1.0.11 below.
- **Root cause correction:** the versionCode-14 fix (adding `getPluginMethods()` to `FirebaseAnalyticsPlugin.java`) did **not** actually resolve the device defect — repeat device testing on this exact V2149 phone reproduced the identical `Firebase singleton exists but logEvent is unavailable` warning on vc14, meaning **vc14 must not be uploaded either.** Bytecode inspection of the bundled Godot Android plugin runtime (`godot-lib.template_release.aar`, `GodotPlugin.class`) confirmed `logEvent` was in fact natively registered via `nativeRegisterMethod` at plugin load in both vc13 and vc14; the real defect is that `Object.has_method("logEvent")` on the JNI-backed native singleton returned `false` unreliably even though the method was registered and callable. `scripts/services/analytics_service.gd`'s `_native_bridge()` no longer gates on `has_method()`; it now relies on `Engine.has_singleton()` plus the actual call's own accept/reject result, which is the only value the Java bridge and Firebase itself can authoritatively confirm.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, existing upload signing, package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, both `arm64-v8a` / `armeabi-v7a` architectures.
- Validation: Bundletool 1.18.3 `validate` passed with no errors. `dump manifest` confirms versionCode 15, versionName 1.0.13, package `com.owais.majestygems`, min/target/compile SDK 24/36/36, required touchscreen, portrait game activity, the unchanged production AdMob application ID, and the same Firebase/Poing AdMob/UMP plugin registrations as prior releases.
- Native/package proof: the extracted universal audit APK has 1,036 entries, three `.so` libraries for each of `arm64-v8a`/`armeabi-v7a`, zero x86/x86_64 libraries, and zero packaged test/report/dev-script entries.
- Signature: `jarsigner -verify` on the AAB reports `jar verified` with the existing Muhammad Owais Khan / Teckvertex Labs upload signer; SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14` (unchanged, expires 2053-12-29).
- Tests: all twelve Godot regression suites reprinted PASS with no assertion failures after the `analytics_service.gd` change; a whole-project Godot editor `--import` pass completed with no script/import errors (the same pre-existing harmless warning about a stray nested `project.godot` under `build/closed_test_aab_audit`, excluded from export). Gradle export completed with no build errors.
- Standalone APK check: Bundletool `build-apks --mode=universal` generated `build/android/production-candidate-vc15-audit-apks.apks` (`universal.apk`, 76,432,567 bytes, SHA-256 `D1155577EEA8B1BE442EC5EAEBEBF8F093295F867833F9D66C94693E7F8C28BB`) from this exact AAB with the local debug keystore; it is a debug-signed audit derivative, not the delivered Play artifact.
- **Device/DebugView: performed and PASSED**, with the user's explicit authorization. The existing debug-signed app was uninstalled from the authorized V2149 (Android 11/API 30) because its signature no longer matched this session's debug keystore, then this exact vc15 universal audit APK was installed fresh. Cold launch, PLAY, and START GAME were driven via `adb shell input`/`monkey`. Logcat confirms, in order: `MajestyAnalytics: Firebase Analytics bridge registered` at Activity startup, `[Analytics] Native Firebase plugin available` when the GDScript service checks `Engine.has_singleton`, `MajestyAnalytics: Forwarded custom event to Firebase: level_start` and `[Analytics] Sent level_start` when Start was pressed — and critically, Firebase's own `FA-SVC` module logged `Logging event: origin=app,name=level_start,params=Bundle[{pattern=..., coin_balance=0, attempt_number=1, level_number=1, ...}]`, proving the event reached Firebase's real pipeline with correct parameters. The device was left with the app uninstalled (clean state) after verification. Full session evidence is in `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md`.
- Report: `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md`.

## Final Pre-Launch Production Candidate RELEASE AAB v1.0.12 (versionCode 14) — SUPERSEDED, DO NOT UPLOAD

- Status: **SUPERSEDED.** Repeat device testing on the same authorized V2149 phone reproduced the identical `Firebase singleton exists but logEvent is unavailable` defect that superseded versionCode 13. The `getPluginMethods()` change made for this build did not fix the root cause; see the versionCode-15 entry above for the actual fix and root-cause analysis.
- AAB: `build/android/majestic-gems-production-candidate-v1.0.12-vc14.aab`
- Size/timestamp: 75,104,762 bytes; 2026-08-28 09:28 +05:00.
- SHA-256: `EAD85A7E30CC0E8D88B7000AED2EC41192BE7BFB1E8F36F2CB2AB19FF44328B7`.
- Source commit/tag: `5d6f74489a4ae15a45ca97d45d50419aa9da02aa` / `final-prelaunch-firebase-device-repair-v1.0.12-vc14-source`.
- Validation: Bundletool 1.18.3 `validate` passed; embedded manifest confirmed versionCode 14/versionName 1.0.12/package `com.owais.majestygems`; `jarsigner` verified the unchanged upload signature; DEX contained the `getPluginMethods`/`logEvent` strings. All of this static validation passed, but it was insufficient to catch the runtime `has_method()` defect — this is why the device test remained a mandatory gate even after full local/static validation passed.
- Device/DebugView: performed. Firebase automatic events (first-open/session) uploaded successfully, but pressing Start reproduced `Firebase singleton exists but logEvent is unavailable`; custom gameplay events were not forwarded. This is why the bundle is superseded.
- Report: `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md`.

## Final Pre-Launch Production Candidate RELEASE AAB v1.0.11 (versionCode 13)

- Status: **SUPERSEDED — DO NOT UPLOAD.** Real-device testing proved Firebase automatic collection/upload but Godot registered the custom singleton without callable `logEvent`, so gameplay custom events were not forwarded. Replaced by the repaired versionCode-14 / versionName-1.0.12 candidate.
- AAB: `build/android/majestic-gems-production-candidate-v1.0.11-vc13.aab`
- Size/timestamp: 75,104,667 bytes; 2026-08-28 08:08:04 +05:00.
- SHA-256: `94852CCA6B75F8D8D0D19219A25B6849962DAA8286B3DDC568CDBFB8226D2257`.
- Source commit/tag: `25bfdffba9d8fdc6b57ec26814ec4a892b0acf44` / `final-prelaunch-production-readiness-v1.0.11-vc13-source`. Delivery tag: `final-prelaunch-production-readiness-v1.0.11-vc13-release` on the manifest/report follow-up commit.
- Version decision: versionCode `13` / versionName `1.0.11`, strictly newer than every recorded/uploaded/delivered identity. Both values and the versioned filename were committed before export.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, existing upload signing, package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, and both `arm64-v8a` / `armeabi-v7a` architectures.
- Validation: Bundletool 1.18.3 `validate` passed. The embedded base manifest reports versionCode 13, versionName 1.0.11, package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, required touchscreen, portrait game activity, production AdMob application ID, Firebase components, and Poing AdMob/UMP registrations.
- Native/package proof: the AAB has 1,039 entries, three libraries for each ARM ABI, zero x86/x86_64 libraries, current compiled `game_config.gdc`, `game_controller.gdc`, and `ad_manager.gdc`, and zero packaged test/report entries.
- Signature: `jarsigner` reports `jar verified`. The upload signer is Muhammad Owais Khan / Teckvertex Labs; SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`.
- Tests: all twelve Godot suites printed their PASS sentinels, whole-project editor parse/import completed without script errors, Gradle dependency resolution passed, and `compileStandardReleaseJavaWithJavac` passed. The known Windows Godot post-PASS shutdown access violation remains separately disclosed in the report.
- Standalone APK check: Bundletool generated `build/android/production-candidate-vc13-audit-apks/universal.apk` (76,432,567 bytes; SHA-256 `C87A6F30DFA3048CBA0F5177132DAE413E210F8FE374746C052D5A0492C642AF`) from this exact AAB. It is a debug-signed audit derivative, not the delivered Play artifact.
- Device/DebugView: after the user removed the old owner-profile app, a never-launched Guest-profile registration was also removed and the versionCode-13 audit APK installed successfully. The phone reported 1.0.11/code 13, arm64, Android 11/API 30. Firebase automatic first-open/session/config upload succeeded with HTTP 204, but pressing Start logged `Firebase singleton exists but logEvent is unavailable`; custom gameplay events were not forwarded. This device proof is why the bundle is superseded.
- Report: `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md`.

## Firebase Custom Gameplay Analytics Pipeline RELEASE AAB v1.0.10 (versionCode 12)

- AAB: `build/android/majestic-gems-firebase-analytics-pipeline-v1.0.10-vc12.aab`
- Size/timestamp: 75,100,120 bytes; 2026-08-27 12:25:19 +05:00.
- SHA-256: `B5EAE522D8454815D42E6DA9CCF96E612558394FAB3E91E48ACD3E7CE481103A`.
- Source commit/tag: `26bcab8` / `firebase-custom-gameplay-analytics-pipeline-v1-source`. Delivery tag: `firebase-custom-gameplay-analytics-pipeline-v1.0.10-vc12-release` on the manifest/report follow-up commit.
- Version decision: versionCode `12` / versionName `1.0.10`. The latest delivered record was code 10 / 1.0.8, but code 11 / 1.0.9 is skipped because an older local AAB already used that identity; neither value is reused.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, existing upload signing, and both `arm64-v8a` / `armeabi-v7a` architectures.
- Validation: Bundletool 1.18.3 `validate` passed. The embedded base manifest reports package `com.owais.majestygems`, versionCode 12, versionName 1.0.10, min SDK 24, target/compile SDK 36, portrait activity, required touchscreen, unchanged AdMob application ID, Firebase init/provider components, Firebase plugin metadata, and unchanged Poing AdMob registrations.
- Native/package proof: a Bundletool universal audit APK exposes `FirebaseAnalyticsPlugin.boolean logEvent(String,String)` and `ensureFirebaseAnalytics()` in DEX. The AAB contains current `analytics_service.gdc`, `game_controller.gdc`, and `ad_manager.gdc`; bytecode strings confirm the new `logEvent` acknowledgement, diagnostics, `level_number`, gem/target schemas, danger reason, and all ad event names. Archive count is 1,039 with zero source-logo, test, or report entries.
- Signature: `jarsigner` reports `jar verified`. The signer remains Muhammad Owais Khan / Teckvertex Labs with SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`.
- Tests: Godot editor parse/import, `FIREBASE_ANALYTICS_PIPELINE_TESTS`, `ADMOB_INTEGRATION_TESTS`, `BRANDING_PUSH_LINE_TESTS`, `GAME_FLOW_REWARD_SPLASH_TESTS`, `RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS`, branding derivative generation, and Gradle `compileStandardReleaseJavaWithJavac` passed.
- Standalone APK check: Bundletool generated `build/android/firebase-analytics-vc12-audit-apks/universal.apk` (76,420,279 bytes) from this exact AAB for DEX/package inspection. It is a debug-signed audit derivative, not the delivered store artifact.
- Device/DebugView: `adb devices -l` returned no connected device. Installation, physical gameplay, logcat forwarding, and Firebase DebugView receipt were not performed and are not claimed; per project rule this does not block delivery of the signed validated AAB.
- Report: `reports/FIREBASE_CUSTOM_GAMEPLAY_ANALYTICS_PIPELINE_V1_REPORT.md`.

## Majestic Branding Refresh AAB v1.0.7 (versionCode 9)

- AAB: `build/android/majestic-gems-branding-refresh-v1.0.7-vc9.aab`
- Size: 71,224,093 bytes; timestamp: 2026-08-26 00:49:20 +05:00; SHA-256: `B155F63DDBFF012BD7AFDE6BA0253827C27A3BB0D1DD44DA77362737C3C32A38`.
- Source commit/tag: `47ac361` / `majestic-branding-refresh-v1.0.7-vc9-source`. Delivery tag: `majestic-branding-refresh-v1.0.7-vc9-release`.
- Version: user-requested same release identity, versionCode `9` / versionName `1.0.7`. It is a fresh AAB with a distinct filename; it must replace the prior local v9 AAB before any Play upload because Play accepts each versionCode only once.
- Validation: Godot 4.6.3 release export, Bundletool 1.18.3 validation, embedded package/version/AdMob/Firebase-plugin manifest audit, v3/v4 branding archive audit (eight new entries, zero v2 entries), and `jarsigner` verification all passed. The existing Teckvertex Labs upload certificate fingerprint is unchanged.
- Tests: `BRANDING_PUSH_LINE_TESTS` and `GAME_FLOW_REWARD_SPLASH_TESTS` passed.
- Device status: not performed; `adb devices -l` found no device. AAB delivery is not blocked.
- Report: `reports/MAJESTIC_BRANDING_REFRESH_V1.0.7_REPORT.md`.

## Firebase Analytics AAB v1.0.7 (versionCode 9)

- Status: delivered. The fresh Godot export contains `analytics_service.gdc`; Bundletool validates its package/version/Firebase metadata. `jarsigner` verifies the unchanged Teckvertex Labs upload certificate. Device installation and Firebase DebugView: not performed because no ADB device was connected; this does not block delivery of the signed validated AAB.
- Version decision: the user confirmed Google Play's latest uploaded build is versionCode 8 / versionName 1.0.6. This release uses the requested next Play identity versionCode 9 / versionName 1.0.7; earlier local v9/v10 entries are superseded artifacts, not Play-upload evidence.

## Complete Majestic Logo Refresh RELEASE AAB v1.0.8 (versionCode 10)

- AAB: `build/android/majestic-gems-logo-refresh-v1.0.8-vc10.aab`
- Size: 68,429,441 bytes (65.26 MiB)
- SHA-256: `F02AD034D03C37657CBB1CEEDF47C5612D6C7C493A8E02182F565A2C6B6EB4F4`
- Source commit/tag: `7e8dc77` / `majestic-logo-refresh-v1.0.8-vc10-source`. Delivery tag: `majestic-logo-refresh-v1.0.8-vc10-release`.
- Validation: Godot 4.6.3 release AAB export and Bundletool validation passed. Embedded manifest is versionCode 10 / versionName 1.0.8 with the required touchscreen and portrait activity. Archive audit found `system_splash_1152_v3` entries, zero old Majestic v1 or splash-v2 entries, and zero tests/reports/dev scripts.
- Tests: `BRANDING_PUSH_LINE_TESTS: PASS`; `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- Device status: no Android device was connected; install and physical splash appearance are not claimed.
- Report: `reports/MAJESTIC_LOGO_REFRESH_V1.0.8_REPORT.md`.

## Android Targeting and Launcher Branding RELEASE AAB v1.0.7 (versionCode 9)

- AAB: `build/android/majestic-gems-android-targeting-icons-v1.0.7-vc9.aab`
- Size: 69,997,682 bytes (66.75 MiB)
- Export timestamp: 2026-08-25 04:10:08 +05:00 (Asia/Karachi)
- SHA-256: `0418F9B100A7CBCF631BC526C556556B11515A68965C1BE6F6C4D098B7C8FC46`
- Source commit/tag: `ffd420b` / `android-targeting-launcher-v1.0.7-vc9-source`. Delivery tag: `android-targeting-launcher-v1.0.7-vc9-release` on the manifest/provenance follow-up commit.
- Version selection: versionCode 9 is greater than all prior recorded codes (maximum 8); versionName 1.0.7 is greater than the previous release 1.0.6. Both values were committed in `export_presets.cfg` before export.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, existing configured release/upload signing, `arm64-v8a` and `armeabi-v7a`.
- Final manifest validation: Bundletool 1.18.3 `validate` passed. The embedded base manifest reports unchanged package `com.owais.majestygems`, versionCode 9, versionName 1.0.7, min SDK 24, target/compile SDK 36, `android.hardware.touchscreen` required=true, game category, portrait activity, and the existing AdMob application ID. It contains no Leanback, Automotive, Wear, or XR declarations.
- Archive validation: 1,004 entries, both ARM library pairs, the v2 legacy/adaptive launcher resources, and zero root `tests/`, `reports/`, or `scripts/dev/` entries.
- Tests: `BRANDING_PUSH_LINE_TESTS: PASS` after importing the v2 PNGs; `UI_SCALE_LAYOUT_TESTS: PASS` for normal phone, tall phone, and tablet portrait layouts. No gameplay code changed.
- Device status: `adb devices -l` found no connected devices. AAB install, physical icon-mask inspection, launcher appearance, touchscreen play, and AdMob on-device behavior are not claimed.
- Report: `reports/ANDROID_TARGETING_LAUNCHER_V1.0.7_REPORT.md`.

## Rail, Target Blast, and Gem Expansion RELEASE AAB v1.0.6 (versionCode 8)

- AAB: `build/android/majestic-gems-rail-target-blast-v1.0.6-vc8.aab`
- Size: 70,147,820 bytes (66.90 MiB)
- Export timestamp: 2026-08-25 01:07:59 +05:00 (Asia/Karachi)
- SHA-256: `54D92F90D0D81A637E3DDDEF5B20AEA4EC5A5E7E65A369D85BD9412B1EA6390E`
- Source commit/tag: `15071b8` / `rail-target-blast-v1.0.6-vc8-source`. Delivery tag: `rail-target-blast-v1.0.6-vc8-release` on the manifest/provenance follow-up commit.
- Version selection: versionCode 8 is strictly greater than the latest recorded release code 7; versionName 1.0.6 is greater than the latest release name 1.0.5. Both values were committed in `export_presets.cfg` before export.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, configured release/upload signing, and both `arm64-v8a` and `armeabi-v7a` architectures.
- Validation: Bundletool 1.18.3 `validate` passed. Its embedded base manifest reports `com.owais.majestygems`, versionCode 8, versionName 1.0.6, min SDK 24, target/compile SDK 36. Archive audit found 1,004 entries, both ARM library sets, `gem_33` and `gem_34`, and zero root `tests/`, `reports/`, or `scripts/dev/` entries. `jarsigner -verify -certs` completed successfully; it emitted the existing JarInputStream signed-entry notices typical of this bundle format.
- Tests: `RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS: PASS` before export. The prior milestone recorded all eleven repository suites passing against the unchanged gameplay source.
- Standalone APK check: the matching prior milestone APK `build/android/majestic-gems-rail-target-blast-gem-expansion-v1.apk` exists and is 82,310,470 bytes. No new APK was requested or exported for this AAB release.
- Device status: `adb devices -l` found no connected devices. AABs are not directly installable, and no Play upload, split delivery, or device launch is claimed.
- Report: `reports/RAIL_TARGET_BLAST_AAB_V1.0.6_REPORT.md`.

## Rail, Target Blast, and Gem Expansion V1 TEST APK (versionCode 7, unreleased)

- APK: `build/android/majestic-gems-rail-target-blast-gem-expansion-v1.apk`
- Size: 82,310,470 bytes (78.50 MiB)
- Export timestamp: 2026-08-25 00:38:01 +05:00 (Asia/Karachi)
- SHA-256: `4FBEC0C511EABB8B838F4B8672FAEBE512736CFBE2A32D0F76AB9735424A6D33`
- Source commit/tag: `21637cb` / `rail-target-blast-gem-expansion-v1-source`. Intake: `97e3c31` / `rail-target-blast-2026-08-25-intake`. Delivery tag: `rail-target-blast-gem-expansion-v1` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 debug APK using committed versionCode 7 / versionName 1.0.5 and Godot debug signing. The committed Gradle AAB format was switched only for this APK export and restored immediately; no AAB was generated and no release identity changed.
- Validation: AAPT package `com.owais.majestygems`, versionCode 7, versionName 1.0.5, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS with one RSA-2048 Godot signer (certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`). ZIP audit: 993 entries, both `arm64-v8a` and `armeabi-v7a`, all 34 runtime gem imports/textures including `gem_33` and `gem_34`, and compiled catalog/config/controller/effects scripts. Zero source-art, tests, reports, project-build payload, or development-script entries are packaged.
- Tests: all eleven repository suites printed PASS. The art preparation pass, focused crop/rail/contact/target/blast/wave/music suite, and two 720x1280 GL Compatibility/ANGLE production captures passed; both frames were manually reviewed.
- Device status: `adb devices -l` returned an empty list. Installation, touch/rail feel, physical listening, haptics, and on-device performance are not claimed.
- Report: `reports/RAIL_TARGET_BLAST_GEM_EXPANSION_V1_REPORT.md`.

## Gem Categories, Pattern Blocks, and Target Feedback V1 TEST APK (versionCode 7, unreleased)

- APK: `build/android/majestic-gems-gem-pattern-feedback-v1.apk`
- Size: 82,140,536 bytes (78.34 MiB)
- Export timestamp: 2026-08-24 23:23:22 +05:00 (Asia/Karachi)
- SHA-256: `D86997A3C132F2A99C663C44D863A487D0517EAB60758210D1C45A924B3E26CB`
- Source commit/tag: `8f93d1c` / `gem-pattern-feedback-v1-source`. Intake: `64cc6df` / `gem-pattern-feedback-2026-08-24-intake`. Delivery tag: `gem-pattern-feedback-v1` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 debug APK using the committed versionCode 7 / versionName 1.0.5 and Godot debug signing. The AAB preset format was switched only for APK export and restored immediately; no AAB was generated and no release version changed. The persistent packaging change adds `scripts/dev/*` to the exclusion filter.
- Validation: AAPT package `com.owais.majestygems`, versionCode 7, versionName 1.0.5, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS with one Godot RSA-2048 signer. ZIP audit: 989 entries, both `arm64-v8a` and `armeabi-v7a`, compiled registry/generator scripts, and all 32 runtime gem identities including `gem_32`. Zero source-art, tests, reports, build output, or development-script entries are packaged.
- Tests: all ten repository suites printed PASS: gem-pattern-feedback v1, reward-feedback v3, reference-game-feel v2, animation/audio/back/privacy, UI scale/layout, game-flow/reward/splash, sound/privacy, branding/push-line, scene-variety/assets, and AdMob integration. `SUPPLIED_ART_REFRESH_PREPARATION: PASS` and `GEM_PATTERN_FEEDBACK_V1_CAPTURE: PASS`; nine 720x1280 GL Compatibility/ANGLE frames were reviewed.
- Device status: `adb devices -l` started the daemon and found no connected device. Installation, touch/rail feel, physical listening, and on-device performance are not claimed.
- Report: `reports/GEM_PATTERN_FEEDBACK_V1_REPORT.md`.

## Supplied Art, Purple UI, and Codebase Cleanup V1 TEST APK (versionCode 7, unreleased)

- APK: `build/android/majestic-gems-supplied-art-purple-ui-cleanup-v1.apk`
- Size: 81,183,723 bytes (77.42 MiB)
- Export timestamp: 2026-08-24 12:58:49 +05:00 (Asia/Karachi)
- SHA-256: `855E7F27D9EF57A5E90CF77B57331FC3CEEEC105C84F9CF47C0874A2A0CC4F7B`
- Source commit/tag: `a2d8372` / `supplied-art-purple-ui-cleanup-v1-source`. Delivery tag: `supplied-art-purple-ui-cleanup-v1` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 debug APK using the currently committed versionCode 7 / versionName 1.0.5 and Godot debug signing. The committed preset remains AAB format; only `gradle_build/export_format` was switched for this one APK and restored to the source commit exactly. No AAB was generated and no release version was changed or reused for a new release.
- Validation: AAPT package `com.owais.majestygems`, versionCode 7, versionName 1.0.5, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS; signer SHA-256 `3b2933181e64f32dae1d52a01642be2c469b36ec05ead7313cde0d6d672ad10f`. ZIP audit: 967 entries, both `arm64-v8a` and `armeabi-v7a` Godot libraries, all five sampled reorganized compiled scripts, and all 20 runtime gem derivatives. Zero source-art, `tests/`, `reports/`, `gems18`, or backgrounds 11-19 entries are packaged.
- Tests: all nine repository suites printed PASS. `SUPPLIED_ART_REFRESH_PREPARATION: PASS`. GL Compatibility/ANGLE produced and reviewed six gameplay captures at 720x1280 and 720x1600 under `reports/supplied-art-purple-ui-cleanup-v1/screenshots/`.
- Device status: `adb devices -l` started the daemon and found no connected device. Installation, touch feel, performance, listening, haptics, and physical-device acceptance are not claimed.
- Report: `reports/SUPPLIED_ART_PURPLE_UI_CODEBASE_CLEANUP_V1_REPORT.md`.


## Reward Gem Simultaneous Physics V6 RELEASE AAB v1.0.5 (versionCode 7)

- AAB: `build/android/majestic-gems-reward-gem-simultaneous-physics-v1.0.5-vc7.aab`
- Size: 70,113,786 bytes (66.87 MiB)
- Export timestamp: 2026-08-23 13:47:05 +05:00 (Asia/Karachi)
- SHA-256: `337ADB0ED1EC07B27CC8F775EC700516A88CA5A82B9A5525186713F2430EB38F`
- Source commit/tag: `ef49309` / `reward-gem-simultaneous-physics-v1.0.5-vc7-source`. Delivery tag: `reward-gem-simultaneous-physics-v1.0.5-vc7-release` on the manifest/provenance follow-up commit.
- Version selection: versionCode 7 is strictly greater than every recorded released/uploaded code (maximum prior 6); versionName 1.0.5 is greater than the latest prior release 1.0.4. Both values are persisted and committed in `export_presets.cfg` before export.
- Export: Godot 4.6.3 `--export-release Android`, Gradle AAB, configured release/upload signing, both `arm64-v8a` and `armeabi-v7a`.
- Bundletool 1.18.3: `validate` PASS. Embedded manifest reports package `com.owais.majestygems`, versionCode `7`, versionName `1.0.5`, compile/target SDK 36, and min SDK 24. The bundle has 1,015 entries, base DEX plus both ARM Godot/C++ libraries, and the install-time asset pack contains all five changed V6 gameplay/rendering scripts. Zero `tests/` or `reports/` entries are packaged.
- Signature: `jarsigner -verify -certs` reports `jar verified`; the configured upload certificate is self-signed and has no timestamp, which is expected for this local signed release bundle.
- Tests: all nine V6 repository suites had already printed PASS for the unchanged gameplay source; `REWARD_FEEDBACK_V3_TESTS: PASS` was rerun after the version bump. The previous standalone debug APK `build/android/majestic-gems-reward-gem-simultaneous-physics-v6.apk` still exists; no separate version-7 APK was requested or exported.
- Device status: `adb devices -l` found no connected device. No installation, launch, touch, performance, listening, haptic, or Play Console upload is claimed.
- Report: `reports/REWARD_GEM_SIMULTANEOUS_PHYSICS_V6_REPORT.md`.

## Reward Gem Simultaneous Physics V6 TEST APK (versionCode 6, unreleased)

- APK: `build/android/majestic-gems-reward-gem-simultaneous-physics-v6.apk`
- Size: 82,273,288 bytes (78.46 MiB)
- Export timestamp: 2026-08-23 13:23:58 +05:00 (Asia/Karachi)
- SHA-256: `25347DE379C63F0EF3E537A8462599527365E7DF83A4A4B136C17018DDE8D82A`
- Source commit/tag: `6fcdb44` / `reward-gem-simultaneous-physics-v6-source`. Delivery tag: `reward-gem-simultaneous-physics-v6` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, Godot debug signing, `arm64-v8a` and `armeabi-v7a`. The committed preset remains versionCode 6 / versionName 1.0.4 and AAB format; export path/format were changed only for this debug APK and restored byte-for-byte. No AAB was generated, so no release version was reused or changed.
- Validation: AAPT package `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS with signer SHA-256 `3b2933181e64f32dae1d52a01642be2c469b36ec05ead7313cde0d6d672ad10f`. ZIP audit: 1,004 entries, both ARM Godot libraries, all five changed compiled gameplay/rendering scripts present, and zero packaged `tests/` or `reports/` entries.
- Tests: all nine repository suites printed PASS. GL Compatibility/ANGLE completed the production-path capture and 33 reviewed PNGs are tracked under `reports/reward-gem-simultaneous-physics-v6/screenshots/`.
- Device status: `adb devices -l` started the daemon and found no connected device. Installation, touch feel, frame time, listening, haptics, and physical-device acceptance are not claimed.
- Report: `reports/REWARD_GEM_SIMULTANEOUS_PHYSICS_V6_REPORT.md`.

## Reward Gem Split Readability V5 TEST APK (versionCode 6, unreleased)

- APK: `build/android/majestic-gems-reward-gem-split-readability-v5.apk`
- Size: 82,276,488 bytes (78.46 MiB)
- Export timestamp: 2026-08-23 12:31:14 +05:00 (Asia/Karachi)
- SHA-256: `8E58509640BCBD5EDF13A25B0382661DF3AF0088446808E5751149E899921644`
- Source commit/tag: `f5d76b5` / `reward-gem-split-readability-v5-source`. Delivery tag: `reward-gem-split-readability-v5` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, Godot debug signing, `arm64-v8a` and `armeabi-v7a`. The committed preset remains versionCode 6 / versionName 1.0.4 and AAB format; `gradle_build/export_format` was changed only for this debug APK and restored immediately. No AAB was generated, so no release version was reused or changed.
- Validation: AAPT package `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS with signer SHA-256 `3b2933181e64f32dae1d52a01642be2c469b36ec05ead7313cde0d6d672ad10f`. ZIP audit: 1,004 entries, both ARM Godot libraries, all five changed compiled gameplay/rendering scripts present, and zero packaged `tests/` or `reports/` entries.
- Tests: all nine repository suites passed together. GL Compatibility/ANGLE completed the production-path capture and 33 reviewed PNGs are tracked under `reports/reward-gem-extraction-v5/screenshots/`.
- Device status: `adb devices -l` started the daemon and found no connected device. Installation, touch feel, frame time, listening, haptics, and physical-device acceptance are not claimed.
- Report: `reports/REWARD_GEM_SPLIT_READABILITY_V5_REPORT.md`.

## Reward Feedback Real Gameplay Gems V4 TEST APK (versionCode 6, unreleased)

- APK: `build/android/majestic-gems-reward-feedback-real-gems-v4.apk`
- Size: 82,272,500 bytes (78.46 MiB)
- Export timestamp: 2026-08-22 08:45:44 +05:00 (Asia/Karachi)
- SHA-256: `4CEA7BC0B5B4B616FEDFA75A5DEC0693C7DF91D87BCFE5C6C2CD68700C769233`
- Source commit/tag: `071d1ba` / `reward-feedback-real-gems-v4-source`. Delivery tag: `reward-feedback-real-gems-v4` on the manifest/provenance follow-up commit.
- Version/export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, Godot debug signing, both `arm64-v8a` and `armeabi-v7a`. The committed preset remains versionCode 6 / versionName 1.0.4 and AAB format; only `gradle_build/export_format` was switched to APK for this debug build, then restored byte-for-byte. No AAB was generated, so no release identity was reused or changed.
- Validation: AAPT package `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36. APK Signature Scheme v2 PASS with one Godot RSA-2048 debug signer. ZIP audit: 1,004 entries, both ARM Godot libraries, all five changed compiled gameplay/rendering scripts present, and zero packaged `tests/` or `reports/` entries.
- Tests: all nine repository suites passed. After the final post-hold coin-flight signal correction, `REWARD_FEEDBACK_V3_TESTS` and `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS` were rerun and passed. GL Compatibility/ANGLE produced and reviewed 31 PNG proof frames plus a 360x640/30 FPS AVI; the PNG evidence is tracked under `reports/reward-feedback-real-gems-v4/screenshots/`.
- Device status: `adb devices -l` found no connected device. Installation, touch feel, frame time, listening, haptics, and physical-device acceptance are not claimed.
- Report: `reports/REWARD_FEEDBACK_REAL_GEMS_V4_REPORT.md`.

## Reward Feedback V3 — HUD Coin-Counter Continuity Fix TEST APK (versionCode 6, unreleased)

- APK: `build/android/majestic-gems-reward-feedback-v3-hud-coin-fix.apk`
- Size: 82,255,008 bytes (78.44 MiB)
- Export timestamp: 2026-08-22 04:46:16 +05:00 (Asia/Karachi)
- SHA-256: `C6122C59BAC86833770F4D500419C7EB2D14C336EE7B497EF42686DD00769790`
- Source state: uncommitted working tree on top of `db11dae` (`docs: record procedural collision sound release`). This build is not tagged and not committed; it exists to validate the reward feedback v3 pass plus the HUD coin-counter continuity fix before either is committed. No version value was changed: versionCode 6 / versionName 1.0.4 match the committed preset exactly, since no AAB was generated and this is a same-identity debug verification build.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, both `arm64-v8a` and `armeabi-v7a`, Godot debug signing. `export_presets.cfg` was temporarily switched from Gradle AAB to Gradle APK, the debug APK was exported, and the preset was restored byte-for-byte to the committed AAB path/format immediately afterward (`git diff export_presets.cfg` shows no change). No AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36, game category, portrait/immersive display settings. APK Signature Scheme v2 PASS with one Godot RSA-2048 debug signer. ZIP audit: 1,004 entries, five DEX files, both ARM Godot/C++ library pairs, `AndroidManifest.xml` present, Tween Composer Home dependency present (`tween_composer.gdc` and its three configuration resources), zero `tests/`/`reports/` entries. Packaged `assets/scripts/game_controller.gdc`, `assets/scripts/gameplay_effects_layer.gdc`, and `assets/scripts/gameplay_hud_layer.gdc` are present; the fixed `gameplay_hud_layer.gd` source predates the export timestamp, so the build reflects the HUD coin-counter fix and not a stale cache.
- Tests: `REWARD_FEEDBACK_V3_TESTS`, `REFERENCE_GAME_FEEL_V2_TESTS`, `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`, `UI_SCALE_LAYOUT_TESTS`, `GAME_FLOW_REWARD_SPLASH_TESTS`, `SOUND_PRIVACY_LINK_TESTS`, `BRANDING_PUSH_LINE_TESTS`, `SCENE_VARIETY_ASSETS_TESTS`, and `ADMOB_INTEGRATION_TESTS` all passed (Godot 4.6.3 headless). Each printed its PASS line before the Windows runner's known post-sentinel teardown access violation; no assertion failed.
- Device status: no Android device was connected; installation, launch, and physical on-device verification are not claimed.
- Report: `reports/REWARD_FEEDBACK_V3_REPORT.md` (Addendum — HUD coin-counter continuity fix).

## Original Procedural Collision Sound Restore RELEASE AAB v1.0.4 (versionCode 6)

- AAB: `build/android/majestic-gems-procedural-collision-restore-v1.0.4-vc6.aab`
- Size: 70,072,285 bytes (66.83 MiB)
- Export timestamp: 2026-08-18T22:03:49+05:00 (Asia/Karachi)
- SHA-256: `FF5A2EE1F2A75B093DA8BAC34780D0A42F0B56A03656604E9708EEC471982419`
- Source commit/tag: `55f96d4` / `procedural-collision-sound-restore-v1.0.4-vc6-source`; delivery tag: `procedural-collision-sound-restore-v1.0.4-vc6-release`.
- Version selection: versionCode 6 is strictly greater than every recorded delivered/uploaded code (maximum prior 5); versionName 1.0.4 is greater than prior 1.0.3. Both values were saved and committed before export.
- Export: Godot 4.6.3 `--export-release`, Gradle AAB, existing configured upload signing, both `arm64-v8a` and `armeabi-v7a`.
- Bundletool 1.18.3 validation: PASS. Embedded manifest reports versionCode `6` and versionName `1.0.4`; feature module contains three DEX files and both ARM Godot/C++ library pairs.
- Tests: `SOUND_PRIVACY_LINK_TESTS`, `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`, and `REFERENCE_GAME_FEEL_V2_TESTS` passed.
- Device/Play status: AAB is not directly installable; no Play upload or physical-device behavior is claimed.
- Report: `reports/PROCEDURAL_COLLISION_SOUND_RESTORE_RELEASE.md`.

## Original Procedural Collision Sound Restore TEST APK v1.0.4 (versionCode 6)

- APK: `build/android/majestic-gems-procedural-collision-restore-v1.0.4-vc6.apk`
- Size: 82,227,532 bytes (78.42 MiB)
- Export timestamp: 2026-08-18T22:05:55+05:00 (Asia/Karachi)
- SHA-256: `C9C3DFEF0C1E4929FC0FB1000E0066D8BE612A47B14A69B90BBE5C60D4041EEB`
- Source commit/tag: `55f96d4` / `procedural-collision-sound-restore-v1.0.4-vc6-source`; delivery tag: `procedural-collision-sound-restore-v1.0.4-vc6-release`.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK with debug signing. The committed AAB path/format was restored immediately after export; no version value changed.
- AAPT/signature validation: `com.owais.majestygems`, versionCode 6, versionName 1.0.4, min SDK 24, target/compile SDK 36; APK Signature Scheme v2 PASS with one signer; both ARM ABIs present.
- Device status: `adb devices -l` found no attached device. Installation and subjective listening are not claimed.
- Report: `reports/PROCEDURAL_COLLISION_SOUND_RESTORE_RELEASE.md`.

## Original Collision / Fast Merge / Visible-Touch Repair TEST APK

- APK: `build/android/majestic-gems-original-contact-fast-merge-touch-fix.apk`
- Size: 82,227,624 bytes (78.42 MiB)
- Export timestamp: 2026-08-18T21:31:01+05:00 (Asia/Karachi)
- SHA-256: `C3EAC8417D9566F4E10E011A7838BA514D15C5FD299B3B80E2B68AF757364A8C`
- Source commit/tag: `442ad33` / `original-collision-fast-merge-visible-touch-source`; delivery tag: `original-collision-fast-merge-visible-touch-apk`.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, debug signing, both `arm64-v8a` and `armeabi-v7a`. The preset was temporarily set to APK and restored to its committed AAB path/format immediately afterward. No AAB was generated.
- Validation: `REFERENCE_GAME_FEEL_V2_TESTS`, `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`, `SOUND_PRIVACY_LINK_TESTS`, and `UI_SCALE_LAYOUT_TESTS` passed. AAPT reports `com.owais.majestygems`, versionCode 5, versionName 1.0.3, min SDK 24, target/compile SDK 36, game category, and portrait support. APK Signature Scheme v2 passes with one signer; ZIP validation found `AndroidManifest.xml`, `classes.dex`, and Godot libraries for both ARM ABIs.
- Device status: `adb devices -l` found no connected device. Installation, physical touch-merging, and subjective original-volume listening are not claimed.
- Report: `reports/ORIGINAL_COLLISION_FAST_MERGE_VISIBLE_TOUCH_REPAIR.md`.

## Reward, Coin, and Merge Timing Restore RELEASE AAB v1.0.3 (versionCode 5)

- AAB: `build/android/majestic-gems-reward-coin-merge-restore-v1.0.3-vc5.aab`
- Size: 70,072,704 bytes (66.83 MiB)
- Export timestamp: 2026-08-18T13:20:06.3308489+05:00 (Asia/Karachi)
- SHA-256: `9A976CA0639E74F98FECC8B0AB5F9C0E57318C47F8E77E493E622037E22ED966`
- Source commit/tag: `5a1fc0f` / `reward-coin-merge-restore-v1.0.3-vc5-source`; delivery tag: `reward-coin-merge-restore-v1.0.3-vc5-release`.
- Version selection: the user confirmed Google Play currently has versionCode 3. Local tester APKs had already used code 4/name 1.0.2, so the committed preset advances permanently to versionCode 5/versionName 1.0.3 rather than reusing code 4.
- Export preset/method: committed `Android` Gradle AAB preset; Godot 4.6.3 headless `--export-release`; existing upload key. No new signing key or credential was generated.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 5; versionName 1.0.3; min SDK 24; target/compile SDK 36; release manifest is not debuggable.
- Signing: JAR verification PASS; existing RSA-2048 upload certificate SHA-256 `E3BA3287A50AF4AC49C07CBCB2E4F10940AD519642CB24F21BCF856B3F3BCE14`.
- Bundle validation: Bundletool 1.18.3 PASS; 1,015 entries; base manifest; three DEX files; `arm64-v8a` and `armeabi-v7a` Godot/C++ pairs; Tween Composer Home dependency present; production AdMob App ID `ca-app-pub-4605895178658062~1516881747`; zero report/test/source-asset entries.
- Tests: all eight repository regression sentinels PASS. The Windows test runner retains its known post-PASS teardown access violation; no assertion failed.
- Device/Play status: AAB files are not directly installable. No Play upload or physical-device launch is claimed.
- Report: `reports/REWARD_COIN_MERGE_TIMING_RESTORE_RELEASE.md`.

## Reward, Coin, and Merge Timing Restore TEST APK v1.0.3 (versionCode 5)

- APK: `build/android/majestic-gems-reward-coin-merge-restore-v1.0.3-vc5.apk`
- Size: 82,228,028 bytes (78.42 MiB)
- Export timestamp: 2026-08-18T13:21:31.9650153+05:00 (Asia/Karachi)
- SHA-256: `966CF3DED40427BA70D2F8256434C1EB722E40B7C04672DEFDA5B5121EC61CDB`
- Source commit/tag: `5a1fc0f` / `reward-coin-merge-restore-v1.0.3-vc5-source`; delivery tag: `reward-coin-merge-restore-v1.0.3-vc5-release`.
- Export preset/method: the committed version-5 Android preset was temporarily switched from Gradle AAB to Gradle APK for Godot 4.6.3 headless `--export-debug`, then restored exactly to the committed AAB path and format.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 5; versionName 1.0.3; min SDK 24; target/compile SDK 36; debug build.
- Signing/package validation: APK Signature Scheme v2 PASS with Godot's RSA-2048 debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT/ZIP audit PASS: 1,004 entries, both ARM Godot/C++ pairs, Tween Composer Home dependency, production AdMob App ID, and zero report/test/source-asset entries.
- Device status: `adb devices -l` returned no attached device. Installation, on-phone timing acceptance, Back/Exit lifecycle, and subjective audio listening are not claimed.
- Report: `reports/REWARD_COIN_MERGE_TIMING_RESTORE_RELEASE.md`.

## Animation Revert, Collision-Audio Midpoint, and Android Exit Fix TEST APK

- APK: `build/android/majestic-gems-animation-revert-audio-midpoint-exit-fix.apk`
- Size: 82,226,968 bytes (78.42 MiB)
- Export timestamp: 2026-08-18T12:49:16+05:00 (Asia/Karachi)
- SHA-256: `371F47693B0019696152E0C1CB0E753522160BB9B6CBD2123D4CD9237E020FE2`
- Source commit/tag: `32794fb` / `animation-revert-audio-midpoint-android-exit-source`.
- Export preset/method: existing `Android` preset temporarily switched from Gradle AAB to Gradle APK for Godot 4.6.3 headless `--export-debug`, then restored exactly to `build/android/majestic-gems-closed-test-v2.aab` / AAB format. Export reached `[DONE]` and exited cleanly. No AAB was generated and no version value changed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 4; versionName 1.0.2; min SDK 24; target/compile SDK 36; game category; portrait; debug build.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. ZIP audit PASS: 1,004 entries, five DEX files, `arm64-v8a` and `armeabi-v7a` Godot/C++ pairs, both midpoint audio imports, target/coin imports, production AdMob App ID `ca-app-pub-4605895178658062~1516881747`, and zero report/test/source-audio entries.
- Tests: Godot import/parse plus all eight repository regression sentinels PASS. The Windows test runner retains its known post-PASS teardown access violation; no assertion failed.
- Device status: `adb devices -l` returned no attached device and the started daemon was stopped. Installation, Activity-exit/OEM dialog confirmation, and subjective collision-audio listening are not claimed.
- Report: `reports/ANIMATION_REVERT_AUDIO_MIDPOINT_ANDROID_EXIT_FIX.md`.

## Animation, Audio, Back, and Privacy Polish TEST APK

- APK: `build/android/majestic-gems-animation-audio-back-privacy-polish-test.apk`
- Size: 82,210,382 bytes (78.40 MiB)
- Export timestamp: 2026-08-18T11:03:48.6826871+05:00 (Asia/Karachi)
- SHA-256: `D1CF50AF7664ACFE377D26DC0342061EE33E1CA377E61099AE8B896EA81FFF21`
- Source commit/tag: `acb28a5` / `animation-audio-back-privacy-polish-source`.
- Export preset/method: existing `Android` preset temporarily switched from Gradle AAB to Gradle APK for Godot 4.6.3 headless `--export-debug`, then restored exactly to `build/android/majestic-gems-closed-test-v2.aab` / AAB format. Export reached `[DONE]` and exited cleanly. No AAB was generated and no version value was changed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 4; versionName 1.0.2; min SDK 24; target/compile SDK 36; game category; portrait; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT and ZIP audits PASS: 1,000 entries, five DEX files, both ARM runtimes, production AdMob App ID `ca-app-pub-4605895178658062~1516881747`, all three new filtered audio imports, existing music/coin resources, and zero report/test/source-audio entries.
- Device status: `adb devices -l` returned no attached device and the started daemon was stopped. Installation, OEM/predictive Back delivery, lifecycle behavior, subjective speaker balance, and phone viewport review are not claimed.
- Report: `reports/ANIMATION_AUDIO_BACK_PRIVACY_POLISH.md`.

## Immediate Merge Sound Sync RELEASE AAB v3 - corrected versionCode 3

- AAB: `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab`
- Size: 69,163,616 bytes (65.96 MiB)
- Export timestamp: 2026-08-17T11:21:49.6706229+05:00 (Asia/Karachi)
- SHA-256: `29E0476F88CEA5EC33AA579AC1E15CA432AA9E761C6A7DE6CDB7B9B61A2C5E3B`
- Build source commit/tag: `aa3a1e1` / `android-version-code-3-source`; implementation source/tag: `3f2fa01` / `merge-sound-sync-v3-source`.
- Export preset/method: existing `Android` preset; Godot 4.6.3 headless `--export-release`; Gradle AAB; existing production signing configuration. `version/code=3` was persisted and committed before export. The output used a new `-vc3.aab` filename and did not overwrite either earlier bundle.
- Export-process status: the export log reached `[DONE] export`; the AAB remained unchanged across a 30-second stability check. The exact export-owned Godot/Java processes that stayed open afterward were stopped; a clean outer-process exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 3; versionName 1.0.1; min SDK 24; target/compile SDK 36; release manifest is not debuggable.
- Signing: JAR verification PASS; existing self-signed RSA-2048 upload certificate owned by Muhammad Owais Khan / Teckvertex Labs; certificate SHA-256 `E3BA3287A50AF4AC49C07CBCB2E4F10940AD519642CB24F21BCF856B3F3BCE14`.
- Bundle validation: Bundletool 1.18.3 PASS; 1,003 ZIP entries; base manifest; three DEX files; `arm64-v8a` and `armeabi-v7a` Godot/C++ pairs; immediate merge Ogg import present; zero report/test entries. Manifest production AdMob App ID is `ca-app-pub-4605895178658062~1516881747`; focused AdMob/UMP routing suite printed `ADMOB_INTEGRATION_TESTS: PASS` before its documented late mock callback teardown error.
- Device status: AAB files are not directly installable. No Play upload/delivery or physical-device launch is claimed.
- Supersession: `majestic-gems-merge-sound-sync-v3.aab` used already-consumed versionCode 2 and must not be uploaded. This versionCode-3 bundle replaces it.
- Report: `reports/MERGE_SOUND_SYNC_FIX_V3_REPORT.md`.

## Immediate Merge Sound Sync RELEASE AAB v3

- AAB: `build/android/majestic-gems-merge-sound-sync-v3.aab`
- Size: 69,163,559 bytes (65.96 MiB)
- Export timestamp: 2026-08-17T10:58:55.8427766+05:00 (Asia/Karachi)
- SHA-256: `D08D5169C19AAA8E8F63FD9BFB3B6345CEE0C64B7C9C550D359B5BECC1346D30`
- Build source commit/tag: `86f0c90` / `merge-sound-sync-v3-test-apk`; implementation source/tag: `3f2fa01` / `merge-sound-sync-v3-source`.
- Export preset/method: existing `Android` preset; Godot 4.6.3 headless `--export-release`; Gradle AAB; existing production signing configuration; output override used a new filename and did not modify the preset or overwrite `majestic-gems-closed-test-v2.aab`.
- Export-process status: the export log reached `[DONE] export` and the AAB remained stable across a 30-second check before the silent outer wrapper timed out. The exact export-owned Godot/Java processes were stopped and none remained; a clean outer exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; release manifest is not debuggable.
- Signing: JAR verification PASS; existing self-signed RSA-2048 upload certificate owned by Muhammad Owais Khan / Teckvertex Labs; certificate SHA-256 `E3BA3287A50AF4AC49C07CBCB2E4F10940AD519642CB24F21BCF856B3F3BCE14`.
- Bundle validation: Bundletool 1.18.3 PASS; 1,003 ZIP entries; base manifest; three DEX files; `arm64-v8a` and `armeabi-v7a` Godot/C++ pairs; immediate merge Ogg import present; zero report/test/source-audio entries. Manifest production AdMob App ID is `ca-app-pub-4605895178658062~1516881747`; focused AdMob/UMP routing suite reached PASS.
- Device status: AAB files are not directly installable. No Play delivery or device install/launch is claimed.
- Play note: superseded because Google Play had already consumed versionCode 2. Do not upload this file; use the corrected `-vc3.aab` bundle above.
- Report: `reports/MERGE_SOUND_SYNC_FIX_V3_REPORT.md`.

## Immediate Merge Sound Sync TEST APK v3

- APK: `build/android/majestic-gems-merge-sound-sync-v3-test.apk`
- Size: 81,319,143 bytes (77.55 MiB)
- Export timestamp: 2026-08-16T13:37:52.4087470+05:00 (Asia/Karachi)
- SHA-256: `58648E9C5FF783AB1D79020E2368CB6FECA56E7A3AEC232BB683303EE2A9695F`
- Source commit/tag: `3f2fa01` / `merge-sound-sync-v3-source`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for Godot 4.6.3 headless `--export-debug`, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated.
- Export-process status: the export log reached `[DONE] export` and the APK was stable across a 30-second check before the silent outer wrapper timed out. The exact export-owned Godot/Java processes were stopped and none remained; a clean outer exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT/ZIP checks PASS: 992 entries, one manifest, primary dex, both ARM runtimes, packaged `merge-target-immediate.ogg` import, and zero report/test/source-audio entries.
- Device status: the bounded `adb devices` probe did not return; its exact helper was stopped. Installation, launch, and physical-device listening are not claimed.
- Report: `reports/MERGE_SOUND_SYNC_FIX_V3_REPORT.md`.

## Sound Mapping Correction TEST APK v2

- APK: `build/android/majestic-gems-sound-mapping-v2-test.apk`
- Size: 81,304,475 bytes (77.54 MiB)
- Export timestamp: 2026-08-16T13:02:21.8052746+05:00 (Asia/Karachi)
- SHA-256: `A3A075124A1DF0F421FF4D87A693D087D618F506420338495C9C47FCBA1FDAC8`
- Source commit/tag: `506e08b` / `sound-mapping-correction-v2-source`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for Godot 4.6.3 headless `--export-debug`, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated.
- Export-process status: the sandboxed attempt failed only because Gradle network access was denied. The approved retry wrote a stable APK which passed all artifact audits before the outer wrapper timed out; the exact two export-owned Godot/Java processes were then stopped and none remained. A clean outer exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT and ZIP checks PASS: 990 entries, one manifest, primary dex, both ARM runtimes, runtime audio resources, and zero report/test/source-audio entries.
- Device status: `adb devices` did not return within the device-check window; its exact helper was stopped. Installation, launch, subjective speaker balance, and physical-device clipping perception are not claimed.
- Report: `reports/SOUND_MAPPING_CORRECTION_V2_REPORT.md`.

## Supplied Sound + Home Privacy Link TEST APK v1

- APK: `build/android/majestic-gems-sound-pass-test.apk`
- Size: 81,303,547 bytes (77.54 MiB)
- Export timestamp: 2026-08-16T12:21:03.2970765+05:00 (Asia/Karachi)
- SHA-256: `8CB63641D116907647A1C81161E59686EA6008901DF36B79622CB0EDB6EC08D3`
- Source commit/tag: `6470a69` / `sound-integration-privacy-link-v1-source`; supplied-file baseline: `ec0f497` / `supplied-sound-assets-baseline`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for one Godot 4.6.3 headless `--export-debug` command, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated.
- Export-process status: the stable APK reached its final timestamp/size and passed ZIP/signature/package validation before the outer Godot wrapper reached its five-minute silent timeout. No export-owned Godot or Java process remained afterward; a clean outer exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT and ZIP checks PASS: 990 entries, one manifest, eight new supplied runtime-audio imports, preserved music/coin runtime resources, compiled default bus layout, and zero scoped source/report/test entries.
- Device status: `adb devices -l` started its daemon and returned no device entry; the daemon was stopped afterward. Installation, launch, speaker balance, clipping perception, haptics, and Home-link safe-area review are not claimed.
- Report: `reports/SOUND_INTEGRATION_PRIVACY_LINK_V1_REPORT.md`.

## Regenerated Scene Art TEST APK v1

- APK: `build/android/majestic-gems-regenerated-scene-art-test.apk`
- Size: 80,913,394 bytes (77.17 MiB)
- Export timestamp: 2026-08-16T10:01:08.0608124+05:00 (Asia/Karachi)
- SHA-256: `18D35421FFFF50627732E37C70EA6E155198078421502B67B62E3EBDD1368CD4`
- Source commit/tag: `f540969` / `regenerated-scene-art-integration-v1`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for one Godot 4.6.3 headless `--export-debug` command, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated.
- Export-process status: the stable APK reached its final timestamp, size, readable ZIP state, and successful signature/package validation before the outer Godot wrapper reached its five-minute silent timeout. No export-owned Godot or Java process remained afterward; a clean outer exit is not claimed.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT identity/SDK checks and ZIP checks PASS: 972 entries, one manifest, 19 regenerated background imports, 10 regenerated table imports, zero temporary original-table entries, and zero scoped source/report/test entries.
- Device status: `adb devices -l` started its daemon and returned no device entry; the daemon was stopped afterward. Installation, launch, touch behavior, performance, and physical safe-area review are not claimed.
- Report: `reports/REGENERATED_SCENE_ART_INTEGRATION_V1_REPORT.md`.

## Responsive Scene Variety TEST APK v1

- APK: `build/android/majestic-gems-responsive-scene-variety-test.apk`
- Size: 81,986,750 bytes (78.19 MiB)
- Export timestamp: 2026-08-16T07:21:56.8005654+05:00 (Asia/Karachi)
- SHA-256: `22A7F145E45EF306F79BD8FFB873455D09D3DD2C2F87177E344E0CEC82DA8249`
- Source commit/tag: `081eb1c` / `responsive-scene-variety-v1-optimized-source`; gameplay implementation commit/tag: `62bd4b8` / `responsive-scene-variety-v1-source`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for one corrective Godot 4.6.3 headless `--export-debug` command, then restored to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated.
- Optimization audit: tracked quality-0.85 background and quality-0.92 alpha-table import profiles reduced imported scene textures from 19.83 MiB to 3.12 MiB. The final APK is 17,480,832 bytes (17.57%) smaller than the diagnostic default-import export and 3,234,765 bytes (3.80%) smaller than the previous hierarchy APK while containing 19 backgrounds and 10 tables.
- Export-process status: `.godot/responsive-scene-variety-optimized-apk-export.log` reached `[DONE] export` and the stable APK existed at its final size. The outer wrapper timed out in Godot's silent post-export phase; exact export-owned Godot PID 11100 and Java PID 13684 were stopped, with zero remaining afterward.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode 2; versionName 1.0.1; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/package validation: APK Signature Scheme v2 PASS with one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT identity/SDK/portrait/features and ZIP checks PASS: 972 entries, one manifest, 19 scene backgrounds, 10 scene tables, and zero scoped source/report/test/retired-asset entries.
- Device status: `adb devices -l` did not return within the validation window; the exact spawned ADB process was terminated and no process remained. Installation, launch, touch behavior, performance, and physical safe-area review are not claimed.
- Report: `reports/RESPONSIVE_SCENE_VARIETY_ASSET_OPTIMIZATION_V1_REPORT.md`.

## Target / Merge-Path Hierarchy TEST APK v1

- APK: `build/android/majestic-gems-target-path-hierarchy-test.apk`
- Size: 85,221,515 bytes (81.27 MiB)
- Export timestamp: 2026-08-16T06:00:35.7160533+05:00 (Asia/Karachi)
- SHA-256: `6A56FE2DC9FD7D14369B0352C08D2A1CB900A45FFFC1D0AB2634223EE4FB34B8`
- Source commit/tag: `c7d03f0` / `target-path-hierarchy-fix-v1-source`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for one Godot 4.6.3 headless `--export-debug` command, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated for this milestone.
- Export-process status: `.godot/target_path_apk_export.log` reached `[DONE] export` and the stable APK existed at its final size. The outer wrapper remained silent afterward, so a clean outer exit is not claimed. The export-owned Godot PID 1152 and Java PID 16720 were stopped; the follow-up audit found neither process.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode `2`; versionName `1.0.1`; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/validation: APK Signature Scheme v2 PASS; one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT package/version/SDK and ZIP/native-library checks PASS. Standalone file existence and SHA-256 checks PASS. The production AAB signing configuration was not changed.
- Device status: `adb devices -l` returned an empty device list after starting its local daemon; the daemon was stopped afterward. Installation, launch, and physical-device layout review are not claimed.
- Report: `reports/TARGET_PATH_HIERARCHY_FIX_REPORT.md`.

## Responsive UI + Scale TEST APK v1

- APK: `build/android/majestic-gems-ui-scale-test.apk`
- Size: 85,220,655 bytes (81.27 MiB)
- Export timestamp: 2026-08-16T04:58:33.6326764+05:00 (Asia/Karachi)
- SHA-256: `12F5BE9848C9982A92B40A1C2FE589BEB7094C5385DA254EF7606305A4578DFB`
- Source commit/tag: `60448dd` / `responsive-ui-scale-test-v1-source`.
- Export preset/method: the existing `Android` preset was temporarily switched from Gradle AAB to Gradle APK for one Godot 4.6.3 headless `--export-debug` command, then restored exactly to `majestic-gems-closed-test-v2.aab` / AAB format. No AAB was generated for this milestone.
- Export-process status: the export log reached `[DONE] export` and the stable APK was present at its final size. The outer wrapper remained silent afterward, so a clean outer exit is not claimed. A final process audit found the export-owned Godot PID 10752 and Java PID 18764 still orphaned; those exact processes were stopped, and the follow-up count was zero.
- Package/version: `com.owais.majestygems`; application label `Majestic Gems`; versionCode `2`; versionName `1.0.1`; min SDK 24; target/compile SDK 36; debug build.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains `libgodot_android.so` and `libc++_shared.so`.
- Signing/validation: APK Signature Scheme v2 PASS; one RSA-2048 Godot debug signer; certificate SHA-256 `3B2933181E64F32DAE1D52A01642BE2C469B36EC05EAD7313CDE0D6D672AD10F`. AAPT package/version/SDK/orientation/features and ZIP/native-library checks PASS. The production AAB signing configuration was not changed.
- Device status: `adb devices -l` did not return within the validation window; the exact spawned ADB process was stopped. Installation, launch, and physical-device layout review are not claimed.
- Report: `reports/RESPONSIVE_UI_SCALE_TEST_REPORT.md`.

## Android Device Compatibility V2 sideload test APK

- APK: `build/android/majestic-gems-v2-test.apk`
- Size: 74,123,752 bytes (70.69 MiB)
- Export timestamp: 2026-08-14T07:57:42.6614200+05:00 (Asia/Karachi)
- SHA-256: `10D9515CBD513358AABE337896D90DC072DD1672A4205487F64C3AD9C2413961`
- Source AAB: `build/android/majestic-gems-closed-test-v2.aab`, generated from commit/tag `4791379` / `android-device-compatibility-v2` configuration.
- Generation method: bundletool 1.18.3 universal APK derived from the validated release AAB and signed with the existing Play upload key.
- Package/version: `com.owais.majestygems`; versionCode `2`; versionName `1.0.1`; min SDK 24; target/compile SDK 36; non-debuggable.
- ABIs/native libraries: `arm64-v8a` and `armeabi-v7a`; each contains matching `libgodot_android.so` and `libc++_shared.so`.
- Signing/validation: APK Signature Scheme v2 PASS; v3 PASS; one RSA-2048 signer; certificate SHA-256 matches the v1/v2 upload certificate. Manifest identity, production AdMob App ID, GLES 3.0, portrait/faketouch features, ABI list, and APK existence checks PASS.
- Device status: `adb devices -l` returned no device, so installation and launch are not claimed. If a Play-installed copy uses Google Play's app-signing certificate rather than the upload certificate, uninstall it before sideloading this APK or test the AAB through the Play closed track.
- Report: `reports/ANDROID_DEVICE_COMPATIBILITY_V2.md`.

## Android Device Compatibility V2 closed-test AAB

- AAB: `build/android/majestic-gems-closed-test-v2.aab`
- Size: 73,049,656 bytes (69.67 MiB raw bundle)
- Export timestamp: 2026-08-14T07:42:15.8111993+05:00 (Asia/Karachi)
- SHA-256: `E00DBBDDD3D19DA81450788B2DF18E062E01A24F33EE1AD3DEB43CA982B10B05`
- Source baseline: `05ca6ed4736d1d470fc5a18fed445ed936d8ab92` / `play-closed-test-release-aab-v1`; configuration and documentation are delivered by the compatibility-v2 commit/tag.
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-release`; Gradle AAB; compressed `arm64-v8a` and `armeabi-v7a` native libraries.
- Package/version: `com.owais.majestygems`; versionCode `2`; versionName `1.0.1`; min SDK 24; target/compile SDK 36; non-debuggable.
- Signing: existing Play upload key; `jarsigner` PASS; RSA-2048 certificate SHA-256 matches the v1 AAB exactly.
- Validation: Bundletool 1.18.3 PASS; both ABI library pairs present; manifest/package/version/SDK/features PASS; packaged production interstitial/rewarded and UMP probes PASS; forced geography `0`; zero release test devices; native `can_request_ads` and privacy URL present; no runtime consent reset. Focused AdMob test printed PASS before the documented late mock callback/exit 1.
- Device status: `adb devices -l` returned no device. AAB install, Play split delivery, and tester-device compatibility are not claimed.
- Report: `reports/ANDROID_DEVICE_COMPATIBILITY_V2.md`.

## Google Play Closed Testing release AAB

- AAB: `build/android/majestic-gems-closed-test.aab`
- Size: 47,475,500 bytes (45.28 MiB raw bundle)
- Export timestamp: 2026-08-13T10:09:17.3928442+05:00 (Asia/Karachi)
- SHA-256: `700CA075051FB62F4356B62C477CADD5DD428056DAB44D5B6635741409649912`
- Source commit: `6d72e238063ecceafb89abf778fefb36cf8c5c1b` (`build: configure Play closed test release`)
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-release`; Gradle AAB, arm64-v8a only, compressed native libraries.
- Signing: user-provided Majestic Gems upload key; JAR signature verification PASS; signer differs from the Godot debug certificate. Keystore and credentials remain ignored and untracked.
- Package/version: `com.owais.majestygems`; versionCode `1`; versionName `Majestic Gems`; min SDK 24; target/compile SDK 36.
- Validation: focused AdMob/UMP suite reached PASS before its documented late Poing mock callback; Bundletool validation PASS; bundle ZIP readable; manifest identity/App ID/permissions/SDK/plugin audit PASS; `android:debuggable` absent; release compiled configuration selects both production units, forced geography `0`, zero release UMP test devices, no consent reset marker, and no temporary device hash; patched native `can_request_ads()` is present in packaged DEX.
- Device status: the AAB is not directly installable and was not Play-delivered to the connected device. No production-ad impression or Play split-install test is claimed.
- Report: `reports/PLAY_CLOSED_TEST_RELEASE_AAB.md`.

## Poing UMP `canRequestAds()` Patch v1

- APK: `build/android/ump-can-request-ads-patch-v1-debug.apk`
- Size: 53,376,732 bytes (50.90 MiB)
- Export timestamp: 2026-08-12T10:29:57.0991603+05:00 (Asia/Karachi)
- SHA-256: `DB2299C1E6F6C779D548A2CFC21833DF32B43353EFEF9324D1771288BF2686C6`
- Source commit: recorded by the source milestone commit following this manifest update.
- Delivery tag: `ump-can-request-ads-patch-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; Gradle-enabled, arm64-only, compressed native libraries, debug signing. The stable APK and Gradle output APK were written before the outer process timed out; exact orphaned Godot/Java processes were stopped, so a clean outer exit is not claimed.
- Native plugin: local Poing v5.0.0 patch; debug/release Ads AAR Gradle build PASS. APK DEX contains `boolean can_request_ads()` on `PoingGodotAdMobConsentInformation`.
- Package: `com.owais.majestygems`; min SDK 24; target/compile SDK 36; five DEX files; arm64-v8a only.
- Validation: Godot import/parse PASS; `ADMOB_INTEGRATION_TESTS`, `GAME_FLOW_REWARD_SPLASH_TESTS`, and `BRANDING_PUSH_LINE_TESTS` print PASS before their documented Windows post-PASS exits; packaged Google debug units/privacy URL, APK DEX patch, ABI, and v2 signature checks PASS.
- Device status: `adb devices -l` returned no device. Installation, launch, live UMP forms, live Google test ads, and physical lifecycle acceptance are not claimed.
- Report: `reports/POING_UMP_CAN_REQUEST_ADS_PATCH.md`.

## Single Splash Correction

- APK: `build/android/majestic-gems-single-splash-correction-debug.apk`
- Size: 53,368,728 bytes (50.90 MiB)
- Export timestamp: 2026-08-12T06:44:06.4725555+05:00 (Asia/Karachi)
- SHA-256: `65575E1B14AF81E88608CB07BDFAB37604B2D5B1B014F340BFC5F6D467351840`
- Source commit: `852538c8cc9fcb3e324f4eb2c8e3d60e33216ce4` (`fix: remove remaining second splash state`)
- Delivery tag: `single-splash-correction-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; exit 0; Gradle-enabled, arm64-only, compressed native libraries, debug signing.
- Package: `com.owais.majestygems`; versionCode `1`; versionName/application label `Majestic Gems`; minSdk `24`; target/compile SDK `36`.
- Validation: whole-project import/parse PASS with exit 0; focused flow/splash suite prints PASS before known Windows teardown; package/manifest, 926-entry payload, five DEX files, arm64-only runtime, forbidden-payload, removed-splash-payload, and APK Signature Scheme v2 checks PASS with one RSA-2048 signer.
- Splash: Android system splash only, using `assets/runtime/ui/majestic_gems_adaptive_foreground_v1.png` over the required opaque Majestic blue. Godot Android boot splash is disabled; Home has no timed startup state.
- Device status: ADB query timed out and its hung process was stopped. Physical installation and force-stopped cold launch are not claimed.
- Report: `reports/SINGLE_SPLASH_CORRECTION.md`.

## Splash and Reward UI Polish

- APK: `build/android/majestic-gems-splash-reward-ui-polish-debug.apk`
- Size: 53,369,788 bytes (50.90 MiB)
- Export timestamp: 2026-08-12T06:17:25.8474273+05:00 (Asia/Karachi)
- SHA-256: `1A500655BBCF5BC8AAE68F36983B46951C5C1C1C6449DBB8D759A7A826055827`
- Source commit: `c51cda96bf576a3a6bdaf3b04a4f9e8bf331e555` (`fix: unify startup and polish reward presentation`)
- Delivery tag: `splash-reward-ui-polish-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; Gradle-enabled, arm64-only, compressed native libraries, debug signing.
- Package: `com.owais.majestygems`; versionCode `1`; versionName/application label `Majestic Gems`; minSdk `24`; target/compile SDK `36`.
- Validation: whole-project import/parse PASS with exit 0; focused flow/splash/reward and AdMob suites print PASS before known Windows teardown behavior; package/manifest, 926-entry payload, five DEX files, arm64-only runtime, forbidden-payload, removed-splash-payload, and APK Signature Scheme v2 checks PASS with one RSA-2048 signer.
- Export-process note: the stable APK was fully written before the outer Godot/Gradle wrapper reached its known timeout; no Godot or Java export process remained afterward.
- Device status: ADB queries did not return within the validation window and the hung ADB process was stopped. Physical installation, force-stopped cold launch, crop/transition review, and Google-served ad playback are not claimed.
- Report: `reports/SPLASH_AND_REWARD_UI_POLISH.md`.

## Game Flow + Reward + Splash Polish

- APK: `build/android/majestic-gems-flow-reward-splash-polish-debug.apk`
- Size: 53,370,111 bytes (50.90 MiB)
- Export timestamp: 2026-08-12T04:41:43.6371289+05:00 (Asia/Karachi)
- SHA-256: `06A5C78AF3DE4A63BBE2107A074E0B0C22D363A0B129D7F8DD20D5B58C999265`
- Source commit: `48399b568449b53be3b4b4c0a4b47ac967bf057d` (`feat: streamline reward flow and polish startup`)
- Delivery tag: `game-flow-reward-splash-polish-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; Gradle-enabled, arm64-only, compressed native libraries, debug signing.
- Package: `com.owais.majestygems`; versionCode `1`; versionName/application label `Majestic Gems`; minSdk `24`; target/compile SDK `36`.
- Validation: editor import/parse PASS with exit 0; focused flow/reward/splash and AdMob suites print PASS before the known Windows teardown behavior; package/manifest, 928-entry payload, five DEX files, arm64-only runtime, forbidden-payload, and APK Signature Scheme v2 checks PASS with one RSA-2048 signer.
- AdMob: the existing application ID, permissions, plugin registrations, and Google debug interstitial/rewarded unit routing remain unchanged. Production unit placeholders remain blank.
- Export-process note: the stable APK was fully written before the outer Godot/Gradle wrapper exceeded the command timeout; the two identified orphaned export processes were stopped.
- Device status: `adb devices -l` returned an empty list. Physical install, native-to-custom cold-launch continuity, reward/ad playback, early-close/background-resume behavior, and on-device interstitial cadence are not claimed.
- Report: `reports/GAME_FLOW_REWARD_SPLASH_POLISH.md`.

## Post-AdMob Reward Flow and Size Fix

- APK: `build/android/majestic-gems-post-admob-fix-debug.apk`
- Size: 53,363,440 bytes (50.89 MiB)
- Export timestamp: 2026-08-11T22:56:17+05:00 (Asia/Karachi)
- SHA-256: `7EEF183F5F7CB068292BFB1B588CD8ED271B9873AC5466D3AD471FBBC3E7DBD4`
- Source commit: `e128be5` (`fix: resolve rewards before level transitions`)
- Delivery tag: `post-admob-reward-flow-and-size-fix`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; Gradle-enabled, arm64-only, compressed native libraries, debug signing.
- Package: `com.owais.majestygems`; versionCode `1`; versionName `Gem Aim`; minSdk `24`; target/compile SDK `36`.
- Size comparison: 108,146,729-byte regressed AdMob APK → 53,363,440-byte final APK; saved 54,783,289 bytes (50.66%). The immediate pre-AdMob APK was 42,831,666 bytes.
- Validation: editor import/parse PASS; focused AdMob/reward and branding/push-line suites print PASS before the known Windows teardown fault; clean main-scene smoke log; export exit 0; package/manifest/arm64-only/test-ID/forbidden-payload inspection PASS; APK Signature Scheme v2 PASS with one RSA-2048 signer.
- AdMob: application ID, Internet/network/AD_ID permissions, Poing interstitial/rewarded registrations, five DEX files, and both Google debug test unit IDs are present. AdMob sample/editor/C#/iOS/mock/docs/skills/media and optional ICU data are absent.
- Device status: `adb devices -l` returned an empty list. Physical installation, launch, Google test-ad rendering, background/resume, earned/early-close callbacks, and on-device cadence are not claimed.
- Report: `reports/POST_ADMOB_REWARD_FLOW_AND_SIZE_FIX.md`.

## AdMob Integration v1

- APK: `build/android/admob-integration-v1-debug.apk`
- Size: 108,146,729 bytes
- Export timestamp: 2026-08-11T11:40:40+05:00 (Asia/Karachi)
- SHA-256: `6BFD90E81F509881C651162B1FA8602200690871F2A564E24B7A06B98C4D4005`
- Baseline commit/tag: `7e700da68935e3c622ad980784ba875131866859` / `admob-integration-v1-baseline`
- Source commit/tag: `d62e5dbb5a9144d0209526bbc4c6b56e0ffd8fd3` / `admob-integration-v1-source`
- Delivery tag: `admob-integration-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; Gradle-enabled debug signing, not a store-release signing claim.
- Validation: headless editor import/full-project parse PASS with exit 0; `ADMOB_INTEGRATION_TESTS: PASS`; `BRANDING_PUSH_LINE_TESTS: PASS`; short main-scene smoke log contains no runtime/script errors; standalone APK exists; debug interstitial/rewarded test IDs are present in packaged `ad_config.gdc`; package `com.owais.majestygems`, arm64 Godot runtime, five DEX files, Internet/network/AD_ID permissions, configured AdMob application ID, and Poing interstitial/rewarded registrations are present; APK Signature Scheme v2 PASS with one RSA-2048 debug signer.
- Export-process note: the first sandboxed attempt was denied network access. The authorized Gradle retry produced the stable APK above, then its outer Godot/Gradle wrapper exceeded the 10-minute command timeout after artifact creation; the two orphaned build processes were stopped. Artifact hash, manifest, package, native runtime, and signature checks all pass.
- Runner note: both `-s` suites and the timed main-scene smoke reach their pass/clean log condition, then this Windows Godot 4.6.3 process exits during teardown with `0xC0000005`. No assertion or runtime script error precedes teardown; the editor parse exits 0.
- Device status: after restarting ADB, `adb devices -l` returned an empty list. Installation, Google-served test-ad rendering, physical rewarded completion/early-close, background/resume, and device interstitial cadence are not claimed.

## Majestic Gems Branding + Draggable Push Line v1

- APK: `build/android/majestic-gems-branding-push-line-v1.apk`
- Size: 42,831,666 bytes
- Export timestamp: 2026-08-11T04:26:13+05:00 (Asia/Karachi)
- SHA-256: `1E27A1E54DCDE2A782E9536CE18006EA37D90D763B7630982A4AF08D5F25072B`
- Baseline commit/tag: `33942b9` / `majestic-gems-branding-push-line-baseline`
- Source commit/tag: `95745b83a0d1509250b35823a24a88903ac07667` / `majestic-gems-branding-push-line-v1-source`
- Delivery tag: `majestic-gems-branding-push-line-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; validation signing, not a store-release keystore claim.
- Validation: headless import/editor parse PASS; clean focused `BRANDING_PUSH_LINE_TESTS: PASS`; production main-scene headless launch PASS; 260-entry APK contains manifest, 14 dex files, arm64 Godot runtime, legacy/adaptive icon resources, and zero forbidden source/report/test/tool/retired-asset paths; APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Size comparison: prior `gem-aim0.2.apk` was 60,517,648 bytes; this APK is 17,685,982 bytes smaller (29.22%).
- Historical-suite note: the pre-Optimize clean-contact/gameplay-feel runners were attempted but are incompatible with the current source/autoload layout and retired catalog constants; no pass is claimed from them.
- Device status: `adb devices -l` returned an empty list; installation, launcher mask appearance, Home logo appearance, touch behavior, and phone performance are not claimed.

## Transparent Purple Glass HUD v1

- APK: `build/android/transparent-purple-glass-hud-v1.apk`
- Size: 122,882,166 bytes
- Export timestamp: 2026-08-08T03:35:21Z (2026-08-08 08:35:21 Asia/Karachi)
- SHA-256: `6BE8A23787D9187D86E2A9BD66E0504C3FF30793037F2B3916D4007C82248966`
- Baseline commit/tag: `74322c0` / `transparent-purple-glass-hud-v1-baseline`
- Source commit/tag: `adab9e8813d8bc7b20b7e7023e2a4870e6b469e9` / `transparent-purple-glass-hud-v1-source`
- Delivery tag: `transparent-purple-glass-hud-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; validation signing, not a store-release keystore claim.
- Validation: all seven regression suites and motion profile PASS; six responsive resolutions plus notch/state Compatibility/ANGLE captures PASS; standalone APK exists; 415 APK entries with one manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths; APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: `adb devices -l` did not complete within the validation window; installation, launch, physical transparency/readability, safe-area/touch behavior, phone performance, listening, and haptics are not claimed.

## Professional Glass HUD v1

- APK: `build/android/professional-glass-hud-v1.apk`
- Size: 122,882,166 bytes
- Export timestamp: 2026-08-08T03:21:40Z (2026-08-08 08:21:40 Asia/Karachi)
- SHA-256: `92F5D1E85CF2710C44D6AAD0640987A65CD5E7560A33CFDAD024F61C5C60AF3D`
- Baseline commit/tag: `aaade4b` / `professional-glass-hud-v1-baseline`
- Source commit/tag: `7b0d18467a6a4bcf506b099d63bd04c36ae759b7` / `professional-glass-hud-v1-source`
- Delivery tag: `professional-glass-hud-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; validation signing, not a store-release keystore claim.
- Validation: all seven regression suites and motion profile PASS; six responsive resolutions plus notch/state Compatibility/ANGLE captures PASS; standalone APK exists; 415 APK entries with one manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths; APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: the final `adb devices -l` query did not complete within the validation window; no installation, launch, physical safe-area/touch behavior, phone performance, listening, or haptics are claimed.

## Purple Production HUD v1

- APK: `build/android/purple-production-hud-v1.apk`
- Size: 122,882,166 bytes
- Export timestamp: 2026-08-08T02:48:20Z (2026-08-08 07:48:20 Asia/Karachi)
- SHA-256: `1FA79BBF64743CA3BE0F60E3478809556531299823AAA6653DD1291DE1B6BDEF`
- Baseline commit/tag: `5b4002d` / `compact-target-hud-copy-v1`
- Source commit/tag: `2b626434cf7116c6f36bed7d12438650c564fae1` / `purple-production-hud-v1-source`
- Delivery tag: `purple-production-hud-v1`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; validation signing, not a store-release keystore claim.
- Validation: all seven regression suites and motion profile PASS; six responsive resolutions plus notch/state Compatibility/ANGLE captures PASS; standalone APK exists; 415 APK entries with one manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths; APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; installation, launch, physical safe-area/touch behavior, phone performance, listening, and haptics are not claimed.

## Production Gameplay UI Finalization V2

- APK: `build/android/production-gameplay-ui-v2.apk`
- Size: 122,882,166 bytes
- Export timestamp: 2026-08-05T05:33:17Z (2026-08-05 10:33:17 Asia/Karachi)
- SHA-256: `3326C2714ED0B29551D3FD209B6B643A95BE4C0B156C4B2D93A5B3F26AC7FCE1`
- Baseline commit/tag: `39f1082112cee3d2d9d948a9d0ac9c110d163daf` / `production-gameplay-ui-v2-baseline`
- Source commit/tag: `48ed83f6ce2377c30c886ef3448c941d7d6d00fc` / `production-gameplay-ui-v2-source`
- Delivery tag: `production-gameplay-ui-v2`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`; validation signing, not a store-release keystore claim.
- Validation: all seven regression suites and motion profile PASS; deterministic ANGLE screenshots/walkthrough PASS; standalone APK exists; 415 APK entries with one manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths; APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; installation, launch, physical safe-area/touch behavior, phone performance, listening, and haptics are not claimed.

## Production Foundation v1

- APK: `build/android/production-foundation-v1.apk`
- Size: 122,878,070 bytes
- Export timestamp: 2026-08-05T04:37:36Z (2026-08-05 09:37:36 Asia/Karachi)
- SHA-256: `F93ADAF33DDA308D3B7F9FFE3E9210D7601B75ECEA77971EA260C8A9632ED1FD`
- Source commit/tag: `8fe30ea652b2ac49c3369fcc9013df64dcaf1692` / `production-foundation-v1-source`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`
- Validation: parser/import PASS; eight regression/profile routes PASS; standalone APK exists; 415 APK entries with zero packaged source/report/build paths; 24 generated launcher-icon entries; APK Signature Scheme v2/v3 PASS with one signer.
- Device status: `adb devices -l` returned no connected device; installation, phone UI, launcher icon display, boot splash display, listening, and haptics are not claimed.

## Production UI motion + Restart restoration v1

- APK: `build/android/production-ui-motion-v1.apk`
- Size: 118,277,818 bytes
- Export timestamp: 2026-08-05T01:24:34Z (2026-08-05 Asia/Karachi)
- SHA-256: `5C8A938AF7815DB48DE7DC499D80D3F650F7FD1B35DBEC953E33490CC97DB947`
- Source commit/tag: `a1b214d` / `production-ui-motion-v1-source`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`
- Validation: parser/import PASS; all seven regression suites PASS; Home copy/motion and Restart visibility regressions PASS; real 720 x 1600 Compatibility/ANGLE captures reviewed; export signed; 411 APK entries with zero packaged source/report/build paths.
- Device status: ADB reported no connected device; physical-device validation is not claimed.

## Asset-matched Home + transparent logo v1

- APK: `build/android/assets-ui-screen-match-v1.apk`
- Size: 118,277,818 bytes
- Export timestamp: 2026-08-04T23:22:27Z (2026-08-05 Asia/Karachi)
- SHA-256: `7AAB0C4A93F29DC6B40B44D511BDC3A2DB40AC04C4456E6342791F932319824F`
- Source commit/tag: `84d855a` / `assets-ui-screen-match-v1-source`
- Export preset/method: `Android`; Godot 4.6.3 headless `--export-debug`
- Validation: all seven regression suites PASS; production UI safe-area suite PASS; real 720 x 1600 Compatibility/ANGLE capture PASS and reviewed; export signed successfully; 411 APK entries with zero packaged source/report/build paths.
- Device status: ADB reported no connected device; physical-device validation is not claimed.

# Branded Production Screen Flow v1

- File: `production-screen-flow-v1.apk`
- Path: `D:\Owais\game\build\android\production-screen-flow-v1.apk`
- Size: `116,811,201` bytes
- Modified: `2026-08-05 03:48:13 +05:00` (`2026-08-04T22:48:13Z`)
- SHA-256: `104DE160B3B4C14432DFB89C9C657D921F2C0D2C15B4F9D5348EBDA6B9DE3972`
- Gameplay source commit/tag: `fea8710fd9e16a8c79f95d0cf12727731ef75d16` / `production-screen-flow-v1-source`.
- Clean export source commit/tag: `de96c7f45684414a4e98c87c6500f8dd5c82accb` / `production-screen-flow-v1-export-source`.
- Delivery tag: `production-screen-flow-v1`.
- Export: Godot 4.6.3 `Android` debug preset; validation signing, not a store-release keystore claim.
- Validation: all seven suites and four reviewed 720 x 1600 Compatibility/ANGLE renders passed. APK has 409 ZIP entries; `build/`, `reports/`, `tools/`, Python, and PowerShell entries are absent. APK Signature Scheme v2/v3 verification passed with one signer.
- Device status: `adb devices` returned an empty list; installation, launch, touch navigation, physical safe areas, persistence, phone feel, listening, and haptics are not claimed.


# Infinite Randomized Eight-Gem Levels v1

- File: `infinite-random-levels-v1.apk`
- Path: `D:\Owais\game\build\android\infinite-random-levels-v1.apk`
- Size: `114,869,209` bytes
- Modified: `2026-08-05 01:41:12 +05:00` (`2026-08-04T20:41:12Z`)
- SHA-256: `E60C83AB649F7F184285770555485F858ACFE03A643ECF1C1D0EF756DB381FBC`
- Gameplay source commit/tag: `2754502f2481239535427df29b9335988a15200d` / `infinite-random-levels-v1-source`.
- Clean export source commit/tag: `436b3a4d40b62223fee2517886f3d1c47bf1796e` / `infinite-random-levels-v1-export-source`.
- Delivery tag: `infinite-random-levels-v1`.
- Export: Godot 4.6.3 `Android` debug preset; validation signing, not a store-release keystore claim.
- Validation: all seven suites passed, including 200 generated levels. APK has 405 ZIP entries; `build/`, `reports/`, `tools/`, Python, and PowerShell entries are absent. APK Signature Scheme v2/v3 verification passed with one signer.
- Device status: `adb devices` returned an empty list; installation, launch, touch navigation, persistence across process restarts, background composition, phone feel, listening, and haptics are not claimed.


# New Background Music v1

- File: `new-background-music-v1.apk`
- Path: `D:\Owais\game\build\android\new-background-music-v1.apk`
- Size: `109,063,713` bytes
- Modified: `2026-08-05 00:09:11 +05:00` (`2026-08-04T19:09:11Z`)
- SHA-256: `615AAA1A67040EDCE68BAA45FF01740A3C85E0EFFDFFF3D486935E3064CD3BF8`
- Gameplay source commit/tag: `25f83f74b23a1fa19bc121a950b834f7d8bcdc4c` / `new-background-music-v1-source`.
- Clean export source commit/tag: `1a4a026bccb95c004dfbc13167428fa9c1c90a87` / `new-background-music-v1-export-source`.
- Delivery tag: `new-background-music-v1`.
- Export: Godot 4.6.3 `Android` debug preset; installable validation signing, not a store-release keystore claim.
- Validation: all six regression/profile suites passed. APK has 391 ZIP entries; `build/`, `reports/`, `tools/`, Python, and PowerShell entries are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices` returned an empty device list; installation, launch, phone feel, listening, and haptics are not claimed.


# Reference Scale Contrast v1

- File: `reference-scale-contrast-v1.apk`
- Path: `D:\Owais\game\build\android\reference-scale-contrast-v1.apk`
- Size: `104,471,551` bytes
- Modified: `2026-08-04 22:53:04 +05:00` (`2026-08-04T17:53:04Z`)
- SHA-256: `61CDB16C4CDB8654108E540ACA3526AE743683A3D8D3630996ADFC0BC09AD9AF`
- Gameplay source commit/tag: `0f410a56f8396a22fedaa108dc07dde8f44ae2f7` / `reference-scale-contrast-v1-source`.
- Clean export source commit/tag: `3886dbff6479bfd1bdea5408e9b79a49ab38d766` / `reference-scale-contrast-v1-export-source`.
- Delivery tag: `reference-scale-contrast-v1`.
- Export: Godot 4.6.3 `Android` debug preset; installable validation signing, not a store-release keystore claim.
- Validation: all six regression/profile suites and two reviewed 720 x 1600 Compatibility/ANGLE proof frames passed. APK has 387 ZIP entries with manifest, primary dex, and arm64 Godot runtime; `build/`, `reports/`, `tools/`, and `assets/generated/` entries are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned an empty device list; installation, launch, phone feel, listening, and haptics are not claimed.


# Merge Animation Revert + L1-L8 Size Calibration v1

- File: `merge-animation-size-calibration-v1.apk`
- Path: `D:\Owais\game\build\android\merge-animation-size-calibration-v1.apk`
- Size: `104,471,551` bytes
- Modified: `2026-08-04 21:04:55 +05:00` (`2026-08-04T16:04:55Z`)
- SHA-256: `93B8FD867E9389CAC584007EE22523B05F5211A953E01E7AA29D7C3408D41565`
- Gameplay source commit/tag: `c5487a5d` / `merge-animation-size-calibration-v1-source`.
- Clean export source commit/tag: `5d5e7867d4e465a75dbead63c5aefdef584f4e17` / `merge-animation-size-calibration-v1-export-source`.
- Delivery tag: `merge-animation-size-calibration-v1`.
- Export: Godot 4.6.3 `Android` debug preset; installable validation signing, not a store-release keystore claim.
- Validation: all six regression/profile suites passed. APK has 387 ZIP entries with manifest, primary dex, and arm64 Godot runtime; `build/`, `reports/`, `tools/`, and `assets/generated/` entries are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned an empty device list; installation, launch, phone feel, listening, and haptics are not claimed.


# Reference Animation + Supplied Audio Polish v4

- File: `reference-animation-audio-polish-v4.apk`
- Path: `D:\Owais\game\build\android\reference-animation-audio-polish-v4.apk`
- Size: `104,471,551` bytes
- Modified: `2026-08-04 14:16:35 +05:00` (`2026-08-04T09:16:35Z`)
- SHA-256: `8300A29ECCEA586DF4A681306AB68D8E87FF1A5F2695583892B791C4982F6F7F`
- Gameplay source commit/tag: `2aa255ea14dcf1349d339916539e953f82bc8268` / `reference-animation-audio-polish-v4-source`.
- Clean export source commit/tag: `038fa786c11a25c7fe3122cd1d87306d8b1c3b08` / `reference-animation-audio-polish-v4-export-source`.
- Delivery tag: `reference-animation-audio-polish-v4`.
- Export: Godot 4.6.3 `Android` debug preset from the clean export-source milestone; installable validation signing, not a store-release keystore claim.
- Validation: all six regression/profile suites passed; six 720 x 1600 Compatibility/ANGLE animation frames passed and were reviewed. APK has 387 ZIP entries with manifest, primary dex, and arm64 Godot runtime; `build/`, `reports/`, `tools/`, and `assets/generated/` entries are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Packaging audit: a 148,942,401-byte intermediate was rejected and replaced after temporary frame-analysis files were detected. `export_presets.cfg` now excludes `build/*`; the hash above belongs only to the clean 104,471,551-byte replacement.
- Device status: `adb devices -l` returned an empty device list after starting the local daemon; install, launch, phone performance, listening balance, loop-seam quality, and haptics were not tested.


# Reference Target Reward Correction v3

- File: `reference-target-reward-correction-v3.apk`
- Path: `D:\Owais\game\build\android\reference-target-reward-correction-v3.apk`
- Size: `102,848,585` bytes
- Modified: `2026-08-04 11:45:35 +05:00`
- SHA-256: `7BEDDD928F29CAD89E05CDB410EFF6203E8DC6612D265614E84D4FBD440A4B7D`
- Source commit: `77daaa0c69de40140f546217f004d37abc556473` (`fix: make coin rewards target-only`)
- Source tag: `reference-target-reward-correction-v3-source`
- Delivery tag: `reference-target-reward-correction-v3`
- Export: Godot 4.6.3 `Android` debug preset from the clean source milestone; installable validation signing, not a store-release keystore claim.
- Validation: `GAMEPLAY_UI_FEEL_TESTS`, `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, `PRODUCTION_UI_FINALIZATION_TESTS`, and `MOTION_PROFILE` passed. Four 720 x 1600 Compatibility/ANGLE captures were reviewed, including zero ordinary-merge coin records and exactly four active-target records. Standalone APK exists; ZIP has 379 entries with manifest, primary dex, and arm64 Godot runtime; `reports/`, `tools/`, and `assets/generated/` are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; install, launch, phone performance, audio listening, and haptics were not tested.

# Reference Audio + Reward Layering v2

- File: `reference-audio-layering-v2.apk`
- Path: `D:\Owais\game\build\android\reference-audio-layering-v2.apk`
- Size: `102,852,681` bytes
- Modified: `2026-08-04 10:36:38 +05:00`
- SHA-256: `2876EE74B74E2A011C8572A381F1BB45DABB58C92F0F98DE90D2F214CDE44DDC`
- Source commit: `7a619981ff5bc8a572b11c62d19dd0362a00ec5f` (`Finalize reference audio and reward layering v2`)
- Source tag: `reference-audio-layering-v2-source`
- Delivery tag: `reference-audio-layering-v2`
- Export: Godot 4.6.3 `Android` debug preset from the clean source milestone; installable validation signing, not a store-release keystore claim.
- Validation: `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GAMEPLAY_UI_FEEL_TESTS`, `GEM18_CHAIN_TESTS`, `PRODUCTION_UI_FINALIZATION_TESTS`, and `MOTION_PROFILE` passed. Four 720×1600 Compatibility/ANGLE captures were reviewed. Standalone APK exists; ZIP has 379 entries with manifest, primary dex, and arm64 Godot runtime; `reports/`, `tools/`, and `assets/generated/` are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; install, launch, phone performance, continuous-loop listening, gem-sound balance, and haptics were not tested.

# Reference Feedback Match v1

- File: `reference-feedback-match-v1.apk`
- Path: `D:\Owais\game\build\android\reference-feedback-match-v1.apk`
- Size: `102,827,861` bytes
- Modified: `2026-08-04 09:21:28 +05:00`
- SHA-256: `16A44ECD5FA4F796E7DD0604DB25FD411F4CDE6D7951BC35B5C925D42C9B1995`
- Source commit: `1c1478e7ab07c86d6e2083e71bdaada0135818d2` (`fix: match reference feedback and audio`)
- Source tag: `reference-feedback-match-v1-source`
- Delivery tag: `reference-feedback-match-v1`
- Export: Godot 4.6.3 `Android` debug preset from the clean source milestone; installable validation signing, not a store-release keystore claim.
- Validation: `GAMEPLAY_UI_FEEL_TESTS`, `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, `PRODUCTION_UI_FINALIZATION_TESTS`, and `MOTION_PROFILE` passed. Four real 720 x 1600 Compatibility/ANGLE captures were reviewed. Standalone APK exists; ZIP has 377 entries with manifest, primary dex, and arm64 Godot runtime; `reports/`, `tools/`, and `assets/generated/` are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; install, launch, phone performance, reference-volume listening, and haptics were not tested.

# Production Gameplay Parity Final v1

- File: `production-gameplay-parity-final-v1.apk`
- Path: `D:\Owais\game\build\android\production-gameplay-parity-final-v1.apk`
- Size: `102,674,715` bytes
- Modified: `2026-08-04 07:50:41 +05:00`
- SHA-256: `132FA633E3208C707D2BA8EF80D5F41A119A061F9608EC0A5C0BC68A06F36E78`
- Source commit: `2f2dbafa96bcb13e423bc8a49e2cbb0306beb2d3` (`feat: finalize production gameplay parity`)
- Source tag: `production-gameplay-parity-final-v1-source`
- Delivery tag: `production-gameplay-parity-final-v1`
- Export: Godot 4.6.3 `Android` debug preset from the clean source milestone.
- Validation: parse/import passed; `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GAMEPLAY_UI_FEEL_TESTS`, `GEM18_CHAIN_TESTS`, `PRODUCTION_UI_FINALIZATION_TESTS`, and `MOTION_PROFILE` passed. Four real 720 x 1600 Compatibility/ANGLE captures were reviewed. Standalone APK exists; ZIP has 363 entries with manifest, primary dex, and arm64 Godot runtime; `reports/` and `tools/` are absent. APK Signature Scheme v2/v3 verification passed with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device; install, launch, phone performance, audio balance, and haptics were not tested.

## Reference Gameplay + Coin Parity v1

- File: `reference-gameplay-coin-parity-v1.apk`
- Path: `D:\Owais\game\build\android\reference-gameplay-coin-parity-v1.apk`
- Size: `100,806,453 bytes`
- Modified: `2026-08-03 23:11:13 +05:00`
- SHA-256: `CED1D7496791BBDEE3E01C85EF1D2D397A98998785A438B1C3B1613E1CE29A94`
- Package: `com.owais.majestygems`; versionCode `1`; versionName `1.0.0`; minSdk `24`; targetSdk `36`.
- Exact gameplay source commit: `b9f15935174f8e52663fcf4c088cac92e0a35bc4` (`feat: add reference-paced coin reward animations`); delivery tag: `reference-gameplay-coin-parity-v1`.
- Export: one fresh Godot 4.6.3 `--export-debug Android`; this is an installable debug-signed validation build, not a store-release signing claim.
- Validation: 359 ZIP entries; `AndroidManifest.xml`, primary dex, and arm64 Godot runtime present; zero `reports/` or `tools/` entries. `apksigner` verifies v2/v3 signatures with one RSA-2048 signer. All six regression/profile suites passed and four 720 x 1600 production ANGLE captures were reviewed.
- Device status: `adb devices -l` returned no connected devices. No install, on-device launch, frame-rate, listening, or haptic result is claimed.

## Physics + Reward Feedback v1

- File: `physics-reward-feedback-v1.apk`
- Path: `D:\Owais\game\build\android\physics-reward-feedback-v1.apk`
- Size: `100,793,853 bytes`
- Modified: `2026-08-03 13:42:55 +05:00`
- SHA-256: `AE1189E5E8AC21EA95497182F90F05B4F81383573222A74886BAD13453861594`
- Package: `com.owais.majestygems`; versionCode `1`; versionName `1.0.0`; minSdk `24`; targetSdk `36`.
- Exact gameplay source commit: `4cde848` (`feat: enliven physics and high-tier rewards`); delivery tag: `physics-reward-feedback-v1`.
- Export: fresh Godot 4.6.3 `--export-debug Android`; this is an installable signed validation build, not a store-release signing claim.
- Validation: 355 ZIP entries; manifest, primary dex, and arm64 Godot runtime present; zero `reports/` or `tools/` entries. `apksigner` verifies v2/v3 signatures with one RSA-2048 signer. Contact, gameplay-feel, Level 1, 18-gem, production UI, and motion-profile suites passed; three ANGLE major-reward captures passed.
- Device status: `adb` is not installed or discoverable in this environment. No installation, physical-device performance, listening, or haptic result is claimed.

## Production UI Polish v4

- File: `production-ui-finalization-v1.apk` (freshly replaced at the user-requested canonical delivery path)
- Path: `D:\Owais\game\build\android\production-ui-finalization-v1.apk`
- Size: `100,789,757 bytes`
- Modified: `2026-08-01 10:45:31 +05:00`
- SHA-256: `B771310C4A1B829AD6AC740663353A61C3EF68AFAD34FDDDD70DD063C00E0266`
- Package: `com.owais.majestygems`; versionCode `1`; versionName `1.0.0`; minSdk `24`; targetSdk `36`.
- Exact source commit: `8bbc4b2ae7f3259defd740e033e053d46dd8a9df` (`feat: finalize production gameplay UI`); delivery tag: `production-ui-polish-v4`.
- Export: fresh Godot 4.6.3 `--export-debug Android`; this is an installable signed validation build, not a store-release signing claim.
- Validation: 355 ZIP entries; manifest, primary dex, and arm64 Godot runtime present; zero `reports/` or `tools/` entries. `apksigner` verifies v2/v3 signatures with one RSA-2048 signer.
- Runtime/UI validation: all six regression/profile suites passed; 36 exact-resolution/state ANGLE captures passed, including 1000 x 1280 wide centering.

## Production UI Simplification v3

- File: `production-ui-simplification-v3.apk`
- Path: `D:\Owais\game\build\android\production-ui-simplification-v3.apk`
- Size: `100,789,757 bytes`
- Modified: `2026-08-01 08:45:42 +05:00` (`2026-08-01T03:45:42Z`)
- SHA-256: `EE39C5935AD6CF992C4BEFEA577B1F5095CD841CDA205B7A1BD4AB3EE2BC710E`
- Exact UI source commit: `126585365fd7a5c5b8bfc4f1590964ddc1b3aedd` (`feat: simplify HUD and show full merge path`); delivery tag: `production-ui-simplification-v3`.
- Export: fresh signed Godot 4.6.3 debug APK; no store-release keystore is configured or claimed.
- Validation: 355 ZIP entries; manifest/dex/arm64 Godot runtime present; zero `reports/`/`tools/` entries; v2/v3 signatures with one RSA-2048 signer. All six regression/profile suites and the 35-image ANGLE capture pass.
- Device status: `adb devices -l` returned an empty device list; no installation or physical-device result is claimed.

## Production UI Finalization v2

- File: `production-ui-finalization-v2.apk`
- Path: `D:\Owais\game\build\android\production-ui-finalization-v2.apk`
- Size: `100,793,853 bytes`
- Modified: `2026-08-01 07:44:38 +05:00` (`2026-08-01T02:44:38Z`)
- SHA-256: `53CEF1A789A91956B80CF8EB627BCE066899C1445919104A366D162F23E61A38`
- Exact UI source commit: `baae6488874174811207437d2b84f5daa6b148fa` (`fix: correct production HUD visual composition`); delivery tag: `production-ui-finalization-v2`.
- Export: fresh Godot 4.6.3 `--export-debug Android`; the unconfigured release-keystore check correctly prevented a release-signed export. This is the same installable signed validation format used by the prior milestone, not a store-release signing claim.
- Validation: 355 ZIP entries; manifest/dex/arm64 Godot runtime present; zero `reports/`/`tools/` entries; v2/v3 signatures with one RSA-2048 signer. All six test/profile suites and the 35-image ANGLE capture pass.
- Device status: `adb devices -l` returned an empty device list. No installation or physical-device result is claimed.

## Production UI Finalization v1

- File: `production-ui-finalization-v1.apk`
- Path: `D:\Owais\game\build\android\production-ui-finalization-v1.apk`
- Size: `100,789,757 bytes`
- Modified: `2026-08-01 05:34:59 +05:00` (`2026-08-01T00:34:59Z`)
- SHA-256: `32737D83797840B2145913CADBD54EE1CC7A4004B3FD752BB3D16C88E3DC57E8`
- Exact gameplay/UI source commit: `a861fecb8e7b344b4dabe63894e2ae10e2c2fc63` (`feat: finalize production gameplay UI`); delivery tag: `production-ui-finalization-v1`.
- Validation: Godot 4.6.3 parse/import and real ANGLE capture passed; `PRODUCTION_UI_FINALIZATION_TESTS`, `GAMEPLAY_UI_FEEL_TESTS`, `LEVEL_1_FLOW_TESTS`, `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE` passed. The APK has 355 ZIP entries with manifest/dex/arm64 runtime present, zero `reports/` or `tools/` entries, and valid v2/v3 signatures.
- Device status: `adb devices -l` returned an empty device list. No install or physical-device launch/performance/haptic result is claimed.

## Gameplay UI, Animation, Reward Feel, and Pause/Settings Finalization v1

- File: `gameplay-ui-feel-finalization-v1.apk`
- Path: `D:\Owais\game\build\android\gameplay-ui-feel-finalization-v1.apk`
- Size: `100,772,764 bytes`
- Modified: `2026-07-31 13:42:12 +05:00` (`2026-07-31T08:42:12Z`)
- SHA-256: `420684CA1D975A434D421EF129FAB195E98FA511C6C2207CA71D64DD7A374090`
- Exact gameplay source commit: `42c7b38085aa70bd422f35637b76758507acc7e9` (`feat: finalize gameplay UI and reward feel`); delivery tag: `gameplay-ui-feel-finalization-v1`.
- Validation: Godot 4.6.3 parse/import passed; `GAMEPLAY_UI_FEEL_TESTS`, `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE` passed; ANGLE evidence capture passed. APK has 349 ZIP entries with manifest/dex/resources/arm64 Godot runtime present and zero `reports/` or `tools/` entries; `apksigner` verifies valid v2/v3 signatures.
- Device status: `adb devices -l` did not return within the validation window. No install, device launch, listening/haptic check, or phone performance result is claimed.

## Video-Verified Unlimited Launcher + HUD v1

- File: `video-verified-unlimited-launcher-hud-v1.apk`
- Path: `D:\Owais\game\build\android\video-verified-unlimited-launcher-hud-v1.apk`
- Size: `102,335,924 bytes`
- Modified: `2026-07-31 09:38:41 +05:00`
- SHA-256: `F171F69976E0B13A8FB82E4329689553BD01C823913C731315FD056DD695782C`
- Source baseline: `bfbd201` / `unlimited-launcher-runtime-proof-v1`; delivery tag: `video-verified-unlimited-launcher-hud-v1`.
- Validation: video evidence review; Godot 4.6.3 parse/import; `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE` passed; local HUD render reviewed. APK is nonzero and contains `AndroidManifest.xml`, `classes.dex`, and arm64 Godot native code.
- Device status: ADB query did not complete; no installation or on-device launch is claimed.

## Unlimited Launcher Runtime Proof v1

- File: `unlimited-launcher-runtime-proof-v1.apk`
- Path: `D:\Owais\game\build\android\unlimited-launcher-runtime-proof-v1.apk`
- Size: `102,335,924 bytes`
- Modified: `2026-07-31 08:39:07 +05:00`
- SHA-256: `FFD9F81B34ECE39C083469A71C1B3A9B421F52DAF73EC2C8E7EA762F2A6C4F46`
- Source baseline: `8a7bc72` / `unlimited-launcher-hud-final-repair-v1`; delivery tag: `unlimited-launcher-runtime-proof-v1`.
- Validation: Godot 4.6.3 headless parse/import; `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE` passed. The fresh APK is nonzero and contains `AndroidManifest.xml`, `classes.dex`, and arm64 Godot native code.
- Device status: no installation or launch attempted in this repair session.

## Unlimited Launcher + HUD Final Repair v1

- File: `unlimited-launcher-hud-final-repair-v1.apk`
- Path: `D:\Owais\game\build\android\unlimited-launcher-hud-final-repair-v1.apk`
- Size: `102,331,828 bytes`
- Modified: `2026-07-31 08:23:44 +05:00`
- SHA-256: `ED0215913CA8C4FB5B724EE395C3EC2466BBD0451FADDA3EF49192AC9E6BA83C`
- Source baseline: `e530cbb` / `portrait-bottom-table-hud-repair-v1`; delivery tag: `unlimited-launcher-hud-final-repair-v1`.
- Validation: Godot 4.6.3 headless import/parse; `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE` passed. The fresh APK is nonzero and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no installation or launch attempted in this repair session.

## Portrait Bottom Table + HUD Repair v1

- File: `portrait-bottom-table-hud-repair-v1.apk`
- Path: `D:\Owais\game\build\android\portrait-bottom-table-hud-repair-v1.apk`
- Size: `101,532,853 bytes`
- Modified: `2026-07-31 08:03:43 +05:00`
- SHA-256: `D74BEBEAF5B86CA625A7390564DE139174F4E70169B063BC3226539CE20B8371`
- Source baseline: `6f7c3ba` / `reference-accurate-hud-unlimited-level1-v1`; delivery tag: `portrait-bottom-table-hud-repair-v1`.
- Validation: Godot 4.6.3 headless import/parse; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. The fresh APK is nonzero and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no installation or launch attempted in this repair session.

## Reference-Accurate HUD + Unlimited Level 1 v1

- File: `reference-accurate-hud-unlimited-level1-v1.apk`
- Path: `D:\Owais\game\build\android\reference-accurate-hud-unlimited-level1-v1.apk`
- Size: `100,754,358 bytes`
- Modified: `2026-07-31 07:33:18 +05:00`
- SHA-256: `DB6298720500B43D70A8F80260C6AB4D9CCED4A6BE5973F4963379F58F503CA7`
- Source baseline: `aebf1fb` / `reference-hud-unlimited-v1`; delivery tag: `reference-accurate-hud-unlimited-level1-v1`.
- Validation: Godot 4.6.3 headless import/parse; `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. The fresh APK is nonzero and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: `adb devices -l` did not complete in this environment; installation and launch were not attempted.

## Gameplay HUD + Sequential Targets v1

- File: `gameplay-hud-sequential-targets-v1.apk`
- Path: `build/android/gameplay-hud-sequential-targets-v1.apk`
- Size: `100,750,262 bytes`
- Modified: `2026-07-30 14:11:00 +05:00`
- SHA-256: `EDC72A77D57289443AC2B45935B4A39DB453C7B2E2A167669FAAA59B7F948D46`
- Baseline: `d0c0e33558068f8c81307a32a0432d8dd766d23b`; device not connected.

## Restored Working Table Rails v1

- File: `restored-working-table-rails-v1.apk`
- Path: `D:\Owais\game\build\android\restored-working-table-rails-v1.apk`
- Size: `100,750,262 bytes`
- Modified: `2026-07-30 13:37:45 +05:00`
- SHA-256: `96A6BD76DDC1574208B74730E8F857A12AB729A77437B6CADABF8ED951C8948A`
- Historical source restored: `0b562d5b85b0b4d0330ecd10da3f832408949ad9` (`new-table-shadow-contact-fix-v1`); delivery tag: `restored-working-table-rails-v1`.
- Validation: Godot 4.6.3 parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK structure was verified.
- Device status: no phone connected; not installed or launched on-device.

## Physical Rails Match Table v1

- File: `physical-rails-match-table-v1.apk`
- Path: `D:\Owais\game\build\android\physical-rails-match-table-v1.apk`
- Size: `99,938,473 bytes`
- Modified: `2026-07-30 13:09:53 +05:00`
- SHA-256: `3B22B7DB5ADCA350FEA4D69CAD7E910407297B8AD8361C18BDCC541E4075B1D5`
- Source commit: `4e8d34f3e8ee9d94534810b557e4c6404c32c25f` (`fix: align physical rails with table artwork`).
- Tag: `physical-rails-match-table-v1`.
- Validation: Godot 4.6.3 headless regression suite and motion profile passed; APK ZIP structure verified.
- Device status: no phone connected; not installed or launched on-device.

## Matched Perspective Physics Scale v1

- File: `matched-perspective-physics-scale-v1.apk`
- Path: `D:\Owais\game\build\android\matched-perspective-physics-scale-v1.apk`
- Size: `99,208,435` bytes
- Modified: `2026-07-30 12:26:21 +05:00`
- SHA-256: `FD9FCF41EE8580F63D1DD8887FFB29FDFF769B0C8E71F47B0A7AA139B2087C23`
- Baseline: `97b6bc355172c3f1df394a85b9bc63f6fb376290` / `pre-shared-perspective-restored-v1`.
- Source commit: `25fac1fa0ae9e8939b7daa618cb02df12054eb83` (`fix: match perspective scaling with gem physics`).
- Tag: `matched-perspective-physics-scale-v1`.
- Validation: Godot 4.6.3 parse/import, `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK ZIP validation found `AndroidManifest.xml` and `classes.dex`.
- Device status: no device connected; no install or launch attempted.

## Pre-Shared-Perspective Restored v1

- File: `pre-shared-perspective-restored.apk`
- Path: `D:\Owais\game\build\android\pre-shared-perspective-restored.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 12:03:14 +05:00`
- SHA-256: `56EE18332CCFC0D96CE6D5E895D97558A3143F5FDDF77F9B0C2F665B8921CE6C`
- Restored source: exact pre-task tree at `70733c0`; rollback commit `97b6bc355172c3f1df394a85b9bc63f6fb376290` reverts `2c7114c`.
- Tag: `pre-shared-perspective-restored-v1`
- Validation: Godot 4.6.3 headless parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK is non-empty and ZIP validation found `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so`.
- Device status: no connected device; installation and launch are not claimed.

## Level 1 Balance v1

- File: `level-1-balance-v1.apk`
- Path: `D:\Owais\game\build\android\level-1-balance-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 09:48:03 +05:00`
- SHA-256: `72883265B690232655C6D62581D4CE3722F8F79007AAF831F83B20E4C576375A`
- Source baseline: `4ad1d51e09e0efce75d6842b0310880095ad349c` (`level-1-flow-v1`)
- Tag: `level-1-balance-v1`
- Validation: Godot 4.6.3 parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected device; installation and device timing are not claimed.

## 18-Gem Order v1

- File: `18-gem-order-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-order-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:43:05 +05:00`
- SHA-256: `95E2279F9BE8DD762FCE196A86D0B6301CDE9001711E3B5AF2E25747AAF62752`
- Source commit: `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194` (`chore: finalize 18-gem progression order`)
- Baseline tag: `18-gem-size-collision-fix-v1`
- Validation: Godot 4.6.3 headless import/parse; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`; APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected Android device; no install or launch claimed.

## 18-Gem Size & Collision Fix v1

- File: `18-gem-size-collision-fix-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-size-collision-fix-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:30:36 +05:00`
- SHA-256: `391A97C53874B783AE00A835F3A3C07EB6D75340686556B18E3B8C42999F7D8D`
- Source commit: `fc71e2dad781134948d1962dfe2a49ad0b6521fe` (`fix: calibrate 18-gem sizes and collisions`)
- Tag: `18-gem-size-collision-fix-v1`
- Validation: Godot 4.6.3 import/parse validation; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`; APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected Android device; no install or launch claimed.

## 18-Gem Motion Smoothness Fix v1 — export blocked

- Requested file: `build/android/18-gem-motion-smoothness-fix-v1.apk`.
- Source commit: the commit tagged `18-gem-motion-smoothness-fix-v1` (`fix: restore smooth motion for 18-gem build`).
- Validation: Godot 4.6.3 import/parse validation; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`.
- Export status: delivered as a fresh standalone debug APK using Godot's Android debug-signing path. The previous block was not a filename issue: release export reached signing but had no release keystore, and the earlier session lacked write access to the project cache/output.
- File: `18-gem-motion-smoothness-fix-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-motion-smoothness-fix-v1.apk`
- Size: `97,688,126` bytes
- Modified: `2026-07-30 05:35:02 +05:00`
- SHA-256: `E63CEE8EAA1AC1A6B3954EC2E94238EC76CE744ACEBDB3105B56CD9261518765`
- Source commit: `6953b4095b8924096a7d71445771cecbc893e30d`
- Source tag: `18-gem-motion-smoothness-fix-v1` (unchanged)
- Godot: `4.6.3.stable.official.7d41c59c4`
- Export preset/method: `Android`; `Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --export-debug Android build/android/18-gem-motion-smoothness-fix-v1.apk`
- Package validation: APK ZIP contains `AndroidManifest.xml`, `classes.dex`, and packaged project assets. No Android phone was connected, so device installation and launch are not claimed.

## 18-Gem Chain v1

- File: `18-gem-chain-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-chain-v1.apk`
- Size: 106,113,431 bytes
- Modified: 2026-07-30 04:37:06 +05:00
- SHA-256: `177E5F12A1E951DE32092801EA91B0354BD1969A1E9C69D30EFB1263AC05200F`
- Source commit: `13d9f24bf88e86ff0b887251e3964c29bd23eec4` (`feat: add isolated 18-gem merge chain`)
- Tag: `18-gem-chain-v1`
- Validation: Godot 4.6.3 parse/import validation, `CLEAN_CONTACT_TESTS: PASS`, and `GEM18_CHAIN_TESTS: PASS`.
- Device status: no device connected; no install or launch claimed.
## New Table Shadow Contact Fix v1

- File: `new-table-shadow-contact-fix-v1.apk`
- Path: `D:\Owais\game\build\android\new-table-shadow-contact-fix-v1.apk`
- Size: 76,113,263 bytes
- Modified: 2026-07-29 13:05:58 +05:00
- SHA-256: `713E25E53E10B36AFA88BB83C1CB3183A11CFA120B6493A1AEE57F29E2B41E19`
- Source commit: `0b562d5b85b0b4d0330ecd10da3f832408949ad9` (`fix: use new table and separate gem shadows from collision`)
- Tag: `new-table-shadow-contact-fix-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation and `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and Godot verified the signed APK.
- Device status: no device was listed by `adb devices -l`; the APK was not installed or launched on a phone.

## Visual Sequencing + Contact v2 — export blocked

- Requested file: `build/android/visual-sequencing-contact-v2.apk`
- Source state: pending commit `fix: delay win presentation and align visible contacts`.
- Validation: Godot 4.6.3 import/parse validation and `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`).
- Export status: blocked. Godot's Android exporter rejected every tested valid output form (absolute Windows path, absolute slash path, project-relative path, and preset path) with `Invalid filename! Android APK requires the *.apk extension.` before compiling. No replacement or old APK was copied, and no device testing is claimed.

## Visual-Physics Calibration v1

- File: `visual-physics-calibration-v1.apk`
- Path: `D:\Owais\game\build\android\visual-physics-calibration-v1.apk`
- Size: 72,539,231 bytes
- Modified: 2026-07-29 10:58:56 +05:00
- Source commit: `8fdebd405c791eddf9188bd32e9f0de3b83cbd42` (`fix: align table perspective and visible gem collisions`)
- Tag: `visual-physics-calibration-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug APK was physically verified.
- Device status: no connected device was used; no install or launch was attempted.

## Asset Integration — Background, Table, and Gems v1

- File: `asset-integration-background-table-gems-v1.apk`
- Path: `D:\Owais\game\build\android\asset-integration-background-table-gems-v1.apk`
- Size: 70,457,131 bytes
- Modified: 2026-07-29 10:24:35 +05:00
- Source commit: `7ac26f197d7768f13f8ea87c17e29b9893db4300` (`feat: integrate gameplay background table and gem assets`)
- Tag: `asset-integration-background-table-gems-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug APK physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Reference Table + Gem Audio v1

- File: `reference-table-gem-audio-v1.apk`
- Path: `D:\Owais\game\build\android\reference-table-gem-audio-v1.apk`
- Size: 27,748,993 bytes
- Modified: 2026-07-29 08:29:58 +05:00
- Source commit: `d2e99213f01005ba08ff1f9bd50a98ac11a967c7` (`feat: match reference table composition and gem audio`)
- Tag: `reference-table-gem-audio-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); signed standalone Android debug export completed and the APK file was physically verified.
- Device status: ADB query did not complete in this session; no install or launch was attempted.

## Sound + Haptics v1

- File: `sound-haptics-v1.apk`
- Path: `D:\Owais\game\build\android\sound-haptics-v1.apk`
- Size: 27,744,897 bytes
- Modified: 2026-07-29 07:59:11 +05:00
- Source commit: `5245163722e2c34f86657aa25483f47d96e7fdfa` (`feat: add gameplay sound and haptic feedback`)
- Tag: `sound-haptics-v1`
- Validation: Godot 4.6.3 headless test suite passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Progression HUD v1

- File: `progression-hud-v1.apk`
- Path: `D:\Owais\game\build\android\progression-hud-v1.apk`
- Size: 27,732,265 bytes
- Modified: 2026-07-29 07:42:27 +05:00
- Source commit: `2dc007575457fec112acabc51b7d6dcfb9f06462` (`feat: add gem progression preview and clean HUD`)
- Tag: `progression-hud-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the requested APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Physics and Pacing Parity v1

- File: `physics-pacing-parity-v1.apk`
- Path: `D:\Owais\game\build\android\physics-pacing-parity-v1.apk`
- Size: 27,728,010 bytes
- Modified: 2026-07-29 07:25:11 +05:00
- Source commit: `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b` (`chore: tune physics and pacing toward reference`)
- Tag: `physics-pacing-parity-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the requested APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Gem Visual Refinement v1

- File: `gem-visual-refinement-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\gem-visual-refinement-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:59:02 +05:00
- Source commit: `14d5de194e60dedf23c29e8c401e8c8b47e761a6` (`feat: refine gemstone visuals and responsive layout`)
- Tag: `gem-visual-refinement-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices` found no connected device. No install or launch was attempted.

## Gameplay Balance v1

- File: `gameplay-balance-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\gameplay-balance-v1.apk`
- Size: 27,728,010 bytes
- Modified: 2026-07-29 06:45:13 +05:00
- Source commit: `4bb5469456bf23480b569a15b9c44c7692e30257` (`chore: tune gameplay physics and pacing`)
- Tag: `gameplay-balance-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Gemstone Visual Prototype v1

- File: `gem-visual-prototype-v1.apk`
- Path: `D:\Owais\game\build\android\gem-visual-prototype-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:40:27 +05:00
- Source commit: `561235ad45a6dbf50a3b8a018820656dae53cd53` (`feat: add first gemstone visual prototype`)
- Tag: `gem-visual-prototype-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: no device install or launch was attempted in this session.

## Clean Contact Merge v3 — Playable Loop

- File: `clean-contact-merge-v3-playable-loop.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v3-playable-loop.apk`
- Size: 27,719,661 bytes
- Modified: 2026-07-29 04:16:50 +05:00
- Source commit: `2d982a8af80e0477caf2c8641f8543c28587a178` (`feat: add scoring win and fail gameplay loop`)
- Tag: `clean-contact-merge-v3-playable-loop`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

Every APK record includes its filename, path, size, modified timestamp, source commit, tag, validation, and device status.

## Clean Contact Merge v2 — Chain Polish

- File: `clean-contact-merge-v2-chain-polish.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v2-chain-polish.apk`
- Size: 27,711,469 bytes
- Modified: 2026-07-29 03:44:48 +05:00
- Source commit: `10f8d59408cccd6287d308f5fc0ab0046326ea3a` (`feat: add smooth merge animation and contact chain merges`)
- Tag: `clean-contact-merge-v2-chain-polish`
- Validation: Godot 4.6.3 headless parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the APK file was physically verified.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Clean Contact Merge v1 — Spawn Lifecycle Fix

- File: `clean-contact-merge-v1-spawn-fix.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v1-spawn-fix.apk`
- Size: 27,707,373 bytes
- Modified: 2026-07-29 03:23:14 +05:00
- Source commit: `53306bf1f9d96fbb6918380657dd611ed1a7a51e` (`fix: spawn exactly one launcher piece per shot cycle`)
- Tag: `clean-contact-merge-v1-spawn-fix`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed, including the controller lifecycle regressions; standalone Android debug export completed.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Clean Contact Merge v1

- File: `clean-contact-merge-v1.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v1.apk`
- Size: 27,707,373 bytes
- Modified: 2026-07-29 03:12:46 +05:00
- Source commit: `ac795736bbecb4ee83c346a2717276d66a2b483c` (`feat: build clean contact merge gameplay slice`)
- Tag: `clean-contact-merge-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed; standalone Android debug export completed and Godot verified the signed APK.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Blank Android baseline

- File: `gem-merge-rebuild-baseline.apk`
- Path: `D:\Owais\game\build\android\gem-merge-rebuild-baseline.apk`
- Size: 27,690,009 bytes
- Modified: 2026-07-29 02:55:38 +05:00
- SHA-256: `B29D90C5E082CFEA0567EA488B831458B8107F15690838BE5F06355139A93A1F`
- Source commit: `ad1e2d720f615ce326da91ac15b5a303543b15d8` (`build: verify blank Android baseline export`).
- Tag: `blank-android-baseline-verified`.
# 18-Gem Progression Tested v1

- File: `18-gem-progression-tested-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-progression-tested-v1.apk`
- Size: `99,195,813` bytes
- Modified: `2026-07-30 08:55:02 +05:00`
- SHA-256: `44FB0D04CD65DB1C666A66258E308AE9853D33F26060D4D3C9C6C04B8318559A`
- Source commit: `306b0c69d3e7f8ecd49887420ea02c67386e61d0` (`test: validate complete 18-gem progression`)
- Tag: `18-gem-progression-tested-v1`
- Validation: Godot 4.6.3 import/parse, `GEM18_CHAIN_TESTS`, `CLEAN_CONTACT_TESTS`, development harness L14 four-step chain, L18 terminal path, and APK ZIP checks passed.
- Device status: no phone was connected; installation, visual manual checks, and device performance are not claimed.
# Level 1 Flow v1

- File: `level-1-flow-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\level-1-flow-v1.apk`
- Size: `99,200,243` bytes
- Modified: `2026-07-30 09:12:13 +05:00`
- SHA-256: `E7BDBBE6D1158F113F705980602A769DA64078194A61780E45D6AA4156616D9B`
- Source commit: `4ad1d51e09e0efce75d6842b0310880095ad349c` (`feat: add isolated level 1 flow`).
- Tag: `level-1-flow-v1`.
- Validation: Godot 4.6.3 parse/import plus `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, and `LEVEL_1_FLOW_TESTS` passed. APK/ZIP structure contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no phone was connected; installation and launch were not attempted.
# Perspective Table View v1

- APK: `build/android/perspective-table-view-v1.apk`
- Build source commit: `5125a4c238d1c9963cad8d185d68491910892623`
- Tag: `perspective-table-view-v1`
- Size: `99,204,339 bytes`
- Modified: `2026-07-30 10:16:44 +05:00`
- SHA-256: `D4BDC9598A28DD5EEB494974215DD617DCDC6EDA9DDC341A93505732D4D77CEC`
- Validation: Godot parse/import, clean-contact, 18-gem chain, Level 1 flow, and motion profile passed. APK ZIP structure verified (`AndroidManifest.xml`, `classes.dex`).
- Device status: no device connected; not installed/tested on-device.
# Complete Perspective View & Variety v1

- File: `complete-perspective-view-variety-v1.apk`
- Path: `D:\Owais\game\build\android\complete-perspective-view-variety-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 10:41:40 +05:00`
- SHA-256: `577F4E90610DD5A03CA849F890F65806DC75D6BE39BF4DF52569C95E478DABB9`
- Source baseline: `845a113` (`perspective-table-view-v1`); final source commit and tag follow this manifest update.
- Validation: Godot parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. Fresh APK exists, is non-zero, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected device; no installation or launch claimed.
# Visible-Touch Table Alignment Fix v1

- File: `visible-touch-table-alignment-fix-v1.apk`
- Path: `D:\Owais\game\build\android\visible-touch-table-alignment-fix-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 11:02:43 +05:00`
- SHA-256: `63238FE064B48BC57ECBBCD1EE522C17347C86CE5B96F57A71B764F00B5AE5DC`
- Source commit: `3316d2dcdebde9528885c882b2de385c26862c66` (`fix: restore visible-touch collision and table alignment`)
- Tag: `visible-touch-table-alignment-fix-v1`
- Validation: Godot 4.6.3 headless parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK is non-empty and ZIP validation found `AndroidManifest.xml`, `classes.dex`, and arm64-v8a entries.
- Device status: no connected Android device; installation and launch were not attempted.
# Table Perspective Matched Physics v1

- File: `table-perspective-matched-physics-v1.apk`
- Path: `D:\Owais\game\build\android\table-perspective-matched-physics-v1.apk`
- Size: `99,208,435` bytes
- Modified: `2026-07-30 12:45:07 +05:00`
- SHA-256: `B4FCA00607414EAE4A9158B4727515BBD339935AC816C6E48EF38263D7057690`
- Source behavior: `25fac1fa0ae9e8939b7daa618cb02df12054eb83` (`fix: match perspective scaling with gem physics`)
- Delivery commit/tag: recorded with this packaging milestone.
- Validation: Godot 4.6.3 headless parse/import plus `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK structure contains `AndroidManifest.xml`, `classes.dex`, and arm64 Godot native code.
- Device status: no phone connected; no device test claimed.

# Identity, UI, Unlimited Play & Target Balance Fix v1

- File: `identity-ui-unlimited-target-balance-fix-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\identity-ui-unlimited-target-balance-fix-v1.apk`
- Size: `100,750,262` bytes
- Modified: `2026-07-30 21:26:25 +05:00`
- SHA-256: `DC593E97E3B114A7718B6CFA7DDE08EFCA4BBD5B88FCE4690B8C1CC2BB8F2DA0`
- Source commit: `463d693` (`fix: correct gem UI targets and unlimited play`)
- Tag: `identity-ui-unlimited-target-balance-fix-v1`
- Validation: Godot 4.6.3 parse/import; clean contact, 18-gem chain, Level 1 flow, and motion profile suites passed. The fresh APK ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected Android device; installation and launch were not attempted.

# Supplied HUD Art + L7/L8 Balance v1

- File: `supplied-hud-l7-l8-balance-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\supplied-hud-l7-l8-balance-v1.apk`
- Size: `100,754,358` bytes
- Modified: `2026-07-30 22:00:03 +05:00`
- SHA-256: `1989D1258C86B46E19B085438F2EC52D9F24D3391100F35679972C9FCC967A63`
- Source commit: `b0fddc5` (`fix: use supplied HUD art and rebalance level one`)
- Tag: `supplied-hud-l7-l8-balance-v1`
- Validation: Godot parse/import; clean contact, 18-gem chain, Level 1 flow, and motion profile checks passed. Fresh APK export succeeded.
- Device status: no connected Android device; installation and launch were not attempted.
# Animation / reward / audio / large-screen polish APK - 2026-08-18

- Filename: `build/android/majestic-gems-animation-large-screen-polish.apk`
- Size: 81,320,711 bytes
- Timestamp: 2026-08-18 04:05:42 +05:00
- SHA-256: `DAC8A7210CD5BADA6F1D6862613877ED61C8FEBB25BDDA31596FE7F647714B7E`
- Export-source commit: `1ef87a9` (the APK content matches this milestone commit; reports/tests are excluded from packaging).
- Delivery tag: `animation-reward-audio-large-screen-polish-apk-v1` on the provenance follow-up commit.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, both ARM ABIs, debug signing. The APK and Gradle output stabilized byte-for-byte; the known silent outer export wrapper was then terminated. The preset was restored to its existing release AAB path/format. No AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36; manifest `android:appCategory=game`, portrait orientation, and `resizeableActivity=true`; APK Signature Scheme v2 PASS with one Godot RSA-2048 debug signer.
- Tests: `UI_SCALE_LAYOUT_TESTS: PASS`, `SOUND_PRIVACY_LINK_TESTS: PASS`, `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`; Godot editor parse/import PASS. The test wrapper's known post-sentinel teardown returned exit 1 without assertion failure.
- Device status: `adb devices -l` returned no connected device. Installation, launch, physical tablet/foldable behavior, listening, and haptic feel are not claimed.

# Animation / reward / audio / large-screen polish APK v2 - 2026-08-18

- Filename: `build/android/majestic-gems-animation-large-screen-polish-v2.apk`
- Size: 81,304,035 bytes
- Timestamp: 2026-08-18 04:48:15 +05:00
- SHA-256: `9132197FB131F8367577573F9D01716AAB95875617975C707148E33174D4A1CA`
- Export-source commit: `9f83eb7` (video-audit documentation plus the `tween_composer/*` Android exclusion; gameplay remains the tagged `1ef87a9` implementation).
- Delivery tag: `animation-reward-audio-large-screen-polish-v2` on the provenance follow-up commit.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, both ARM ABIs, debug signing. The committed release AAB path/format was restored immediately after export. No AAB was generated.
- Packaging impact: zero Tween Composer entries and two Global Tweens entries. Later last-AAB audit proved Tween Composer is a production Home dependency; therefore the size reduction was an Android Home packaging regression. Do not use this v2 APK as a valid Home-flow baseline.
- Validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36; manifest `android:appCategory=game`, portrait orientation, and `resizeableActivity=true`; both `arm64-v8a` and `armeabi-v7a`; APK Signature Scheme v2 PASS with one Godot RSA-2048 debug signer.
- Tests: `UI_SCALE_LAYOUT_TESTS: PASS`, `SOUND_PRIVACY_LINK_TESTS: PASS`, `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`; Godot editor parse/import PASS. Each Windows runner returned the repository's known post-sentinel teardown access violation after printing PASS; no assertion failed.
- Device status: `adb devices -l` found no connected device and no AVD was installed. Installation, launch, physical tablet/foldable behavior, listening, and haptic feel are not claimed.
# Reference-Driven Game Feel v2 APK - 2026-08-18

- Filename: `build/android/majestic-gems-reference-game-feel-v2.apk`
- Size: 81,304,919 bytes
- Timestamp: 2026-08-18 05:22:47 +05:00
- SHA-256: `D4C224E14B029C70F3D8655A85F130AC1A35C11B38D6E32EB76870133EAE901F`
- Export-source commit/tag: `f2922c8` / `reference-driven-game-feel-v2-source`.
- Delivery tag: `reference-driven-game-feel-v2-apk` on the manifest/provenance follow-up commit.
- Export: Godot 4.6.3 `--export-debug Android`, Gradle APK format, both `arm64-v8a` and `armeabi-v7a`, Godot debug signing. The committed release AAB path/format was restored immediately; no AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36; APK contains `AndroidManifest.xml`, primary DEX, and both ARM library sets; tests/reports are excluded. APK Signature Scheme v2 passes with one Godot RSA-2048 signer.
- Tests: editor parse/import, `REFERENCE_GAME_FEEL_V2_TESTS`, `UI_SCALE_LAYOUT_TESTS`, `SOUND_PRIVACY_LINK_TESTS`, `GAME_FLOW_REWARD_SPLASH_TESTS`, `SCENE_VARIETY_ASSETS_TESTS`, and `BRANDING_PUSH_LINE_TESTS` passed.
- Device status: `adb devices -l` found no connected device. Installation, launch, post-change screen recording, physical listening/haptics, and on-device perceptual acceptance are not claimed.
# Home Startup and Return Flow Repair APK - 2026-08-18

- Filename: `build/android/majestic-gems-home-flow-repair.apk`
- Size: 81,305,019 bytes
- Timestamp: 2026-08-18 05:38:48 +05:00
- SHA-256: `BC55ECBAF4D7DD3BC7D74AC847C92B65D6EF9AFA148561666FE04E77801D57EE`
- Export-source commit/tag: `e65bc5f` / `home-startup-return-flow-repair-source`.
- Delivery tag: `home-startup-return-flow-repair-apk` on the provenance follow-up commit.
- Export: Godot 4.6.3 debug APK, Gradle format, both ARM ABIs, Godot debug signing. The committed release AAB preset was restored; no AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36; APK Signature Scheme v2 PASS with one signer.
- Tests: editor parse/import and game-flow, game-feel/contact, UI/layout, sound/privacy, scene assets, branding/input, and AdMob suites reached PASS.
- Device status: `adb devices -l` found no connected device. Installation and physical startup/Home-return verification are not claimed.

# Android Back, Idle, Settings, and Splash Repair APK - 2026-08-18

- Filename: `build/android/majestic-gems-back-idle-settings-splash-repair.apk`
- Size: 82,149,382 bytes
- Timestamp: 2026-08-18 07:09:56 +05:00
- SHA-256: `F60C5A6DBB9A17F37C3CC4C37E198DE23D33A338EA2B213FF10025297C79ED9B`
- Export-source commit/tag: `159f9a8` / `android-back-idle-settings-splash-repair-source`.
- Export: Godot 4.6.3 debug APK, Gradle format, both `arm64-v8a` and `armeabi-v7a`, Godot debug signing. The committed release AAB path/format was restored immediately; no AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36, game category and portrait support; APK Signature Scheme v2 PASS with one RSA-2048 signer; primary DEX and both Godot ARM libraries present; packaged contents include the imported 1152x1152 system-splash derivative.
- Tests: editor parse/import and game-flow/Back/idle, sound/privacy, AdMob/shutdown, responsive layout, reference game-feel/contact, scene assets, and branding/input suites reached PASS. The Windows runner returned its known post-sentinel teardown access violation after test quit; no assertion failed.
- Device status: `adb devices -l` found no connected device. Installation, multi-minute physical idle, OEM Back/exit behavior, and splash sharpness are not claimed.

# Last-AAB Home and Android Back Regression Repair APK - 2026-08-18

- Filename: `build/android/majestic-gems-last-aab-home-back-repair.apk`
- Size: 82,166,770 bytes
- Timestamp: 2026-08-18 08:38:43 +05:00
- SHA-256: `B84DDD485475F5BA60ECB01ECE765E1AF39AEDB5A1691F0C0B499B8F9BFB4A8B`
- Export-source commit/tag: `56a27bb` / `last-aab-home-back-regression-repair-source`.
- Baseline audited: last delivered release AAB `majestic-gems-merge-sound-sync-v3-vc3.aab`, source `aa3a1e1`, delivery `735f81a`, versionCode 3 / versionName 1.0.1.
- Export: Godot 4.6.3 debug APK, Gradle format, both `arm64-v8a` and `armeabi-v7a`, Godot debug signing. The committed release AAB preset was restored; no AAB was generated.
- Dependency validation: packaged Home contains `tween_composer.gdc` (23,772 bytes), `tween_sequence_resource.gdc` (1,916), `tween_step_collection_resource.gdc` (1,300), and `tween_step_item_resource.gdc` (9,984). This restores the dependency omitted by the broken post-AAB packages.
- Package validation: AAPT package `com.owais.majestygems`, versionCode 4, versionName 1.0.2, min SDK 24, target/compile SDK 36 and game category; primary DEX and both Godot ARM libraries present; APK Signature Scheme v2 PASS with one RSA-2048 signer.
- Tests: game-flow/Home/Back, sound/privacy, AdMob/shutdown, responsive layout, reference game-feel/contact, scene-variety, and branding/input suites reached PASS. The Windows runner returned its known post-sentinel teardown access violation; no assertion failed.
- Device status: `adb devices -l` found no connected device. Installation, physical Home/Level Ready visibility, OEM Back behavior, and prolonged idle acceptance are not claimed.

# Final HUD, Tiered VFX, Power Cinematic, and Audio Test Candidate APK - 2026-08-30

- Filename: `build/android/majestic-gems-final-vfx-hud-audio-test-v1.0.15-vc17.apk`
- Size: 114,502,601 bytes
- Timestamp: 2026-08-30 16:20:55 +05:00
- SHA-256: `A5A64EF346E5869A61B95AE124E7F355002ED68E1BC5DF6F6AA48343E03B5444`
- Export-source commit/tag: `3637090` / `final-hud-vfx-audio-test-candidate-source`.
- Delivery tag: `final-hud-vfx-audio-test-candidate-apk` on the manifest/provenance follow-up commit.
- Export: Godot 4.6.3 debug APK, Gradle format, both `arm64-v8a` and `armeabi-v7a`, Godot debug signing. No AAB was generated.
- Validation: AAPT package `com.owais.majestygems`, versionCode 17, versionName 1.0.15, min SDK 24, target/compile SDK 36; manifest and primary DEX present; APK Signature Scheme v2 PASS with one Godot debug signer. All five runtime audio imports are packaged; preserved source audio, reports, and tests are excluded.
- Tests: corrected-state full regression passed 29/29 suites (`FINAL2_REGRESSION passed=29 failed=0 total=29`); post-FFmpeg Godot re-import and `SOUND_PRIVACY_LINK_TESTS` also passed. Visual capture reached `POWERS_V1_CAPTURE: PASS`; the Windows runner's known teardown access violation occurred after the sentinel.
- Device status: `adb devices -l` found connected V2149 `34385676890001M`. The APK was not installed or launched; on-device visual, listening, haptic, and performance acceptance are not claimed.
