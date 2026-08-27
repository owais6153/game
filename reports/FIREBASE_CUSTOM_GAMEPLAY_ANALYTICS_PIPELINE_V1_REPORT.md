# Firebase Custom Gameplay Analytics Pipeline v1

Date: 2026-08-27 (Asia/Karachi)

## Root cause and prior-build audit

Firebase automatic events worked because `FirebaseInitProvider` and the Firebase Analytics SDK initialize independently of Godot gameplay. Custom events required a second path: gameplay hook -> `Analytics` Autoload -> Godot Android singleton -> exported Java method -> `FirebaseAnalytics.logEvent()`.

The prior code-10 closed-test AAB was audited directly. Its manifest registered `org.godotengine.plugin.v2.FirebaseAnalytics`, its DEX contained `FirebaseAnalyticsPlugin` and the exported `void log_event(String,String)` method, and its asset pack contained `analytics_service.gdc`, `game_controller.gdc`, and `ad_manager.gdc`. Packaging was therefore not the missing link.

The broken runtime path was silent and startup-fragile: the Java plugin acquired Firebase eagerly during plugin construction, while GDScript returned with no log or acknowledgement whenever the singleton/method was unavailable. A Godot Activity ordering failure could prevent the custom bridge from becoming usable while Firebase automatic collection continued through its provider. There was no diagnostic evidence capable of distinguishing or recovering from that state.

Two ad hooks were also semantically early: `rewarded_ad_shown` and `interstitial_shown` were requested before `ad.show()` instead of from the SDK shown callback. Retry began a new playable run without emitting `level_start`. Gameplay schemas omitted several requested parameters.

## Implementation

- `Analytics` is confirmed in `[autoload]` as `*res://scripts/services/analytics_service.gd`.
- The facade logs event request, service state, native-plugin state, and acknowledged sent/rejected status. It validates event/parameter names and removes non-primitive values.
- Native `logEvent` returns a boolean, logs bridge initialization/forwarding/errors, and lazily retries Firebase acquisition after Activity startup.
- `GameController` adds per-run start/end guards. Level Ready and Retry emit one start; accepted result IDs emit merge; authoritative target progression emits target completion; win qualification and danger failure emit one mutually guarded end event.
- Level parameters now include the requested level number, generated pattern, mapped identity/local type, target involvement/index, coins earned where already available, and fail reason.
- Ad shown events now come from `on_ad_showed_full_screen_content` with per-session guards. Rewarded completion remains only in the accepted earned-reward callback.

## Branding scope

The supplied opaque root PNG was moved to `assets/logo/majestic_gems_logo_with_background_source_v5.png`. It replaces the removed opaque v3 presentation reference and generated the v5 legacy/adaptive launcher assets plus v6 native splash. The transparent Home/fallback source and `majestic_gems_logo_v4.png` were not modified.

## Validation

- Godot 4.6.3 editor parse/import: PASS.
- `FIREBASE_ANALYTICS_PIPELINE_TESTS`: PASS. It exercises actual controller Level Ready, Retry, confirmed merge-result, target, win, and danger-fail boundaries and verifies duplicate guards and schemas.
- `ADMOB_INTEGRATION_TESTS`: PASS after exercising shown callbacks and exactly-once earned reward analytics.
- Gradle `compileStandardReleaseJavaWithJavac`: PASS.
- Branding derivative generation: `MAJESTIC_GEMS_LAUNCHER_V5: PASS`.

## Release artifact and device status

Release identity is versionCode 12 / versionName 1.0.10. Code 11 / 1.0.9 is deliberately skipped because an older local AAB already used that pair, although the latest delivered AAB record was code 10 / 1.0.8.

Final AAB details, Bundletool/manifest/package/signing/archive validation, latest-script proof, ADB status, and DebugView status are recorded after export below.

<!-- FINAL_AAB_EVIDENCE -->
