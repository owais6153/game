# Majestic Branding Refresh v1.0.7

## Scope

The two supplied root PNGs were moved into `assets/logo/` as preserved v3 branding sources. The active Home/fallback logo, Android legacy launcher icon, adaptive foreground/background, and Android system-splash assets are regenerated from the new logo. The Home tagline is now exactly `A Majestic World of Gems`.

## Asset mapping

| Supplied source | Active derivative | Use |
| --- | --- | --- |
| `assets/logo/majestic_gems_logo_source_v3.png` | `assets/runtime/ui/majestic_gems_logo_v3.png` | Home and Godot fallback boot logo |
| same | `majestic_gems_app_icon_192_v3.png` | Project and legacy Android launcher icon |
| same | `majestic_gems_adaptive_foreground_v3.png` + `majestic_gems_adaptive_background_v3.png` | Android adaptive launcher icon |
| same | `majestic_gems_system_splash_1152_v4.png` | Android native system splash |
| `assets/logo/majestic_gems_logo_presentation_reference_v3.png` | preserved reference only | Source provenance |

The supplied logo has an opaque black studio background. The reproducible Godot preparation script removes fully black pixels only in the runtime derivative, preserving the supplied source unchanged. The old active v2 logo/icon/splash assets are removed.

## Guardrails

The Android package remains `com.owais.majestygems`; production signing and existing AdMob configuration are unchanged. No gameplay code, simulation, scoring, rewards, ads, or progression behavior is changed. The requested release identity remains versionCode `9` / versionName `1.0.7`.

## Validation

- `BRANDING_PUSH_LINE_TESTS`: passed.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: passed.
- Generated assets: RGBA logo `1448×1086`, legacy icon `192×192`, adaptive foreground/background `432×432`, system splash `1152×1152`.
- Fresh release-AAB, Bundletool, signing, manifest, and archive evidence will be appended after export.
