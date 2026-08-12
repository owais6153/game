# Poing UMP `canRequestAds()` Local Maintenance Patch

Date: 2026-08-12 (Asia/Karachi)

## Scope

This is a **LOCAL MAINTENANCE PATCH** against Poing Studios Godot AdMob v5.0.0. It adds only the missing Android bridge call required to expose Google UMP's authoritative `ConsentInformation.canRequestAds()` result to GDScript. Poing, Godot, the Google Mobile Ads dependency, package ID, ad units, ad cadence, reward logic, and gameplay systems were not replaced or retuned.

- Godot: `4.6.3.stable.official.7d41c59c4`
- Poing plugin: `v5.0.0`, upstream commit `a2d7a243a9362a4ee2c9f7bdeb6d680707334a86`
- Android Ads dependency: `com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.2.1`
- Package: `com.owais.majestygems`

## Exact bridge patch

Native class modified in the exact Poing v5.0.0 source tree:

`platforms/android/src/ads/src/main/java/com/poingstudios/godot/admob/ads/PoingGodotAdMobConsentInformation.kt`

Method exposed:

```kotlin
@UsedByGodot
fun can_request_ads() : Boolean{
    return UserMessagingPlatform.getConsentInformation(aActivity).canRequestAds()
}
```

The permanent, reviewable source delta is `patches/poing-admob-v5.0.0-can-request-ads.patch`. The existing wrapper `addons/admob/gdscript/src/ump/api/ConsentInformation.gd` now provides `can_request_ads()` and returns `false` when no native plugin exists. No duplicate consent abstraction was added.

## Rebuilt native artifacts

Poing's v5.0.0 Android project was compiled with JDK 17, its Gradle 9.6.1 wrapper/AGP 9.3.0 setup, the unchanged `ads-mobile-sdk:1.2.1` dependency, and this project's Godot 4.6.3 release AAR as the compile library. `:src:ads:assembleDebug` and `:src:ads:assembleRelease` completed successfully.

- `addons/admob/android/bin/ads/libs/poing-godot-admob-ads-debug.aar`
  - SHA-256: `D36A0431B019C2FA71D1298D889BF792D1291FA5FACD226E939D7F3373B71899`
- `addons/admob/android/bin/ads/libs/poing-godot-admob-ads-release.aar`
  - SHA-256: `9CB2D36A3DA8B76C06856FD10942B1D4DF7F670BB7E98860E6C05638123BE240`

`javap` confirms `public final boolean can_request_ads()` in the rebuilt release AAR. Final APK DEX inspection independently confirms the same method on `com.poingstudios.godot.admob.ads.PoingGodotAdMobConsentInformation`.

## Consent and ad-request flow

On Android, `AdManager` now performs one consent-information update at app launch. It loads and presents Poing's official Google UMP form only when consent status is `REQUIRED` and a form is available. It calls the patched authoritative `can_request_ads()` after:

- a successful consent-information update;
- a consent form dismissal or form error;
- a failed consent-information update;
- dismissal of the official privacy-options form.

The update-failure path intentionally checks `canRequestAds()` because Google UMP can retain a valid decision from an earlier session. If it returns `true`, the manager initializes Mobile Ads once and starts the existing interstitial/rewarded preloads. If it returns `false`, no ad is requested and the game remains usable. Consent callbacks cannot double-initialize or double-preload because `_ads_start_committed`, the existing initialization guards, per-format loading guards, and cached-ad guards share one start path.

If permission becomes unavailable after Privacy Options, cached ads are destroyed and later load/show paths remain gated. Active fullscreen ownership and the existing exactly-once rewarded callback remain unchanged.

Desktop/editor mock-ad tests bypass Android UMP while preserving the existing mock lifecycle. Android is the only platform using the native consent gate.

## Settings privacy actions

Home Settings and Pause Settings retain the existing UI theme and add:

- `PRIVACY POLICY`, which opens `https://teckvertexlabs.vercel.app/privacy/majestic-gems` in the external browser;
- `PRIVACY OPTIONS`, which is hidden unless UMP reports `PrivacyOptionsRequirementStatus.REQUIRED` and opens Poing's existing official Google privacy-options form.

No custom consent popup was created.

## UMP debug testing

Testing constants are centralized in `scripts/ad_config.gd` and default to disabled:

- `UMP_DEBUG_GEOGRAPHY_DISABLED = 0`
- `UMP_DEBUG_GEOGRAPHY_EEA = 1`
- `UMP_DEBUG_GEOGRAPHY_NOT_EEA = 2`
- `UMP_DEBUG_GEOGRAPHY = 0`
- `UMP_TEST_DEVICE_HASHED_IDS = []`

For a debug build on a physical test device, copy the hashed test-device ID printed by UMP into `UMP_TEST_DEVICE_HASHED_IDS`, then temporarily set `UMP_DEBUG_GEOGRAPHY` to `1` for consent-required EEA testing or `2` for not-EEA testing. Reset app data between first-install scenarios. Restore `0` after testing.

