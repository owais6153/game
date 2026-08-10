# Majestic Gems Branding + Draggable Push Line v1

Source: `95745b83a0d1509250b35823a24a88903ac07667` / `majestic-gems-branding-push-line-v1-source`. Delivery tag: `majestic-gems-branding-push-line-v1`.

## Scope

This milestone integrates only the two supplied branding assets, removes or excludes inactive APK resources, and makes the existing ready-state vertical push line share the launcher's existing drag behavior. It does not retune or refactor gameplay.

## Branding implementation

- Preserved the exact supplied 1536×1024 transparent logo and 1254×1254 JPEG icon under `assets/logo/`.
- Home and fallback boot use an exact runtime copy of the logo with aspect-centered rendering.
- Generated one 192×192 legacy icon and a 432×432 adaptive pair. The complete supplied icon occupies 68% of each foreground canvas, inside the conservative inscribed mask-safe square; no source content is cropped.
- Android launcher, adaptive foreground/background, native system splash, project icon, and fallback boot paths now resolve to the new derivatives.

## Push-line interaction

- Before: a touch had to begin within `1.8 × gem radius`; the vertical line moved visually after gem dragging but could not start a drag.
- After: the visible line accepts touches within 28 design pixels per side and within its rendered vertical span.
- Both touch origins set the same `GameController.dragging` flag, call `move_active_to()`, use `GameConfig.launcher_drag_x()`, and release through `launch_active_piece()`.
- No raycast, trajectory prediction, collision body, score path, or alternate launcher lifecycle was added.

## APK asset audit

- Removed obsolete `AssetCatalog` preloads for the retired UI atlases and five-gem fallback textures; the active 18-gem cache remains authoritative.
- Explicitly excluded source/reference directories, tests/tools/reports/builds, retired UI atlases, inactive reference audio, old reward art, old branding, old five-gem textures, and unused root media/icon resources.
- The explicitly enumerated obsolete runtime files total 6,593,409 bytes before Godot import/compression. APK size is measured only after export.

## Validation

- Godot 4.6.3 headless import/editor parse: PASS.
- Focused `BRANDING_PUSH_LINE_TESTS`: PASS with a clean log. It checks logo/icon dimensions, transparent adaptive corners, conservative occupied bounds, guide hit bounds, and the shared launcher rail clamp.
- Actual main-scene headless launch with project autoloads: PASS.
- Historical clean-contact/gameplay-feel runners restored from before the repository's `Optimize` cleanup were attempted but are no longer compatible with the current source: they reference retired `AssetCatalog` constants and do not initialize the newer `GlobalTweens` autoload in script-runner mode. They are not reported as product failures or passing evidence.
- Standalone APK: `build/android/majestic-gems-branding-push-line-v1.apk`, 42,831,666 bytes, SHA-256 `1E27A1E54DCDE2A782E9536CE18006EA37D90D763B7630982A4AF08D5F25072B`.
- Size comparison: prior `gem-aim0.2.apk` was 60,517,648 bytes; final saved 17,685,982 bytes (29.22%).
- Package audit: 260 entries; `AndroidManifest.xml`, `classes.dex`, arm64 Godot runtime, legacy icon, adaptive foreground, and adaptive background are present; zero forbidden source/report/test/tool/retired asset paths.
- Signature audit: APK Signature Schemes v2/v3 PASS with one RSA-2048 debug signer. This is validation signing, not a store-release keystore claim.
- Device status: `adb devices -l` returned an empty device list. Installation, launcher mask appearance, Home logo appearance, touch behavior, and phone performance are not claimed.

## Manual device checklist

1. Confirm the launcher shows the complete icon, with no zoom/crop on the device's selected mask.
2. Confirm Home shows the complete logo without clipping.
3. Touch and slide the vertical push line left/right; verify the gem follows exactly and remains inside both rails.
4. Release from the line; verify one normal upward launch and one replacement launcher.
5. Verify direct gem dragging remains unchanged.
