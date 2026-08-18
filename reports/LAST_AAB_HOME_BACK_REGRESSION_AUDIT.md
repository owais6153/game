# Last-AAB Home and Android Back Regression Audit

Date: 2026-08-18

## Baseline reviewed

The last delivered release AAB is `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab`. Its prepared source commit/tag is `aa3a1e1` / `android-version-code-3-source`; delivery commit/tag is `735f81a` / `merge-sound-sync-v3-release-aab-vc3`. It shipped versionCode 3 and versionName 1.0.1.

At that baseline, Android export did not exclude `tween_composer/*`. `HomeOverlayLayer` already preloaded and instantiated `tween_composer.gd`, `tween_sequence_resource.gd`, `tween_step_collection_resource.gd`, and `tween_step_item_resource.gd` for the Home logo loop.

## Changes after the AAB

- `4b16285` prepared versionCode 4 / versionName 1.0.2 only.
- `1ef87a9` changed gameplay feedback, collision presentation, timing, audio hierarchy, and responsive containment; it did not change Home startup logic.
- `9f83eb7` added `tween_composer/*` to the Android exclusion filter while production Home still referenced it. Its package-size audit incorrectly described Tween Composer as unreferenced.
- `f2922c8` changed simulation/contact/game-feel behavior but not Home startup.
- `e65bc5f` and `159f9a8` attempted startup/Back repairs against source-level tests, but did not restore the missing Android Home dependency. Those tests ran from the repository, where Tween Composer remained available.

## Root causes

1. The exported APK omitted a runtime dependency required while `HomeOverlayLayer` was created. Gameplay HUD construction occurs before Home construction, so an Android-only Home creation failure leaves the game screen exposed with no Home or Level Ready UI.
2. `GameController` still marked Home as the navigation state without independently hiding the gameplay HUD. If Home presentation aborted, Back could treat the invisible screen as Home and quit.
3. Both `NOTIFICATION_WM_GO_BACK_REQUEST` and an Escape-style key event called the Back transition directly. Devices delivering both representations could apply one physical press twice: Playing -> Pause -> resume, or Level Ready -> Home -> exit.

## Fix

- Restored `tween_composer/*` to Android packaging, matching the last-AAB dependency boundary.
- Home now hides the gameplay HUD explicitly; it no longer relies only on overlay coverage.
- `HomeOverlayLayer.present()` establishes the visible, input-owning Home surface before snapshot and motion work.
- Both platform Back entry points now pass through a 350 ms monotonic debounce before the state-aware Back policy.
- Added regressions for hidden gameplay on Home, export dependency retention, and duplicate Back suppression.

No board, launcher, collision, merge, target, reward, progression, or ad-cadence rule changed.
