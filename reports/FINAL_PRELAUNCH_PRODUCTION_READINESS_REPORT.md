# Final Pre-Launch Production Readiness Report

> Device correction (round 2): versionCode 13 / versionName 1.0.11 **and** versionCode 14 / versionName 1.0.12 are both superseded and must not be uploaded. Round 1 found Firebase automatic events uploading but custom events failing with `Firebase singleton exists but logEvent is unavailable`; the round-1 fix (`getPluginMethods()` on the Java plugin) did not actually work — repeat device testing on the same authorized V2149 reproduced the identical warning on vc14. The real defect, found by decompiling the bundled Godot Android plugin runtime, is that `Object.has_method("logEvent")` on the JNI-backed native singleton unreliably returns `false` even though the method is natively registered and callable. `scripts/services/analytics_service.gd` no longer gates on `has_method()`. The repaired candidate, versionName `1.0.13` / versionCode `15`, was device-verified with explicit user authorization: Firebase's own `FA-SVC` module logged the real `level_start` event with correct parameters.

## Scope and release identity

This is the final pre-launch production-readiness pass for Majestic Gems. It preserves the approved game loop and adds exactly one economy sink: a deterministic `REROLL 100` action for the displayed Next Gem. Following two rounds of device-found Firebase bridge defects (1.0.11/code 13 and 1.0.12/code 14), the repaired and device-verified Google Play identity is versionName `1.0.13`, versionCode `15`, package `com.owais.majestygems`, with a dual-ARM release AAB named `majestic-gems-production-candidate-v1.0.13-vc15.aab`.

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

## Superseded versionCode-14 artifact and device evidence (fix did not work)

- Release AAB: `build/android/majestic-gems-production-candidate-v1.0.12-vc14.aab`
- Size/timestamp: 75,104,762 bytes; 2026-08-28 09:28 +05:00
- SHA-256: `EAD85A7E30CC0E8D88B7000AED2EC41192BE7BFB1E8F36F2CB2AB19FF44328B7`
- Source commit/tag: `5d6f74489a4ae15a45ca97d45d50419aa9da02aa` / `final-prelaunch-firebase-device-repair-v1.0.12-vc14-source`
- All twelve Godot regression suites, whole-project editor import, Bundletool `validate`/manifest dump, DEX string presence (`getPluginMethods`/`logEvent`), and `jarsigner` signature verification all PASSED for this build. This static/local validation was not sufficient to catch the real defect.
- **Device/DebugView, performed with user authorization: FAILED.** With the user's explicit go-ahead to use `adb`, the existing signature-mismatched app was uninstalled from the authorized V2149 and this exact vc14 universal audit APK was installed fresh. Cold launch and pressing START GAME reproduced the identical `WARNING: [Analytics] Firebase singleton exists but logEvent is unavailable` from `push_warning`, and `[Analytics] Native Firebase plugin unavailable; skipped level_start` — custom events were still not forwarded. This proves the round-1 `getPluginMethods()` fix did not address the real defect, despite passing every static/local check.
- Root cause found by decompiling `godot-lib.template_release.aar`'s `org/godotengine/godot/plugin/GodotPlugin.class` (`javap -c`): `onRegisterPluginWithGodotNative()` collects every method annotated `@UsedByGodot` **and** every declared method whose name matches an entry in `getPluginMethods()`, then calls `nativeRegisterMethod` for each. `logEvent` satisfied both criteria in both vc13 and vc14, so it was registered natively. The actual failure is that `Object.has_method("logEvent")`, called from GDScript on the JNI-backed native singleton returned by `Engine.get_singleton()`, does not reliably reflect that native registration — it returned `false` even though the method was registered and (as vc15 proves) callable.

## Repaired and device-verified versionCode-15 artifact

