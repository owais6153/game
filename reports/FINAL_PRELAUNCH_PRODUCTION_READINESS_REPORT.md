# Final Pre-Launch Production Readiness Report

> Device correction: versionCode 13 / versionName 1.0.11 is superseded and must not be uploaded. On the authorized V2149, Firebase automatic first-open/session events uploaded successfully, but pressing Start produced `Firebase singleton exists but logEvent is unavailable`; custom gameplay events were not forwarded. The Java bridge now explicitly lists `logEvent` through `getPluginMethods()` as well as `@UsedByGodot`, and the repaired candidate advances to 1.0.12 / code 14 for a fresh export and device proof.

## Scope and release identity

This is the final pre-launch production-readiness pass for Majestic Gems. It preserves the approved game loop and adds exactly one economy sink: a deterministic `REROLL 100` action for the displayed Next Gem. Following the device-found Firebase bridge defect in 1.0.11/code 13, the repaired Google Play identity is versionName `1.0.12`, versionCode `14`, package `com.owais.majestygems`, with a dual-ARM release AAB named `majestic-gems-production-candidate-v1.0.12-vc14.aab`.

## Firebase Analytics audit

- The existing `Analytics` autoload and acknowledged Android Java bridge remain the single analytics path. Firebase initializes lazily and gameplay remains fail-open when the native bridge is unavailable.
- Home display does not emit `level_start`. Pressing Start and each Retry create a new attempt and emit one `level_start` with level, attempt, starting balance, and queue context.
- Confirmed controller events cover starts/ends, merges, target completion, level completion/failure, retry, danger warning, coin earnings/spending, rewarded/interstitial requests and outcomes. Partial `target_progress` is emitted only for multi-quantity target progress; current quantity-one levels correctly do not manufacture it.
- The established production names `merge` and `rewarded_ad_completed` remain the canonical equivalents of semantic `gem_merge` and reward-earned events. Duplicate aliases were deliberately not added.
- Every event, parameter, trigger, deduplication guard, and product purpose is documented in `ANALYTICS_EVENT_CATALOG.md`.

## AdMob and UMP audit

- Poing Godot AdMob `5.0.0` remains integrated with Google next-generation Mobile Ads SDK `1.2.1`; production app/interstitial/rewarded IDs remain unchanged.
- Android requests a UMP consent-information update at launch. Ads do not initialize or preload until the native `canRequestAds()` result permits requests. A retained prior-session decision may safely permit ads after an update error.
- Initialization/preload guards prevent duplicate requests. Privacy Options remains exposed only when UMP requires it. Release geography is disabled and release test-device IDs are empty.
- Controller intent is logged before an ad request. Shown, failed, and rewarded-completion events carry bounded placement/reward context. Reward completion is emitted only from the earned callback and is protected from duplicate reward delivery.
- Missing SDK, denied consent, load/show failure, and callback timeout all fail open to gameplay. Interstitial failure continues progression; rewarded failure restores the normal non-doubled result.

## Play policy and store-console audit

- `PLAY_CONSOLE_PRODUCTION_CHECKLIST.md` records the package/version, Contains ads declaration, Data safety review, privacy-policy placement, target audience, content rating, app access, store assets, UMP messages, and release checks that require dashboard confirmation.
- The checklist treats Firebase Analytics, Google Mobile Ads/UMP, and advertising identifiers as third-party data practices that must be reflected accurately in Data safety.
- The app currently configures under-age treatment as false and has no neutral age screen. A child or mixed-child target-audience declaration is therefore not production-ready without a separate Families/COPPA design and review. The intended listing remains 13+ subject to the developer's Play Console answers.
- Store-console declarations, configured UMP message availability by region, live ad serving, and Play review cannot be proven from source or a local bundle and remain manual release-owner gates.

## Economy sink and save safety

