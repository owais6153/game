# Build Manifest

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
