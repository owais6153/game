# Android Targeting and Launcher Branding v1.0.7

## Scope

This release changes Android targeting and launcher branding only. Gameplay, UI layout, portrait orientation, package name, signing, AdMob configuration, and unrelated Android settings remain unchanged.

## Persistent sources

- Gradle-template manifest: `android/build/src/main/AndroidManifest.xml`
- Godot Android preset: `export_presets.cfg`
- Project icon pointer: `project.godot`
- Supplied transparent source logo: `assets/logo/majestic_gems_logo_source_v2.png`
- Non-runtime presentation reference: `assets/logo/majestic_gems_logo_presentation_reference_v2.png`
- Legacy launcher icon: `assets/runtime/ui/majestic_gems_app_icon_192_v2.png`
- Adaptive foreground/background: `assets/runtime/ui/majestic_gems_adaptive_foreground_v2.png` and `assets/runtime/ui/majestic_gems_adaptive_background_v2.png`

The 1254x1254 source logo is preserved without redraw or crop. The deterministic preparation script crops only its transparent canvas bounds for placement, then centers the complete visible logo into a 192px legacy canvas and a 432px adaptive foreground. The 288px maximum adaptive artwork edge remains inside Android's conservative safe zone. The background is the existing dark-amethyst brand color `#1d0734`.

## Device targeting audit

Before this change, the final merged manifest was portrait, tablet-enabled, game-categorized, and had only the GLES feature requirement; it had no explicit touchscreen feature. It contained no `LEANBACK_LAUNCHER`, `android.software.leanback`, Automotive, Wear, or XR declaration. The absence of XR declarations means normal Android compatibility only; no XR support was opted into.

The persistent template now adds one feature: `android.hardware.touchscreen` with `android:required="true"`. It adds no device-size exclusions, TV launcher/banner, Automotive, Wear, or XR entry. Godot continues to inject the unchanged package, `android:screenOrientation="portrait"`, all four phone/tablet screen-support flags, app category, icon resource names, and existing AdMob application metadata during export.

## Final AAB verification

Bundletool 1.18.3 validation passed for `build/android/majestic-gems-android-targeting-icons-v1.0.7-vc9.aab`. Its final embedded manifest confirms package `com.owais.majestygems`, versionCode 9, versionName 1.0.7, min SDK 24, target/compile SDK 36, required touchscreen, `appCategory=game`, portrait activity, and the unchanged AdMob app ID. There are no Leanback, Automotive, Wear, or XR declarations. Android's adaptive `@mipmap/icon` resource is present; no separate round-icon resource is configured by Godot, and adaptive masks supply the launcher-shape compatibility.

The bundle contains both ARM ABI pairs and no root tests, reports, or dev scripts. `BRANDING_PUSH_LINE_TESTS` and `UI_SCALE_LAYOUT_TESTS` pass. The latter covers normal-phone, tall-phone, and tablet portrait layouts; stretch remains `canvas_items` plus `expand`, so no gameplay coordinate or physics change was introduced.

## Device limitation

`adb devices -l` found no Android device. The build succeeds and the merged manifest/resource configuration is verified, but installation, actual launcher icon appearance under OEM masks, portrait launch, touch gameplay, and AdMob behavior must be checked on a physical phone/tablet or Play-delivered install.