- Release AAB: `build/android/majestic-gems-production-candidate-v1.0.13-vc15.aab`
- Size/timestamp: 75,104,741 bytes; 2026-08-28 09:44 +05:00
- SHA-256: `DD398E1201CC2A9CC60DEEF48AC8A34410AB917F3F82A7B237CA981A39273633`
- Fix: `scripts/services/analytics_service.gd`'s `_native_bridge()` no longer calls `bridge.has_method("logEvent")` before returning the bridge. It relies on `Engine.has_singleton("FirebaseAnalytics")` (which correctly reflects plugin presence) plus the actual `logEvent` call's own boolean accept/reject result — the only value the Java bridge and Firebase itself can authoritatively confirm.
- All twelve Godot regression suites reprinted PASS after the change (`FIREBASE_ANALYTICS_PIPELINE_TESTS`, `ADMOB_INTEGRATION_TESTS`, `SCENE_VARIETY_ASSETS_TESTS`, `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`, `SOUND_PRIVACY_LINK_TESTS`, `GEM_PATTERN_FEEDBACK_V1_TESTS`, `RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS`, `REFERENCE_GAME_FEEL_V2_TESTS`, `REWARD_FEEDBACK_V3_TESTS`, `UI_SCALE_LAYOUT_TESTS`, `BRANDING_PUSH_LINE_TESTS`, `GAME_FLOW_REWARD_SPLASH_TESTS`), and a whole-project Godot editor `--import` pass completed with no script/import errors.
- Bundletool 1.18.3 `validate`: PASS. `dump manifest` confirms package `com.owais.majestygems`, versionCode 15, versionName 1.0.13, min SDK 24, target/compile SDK 36, required touchscreen, portrait game activity, the unchanged production AdMob application ID, and the same Firebase/Poing AdMob/UMP plugin registrations as prior releases.
- Native/package proof: the extracted universal audit APK has 1,036 entries, three `.so` libraries for each ARM ABI (`arm64-v8a`, `armeabi-v7a`), zero x86/x86_64 libraries, and zero packaged test/report/dev-script entries.
- Signature: `jarsigner -verify` on the AAB reports `jar verified`; unchanged Muhammad Owais Khan / Teckvertex Labs upload signer, SHA-256 certificate fingerprint `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`.
- Standalone existence check: `build/android/production-candidate-vc15-audit-apks.apks` (`universal.apk`, 76,432,567 bytes, SHA-256 `D1155577EEA8B1BE442EC5EAEBEBF8F093295F867833F9D66C94693E7F8C28BB`). Debug-signed audit derivative only, not the delivered Play artifact.
- **Device/DebugView, performed with user authorization: PASSED.** The vc14 audit install was uninstalled and this exact vc15 universal audit APK was installed fresh on the same V2149. Cold launch, PLAY, and START GAME were driven via `adb shell input`/`monkey`. Logcat confirms, in order: `MajestyAnalytics: Firebase Analytics bridge registered` at startup, `[Analytics] Native Firebase plugin available` from the GDScript service, `MajestyAnalytics: Forwarded custom event to Firebase: level_start` and `[Analytics] Sent level_start` when Start was pressed. Critically, Firebase's own `FA-SVC` module independently logged `Logging event: origin=app,name=level_start,params=Bundle[{pattern=same_shape:rounded_square, coin_balance=0, attempt_number=1, level_number=1, ...}]` — proof the event reached Firebase's real pipeline with correct gameplay parameters, not just that the Java call returned true. The device was left with the app uninstalled (clean state) after verification. Merge/target/coin/ad events were not separately device-tested in this session because they share the identical `analytics_service.gd` → `FirebaseAnalyticsPlugin.logEvent` call path already proven working by `level_start`; DebugView (as opposed to raw logcat) was not separately opened.

## Residual risks and manual acceptance

- Complete every unchecked item in `PLAY_CONSOLE_PRODUCTION_CHECKLIST.md`, using current Play Console and AdMob dashboard state rather than assumptions.
- `level_start` was the only event device-verified end to end in this session. Before Play upload, verify at least one merge, one target completion, one level win/fail, one retry, and one rewarded-ad completion actually appear in Firebase DebugView on a physical device, since they share the same fixed call path but were not each individually observed reaching Firebase in this session.
- On a Play-delivered physical-device build, verify first-launch UMP behavior in an applicable region, Privacy Options when required, production/test-ad callbacks, interstitial failure fallback, exactly-once rewarded coins, Android Back, audio mix, touch feel, and an extended dense-board session.
- This task uncovered that passing every static/local validation check (Bundletool, manifest, DEX string presence, signature) does not guarantee a Godot Android plugin method is actually callable at runtime — vc14 passed all of those checks and was still broken. Treat on-device verification as a mandatory gate for any future change to native plugin bridges (Firebase, AdMob), not an optional nice-to-have.
- Live Google service behavior and Play Console declarations remain external acceptance gates even when the signed AAB passes local validation.
