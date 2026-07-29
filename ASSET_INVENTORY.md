# Asset Inventory — Background, Table, and Gems v1

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

The supplied gem originals have genuine alpha at their corners. The runtime gems retain alpha; no checkerboard, gray plate, or opaque rectangular background is used. Godot imports use the project’s Android ETC2/ASTC support with alpha-border fixing and no mipmaps, appropriate for these compact mobile sprites.

## Table calibration

The table texture is a 1024×1536 transparent asset centered at `(360, 650)` in the fixed 720×1280 design canvas. Its visible inner rail anchors were measured and encoded once in `GameConfig`:

- top rail / inner surface: `y=224`, `x=129..594`
- bottom surface: `y=1080`, `x=0..720`
- side rails: linear interpolation between those anchors
- danger line: `y=926`, dynamically drawn from the same rail functions
- launcher: `y=1008`, horizontally clamped by the same rail functions

The renderer, launcher clamp, spawn point, bounds simulation, and danger-line drawing consume this one layout model. The gem collision radius remains the existing `42 px`; art never determines collision geometry.
