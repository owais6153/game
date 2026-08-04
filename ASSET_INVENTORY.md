# Asset Inventory — Background, Table, and Gems v1

## Production gameplay parity coin v1

| Purpose | Preserved supplied source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| HUD and animated reward coin | `assets/buttons/ChatGPT Image Aug 4, 2026, 07_10_27 AM.png` (1024 x 1536 ARGB) | `assets/runtime/effects/coin_reward.png` (256 x 256 ARGB) | Alpha-visible bounds measured as source x `178..846`, y `382..1022`; square crop x `130`, y `320`, side `765`, then high-quality bicubic resize. Original is untouched. |

`AssetCatalog.COIN_REWARD` is the only runtime mapping. `CoinIcon` and `GameplayEffectsLayer` share `CoinVisuals`; neither artwork nor alpha bounds affect currency, collision geometry, merge eligibility, or table layout. Evidence PNGs under `reports/production-gameplay-parity-final-v1/` are development-only and excluded from Android export.

## Production gameplay parity coin v1

| Purpose | Preserved supplied source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| HUD and animated reward coin | `assets/buttons/ChatGPT Image Aug 4, 2026, 07_10_27 AM.png` (1024 x 1536 ARGB) | `assets/runtime/effects/coin_reward.png` (256 x 256 ARGB) | Alpha-visible bounds measured as source x `178..846`, y `382..1022`; square crop x `130`, y `320`, side `765`, then high-quality bicubic resize. Original is untouched. |

`AssetCatalog.COIN_REWARD` is the only runtime mapping. `CoinIcon` and `GameplayEffectsLayer` share `CoinVisuals`; neither artwork nor alpha bounds affect currency, collision geometry, merge eligibility, or table layout. Evidence PNGs under `reports/production-gameplay-parity-final-v1/` are development-only and excluded from Android export.

## Production UI polish v4

No production raster asset was added, regenerated, or destructively modified. Source originals under `assets/gems/` remain untouched. Table sprites and all dynamic UI previews continue to resolve through `AssetCatalog.GEM_TIER_TEXTURES`, whose calibrated runtime textures are non-destructive alpha-trimmed derivatives of those originals.

The prior shape mismatch was not an asset mapping defect: circular progression `PanelContainer` frames visually replaced each gem's silhouette. Those frames were removed. MERGE PATH now displays the same aspect-preserved catalog textures used by `GemSpriteLayer`, NEXT, TARGET, target collection, and result art.

Pause/Win/Fail no longer depend on the ornamental white-panel NinePatch region for their outer composition. Their new cream/gold surfaces are cached `StyleBoxFlat` resources from `UiDesignSystem`; dynamic text and numbers remain native labels. The previous atlas/reference assets remain preserved and unchanged. PNG evidence under `reports/production-ui-polish-v4/` and the local walkthrough recording are development-only and excluded from Android export.

## Production UI simplification v3

No raster production asset changed. SCORE, NEXT, TARGET, LEVEL, and MERGE PATH now use native `PanelContainer`/`StyleBoxFlat` composition; the prior ornamental atlas headers are no longer used by these gameplay labels. `assets/buttons/Generated image 10.png` remains retained and still supplies the Settings control and any legacy/reference regions needed elsewhere.

The expanded eight-gem path and gem-only target use the existing `AssetCatalog` textures without derivatives or duplicate preview arrays. Evidence under `reports/production-ui-simplification-v3/` is development-only and excluded from Android export.

## Production UI corrective pass v2

No raster asset was added, regenerated, resized, or destructively edited. The correction retains `assets/buttons/Generated image 10.png` for the ornamental SCORE/NEXT/target headers, Settings icon, and outer panel framing; dynamic containment surfaces, level badge, merge-path panel, progress track, borders, and shadows are cached Godot `StyleBoxFlat` resources.

All gem images remain authoritative `AssetCatalog` textures in aspect-preserving slots. PNGs under `reports/production-ui-corrective-pass-v2/` are validation evidence only, covered by `reports/.gdignore`, and absent from the APK. No production asset mapping changed.

## Production UI finalization v1

