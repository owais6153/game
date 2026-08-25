# Firebase Analytics Android Integration v1.0.7

## Scope

Firebase Analytics is added to the persistent Godot Android custom-build template without changing the package name, signing, AdMob IDs, simulation, scoring, rewards, or ad cadence.

## Persistent implementation

- `android/build/settings.gradle` declares Google Services Gradle plugin `4.5.0`.
- `android/build/build.gradle` applies the plugin and adds Firebase BoM `34.18.0` plus `firebase-analytics`.
- The supplied root `google-services.json` matches `com.owais.majestygems`; a tracked module copy at `android/build/google-services.json` lets Google Services process the single-module Godot Gradle project.
- `FirebaseAnalyticsPlugin.java` exposes the native `FirebaseAnalytics` singleton. `scripts/services/analytics_service.gd` is the lightweight GDScript facade and stays a no-op where the Android singleton is unavailable.

## Event authority

| Event | Confirmed source |
| --- | --- |
| `level_start` | Player starts from the Level Ready/Home flow |
| `level_complete` | Final target win qualification |
| `level_fail` | Danger failure transition |
| `target_complete` | Target objective advances |
| `merge` | Merge result is accepted by the controller |
| `rewarded_ad_shown` | Rewarded fullscreen session commits |
| `rewarded_ad_completed` | AdMob reward callback grants an earned reward |
| `interstitial_shown` | Interstitial fullscreen session commits |

## Release and device status

- Play version selected: `9 (1.0.7)`, following the user's confirmation that Play's latest uploaded build is `8 (1.0.6)`.
- Godot 4.6.3 regenerated the asset pack, and the final AAB contains `assets/scripts/services/analytics_service.gdc`. Bundletool 1.18.3 validates its embedded base manifest: `com.owais.majestygems`, versionCode `9`, versionName `1.0.7`, existing AdMob application ID `ca-app-pub-4605895178658062~1516881747`, and Firebase Godot-plugin metadata. Firebase resources/dependency entries are present.
- Signing comparison: the first inspected direct-Gradle intermediate was unsigned because it did not receive Godot export credentials. The completed Godot export uses the existing ignored `.godot/export_credentials.cfg` and existing upload keystore. `jarsigner -verify -certs` reports `jar verified`; its SHA-256 certificate fingerprint is exactly the same as the last known signed v1.0.8 AAB: `E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`.
- Final AAB: `build/android/majestic-gems-firebase-analytics-v1.0.7-vc9.aab`; 69,468,298 bytes; SHA-256 `E70B8B5383D2B8D1DC4428127681643A677B1F7DC88CCEFD0F04C1A7E2F1AA5C`; 2026-08-25 22:33:29 +05:00.
- Delivery: the signed, Bundletool-validated AAB is delivered. Device DebugView verification is separately not performed: `adb devices -l` found no device in this session, so no installation, event invocation, or DebugView receipt is claimed.
- DebugView requires an Android device connected with USB debugging and Firebase debug mode enabled. A release AAB alone cannot prove event receipt.
