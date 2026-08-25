# Complete Majestic Logo Refresh v1.0.8

The Android system splash had still referenced `majestic_gems_system_splash_1152_v2.png`, a derivative of the previous supplied icon. This release replaces it with `assets/runtime/ui/majestic_gems_system_splash_1152_v3.png`, generated directly from `assets/logo/majestic_gems_logo_source_v2.png`.

`AssetCatalog.BRAND_LOGO` and the project fallback boot splash now use `assets/runtime/ui/majestic_gems_logo_v2.png`. The launcher continues using its v2 legacy/adaptive derivatives. The old v1 Majestic source/logo/launcher/adaptive assets and the old splash-v2 derivative were deleted. No active project code or configuration references them.

`BRANDING_PUSH_LINE_TESTS` and `GAME_FLOW_REWARD_SPLASH_TESTS` passed. The signed AAB `build/android/majestic-gems-logo-refresh-v1.0.8-vc10.aab` is versionCode 10 / versionName 1.0.8. Bundletool validation passed; its archive contains the v3 splash asset and zero old Majestic v1 or splash-v2 entries. No Android device was connected.
