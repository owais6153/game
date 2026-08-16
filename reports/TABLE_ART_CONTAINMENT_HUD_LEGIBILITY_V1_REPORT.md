# Table-Art Containment and HUD Legibility v1

> Superseded on 2026-08-16 by `ORIGINAL_TABLE_RESTORE_V1_REPORT.md`. The user rejected this global multi-table width calibration; gameplay no longer uses its 1.15 factor or randomized table selection.

Date: 2026-08-16

## Request and diagnosis

The supplied gameplay screenshot showed legal gems and the danger line extending beyond the visible inner rails of a newly randomized table. Physics was explicitly required to remain unchanged. Coins also sat slightly lower than Next, Next needed modestly more emphasis, and gameplay text needed better visibility.

Review of all ten normalized 920x810 runtime tables found a presentation mismatch: their canvas sizes match, but their visible inner-rail widths do not. The previous common X scale (`0.7391304`) fit the former table footprint but was too narrow for the most tapered new designs.

## Delivered correction

- Added `GameConfig.TABLE_ART_HORIZONTAL_COVERAGE_SCALE = 1.15` and applied it only inside `table_texture_render_scale()`.
- Effective base table-art scale changed from `0.7391304 x 0.9691358` to `0.85 x 0.9691358`. The presentation gains 102 design pixels of width (`680 -> 782`) while retaining identical center and vertical placement.
- Preserved every physical landmark exactly: table outer `420..1205`, board `460..1130`, back rails `188..532`, front rails `62..658`, danger line `980`, and launcher `1062`.
- Top-aligned Coins with Next by changing only the Coins card's container alignment.
- Enlarged Next by 10%, from `128.25 x 112.5` to `141.075 x 123.75`; Settings remains immediately below it.
- Increased gameplay card headings, target progress, coin value scaling, and white outline contrast. Target remains substantially larger than Next.

No gem radius, perspective radius, solver coordinate, collision response, contact capture, launcher input/clamp, launch motion, merge eligibility, danger qualification/timing, target logic, score/reward, queue, sound/haptics, ads, or result flow changed.

## Regression coverage

`tests/run_ui_scale_layout_tests.gd` now freezes the complete pre-change physical geometry, asserts the art-only 1.15 coverage factor and unchanged vertical scale, checks Coins/Next top alignment, verifies the enlarged Next footprint and Target hierarchy, and guards the stronger coin/target outlines across eight portrait/cutout cases.

`tests/run_scene_variety_assets_tests.gd` continues to validate all ten table textures, normalized dimensions, wrapping, seeded retry stability, and generated-level coverage.

`tests/capture_table_art_containment_hud.gd` is a development-only visual harness. With controller processing disabled, it places proof gems exactly at legal rail limits and captures the three narrowest representative table styles at 720x1280 and 720x1600.

## Validation performed

- Godot 4.6.3 editor parse/import: PASS, clean exit 0.
- `UI_SCALE_LAYOUT_TESTS`: PASS sentinel.
- `SCENE_VARIETY_ASSETS_TESTS`: PASS sentinel.
- `BRANDING_PUSH_LINE_TESTS`: PASS sentinel.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS sentinel.
- `TABLE_ART_CONTAINMENT_HUD_CAPTURE`: PASS under Compatibility/ANGLE.
- `git diff --check`: PASS before documentation finalization.

The four scripted suites and capture process retain this Windows environment's documented post-PASS exit code 1 behavior; no failed assertion or script/runtime error preceded their PASS sentinels.

Reviewed evidence:

- [720x1280 table 02](table-art-containment-hud-legibility/final-screenshots/720x1280-table-02.png)
- [720x1280 table 05](table-art-containment-hud-legibility/final-screenshots/720x1280-table-05.png)
- [720x1280 table 08](table-art-containment-hud-legibility/final-screenshots/720x1280-table-08.png)
- [720x1600 table 02](table-art-containment-hud-legibility/final-screenshots/720x1600-table-02.png)
- [720x1600 table 05](table-art-containment-hud-legibility/final-screenshots/720x1600-table-05.png)
- [720x1600 table 08](table-art-containment-hud-legibility/final-screenshots/720x1600-table-08.png)

Every proof keeps the legal edge gems' visible bodies and the complete danger line inside the table playfield. Coins and Next share one top baseline, Next has the requested extra emphasis, Settings remains below it, and text contrast is visibly stronger.

## Android status

No APK or AAB was created or modified. This was intentional per the user's request to review the correction in Godot first. No installation or physical-device acceptance is claimed.
