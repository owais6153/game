# Asset Inventory — Background, Table, and Gems v1

## Isolated 18-gem chain v1

The user-selected source originals are preserved in `assets/gems/`. Their deterministic L1-L18 mapping, SHA-256 checksums, and source filenames are in `assets/runtime/gems18/source-gems-sha256.json`. Non-destructive alpha-trimmed derivatives are in `assets/runtime/gems18/tier_01.png` through `tier_18.png`, with bounds and crop details in `normalization_manifest.json`. The original Moonstone source has an opaque exterior; only its runtime derivative receives a circular body mask. Existing `gem_soft_shadow.png` remains a separate presentation-only layer.

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

## New table + shadow separation v1

| Purpose | Preserved source | Active runtime asset | Audit |
| --- | --- | --- | --- |
| Table | `assets/tables/ChatGPT Image Jul 29, 2026, 12_44_35 PM.png` | `assets/runtime/table/new_table_v1.png` | Newest table source; transparent trapezoid crop. |
| UI placement reference | `assets/ui/Generated image 1 (3).png` | none | Used only for normalized placement measurements. |
| Pearl/Ruby/Emerald/Sapphire/Diamond | `assets/runtime/gems_calibrated/*.png` | `assets/runtime/gems_body_v2/*.png` | Body-only crops/masks exclude lower baked shadows, halos, and outer sparkles. |
| Shadow | none | `assets/runtime/effects/gem_soft_shadow.png` | Independent low-opacity soft ellipse; excluded from physics. |

All sources remain intact. Live gameplay loads only the new body textures and never uses any shadow/glow pixels to set collision geometry.