- Cost: `GameConfig.NEXT_GEM_REROLL_COST = 100` coins.
- Availability: active nonterminal gameplay, a valid alternative tier, no in-flight reroll, and at least 100 banked coins from the level-start baseline.
- The reroll changes only the displayed Next Gem. It never changes the active gem, physics, merge rules, target rules, score, reward amounts, ad cadence, or the underlying deterministic launcher sequence.
- Candidate choice is deterministic from the existing level seed, queue index, and successful reroll count; the new tier is valid and differs from the displayed tier.
- Persistence is save-before-commit. A failed save leaves balance and queue untouched. A short lock plus disabled HUD state prevents double-spend. Only banked baseline coins are spendable, so Retry cannot refund a reroll and a force-close cannot accidentally persist unresolved level earnings.
- Focused tests cover exact cost, atomic save failure, deterministic valid replacement, double-tap protection, analytics, and actual-save backup/restoration. Full details are in `ECONOMY.md`.

## Android production configuration

- Godot `4.6.3`, Gradle Android template, JDK 17, AGP `8.6.1`, compile/target SDK 36, minimum SDK 24.
- Release/upload signing configuration is retained. Architectures are `arm64-v8a` and `armeabi-v7a`; x86/x86_64 are disabled.
- Firebase BoM resolves to `34.18.0` and Firebase Analytics to `23.2.0` on `standardReleaseRuntimeClasspath`.
- The prepared identity in `export_presets.cfg` is committed before export, in accordance with the repository release workflow.

## Automated validation

The complete twelve-suite Godot regression run printed PASS for Firebase analytics, AdMob, audio/back/privacy, branding, game flow, gem feedback, rail/target/gem expansion, game feel, reward feedback, scene/assets, sound/privacy, and UI scale/layout. No assertion failure occurred. On this Windows environment, each headless Godot test process still exits with the already-known `-1073741819` access violation after printing its PASS sentinel; this post-PASS engine shutdown condition is not represented as a clean exit.

Focused production additions passed:

- `FIREBASE_ANALYTICS_PIPELINE_TESTS: PASS`
- `ADMOB_INTEGRATION_TESTS: PASS`
- whole-project Godot editor import/parse completed without a script parse error
- Gradle release dependency resolution completed successfully
- Gradle `compileStandardReleaseJavaWithJavac` completed successfully. AGP `8.6.1` emitted its existing compile-SDK-36 support warning and two harmless manifest replacement warnings; compilation itself passed.

The AAB export, Bundletool manifest/version/ABI inspection, signature/hash audit, audit-APK existence check, ADB status, and Firebase DebugView status are recorded in the final artifact section after export.

## Performance and stability review

- The reroll is a bounded UI/controller transaction with no per-frame work and no new physics or rendering path.
- Analytics adds small dictionaries only on confirmed discrete events. Ad context is cleared after each fullscreen session.
- Existing delta-based simulation, audio contact thresholds/cooldowns/concurrency caps, save rollback rules, overlay spawn blocking, and controller-reset coverage are preserved by the full regression suite.
- No broad refactor, retuning, new network service, or background loop was introduced.

## Deferred post-launch work

`POST_LAUNCH_ROADMAP.md` separates V1.1, V1.2, and later ideas. No second coin sink, shop, booster, progression redesign, remote-config economy, mediation expansion, or post-launch feature was pulled into this release.

## Superseded versionCode-13 artifact evidence

