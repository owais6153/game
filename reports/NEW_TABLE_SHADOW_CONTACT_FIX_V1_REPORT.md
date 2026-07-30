# New Table + Shadow-Separation Contact Fix v1

## Baseline

- Starting commit/tag: `e6ddc99` / `visual-sequencing-contact-v2`.
- Working tree was clean before this scoped milestone.
- Scope is limited to supplied-table replacement, visual/body calibration, separate shadows, related tests, and documentation. Merge, score, queue, launcher, and outcome logic are unchanged.

## Selected assets and measurements

- New table source: `assets/tables/ChatGPT Image Jul 29, 2026, 12_44_35 PM.png`.
- UI composition reference: `assets/ui/Generated image 1 (3).png` (941x1672).
- Active table derivative: `assets/runtime/table/new_table_v1.png` (920x810), a non-destructive transparent crop of the supplied table.
- Normalized composition on the 720x1280 design canvas: table outer top/bottom `y=252..1208`; center `(360,730)`; render scale `(0.782609,1.180247)`.
- Measured authoritative inner rails: top `x=178..542` at `y=300`; bottom `x=44..676` at `y=1112`. Danger line is `y=930`; launcher is `y=1028`.

## Body/shadow audit and calibration

| Gem | Source body issue | Active clean body | Collider | Shadow offset / opacity |
| --- | --- | --- | ---: | --- |
| Pearl | large lower baked shadow and sparkles | `gems_body_v2/pearl.png` | 42 px circle | `(5,23)` / 0.42 |
| Ruby | lower baked shadow and rim sparkle | `gems_body_v2/ruby.png` | 42 px circle | `(5,23)` / 0.40 |
| Emerald | lower baked shadow and side sparkle | `gems_body_v2/emerald.png` | 32 px circle | `(4,18)` / 0.38 |
| Sapphire | lower baked shadow, glow, and sparkles | `gems_body_v2/sapphire.png` | 42 px circle | `(5,23)` / 0.40 |
| Diamond | lower halo/shadow and decorative sparkle | `gems_body_v2/diamond.png` | 33 px circle | `(4,19)` / 0.34 |

Clean bodies use a 1.0 body-to-collider render scale. The previous `0.20 px` contact epsilon and `0.02 px` separation epsilon remain unchanged. At 1080x1920 (1.5x design scale), physical contact is therefore calibrated to the body edge within the 2–4 px acceptance band.

## Implementation

- `AssetCatalog` now loads the new table and body-only runtime gem textures.
- `GemSpriteLayer` creates a separate `gem_soft_shadow.png` Sprite2D for each live gem. Shadows are low-opacity, offset, and scaled independently; no shadow value reaches simulation or merging.
- `GameConfig` is the only authority for the new table render scale, rails, launch/danger geometry, body scale, and shadow presentation values.
- Contact/wall sounds continue to route only from confirmed narrow-phase impacts. Shadow overlap cannot emit audio.
- F8 debug adds cyan shadow bounds alongside the existing magenta rails, yellow colliders, and pink contact points. It remains disabled by default.

## Automated validation

- Godot 4.6.3 headless import/parse validation: passed.
- `tools/run_clean_contact_tests.gd`: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Added checks for the active new table, old-table exclusion, normalized table scale, runtime shadow asset, and shadow-overlap non-merge behavior.

## Manual phone checklist

1. Compare empty-board table placement to `Generated image 1 (3).png`.
2. Slowly approach Pearl/Pearl: shadows may overlap first, but no collision/sound/merge occurs until bodies touch.
3. Confirm Ruby/Ruby merges, Pearl/Ruby pushes without merge, and Emerald/Diamond remain stable.
4. Check Diamond against top/side rails for visible body contact.
5. Confirm direct and chain merges still work; create Diamond and ensure it appears before the win overlay.
6. Check 16:9, 19.5:9, and tall portrait phones; F8 diagnostics are desktop/editor-only.

## Delivery

- APK: `D:\Owais\game\build\android\new-table-shadow-contact-fix-v1.apk`
- Size: 76,113,263 bytes
- Built: 2026-07-29 13:05:58 +05:00
- SHA-256: `713E25E53E10B36AFA88BB83C1CB3183A11CFA120B6493A1AEE57F29E2B41E19`
- Source commit/tag: `0b562d5b85b0b4d0330ecd10da3f832408949ad9` / `new-table-shadow-contact-fix-v1`
- Device status: `adb devices -l` found no attached device; no install or launch is claimed.