The milestone inspected all six 941 x 1672 RGB UI reference compositions, both 1024 x 1536 ARGB button sheets, all active panel/icon regions, pause/win/fail sources, the complete 18-gem catalog, and the project font inventory. There is no bundled font file; production uses one cached emboldened `ThemeDB.fallback_font` variation.

No raster asset was generated or destructively edited. `assets/buttons/Generated image 10.png` remains the active UI atlas; scalable panel/header regions are composed with AtlasTexture and NinePatchRect, while dynamic labels/numbers remain Godot text. `assets/ui/Generated image 1 (3).png` through `Generated image 6.png`, including the previous pause/result compositions, remain preserved reference assets. All gem, table, background, and shadow assets are unchanged.

New reusable non-raster UI resources: `scenes/ui/GameplayHud.tscn`, `scenes/ui/ResultOverlay.tscn`, and `scripts/ui_design_system.gd`. Evidence images under `reports/production-ui-finalization-v1/` are development artifacts excluded from Android export.

## Isolated 18-gem chain v1

The user-selected source originals are preserved in `assets/gems/`. Their deterministic L1-L18 mapping, SHA-256 checksums, and source filenames are in `assets/runtime/gems18/source-gems-sha256.json`. Non-destructive alpha-trimmed derivatives are in `assets/runtime/gems18/tier_01.png` through `tier_18.png`, with bounds and crop details in `normalization_manifest.json`. The original Moonstone source has an opaque exterior; only its runtime derivative receives a circular body mask. Existing `gem_soft_shadow.png` remains a separate presentation-only layer.

For the motion smoothness fix, every 18-gem runtime derivative is additionally capped at a 256 px longest side after alpha trimming. This replaces only `assets/runtime/gems18/`; no supplied source asset was changed. These runtime textures are preloaded once by `AssetCatalog` and are never loaded, cropped, or resized during gameplay.

All source files below were supplied by the user in `assets/` and remain untouched. Runtime copies are intentionally separate in `assets/runtime/`.

| Source folder | Files | Format / dimensions | Alpha | This milestone |
| --- | --- | --- | --- | --- |
| `assets/bg` | 5 tropical compositions | PNG, 941×1672 | no | selected `ChatGPT Image Jul 29, 2026, 09_47_21 AM.png` as the portrait gameplay background; the other four are preserved for later art selection. |
| `assets/tables` | 4 coral-rail table variants | PNG, 1024×1536 | yes | selected `ChatGPT Image Jul 29, 2026, 09_52_25 AM (2).png`, the turquoise-surface variant, as the supplied playfield. |
| `assets/gems` | `Generated image 5 (1).png`, `6 (1).png`, `7.png`, `8.png`, `9.png` | PNG, 1024×1536 | yes | mapped in filename order to Pearl, Ruby, Emerald, Sapphire, Diamond. |
| `assets/logo` | 1 logo sheet | PNG, 1024×1536 | yes | deferred. |
| `assets/buttons` | 2 UI/button sheets | PNG, 1024×1536 | yes | deferred. |
| `assets/ui` | 6 screen/UI compositions | PNG, 941×1672 | no | deferred. |

## Derived runtime files

| Runtime file | Source | Processing | Intended use |
| --- | --- | --- | --- |
| `assets/runtime/backgrounds/tropical_beach.png` | selected background | unmodified copy | full-screen, aspect-preserving Sprite2D backdrop. |
| `assets/runtime/table/coral_table.png` | selected table | unmodified copy | centered Sprite2D table; physical rails use the matching authoritative trapezoid data in `GameConfig`. |
| `assets/runtime/gems/pearl.png` | `Generated image 5 (1).png` | trimmed transparent outer padding; longest side capped at 512 px | L1 Pearl. |
| `assets/runtime/gems/ruby.png` | `Generated image 6 (1).png` | trimmed transparent outer padding; longest side capped at 512 px | L2 Ruby. |
| `assets/runtime/gems/emerald.png` | `Generated image 7.png` | trimmed transparent outer padding; longest side capped at 512 px | L3 Emerald; its rectangular composition stays centered. |
| `assets/runtime/gems/sapphire.png` | `Generated image 8.png` | trimmed transparent outer padding; longest side capped at 512 px | L4 Sapphire. |
| `assets/runtime/gems/diamond.png` | `Generated image 9.png` | trimmed transparent outer padding, then a transparent diamond-silhouette mask removed the large outer/lower glow from the runtime copy | L5 Diamond. The source is not altered. |
| `assets/runtime/gems_calibrated/*.png` | corresponding `assets/runtime/gems/*.png` | alpha >=32 body bounds trimmed with a 2 px anti-alias rim | v1 calibrated live runtime sprites; source and prior runtime copies remain untouched. |
| `assets/runtime/table/coral_table_calibrated.png` | `assets/runtime/table/coral_table.png` | non-destructive projective correction that widens only the upper playfield | shallower table convergence for the tropical background camera. |

