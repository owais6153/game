# Android Device Compatibility V2

Date: 2026-08-14 (Asia/Karachi)

## Outcome

- Previous ABIs: `arm64-v8a` only.
- New ABIs: `arm64-v8a` and `armeabi-v7a`.
- `armeabi-v7a` is safely supported by every required native dependency in the generated release bundle.
- The previous arm64-only result was caused by `architectures/armeabi-v7a=false` in `export_presets.cfg`; Gradle correctly honored the preset's single enabled ABI.
- The compatibility change is limited to Android packaging and release version metadata. Gameplay, UI, assets, audio, economy, AdMob behavior, and UMP behavior are unchanged.

## Native dependency audit

The active Android export uses Godot 4.6.3, Poing AdMob v5.0.0 Ads/Core AARs, Google `ads-mobile-sdk:1.2.1`, Google UMP `4.0.0` transitively, and AndroidX dependencies. Optional Poing mediation adapter files are present in the repository but are not enabled by the export plugin and are not packaged.

Every Poing Android AAR in `addons/admob/android/bin` was inspected for `.so`/`jni` entries; none contains native code. The v1 AAB likewise contains only the Godot engine and C++ runtime native libraries. The installed Godot 4.6.3 release template contains both required libraries for both target ARM ABIs.

The generated v2 AAB contains exactly:

- `base/lib/arm64-v8a/libc++_shared.so` — 1,374,336 bytes
- `base/lib/arm64-v8a/libgodot_android.so` — 70,322,664 bytes
- `base/lib/armeabi-v7a/libc++_shared.so` — 963,028 bytes
- `base/lib/armeabi-v7a/libgodot_android.so` — 74,273,720 bytes

There is no unmatched native library and no required plugin `.so` missing from either ABI. `x86` and `x86_64` remain disabled because this release targets Android phones, not emulator compatibility.

## Google Play required features and other restrictions

Android `aapt` analysis of a bundletool-generated universal APK identifies Play's two required features:

1. `android.hardware.faketouch` — Android's default implied touch-input feature. The game requires pointer/touch-style drag and release input. Normal Android phones satisfy it; removing it would primarily broaden delivery to non-touch device categories without establishing a usable control scheme.
2. `android.hardware.screen.portrait` — implied by the launch activity's fixed portrait orientation. The game is deliberately designed around a portrait canvas and layout, so this is necessary.

The manifest separately requires OpenGL ES 3.0 (`android:glEsVersion="0x00030000"`). Godot 4's GL Compatibility renderer requires this graphics baseline, so it was not weakened. Other restrictions are minimum SDK 24, portrait orientation, and ARM phone ABIs. All four Android screen-size classes are enabled; no camera, GPS, telephony, Vulkan, XR, TV, or other hardware feature is explicitly required. No unnecessary phone restriction was found.

Intentional unsupported categories include Android versions below API 24, GLES 2-only hardware, x86/x86_64 devices, non-touch-only device classes, and devices that cannot support the portrait activity. These facts mean this update is a confirmed compatibility fix for otherwise-qualified 32-bit ARM devices, but it does not prove the cause for any of the three tester devices without their Play device-catalog exclusion reason and hardware details.

## Release artifact

- Package: `com.owais.majestygems`
- versionCode: `2`
- versionName: `1.0.1`
- Minimum SDK: 24
- Target/compile SDK: 36
- Build: Godot 4.6.3 Gradle release AAB, compressed native libraries
- Path: `D:\Owais\game\build\android\majestic-gems-closed-test-v2.aab`
- Size: 73,049,656 bytes (69.67 MiB)
- Modified: `2026-08-14T07:42:15.8111993+05:00`
- SHA-256: `E00DBBDDD3D19DA81450788B2DF18E062E01A24F33EE1AD3DEB43CA982B10B05`

## Verification

- Bundletool 1.18.3 `validate`: PASS, exit 0. It enumerated both ARM ABI library pairs.
- Bundletool manifest dump: PASS for package, versions, min/target/compile SDK, screen support, GLES 3.0, production AdMob App ID, and absence of `android:debuggable`.
- Release signature: PASS. `jarsigner` reported `jar verified`; the v2 certificate SHA-256 exactly matches v1 (`E3:BA:32:87:A5:0A:F4:AC:49:C0:7C:BC:B2:E4:F1:09:40:AD:51:96:42:CB:24:F2:1B:CF:85:6B:3F:3B:CE:14`), using the existing Teckvertex Labs RSA-2048 upload key.
- Production AdMob App ID: PASS (`ca-app-pub-4605895178658062~1516881747`).
- Packaged production interstitial selection: PASS (`ca-app-pub-4605895178658062/5792148613`).
- Packaged production rewarded selection: PASS (`ca-app-pub-4605895178658062/3277665917`).
- Production UMP: PASS. Packaged probe reports forced geography `0`, zero release test-device IDs, the privacy-policy URL is packaged, no runtime consent-reset call exists, and native `can_request_ads` remains in DEX.
- Google demo IDs: present only as dormant debug constants; packaged release-function probes select both production IDs.
- Focused AdMob regression: `ADMOB_INTEGRATION_TESTS: PASS` printed before the already-documented late Poing mock callback caused process exit 1.
- Connected-device status: `adb devices -l` returned no device. No install, Play split delivery, live consent, or production-ad impression is claimed.

The locally generated universal APK and `.apks` set were inspection-only outputs signed by bundletool's debug key. They are not release deliverables; the signed AAB above is the upload artifact.
