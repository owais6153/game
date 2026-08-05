# Production UI motion + Restart restoration v1

Date: 2026-08-05

Delivery provenance: source `a1b214d` / `production-ui-motion-v1-source`; export record `3a27c83` / `production-ui-motion-v1-export-source`; final tag `production-ui-motion-v1`.

## Supplied-video review

Reviewed all 60.27 seconds of `WhatsApp Video 2026-08-05 at 4.39.25 AM.mp4` (576 x 1312, H.264, 23.96 fps) through 3-second whole-video and 1-second Restart-sequence contact sheets under `reports/production-ui-motion-v1/`.

Confirmed defects:

- Home exposed implementation copy: “8 RANDOM GEMS • A NEW PATH EVERY LEVEL” and “CURRENT JOURNEY”.
- The large journey card plus stacked Pause buttons made the flow read as static forms instead of a game lobby/modal.
- Home had entrance motion only and then became completely static.
- At 0:55 Home was selected, at 0:56 Continue restored play, at 0:57 Pause reopened, and at 0:58 Restart reset the table while leaving the entire gameplay HUD hidden through 0:59.

## Delivered behavior

- `GameController.restart()` explicitly restores `GameplayHudLayer` visibility before presentation reset and snapshot refresh. `_on_restart_requested()` no longer hides the HUD.
- Home removes the journey card and all random/infinite/internal copy. Level and Coins float directly over the tropical scene, Coins uses the production icon, and the one primary action remains explicit.
- After its entrance, the logo and Play/Continue action use a low-amplitude 2.7-second presentation-only loop. Dismiss kills the tween and restores neutral scale/rotation.
- Pause is reduced to one gem-accented card, a primary Resume action, and compact Restart/Home utilities.

## Scope protection

No simulation, merge eligibility, collider, launcher pacing, target qualification, reward integer, audio routing, generated level, persistence, or table geometry changed.

## Validation

- Parser/import: PASS with no script or parse errors.
- Restart/Level 1 flow: PASS, including visible HUD after Pause Restart.
- Production UI/safe-area/copy/motion: PASS across 576 x 1312, 720 x 1600, and 1080 x 2400.
- Real 720 x 1600 Compatibility/ANGLE Home/Pause/Result captures: PASS and visually reviewed.
- All seven regression suites: PASS. Motion profile retains zero per-gem process callbacks, zero runtime gameplay resource loads, and zero UI node delta.
- Standalone signed APK: `build/android/production-ui-motion-v1.apk`, 118,277,818 bytes, SHA-256 `5C8A938AF7815DB48DE7DC499D80D3F650F7FD1B35DBEC953E33490CC97DB947`.
- APK audit: 411 ZIP entries and zero packaged `.gd`, `reports/`, `build/`, or `.git/` paths.
- Device status: ADB reported no connected device; physical-device testing is not claimed.