Release builds ignore forced geography and test-device IDs regardless of those constant values. No release build can enable this test forcing through `AdConfig`.

## Verification performed

- Poing native Android debug/release AAR build: PASS, Gradle exit 0.
- Rebuilt release AAR `javap`: PASS; `can_request_ads()` present.
- Godot 4.6.3 whole-project editor import/parse: PASS, exit 0.
- `ADMOB_INTEGRATION_TESTS: PASS` including wrapper presence, authoritative gate source, false/true prior-consent outcomes, release debug-geography guards, existing initialization/preload lifecycle, interstitial cadence, rewarded exact-once behavior, and Settings privacy actions. The known Windows runner exits nonzero after the PASS marker because of a late Poing mock callback.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`; known Windows post-PASS exit remains.
- `BRANDING_PUSH_LINE_TESTS: PASS`; known Windows post-PASS exit remains.
- APK package/min/target audit: `com.owais.majestygems`, min SDK 24, target SDK 36.
- APK DEX audit: patched `can_request_ads()` method present.
- APK payload: five DEX files and arm64-v8a Godot/C++ libraries only.
- APK signature: v2 PASS, one RSA-2048 Godot debug signer.
- Packaged debug ad units and privacy-policy URL: PASS.
- Connected-device status: `adb devices -l` returned no device. Installation, launch, live UMP rendering, live Google test ads, and lifecycle testing on a phone are not claimed.

## Debug APK

- Path: `build/android/ump-can-request-ads-patch-v1-debug.apk`
- Size: `53,376,732` bytes
- Modified: `2026-08-12T10:29:57.0991603+05:00`
- SHA-256: `DB2299C1E6F6C779D548A2CFC21833DF32B43353EFEF9324D1771288BF2686C6`
- Build type: Android debug, Godot debug-signed validation artifact

The stable APK and Gradle output APK were fully written. As documented on recent project exports, the outer Godot/Java processes remained alive after artifact creation and exceeded the command timeout; the two exact orphaned processes were stopped. Artifact, DEX, manifest, ABI, configuration, and signature audits passed, but a clean outer export-process exit is not claimed.

## Manual AdMob Configuration Required

- In AdMob Privacy & messaging, create/configure and publish the GDPR message for package `com.owais.majestygems` and the configured AdMob App ID.
- Add the published privacy-policy URL: `https://teckvertexlabs.vercel.app/privacy/majestic-gems`.
- Configure any applicable U.S. state-regulation message so UMP can require the Privacy Options entry point where appropriate.
- Review and select the correct consent ad partners, including every mediation partner if mediation is enabled later.
- Confirm the AdMob account/app maximum ad-content rating appropriate for the Play content rating and intended 13+ audience. No dashboard value was guessed or changed in code.
- Keep the app outside child-directed treatment unless the product/audience declaration changes; this patch does not globally mark it child-directed and adds no under-13 age gate.
- Replace the intentionally blank production interstitial/rewarded constants and use release signing before a store build.
- On a real device, verify EEA first-install consent, not-EEA no-popup behavior, offline first launch, update failure with prior valid consent, Privacy Options, interstitials after completed levels 2/4, rewarded success once, rewarded early close with zero bonus, and background/resume.

## Reapply or remove after a Poing upgrade

To reapply against v5.0.0: check out Poing tag `v5.0.0`, apply `patches/poing-admob-v5.0.0-can-request-ads.patch`, compile the `ads` debug/release AARs against the matching Godot library, replace only the two Poing Ads AARs, and retain the wrapper method. Verify the AAR and final APK DEX before delivery.

For a future Poing release, first check whether its native and GDScript `ConsentInformation` already expose `canRequestAds()`. If they do, remove this local patch and use the upstream method after compatibility testing. Do not blindly apply the patch to a different source version. To remove it from v5.0.0, reinstall the official v5.0.0 Ads AARs and remove the wrapper/app calls in the same change.

## Files changed

- `patches/poing-admob-v5.0.0-can-request-ads.patch`
- `addons/admob/android/bin/ads/libs/poing-godot-admob-ads-debug.aar`
- `addons/admob/android/bin/ads/libs/poing-godot-admob-ads-release.aar`
- `addons/admob/gdscript/src/ump/api/ConsentInformation.gd`
- `scripts/ad_config.gd`
- `scripts/ad_manager.gd`
- `scripts/game_controller.gd`
- `scripts/home_overlay_layer.gd`
- `scripts/gameplay_hud_layer.gd`
- `tests/run_admob_integration_tests.gd`
- central project documentation, build manifest, changelog, and reports index

## Known limitations

- No Android device was connected, so UMP forms and live Google ad callbacks require manual phone acceptance.
- Production ad-unit constants remain blank and the delivered APK is debug-signed.
- This maintenance patch is tied specifically to Poing v5.0.0 and must be reevaluated on upgrade.
