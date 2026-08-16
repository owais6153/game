# Responsive UI + Scale Test Report

Date: 2026-08-16  
Scope: gameplay-screen composition, responsive table geometry, L1-L8 size readability, and TEST APK only.

## Reference interpretation

The supplied image establishes a clear hierarchy: compact Coins at upper left, the current Target centered and largest, Next plus Settings at upper right, a centered dominant table, and the complete eight-tier path at the bottom. Existing Majestic Gems backgrounds, table art, gem art, glass controls, and icon mappings were reused. No new theme or copied reference artwork was introduced.

## Delivered layout

- One top safe-area row: Coins / Target / Next + Settings.
- Equal 184-design-pixel left/right slots keep the 304-pixel Target card centered even when card content reaches its intrinsic minimum size.
- The separate Level box and its runtime update path are removed.
- All eight mapped path gems remain ordered and visible in a 580×72 centered bottom-safe panel.
- Target/Next/path textures still resolve through `AssetCatalog`; HUD state still reads controller snapshots only.

## Table and board geometry

Before this milestone, the table texture used center `(360,846)`, render scale `(0.7826087,1.1802469)`, board y `416..1228`, and rails `178..542` at the back / `44..676` at the front. It was bottom-offset without scaling on added portrait height.

The new 720×1280 base uses outer table y `360..1145`, texture center `(360,752.5)`, render scale `(0.7391304,0.9691358)`, board y `400..1070`, rails `188..532` at the back / `62..658` at the front, danger y `920`, and launch y `1002`. On additional portrait height, the table receives 40% of the extra height as top offset and a bounded vertical scale up to 1.22×. At 720×1600, outer table y is approximately `488..1446`.

The same transform feeds artwork, table rails, board bounds, launcher, drag clamp, danger line, containment, and perspective interpolation. Artwork still does not define collision geometry.

## Gem scale calibration

| Tier | Before radius | Delivered radius | L1-relative |
| --- | ---: | ---: | ---: |
| L1 | 30 px | 36 px | 1.000× |
| L2 | 33 px | 39 px | 1.083× |
| L3 | 36 px | 42 px | 1.167× |
| L4 | 39 px | 45 px | 1.250× |
| L5 | 42 px | 48 px | 1.333× |
| L6 | 45 px | 51 px | 1.417× |
| L7 | 48 px | 54 px | 1.500× |
| L8 | 51 px | 57 px | 1.583× |

Safe range for this milestone is the delivered monotonic three-pixel ladder with a 36 px minimum and 57 px maximum. `GameConfig.GEM_COLLISION_RADIUS` remains authoritative for both alpha-trimmed visual diameter and the simple circular collider.

## Validation

- Whole-project Godot 4.6.3 editor import/parse: PASS, exit 0. Windows root-certificate/editor-settings warnings are environment-only.
- `UI_SCALE_LAYOUT_TESTS`: PASS marker for 576×1312, 720×1280, 720×1440, 720×1560, 720×1600, 1080×1920, 1080×2340, and 1080×2400 with simulated 88 px top / 104 px bottom cutouts.
- The focused suite verifies Target and path centering, non-overlap, horizontal bounds, bottom-safe clearance, Level removal, Target/Next texture resolution, all eight path icons, responsive table limits, and exact L1-L8 radii.
- `BRANDING_PUSH_LINE_TESTS`: PASS marker.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS marker.
- `ADMOB_INTEGRATION_TESTS`: PASS marker before the known late mock rewarded-loader callback during Windows teardown.
- Headless script suites return the known Windows post-PASS exit 1 because the sandbox cannot read the system root-certificate store; success claims are based on their explicit PASS markers and absence of assertion failures.

The optional off-screen bitmap capture was attempted but the headless GL renderer did not complete within the diagnostic window and was terminated. No visual-capture success is claimed. Multi-viewport geometry and live HUD-tree assertions are the recorded responsive evidence.

## Frozen behavior

Merge eligibility and rules, launch/movement timing, target quantities/order, score and progression authority, rewards, result flow, audio/haptics, ads/UMP, and animation sequencing were not changed. Aim-guide width/opacity and danger-warning opacity changed only as presentation values.

## TEST APK

- File: `build/android/majestic-gems-ui-scale-test.apk`
- Source: `60448dd` / `responsive-ui-scale-test-v1-source`
- Size: 85,220,655 bytes (81.27 MiB)
- Timestamp: 2026-08-16T04:58:33.6326764+05:00
- SHA-256: `12F5BE9848C9982A92B40A1C2FE589BEB7094C5385DA254EF7606305A4578DFB`
- Identity: `com.owais.majestygems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36, debug build.
- Native payload: arm64-v8a and armeabi-v7a, each with matching Godot and C++ shared libraries.
- Signature: APK Signature Scheme v2 PASS, one RSA-2048 Godot debug signer.
- Export status: log reached `[DONE] export`; stable final APK confirmed. The silent outer wrapper was stopped after no Godot/Java/Gradle process remained, so outer exit 0 is not claimed.
- Preset safety: the production AAB output/format was restored exactly after export; no AAB was generated for this task and production signing was not changed.
- Device status: ADB timed out and the exact spawned process was stopped. No installation, launch, performance, or physical-device visual validation is claimed.
