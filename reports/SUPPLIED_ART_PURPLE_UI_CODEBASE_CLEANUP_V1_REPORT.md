# Supplied Art, Purple UI, and Codebase Cleanup V1 Report

Date: 2026-08-24

## Outcome

The newly supplied set is active: 10 portrait backgrounds, 10 transparent portrait tables, and 20 gem identities. All player-facing gem names are removed. The HUD, Home, Level Ready, Pause, Settings, and Result surfaces now use the supplied reference's dark-amethyst glass language while retaining their existing dimensions and anchors.

## Asset preparation

| Family | Preserved originals | Runtime derivatives | Processing |
| --- | --- | --- | --- |
| Backgrounds | `assets/backgrounds/background_01.png` through `background_10.png`; 941x1672; 15,615,550 bytes | `assets/runtime/backgrounds/scene_bg_01.webp` through `scene_bg_10.webp`; 720x1280; 304,358 bytes | Lanczos resize, WebP quality 0.84 |
| Tables | `assets/tables/table_01.png` through `table_10.png`; 941x1672 RGBA; 12,840,571 bytes | `assets/runtime/tables/table_01.webp` through `table_10.webp`; full 720x1280 RGBA composition; 1,137,804 bytes | Lanczos resize, lossless-alpha WebP quality 0.92 |
| Gems | `assets/gems/gem_01.png` through `gem_20.png`; 1254x1254 RGBA; 23,718,056 bytes | `assets/runtime/gems/gem_01.png` through `gem_20.png`; 255-256 by 248-256; 1,785,487 bytes | Alpha threshold 0.01, exact visible-bounds crop, longest edge 256, Lanczos resize, low-alpha clearing |
| Settings icon | `assets/ui/icons/cog_blue_crisp.png` | `assets/runtime/ui/icons/cog_lavender_crisp.png` | Alpha-preserving amethyst tint |

`scripts/dev/prepare_supplied_art_refresh.gd` is the single reproducible preparation path. `assets/runtime/art_refresh_manifest.json` records source/runtime sizes, alpha rectangles, and SHA-256 values. Its final SHA-256 is `8DC315D84298CA72E4F3A45F5C77AE45CA99647447B425129DD0C38B2BB2D5AE`.

Every runtime gem's used-alpha rectangle is exactly its complete image rectangle; there is no transparent border. The unmodified originals remain available for future reprocessing and are excluded from Android packaging.

## Table and physics calibration

The supplied table alpha bounds and bright rail edges were measured before changing geometry. Rendering and physics still read the same centralized `GameConfig` model.

| Geometry | Before | After |
| --- | ---: | ---: |
| Table outer top / bottom | 400 / 1185 | 420 / 1215 |
| Table texture canvas | 920x810 | 720x1280 |
| Table texture center | (360, 792.5) | (360, 844) |
| Table render scale | (0.7391304, 0.9691358) | (0.9583333, 0.752) |
| Board top / bottom | 440 / 1110 | 455 / 1165 |
| Back inner rails | 188 / 532 | 130 / 590 |
| Front inner rails | 62 / 658 | 54 / 666 |
| Danger / launcher Y | 960 / 1042 | 1015 / 1095 |

L1-L8 collider radii remain exactly 36, 39, 42, 45, 48, 51, 54, and 57 pixels. No movement, merge eligibility, scoring, target, queue, collision-response, audio, or reward behavior changed. The updated regression scans all 10 runtime table rows at the back and front physics anchors and proves each collider rail remains just inside visible table art.

## UI and naming

- Dark purple translucent panels, amethyst borders, lavender/white text, purple progress fills, purple buttons/switches, deep-purple outlines, and lavender utility icons replace the previous light cyan/cream treatment.
- Existing panel sizes, margins, anchors, safe-area behavior, touch targets, and HUD ordering are unchanged.
- `TargetName` was removed from the gameplay HUD, Level Ready now says `MERGE TARGET x N`, catalog display names are empty, and UI code no longer reads a gem name.
- Internal stable identifiers remain generic (`gem_01` through `gem_20`) for data/debugging only.

## Repository cleanup

- Scripts are grouped into `scripts/core`, `scripts/gameplay`, `scripts/presentation`, `scripts/ui`, `scripts/services`, and `scripts/dev`.
- Removed unused `hud_renderer.gd` and `gem_visuals.gd`.
- Removed the broken old `tests/prepare_regenerated_scene_assets.gd` pipeline.
- Removed the retired `assets/source` tree, `assets/runtime/gems18`, runtime backgrounds 11-19, the unused vibration icon, and ten superseded runtime audio files. Supplied audio originals remain under `assets/sound`.
- Replaced upload-style filenames with stable numbered names in their semantic source folders.
- `assets/runtime` remains intentionally: it is the package-ready derivative boundary, not a second source library. Unlike the retired normalized table set, current runtime tables preserve the same full portrait composition as the new originals.

Deleted tracked material remains recoverable from Git history. Local ignored historical reference recordings were not deleted because reports still cite them and they belong to the user, not the shipped game.

## Validation

- `SUPPLIED_ART_REFRESH_PREPARATION: PASS`.
- All nine repository suites printed PASS: scene variety/assets, UI scale/layout, game flow/reward/splash, reward feedback V3, reference game feel V2, animation/audio/back/privacy, sound/privacy, AdMob integration, and branding/push-line.
- Godot 4.6.3 on this Windows host exits several completed headless scripts with its known access-violation code after printing PASS; assertions completed before that native shutdown fault.
- GL Compatibility/ANGLE capture: PASS, six reviewed gameplay PNGs at 720x1280 and 720x1600 under `reports/supplied-art-purple-ui-cleanup-v1/screenshots/` for tables 01, 05, and 10. Edge-proof gems remain contained against the calibrated rails.
- APK and device validation: `build/android/majestic-gems-supplied-art-purple-ui-cleanup-v1.apk`, 81,183,723 bytes, SHA-256 `855E7F27D9EF57A5E90CF77B57331FC3CEEEC105C84F9CF47C0874A2A0CC4F7B`; AAPT versionCode 7/versionName 1.0.5, v2 signature PASS, dual ARM PASS, 20 runtime gems present, source/tests/reports/retired assets absent; ADB found no connected device

Source milestone: `a2d8372` / `supplied-art-purple-ui-cleanup-v1-source`. Final delivery tag: `supplied-art-purple-ui-cleanup-v1`.