The supplied gem originals have genuine alpha at their corners. The runtime gems retain alpha; no checkerboard, gray plate, or opaque rectangular background is used. Godot imports use the project’s Android ETC2/ASTC support with alpha-border fixing and no mipmaps, appropriate for these compact mobile sprites.

## Table calibration

The table texture is a 1024×1536 transparent asset centered at `(360, 650)` in the fixed 720×1280 design canvas. Its visible inner rail anchors were measured and encoded once in `GameConfig`:

- top rail / inner surface: `y=224`, `x=90..630`
- bottom surface: `y=1080`, `x=0..720`
- side rails: linear interpolation between those anchors
- danger line: `y=926`, dynamically drawn from the same rail functions
- launcher: `y=1008`, horizontally clamped by the same rail functions

The renderer, launcher clamp, spawn point, bounds simulation, and danger-line drawing consume this one layout model. Calibrated simple gem radii are Pearl/Ruby/Sapphire `42 px`, Emerald `32 px`, and Diamond `33 px`; the art mapping remains presentation-only.
# Runtime visual derivative v2

- `assets/runtime/table/shallow_table.gdshader`: non-destructive runtime table-perspective correction. It expands upper texture rows without replacing `coral_table_calibrated.png` or any supplied table source.
- Gem source/runtime files are unchanged. `GEM_VISUAL_BODY_SCALE` supplies the final body-to-collider visual calibration at render time.

## 18-gem calibrated runtime derivatives v1

| Purpose | Preserved source/runtime input | Active runtime asset | Audit |
| --- | --- | --- | --- |
| L1-L18 solid gem body | `assets/gems/` originals and `assets/runtime/gems18/tier_*.png` normalization inputs | `assets/runtime/gems18/calibrated/tier_*.png` | Alpha threshold 128, one-pixel antialias padding, max 256px, no shadow/glow used for physics. |

`assets/runtime/gems18/calibrated/calibration_manifest.json` contains the measured visible-body bounds for all 18 tiers. The runtime copies are presentation-only; circle radii continue to live in `GameConfig`.

## New table + shadow separation v1

| Purpose | Preserved source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| Table | `assets/tables/ChatGPT Image Jul 29, 2026, 12_44_35 PM.png` | `assets/runtime/table/new_table_v1.png` | Newest table source; transparent trapezoid crop. |
| UI placement reference | `assets/ui/Generated image 1 (3).png` | none | Used only for normalized placement measurements. |
| Pearl/Ruby/Emerald/Sapphire/Diamond | `assets/runtime/gems_calibrated/*.png` | `assets/runtime/gems_body_v2/*.png` | Body-only crops/masks exclude lower baked shadows, halos, and outer sparkles. |
| Shadow | none | `assets/runtime/effects/gem_soft_shadow.png` | Independent low-opacity soft ellipse; excluded from physics. |

All sources remain intact. Live gameplay loads only the new body textures and never uses any shadow/glow pixels to set collision geometry.
# Video-verified gameplay HUD mapping v1

- `assets/buttons/Generated image 10.png`: SCORE `(632,358,360,232)`, NEXT `(632,610,360,400)`, GOAL blank red header `(46,428,530,142)`, GOAL blank cream body `(38,620,550,190)`, and settings cog `(276,832,180,180)` are sampled directly at runtime; the original is unchanged.
- `assets/ui/Generated image 3.png`: literal RESTART control `(321,1128,300,100)` is sampled directly at runtime at its native 3:1 aspect ratio; the opaque source original is unchanged and no derivative is created.
- Asset review found BACK arrows but no circular restart/refresh icon. BACK art is not mapped to restart behavior.
