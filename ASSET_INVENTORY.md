# Asset Inventory — Background, Table, and Gems v1

## Reference scale contrast v1

No raster or audio asset changed. Frame comparison changed only code-owned geometry: the same existing alpha-trimmed L1-L8 textures now map to the `30/33/36/39/42/45/48/51 px` base-radius ladder. The target collection proxy uses the identical per-axis live-body mapping before its uniform presentation pop, so no new derivative or destructive resize is required.

## Merge animation revert and active-tier size calibration v1

No raster or audio asset changed. The preserved sources, alpha-trimmed runtime derivatives, and `calibration_manifest.json` mappings remain byte-for-byte unchanged. L1-L8 sizing is now a code-owned `36/38/40/42/44/46/48/50 px` base-radius ladder; `GemSpriteLayer` maps each already-trimmed body to that diameter while `GemPiece` uses the same value for its circle collider. Artwork, alpha bounds, shadows, and effects do not independently define physics.

## Reference animation and supplied-audio polish v4

| Purpose | Preserved source | Active runtime derivative | Audit |
| --- | --- | --- | --- |
| Target-only coin cue | `assets/sound/coin-sound.mp3` | `assets/runtime/audio/supplied_coin_reward_v4.ogg` | Source: 41,472 bytes, 1.30 s, SHA-256 `AF8A9EC4D8B718703980C28B58C851AACF515DA9FC1E2D90AC592D1295D0EF76`. Runtime: 25,523 bytes, 0.98 s, SHA-256 `B2008F0331507EBDCF4F5FC008EFE9DCF2FDCC64D4515C1A21E0D2746F1C501A`; leading silence trimmed non-destructively, 12 ms fade-in and 75 ms fade-out, Ogg quality 6, no gain/EQ/pitch change. |
| Continuous background music | `assets/sound/gem_merge_music_loop.wav` | `assets/runtime/audio/supplied_background_music_v4.ogg` | Source: 5,242,892 bytes, 29.72 s PCM16 stereo 44.1 kHz, SHA-256 `AF055BE7F2BFC356778B3D1343CB442B46FAE753070EF671F90DD6889789AB2C`. Runtime: 518,102 bytes, 29.72 s, SHA-256 `C214AE23E35B5A2BD5D9038C84E13FCF40CE759AA970D781243EB864C46BB86E`; full-duration Ogg quality 5, no trim/gain/EQ/pitch processing. |

Runtime measurements are coin mean/max `-27.5/-6.9 dBFS` and music mean/max `-15.5/-1.0 dBFS`. The music player applies linear `0.14` (about `-17.1 dB`) at runtime, giving an estimated played music mean/max near `-32.6/-18.1 dBFS` before device/bus effects. The two files remain separate: music loops independently and one coin cue is routed only by active-target qualification.


## Reference target reward correction v3

| Purpose | Preserved source | Runtime asset | Current status |
| --- | --- | --- | --- |
| Mixed music/reward derivative | `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`, input window `25.05-26.90 s` | `assets/runtime/audio/reference_music_loop.ogg` | Preserved but inactive. Production does not preload or play it because the source contains embedded reward audio. Separate clean music and coin files are required for reliable independent mixing. |
| Target-only animated coin | `assets/generated/reference_match_coin_source.png` | `assets/runtime/effects/coin_reward_reference_v2.png` | Active in HUD and exactly four target-qualified foreground reward records. Ordinary merges create zero coin records. |

The preserved reference recording SHA-256 remains `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`. No audio file was deleted or destructively modified in this correction.

## Reference audio and reward layering v2

| Purpose | Preserved source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| Retired mixed reference loop | `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`, input window `25.05-26.90 s` | `assets/runtime/audio/reference_music_loop.ogg` | `1.800 s`, mono 48 kHz, 21,001 bytes; SHA-256 `F6620082833E5481282320ADCEAAB23C6F92A5EE497C29A5C093684F2EC0428F`. The body uses `25.10-26.85 s`; the final 50 ms crossfades source tail `26.85-26.90 s` into head `25.05-25.10 s`. This historical v2 row is superseded above: the file is no longer active. |

The preserved recording hash remains `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`. The prior `reference_launch.ogg`, `reference_contact.ogg`, `reference_merge_reward.ogg`, `reference_target_reward.ogg`, and mixed loop remain recorded for provenance but are no longer preloaded or routed by production.

## Reference feedback match v1

| Purpose | Preserved source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| HUD and animated reward coin | `assets/generated/reference_match_coin_source.png` (built-in image generation; SHA-256 `8F9319B4090B3D1311A048125296446CF19752652C3313BBE5319B2ECFEADEFF`) | `assets/runtime/effects/coin_reward_reference_v2.png` (256 x 256 RGBA; SHA-256 `8D834D6B963EDA9AA3CF68259D345E5C70CB8FD561C2F77813C8DD57F29F88F5`) | Original simple gold/star-gem token generated on a chroma background; runtime copy was non-destructively keyed, square-cropped, Lanczos-resized, and alpha-validated. `assets/generated/.gdignore` keeps the 1,254 px source out of import/export. |
| Launch cue | `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`, 5.98-6.38 s | `assets/runtime/audio/reference_launch.ogg` | 0.400 s, mono 48 kHz, 8,110 bytes; no gain/EQ/pitch processing. |
| Contact cue | same supplied reference, 6.90-7.32 s | `assets/runtime/audio/reference_contact.ogg` | 0.420 s, mono 48 kHz, 8,605 bytes; no gain/EQ/pitch processing. |
| Second target reward (previously mislabeled ordinary) | same supplied reference, 46.55-48.45 s | `assets/runtime/audio/reference_merge_reward.ogg` | 1.900 s, mono 48 kHz, 25,771 bytes; preserved inactive derivative. Frame re-review confirms this sequence belongs to the second target event. |
| Target merge/reward | same supplied reference, 14.45-17.10 s | `assets/runtime/audio/reference_target_reward.ogg` | 2.650 s, mono 48 kHz, 32,215 bytes; one combined reference sequence aligns with result/target/coin presentation. |

The supplied reference recording is preserved unchanged at SHA-256 `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`. Ogg conversion changes only the container/codec needed for Godot playback; it does not normalize, synthesize, or remix the captured audio. All audio and coin assets are presentation-only and cannot affect simulation, currency, target qualification, or collision.

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