- Release AAB: `build/android/majestic-gems-production-candidate-v1.0.11-vc13.aab`
- Size/timestamp: 75,104,667 bytes; 2026-08-28 08:08:04 +05:00
- SHA-256: `94852CCA6B75F8D8D0D19219A25B6849962DAA8286B3DDC568CDBFB8226D2257`
- Source commit/tag: `25bfdffba9d8fdc6b57ec26814ec4a892b0acf44` / `final-prelaunch-production-readiness-v1.0.11-vc13-source`
- Delivery tag: `final-prelaunch-production-readiness-v1.0.11-vc13-release` on the final documentation/manifest commit
- Bundletool 1.18.3 `validate`: PASS
- Embedded manifest: package `com.owais.majestygems`; versionCode 13; versionName 1.0.11; min SDK 24; target/compile SDK 36; required touchscreen; portrait game activity; production AdMob app ID; Firebase and Poing AdMob/UMP components present
- Archive: 1,039 entries; three `.so` files for `arm64-v8a`; three for `armeabi-v7a`; zero x86/x86_64 libraries; current compiled config/controller/ad manager; zero packaged test/report entries
- Signature: `jar verified`; existing Muhammad Owais Khan / Teckvertex Labs upload signer; SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`. The expected self-signed/no-timestamp and JarInputStream bundle-format notices remain non-failing.
- Standalone existence check: `build/android/production-candidate-vc13-audit-apks/universal.apk`, 76,432,567 bytes, SHA-256 `C87A6F30DFA3048CBA0F5177132DAE413E210F8FE374746C052D5A0492C642AF`. Bundletool generated it from this exact AAB with its local debug keystore; it is an audit derivative, not the delivered Play artifact.
- ADB/device: after the old owner-profile app and its never-launched Guest-profile registration were removed, the exact audit APK installed successfully on the V2149 (Android 11/API 30). The package reported 1.0.11/code 13 and arm64. Firebase fetched config and uploaded automatic first-open/session data with HTTP 204. Pressing Start then logged `Firebase singleton exists but logEvent is unavailable`; custom gameplay telemetry was not forwarded, so this artifact is invalid for upload.

## Repaired versionCode-14 artifact and device evidence

- Release AAB: `build/android/majestic-gems-production-candidate-v1.0.12-vc14.aab`
- Size/timestamp: 75,104,762 bytes; 2026-08-28 09:28 +05:00
- SHA-256: `EAD85A7E30CC0E8D88B7000AED2EC41192BE7BFB1E8F36F2CB2AB19FF44328B7`
- Source commit/tag: `5d6f74489a4ae15a45ca97d45d50419aa9da02aa` / `final-prelaunch-firebase-device-repair-v1.0.12-vc14-source`
- All twelve Godot regression suites reprinted PASS (Firebase analytics pipeline, AdMob, scene/asset variety, animation/audio/back/privacy, sound/privacy, gem pattern feedback, rail/target/gem expansion, reference game feel, reward feedback, UI scale/layout, branding, game flow/reward/splash), and a whole-project Godot editor `--import` pass completed with no script/import errors.
- Bundletool 1.18.3 `validate`: PASS. `dump manifest` confirms package `com.owais.majestygems`, versionCode 14, versionName 1.0.12, min SDK 24, target/compile SDK 36, required touchscreen, portrait game activity, the unchanged production AdMob application ID, and the same Firebase/Poing AdMob/UMP plugin registrations as prior releases.
- Native/package proof: the extracted universal audit APK has 1,036 entries, three `.so` libraries for each ARM ABI, zero x86/x86_64 libraries, current compiled `analytics_service.gdc`/`game_controller.gdc`/`ad_manager.gdc`, and zero packaged test/report/dev-script entries. `classes.dex`/`classes2.dex`/`classes3.dex` contain the `getPluginMethods`/`logEvent` bridge strings, confirming the device-found fix is packaged in this exact build.
- Signature: `jarsigner -verify` on the AAB reports `jar verified`; unchanged Muhammad Owais Khan / Teckvertex Labs upload signer, SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`.
- Standalone existence check: `build/android/production-candidate-vc14-audit-apks.apks` (`universal.apk`, 76,436,663 bytes, SHA-256 `758B5EBA4E57FB41A48E8CF1BC38D707FD9A9538BA8F5CD8D3A36D5872FED4F3`). Debug-signed audit derivative only, not the delivered Play artifact.
- Device/DebugView: **not performed.** No `adb` command was run against a physical device in this session; per explicit user instruction, device installation and Firebase DebugView verification require the user's authorization first. This remains the single open gate before this AAB is confirmed for Play upload — repeat the exact V2149 device flow (install, press Start, confirm `logEvent` no longer logs "unavailable", confirm custom gameplay events appear in DebugView) once authorized.

## Residual risks and manual acceptance

- Complete every unchecked item in `PLAY_CONSOLE_PRODUCTION_CHECKLIST.md`, using current Play Console and AdMob dashboard state rather than assumptions.
- On a Play-delivered physical-device build, verify first-launch UMP behavior in an applicable region, Privacy Options when required, production/test-ad callbacks, interstitial failure fallback, exactly-once rewarded coins, Firebase DebugView receipt, Android Back, audio mix, touch feel, and an extended dense-board session.
- Live Google service behavior and Play Console declarations remain external acceptance gates even when the signed AAB passes local validation.
