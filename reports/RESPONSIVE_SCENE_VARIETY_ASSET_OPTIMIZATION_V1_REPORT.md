# Responsive Scene Variety and Asset Optimization v1

Date: 2026-08-16

## Request and baseline

The requested visual hierarchy was table first, Target second, and merge path third, with more space above the table, larger Coins/Next cards, Next above Settings on the right, newly supplied random level backgrounds/tables, responsive behavior, organized assets, and aggressive safe APK optimization.

The task began from clean commit `4332013` / `target-path-hierarchy-fix-v1-verified`. The 19 untracked supplied backgrounds and 10 untracked supplied tables were preserved byte-for-byte in baseline commit `e9e3426`, tagged `responsive-scene-variety-baseline`, before integration.

## Delivered layout

- Moved the complete authoritative baseline table model down 20 design pixels: outer table `400..1185 -> 420..1205`, board `440..1110 -> 460..1130`, danger line `960 -> 980`, launcher `1042 -> 1062`, and texture center Y `792.5 -> 812.5`.
- Enlarged Coins and Next by exactly 12.5%: Coins `146x100 -> 164.25x112.5`; Next `114x100 -> 128.25x112.5`.
- Replaced the right utility HBox with a right-aligned VBox so Next is above Settings. Target and the complete merge path remain an independent centered stack above the table.
- Preserved the existing tall-screen table transform and safe-area calculations. Eight layout targets cover 576x1312 through notched 1080x2400.

No gem radius, collision, merge rule, launch speed, danger timing, target progression, queue, score/reward, audio/haptic, ad, or result-flow behavior changed.

## Scene variety and asset organization

- Preserved 19 original 941x1672 background PNGs under `assets/source/backgrounds/` and 10 original 1385x1136 alpha-table PNGs under `assets/source/tables/`.
- Generated 19 quality-82 720x1280 WebP backgrounds and 10 quality-90 alpha WebP tables on one 920x810 runtime canvas under `assets/runtime/`.
- Reduced the supplied 57.40 MiB set to a 2.93 MiB runtime set (94.90% reduction) and excluded the entire source tree from Android export.
- Tracked explicit Godot lossy import profiles at quality 0.85 for backgrounds and 0.92 for alpha tables. They reduce imported scene textures from 19.83 MiB to 3.12 MiB (84.27%) without reducing runtime dimensions.
- `LevelConfig.generated()` now produces bounded deterministic background/table indices. The same level seed produces the same pair on retry; 500-level coverage reaches every supplied variant.
- `GameController` swaps presentation textures only. All table art continues to consume the one centralized `GameConfig` geometry.

## Audited cleanup

Sixty-six dependency-audited unused files totaling 27.83 MiB were removed: retired backgrounds/table, reference-only audio and service, first-generation gem bodies, Crystal Magic/Gem Aim runtime branding, the old coin derivative, retired UI source, and unused SVG variants. Active Majestic Gems branding/provenance, production music and coin audio, calibrated gems/manifests, gem shadow, active icons, Android/AdMob dependencies, and both ARM ABIs remain.

## Validation

- Godot 4.6.3 project parse/import: PASS for all 29 WebP derivatives.
- `SCENE_VARIETY_ASSETS_TESTS`: PASS (catalog counts, dimensions, wrapping, bounds, retry stability, and all-variant coverage).
- `UI_SCALE_LAYOUT_TESTS`: PASS across eight portrait targets including narrow and simulated-notch layouts.
- `BRANDING_PUSH_LINE_TESTS`: PASS.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS.
- `ADMOB_INTEGRATION_TESTS`: printed PASS; its existing late mock callback still reports the known shutdown-only null callback afterward.
- `RESPONSIVE_SCENE_VARIETY_CAPTURE`: PASS using Godot 4.6.3 Compatibility/ANGLE.
- Refreshed all six ANGLE frames after applying the optimized import profiles; visual review found no accepted background, alpha-edge, or rail degradation.
- `git diff --check`: PASS.

Godot headless tests print their PASS sentinels but return code 1 after the Windows root-certificate-store warning in this environment. The new catalog test additionally produced one Windows shutdown access-violation code after PASS. Assertions and logs are recorded truthfully by their PASS sentinels; these post-quit environment codes are not represented as clean process exits.

## Reviewed render evidence

The six production captures under `reports/responsive-scene-variety/final-screenshots/` cover three deterministic background/table pairings at 720x1280 and 720x1600. Visual review confirms no panel overlap or clipping, clear Next-over-Settings ordering, readable Target/path hierarchy, adequate table separation, full-bleed background cover, and table rails aligned to the common playable geometry.

## Android delivery

Implementation source is `62bd4b8` / `responsive-scene-variety-v1-source`. The APK-size audit then found that Godot's default lossless WebP import expanded scene textures to 19.83 MiB; the tracked high-quality import correction is `081eb1c` / `responsive-scene-variety-v1-optimized-source`.

Final artifact: `build/android/majestic-gems-responsive-scene-variety-test.apk`, 81,986,750 bytes (78.19 MiB), SHA-256 `22A7F145E45EF306F79BD8FFB873455D09D3DD2C2F87177E344E0CEC82DA8249`. It is 17,480,832 bytes (17.57%) smaller than the diagnostic default-import export and 3,234,765 bytes (3.80%) smaller than the previous 85,221,515-byte hierarchy APK despite increasing active scene art from five backgrounds/one table to 19 backgrounds/10 tables.

The optimized export log reached `[DONE] export`; Godot's outer process stayed silent until the wrapper timeout, so a clean outer exit is not claimed. Exact export-owned Godot/Java processes were stopped and a follow-up process check found zero remaining. The existing release preset was restored to AAB output and no AAB was generated.

AAPT confirms `com.owais.majestygems`, `Majestic Gems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36, GLES 3.0, portrait, and faketouch. APK Signature Scheme v2 verification passes with the Godot debug RSA-2048 signer. ZIP audit confirms 972 entries, one Android manifest, both `arm64-v8a` and `armeabi-v7a` with matching Godot/C++ libraries, all 19 background imports, all 10 table imports, and zero scoped source/report/test/retired-asset entries.

`adb devices -l` did not return within the validation window; the exact spawned ADB process was terminated and no ADB process remained. Installation, launch, physical safe-area/touch behavior, and phone performance are not claimed.
