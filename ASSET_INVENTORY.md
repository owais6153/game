# Kit plate re-authoring - 2026-08-29

The runtime button/banner plates under `assets/runtime/ui/kit/` were regenerated from the same preserved slices at the exact design height each is drawn at, because these plates have no meaningful uniform vertical band (measured 2-5px) and therefore cannot be stretched vertically without smearing the rim and specular highlight.

| Plate | Authored size | Drawn at | Nine-patch margins (L,T,R,B) |
| --- | --- | --- | --- |
| `btn_hero_bright` | 650x116 | `HERO_BUTTON_HEIGHT` 116 | 72, 56, 72, 56 |
| `btn_pill_gem` / `_off` | 317x96 | `BUTTON_HEIGHT` 96 | 54, 46, 48, 46 |
| `btn_pill_plain` | 282x96 | `BUTTON_HEIGHT` 96 | 32, 46, 31, 46 |
| `btn_green` / `_off` | 242x96 | `BUTTON_HEIGHT` 96 | 40, 46, 40, 46 |
| `btn_pill_silver` | 360x96 | `BUTTON_HEIGHT` 96 | 52, 46, 51, 46 |
| `btn_square_small` | 78x76 | `ICON_BUTTON_SIZE` 76 | 20, 36, 20, 36 |
| `bar_gold_frame` | 679x92 | `BANNER_HEIGHT` 92 | 63, 44, 63, 44 |
| `banner_leaf` | 424x92 | `BANNER_HEIGHT` 92 | 84, 44, 85, 44 |

Horizontal margins were measured from the opaque silhouette (where the ornamental cap stops changing the outline), not from colour uniformity: the gloss is a smooth horizontal gradient that stretches cleanly, and a colour metric wrongly treats it as unstretchable. `btn_green_off` and `btn_pill_gem_off` are luma-desaturated derivatives of their plates, used for disabled states where a tint cannot remove green.

# Supplied UI art kit - 2026-08-29

Six supplied sheets (1448x1086 RGBA, transparent) plus the home-screen mockup are preserved under `assets/ui_kit_source/`. Runtime derivatives live in `assets/runtime/ui/kit/` and are the only versions loaded at runtime, via `scripts/ui/ui_kit.gd`.

| Purpose | Preserved source | Runtime derivatives | Processing / boundary |
| --- | --- | --- | --- |
| Button plates | `assets/ui_kit_source/sheet_buttons.png` | `btn_hero_bright`, `btn_hero_deep`, `btn_pill_plain`, `btn_green`, `btn_square_small`, `btn_square_swap`, `btn_pill_gem`, `btn_pill_gem_glow`, `btn_pill_silver` | Connected-component extraction (alpha > 0.30, 2px half-res dilation to bridge glow seams), alpha >= 0.02 trim, Lanczos downscale to <= 664px longest edge |
| Panels, bars, banners | `assets/ui_kit_source/sheet_panels.png` | `chip_coin`, `bar_gem_wide`, `tile_coin`, `bar_gem_row`, `card_leaf_cta`, `panel_banner_slots`, `bar_coin_progress`, `banner_leaf`, `bar_gold_frame` | Same extraction; nine-patch margins recorded in `UiKit.NINE` only for assets that may stretch |
| UI icons | `assets/ui_kit_source/sheet_icons.png` | `icon_gear`, `icon_gear_tile`, `icon_plus`, `icon_coin`, `icon_swap`, `icon_check`, `icon_star_coin`, `icon_shield_star`, `icon_sparkle`, `icon_gem_count` | Same extraction, 128px longest edge (224px for the gem-count pill) |
| Mission / reward badges | `assets/ui_kit_source/sheet_badges.png` | `badge_gems`, `badge_crown`, `badge_coinbag`, `badge_calendar`, `badge_flame`, `badge_chest`, `badge_timer`, `badge_medal`, `badge_check_laurel` | Fixed 3x3 grid slice then alpha trim; connected components merged these rows because the artwork touches vertically |
| Composition reference only | `assets/ui_kit_source/mockup_home_screen.png`, `sheet_gems.png` | none | Never loaded at runtime; the gem sheet is superseded by the existing `assets/runtime/gems/` catalog |

Nine-patch margins must stay below half the shortest height each asset is drawn at. Where top+bottom margins exceed the drawn height the unstretched caps overlap and the plate's rim visibly crushes; button verticals are therefore 26-34, not the art's natural rim thickness. Kit art is presentation only and never defines collision radius, merge eligibility, or score behavior.

# Supplied typefaces - 2026-08-29

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| All UI copy, counters, button captions | `assets/fonts/Nunito_Sans/NunitoSans-VariableFont_YTLC,opsz,wdth,wght.ttf` | `assets/runtime/fonts/NunitoSans-Variable.ttf` | Variable font; `wght` axis defaults to 200 (ExtraLight) and **must** be set explicitly. `UiDesignSystem` applies 800 for UI and 1000 for counters via `FontVariation.variation_opentype` |
| Brand tagline and display | `assets/fonts/Cinzel/static/Cinzel-Black.ttf` | `assets/runtime/fonts/Cinzel-Black.ttf` | Static Black instance; also kept `Cinzel-Bold.ttf` |

# Supplied opaque Majestic logo replacement v5 - 2026-08-27

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Opaque illustrated launcher branding | `assets/logo/majestic_gems_logo_with_background_source_v5.png` (512x512 supplied PNG) | `assets/runtime/ui/majestic_gems_app_icon_192_v5.png` | Complete square artwork is aspect-contained at 134px on the existing 192px brand canvas. |
| Adaptive launcher foreground/background | same supplied opaque source | `majestic_gems_adaptive_foreground_v5.png` + `majestic_gems_adaptive_background_v5.png` | Complete artwork is bounded to the existing 288px adaptive safe edge; the established dark-amethyst background remains separate. |
| Android native system splash | same supplied opaque source | `assets/runtime/ui/majestic_gems_system_splash_1152_v6.png` | Complete artwork is Lanczos-scaled to a 784px safe edge and centered on the existing 1152px canvas. |

The retired opaque `majestic_gems_logo_presentation_reference_v3.png` is removed. The transparent `assets/logo/majestic_gems_home_logo_source_v4.png` and `assets/runtime/ui/majestic_gems_logo_v4.png` are unchanged and remain authoritative for Home and fallback boot presentation.

# Gem Registry and Runtime Expansion V2 - 2026-08-25

| Purpose | Preserved originals | Active runtime derivatives | Processing / boundary |
| --- | --- | --- | --- |
| Full gem catalog | `assets/gems/gem_01.png` through `gem_34.png`; 34 x 1254x1254 RGBA; 39,939,292 bytes | `assets/runtime/gems/gem_01.png` through `gem_34.png`; alpha-tight widths 255-256, heights 243-256; 3,081,575 bytes | Alpha >= 0.01 exact crop, aspect-preserving 256 px longest edge, low-alpha clear; presentation never defines collider size |

The two Aug-24 intake files were preserved byte-for-byte under stable IDs: `10_21_05 PM (1)` -> `gem_33` and `10_21_09 PM (7)` -> `gem_34`. Their source alpha rectangles are `(100,94,1054,1042)` and `(146,141,962,954)`; their runtime sizes are `256x253` and `256x254`.

`assets/runtime/art_refresh_manifest.json` records all 34 mappings/hashes/bounds. Current manifest SHA-256: `DA3EF0309B7850E9342184F7221621698BD99130859EA323D2512A480F7F68C7`.

# Gem Registry and Runtime Expansion V1 - 2026-08-24

| Purpose | Preserved originals | Active runtime derivatives | Processing / boundary |
| --- | --- | --- | --- |
| Full gem catalog | `assets/gems/gem_01.png` through `gem_32.png`; 32 x 1254x1254 RGBA; 37,692,448 bytes | `assets/runtime/gems/gem_01.png` through `gem_32.png`; alpha-tight widths 255-256, heights 243-256; 2,888,351 bytes | Alpha >= 0.01 exact crop, aspect-preserving 256 px longest edge, low-alpha clear; 92.34% smaller than sources |

The 12 Aug-24 additions were preserved unchanged in content and normalized by sorted intake order: `10_21_06 PM (2)/(3)/(4)` -> `gem_21/22/23`; `10_21_08 PM (6)` -> `gem_24`; `10_21_10 PM (9)` -> `gem_25`; `10_21_11 PM (10)` -> `gem_26`; `10_21_14 PM (1)` -> `gem_27`; `10_21_15 PM (3)` -> `gem_28`; `10_21_16 PM (5)` -> `gem_29`; `10_21_17 PM (6)` -> `gem_30`; `10_21_18 PM (7)` -> `gem_31`; `10_21_19 PM (9)` -> `gem_32`.

`assets/runtime/art_refresh_manifest.json` records each source/runtime hash, size, and measured alpha rectangle. Current manifest SHA-256: `98E129A8D5CC97EBC75D212F6ACB0C9D261300BEA1BF66909B79017B29620C38`.

# Supplied Art Refresh V1 - 2026-08-24

| Purpose | Preserved originals | Active runtime derivatives | Processing / boundary |
| --- | --- | --- | --- |
| Backgrounds | `assets/backgrounds/background_01.png` through `background_10.png`; 10 x 941x1672 RGB; 15,615,550 bytes | `assets/runtime/backgrounds/scene_bg_01.webp` through `scene_bg_10.webp`; 10 x 720x1280; 304,358 bytes | Lanczos, WebP quality 0.84; presentation-only |
| Tables | `assets/tables/table_01.png` through `table_10.png`; 10 x 941x1672 RGBA; 12,840,571 bytes | `assets/runtime/tables/table_01.webp` through `table_10.webp`; 10 x 720x1280 RGBA; 1,137,804 bytes | Full composition retained; Lanczos, WebP quality 0.92; shared `GameConfig` physics |
| Gems | `assets/gems/gem_01.png` through `gem_20.png`; 20 x 1254x1254 RGBA; 23,718,056 bytes | `assets/runtime/gems/gem_01.png` through `gem_20.png`; 255-256 x 248-256; 1,785,487 bytes | Alpha >= 0.01 exact crop, aspect-preserving max edge 256, low-alpha clear |
| Settings cog | `assets/ui/icons/cog_blue_crisp.png` | `assets/runtime/ui/icons/cog_lavender_crisp.png` | Alpha-preserving amethyst tint for current theme |

`assets/runtime/art_refresh_manifest.json` is generated by `scripts/dev/prepare_supplied_art_refresh.gd` and records every source/runtime SHA-256, dimension, and source alpha rectangle. Manifest SHA-256: `8DC315D84298CA72E4F3A45F5C77AE45CA99647447B425129DD0C38B2BB2D5AE`.

Retired sets removed in this milestone: `assets/source/backgrounds` (19), `assets/source/tables` (10), `assets/runtime/gems18` (18 plus manifests), runtime backgrounds 11-19, the vibration icon, and unused/superseded runtime contact/target audio copies. Active runtime audio is limited to the streams actually preloaded by `AudioFeedbackService`; the supplied originals remain preserved under `assets/sound`.

This section supersedes older inventory rows that describe the retired 19-background, 920x810-table, or `gems18` runtime pipelines; those rows remain below as history only.

# Supplied gameplay SFX v1 - 2026-08-16

The exact supplied files are preserved under `assets/sound/` and mapped byte-for-byte to active copies under `assets/runtime/audio/`. `assets/sound/*` remains Android-export excluded; only the runtime copies are packaged.

| Event | Source/runtime basename | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Gem to gem contact | `gems-colide.mp3` | 11,520 | `18753271A75E742689D7F2CB6B38E8616982A0277FE1E030AC7820AC64B3BADB` |
| Gem to rail contact | `gems-rail-colide.mp3` | 12,288 | `1E893D5A26EBF85827DC4D037A2F1E5774170F7DCD95682ADC94590232DDAC21` |
| Normal merge | `merge-basic.mp3` | 57,678 | `A66B2829A307BCB5B1F6551D7CDC72FE45BBE9A91ABFB994D28DB8D5E4E42EA8` |
| Target-producing merge | `merge-target.mp3` | 41,760 | `B68136FA50DD04F5D82BFD8EE05F4E5EB0CE25BA4AC8406AD5639DBCD7711250` |
| Target arrival | `mixkit-fairy-arcade-sparkle-866.wav` | 264,132 | `429C4D316D6269A8B66E97698D560F0FDE01FB48DBD5AB794208EC5215E897F6` |
| Objective completion | `mixkit-game-flute-bonus-2313.wav` | 656,572 | `2670161AEA58C04505C0FE9F857AEDD94DB77BC6FF8643CEF059C431B6A2095F` |
| Level success | `mixkit-game-success-alert-2039.wav` | 342,502 | `7FD53035349A866EF8A886D295F4DD881F68DE04E403C466522AC8D40A722344` |
| UI tap | `mixkit-on-or-off-light-switch-tap-2585.wav` | 195,092 | `F8BCC70FCA395B92AB2EF111EF874BF38C8659BC574452341F4E30BEF4EC2397` |

The existing runtime music `supplied_background_music_v5.ogg`, procedural launch/push stream, and `supplied_coin_reward_v4.ogg` remain authoritative and unchanged. Supplied filenames are provenance only; no license or ownership claim is inferred.

# Supplied gameplay SFX v1 - 2026-08-16

The exact supplied files are preserved under `assets/sound/` and mapped byte-for-byte to active copies under `assets/runtime/audio/`. `assets/sound/*` remains Android-export excluded; only the runtime copies are packaged.

| Event | Source/runtime basename | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Gem to gem contact | `gems-colide.mp3` | 11,520 | `18753271A75E742689D7F2CB6B38E8616982A0277FE1E030AC7820AC64B3BADB` |
| Gem to rail contact | `gems-rail-colide.mp3` | 12,288 | `1E893D5A26EBF85827DC4D037A2F1E5774170F7DCD95682ADC94590232DDAC21` |
| Normal merge | `merge-basic.mp3` | 57,678 | `A66B2829A307BCB5B1F6551D7CDC72FE45BBE9A91ABFB994D28DB8D5E4E42EA8` |
| Target-producing merge | `merge-target.mp3` | 41,760 | `B68136FA50DD04F5D82BFD8EE05F4E5EB0CE25BA4AC8406AD5639DBCD7711250` |
| Target arrival | `mixkit-fairy-arcade-sparkle-866.wav` | 264,132 | `429C4D316D6269A8B66E97698D560F0FDE01FB48DBD5AB794208EC5215E897F6` |
| Objective completion | `mixkit-game-flute-bonus-2313.wav` | 656,572 | `2670161AEA58C04505C0FE9F857AEDD94DB77BC6FF8643CEF059C431B6A2095F` |
| Level success | `mixkit-game-success-alert-2039.wav` | 342,502 | `7FD53035349A866EF8A886D295F4DD881F68DE04E403C466522AC8D40A722344` |
| UI tap | `mixkit-on-or-off-light-switch-tap-2585.wav` | 195,092 | `F8BCC70FCA395B92AB2EF111EF874BF38C8659BC574452341F4E30BEF4EC2397` |

The existing runtime music `supplied_background_music_v5.ogg`, procedural launch/push stream, and `supplied_coin_reward_v4.ogg` remain authoritative and unchanged. Supplied filenames are provenance only; no license or ownership claim is inferred.

# Regenerated scene art integration v1 - 2026-08-16

| Purpose | Preserved replacement sources | Active runtime derivatives | Processing / boundary |
| --- | --- | --- | --- |
| Level backgrounds | `assets/source/backgrounds/scene_bg_01_source.png` through `scene_bg_19_source.png` (19 opaque RGB PNGs, 941x1672; 35,609,686 bytes) | `assets/runtime/backgrounds/scene_bg_01.webp` through `scene_bg_19.webp` (19 RGB WebPs, 720x1280; 1,252,320 bytes) | One-to-one numeric mapping; Lanczos resize and WebP quality 0.82. Cover-scaled presentation only. |
| Level tables | `assets/source/tables/table_01_source.png` through `table_10_source.png` (10 transparent RGBA PNGs, 1343x1171; 15,367,180 bytes) | `assets/runtime/tables/table_01.webp` through `table_10.webp` (10 transparent WebPs, shared 920x810 canvas; 893,444 bytes) | One-to-one numeric mapping; Lanczos resize and WebP quality 0.90. All variants use one fixed `GameConfig` geometry model. |

The user's new source files replace the prior canonical scene sources; the temporary `assets/runtime/table/new_table_v1.png` is deleted. `tests/prepare_regenerated_scene_assets.gd` is the reproducible source-to-runtime preparation path and rejects a table whose outer corner is opaque. The active runtime background/table payload is 2,145,764 bytes versus the previous 3,068,162 bytes, saving 922,398 bytes (30.06%). Artwork is presentation-only and never defines physics.

# Original table restoration v1 - 2026-08-16

| Purpose | Runtime asset | Status / boundary |
| --- | --- | --- |
| Active gameplay table | `assets/runtime/table/new_table_v1.png` | Restored tracked 920x810 RGBA derivative, 1,132,907 bytes, SHA-256 `1C32E185D32DC71A65C9CAC67C1351D1A5898D9B11B6599C3BA03BEC90F0236B`; selected through `AssetCatalog.ORIGINAL_TABLE` at the original transform. |
| Replacement table inputs | `assets/runtime/tables/table_01.webp` through `table_10.webp` | Preserved but inactive while their rail artwork is regenerated; they have no physics authority. |

The 19 optimized random backgrounds remain active. Restoring the table does not derive rails or colliders from pixels; `GameConfig` remains authoritative.

# Responsive scene variety and cleanup v1 - 2026-08-16

| Purpose | Preserved source set | Active runtime set | Processing / boundary |
| --- | --- | --- | --- |
| Level backgrounds | `assets/source/backgrounds/scene_bg_01_source.png` through `scene_bg_19_source.png` (19 RGB PNGs, 941x1672) | `assets/runtime/backgrounds/scene_bg_01.webp` through `scene_bg_19.webp` (19 RGB WebPs, 720x1280) | Chronological supplied order; Lanczos resize, WebP quality 82/picture preset. Cover-scaled presentation only. |
| Level tables | `assets/source/tables/table_01_source.png` through `table_10_source.png` (10 alpha PNGs, 1385x1136) | `assets/runtime/tables/table_01.webp` through `table_10.webp` (10 alpha WebPs, shared 920x810 canvas) | Numeric supplied order; Lanczos normalization, WebP quality 90/picture preset. Presentation-only variants share one `GameConfig` geometry model. |

The preserved source set totals 57.40 MiB. The active scene derivatives total 2.93 MiB, a 94.90% reduction before Godot import. `export_presets.cfg` excludes the complete `assets/source/*` tree. Mapping is one-to-one by the two-digit basename; no original was overwritten.

Tracked Godot import profiles use lossy texture storage at quality 0.85 for backgrounds and 0.92 for alpha tables, with mipmaps disabled. This reduces the imported scene-texture payload from 19.83 MiB under the default lossless profile to 3.12 MiB (84.27%) while retaining the full runtime dimensions. Six refreshed ANGLE renders were reviewed after reimport; no visible rail, alpha-edge, panel, or background defect was accepted.

Dependency review removed 66 unused files totaling 27.83 MiB: five retired level backgrounds plus the old tropical backdrop, the superseded single table, five first-generation gem bodies, Crystal Magic/Gem Aim runtime branding, reference-only audio and its unused service, the old coin derivative, the retired UI source, and unused cog/next SVG variants. Current Majestic Gems branding sources/derivatives, coin provenance, production audio, gem shadow, calibrated 18-gem textures/manifests, and active UI icons remain.

# Majestic Gems branding v1 — 2026-08-11

| Purpose | Preserved supplied source | Active runtime derivative | Audit |
| --- | --- | --- | --- |
| Home and fallback boot logo | `assets/logo/majestic_gems_logo_source_v3.png` | `assets/runtime/ui/majestic_gems_logo_v3.png` | Supplied 1448×1086 logo; its fully black studio backdrop is removed only in the transparent runtime derivative, which remains aspect-centered. |
| Legacy launcher/project icon | same supplied logo source | `assets/runtime/ui/majestic_gems_app_icon_192_v3.png` | 192×192 PNG with the complete logo centered inside safe padding. |
| Adaptive launcher/system-splash icon | same supplied logo source | `majestic_gems_adaptive_foreground_v3.png` + `majestic_gems_adaptive_background_v3.png` + `majestic_gems_system_splash_1152_v4.png` | 432×432 transparent foreground limited to a 288 px safe edge, dark-amethyst adaptive background, and an 1152×1152 high-resolution transparent system-splash derivative. |

Historical Crystal Magic/Gem Aim branding, retired five-gem fallback textures, inactive reference audio, old reward art, and retired HUD atlases remain preserved in the repository but are explicitly excluded from Android export. The enumerated obsolete runtime set accounts for 6,593,409 source bytes before Godot import/compression. The final APK is 42,831,666 bytes, 17,685,982 bytes (29.22%) smaller than the prior `gem-aim0.2.apk`; its 260-entry audit contains zero forbidden retired/source/report/test/tool paths.

# Runtime UI icon/splash additions — 2026-08-09

- `addons/at-icons/` — supplied MIT icon library + editor picker.
- `assets/runtime/ui/icons/cog_white.svg` — padded Settings cog derived from @icons.
- `assets/runtime/ui/icons/play_white.svg` — primary Play/Resume/Start glyph.
- `assets/runtime/ui/icons/check_white.svg` — Done glyph.
- `assets/runtime/ui/icons/back_navy.svg` — secondary Back glyph.
- `assets/runtime/ui/icons/restart_navy.svg` / `restart_white.svg` — Restart/Retry glyphs.
- `assets/runtime/ui/icons/home_navy.svg` — Home glyph.
- `assets/runtime/ui/icons/note_navy.svg`, `speaker_navy.svg`, `vibration_navy.svg` — settings-row glyphs.
- `assets/runtime/ui/icons/next_white.svg` — Next Level glyph.
- `assets/runtime/ui/crystal_magic_adaptive_bg_v1.png` — solid tropical-teal Android adaptive/system-splash background fallback.
- `assets/runtime/ui/crystal_magic_system_splash_icon_v1.png` — 432×432 transparent padded Crystal Magic mark for Android system splash. It is not the launcher icon.

# Motion Asset Addendum — 2026-08-09

- `GlobalTweens.gd`: supplied third-party/general tween toolkit; now registered as project autoload for presentation-only button/pulse feedback.
- `tween_composer/`: supplied Tween Composer 0.5.1 runtime scripts/resources; used by Home overlay ambient scale loops.
- No separate icon library/plugin/icon-pack files were detected in the supplied `game(2).zip`. Existing `assets/ui`, HUD atlas, and Crystal Magic runtime branding remain authoritative for icons in this milestone.

# Asset Inventory — Background, Table, and Gems v1

## Production Foundation v1 branding

| Use | Preserved/generated source | Runtime asset | Mapping |
|---|---|---|---|
| Android launcher icon and boot splash | `assets/generated/gem_rush_app_icon_source_v1.png` | `assets/runtime/ui/gem_rush_app_icon_v1.png` | `project.godot` icon and boot splash; 1254 x 1254 PNG, SHA-256 `BB4D2AEDE4424EEAE8360A20E114B1290B6E1624EBC152346C57505C32051F67`. |

The built-in image-generation tool used the established GEM RUSH direction: gold lettering, pearl, red/green/blue jewels, leaves, teal/ocean field, coral-gold rim, Android-safe margins, no Godot mark, and no extra wording. Source and runtime copies are intentionally identical so the generated master remains preserved while runtime references stay under `assets/runtime/`.

## Asset-matched transparent brand v2

| Purpose | Preserved source | Active runtime derivative | Audit |
| --- | --- | --- | --- |
| Transparent GEM RUSH Home hero | Uploaded original remains `assets/logo/ChatGPT Image Aug 5, 2026, 03_32_00 AM.png`; generated flat-key edit is `assets/generated/gem_rush_logo_chroma_source_v2.png` | `assets/runtime/ui/gem_rush_logo_transparent_v2.png` | Built-in image edit preserved the GEM RUSH wording, gold sign, gems, leaves, and sparkles on a flat magenta key. Windows alpha matte used measured key RGB `(238,20,218)`, transparent distance `<=28`, opaque distance `>=120`, soft interpolation and edge despill. Runtime is 1254 x 1254 RGBA, 2,846,807 bytes, SHA-256 `64A6A274A1B1AE92CC0061765292FE650CC101737941F3A65E38A44DD3B9B814`; all four corner alpha values are `0`. Generated keyed source SHA-256 is `417760299539758FE6A236598AD4A5B899C1B5922FB5ACA50BC00BBE92C3E833`. |

## New background music v1

| Purpose | Preserved source | Active runtime derivative | Audit |
| --- | --- | --- | --- |
| Continuous background music | `assets/sound/sonican-uplifting-loop-cheerful-happiness-297034.mp3` | `assets/runtime/audio/supplied_background_music_v5.ogg` | Source: 2,817,044 bytes, 88.032625 s, MP3 256 kb/s stereo 44.1 kHz, SHA-256 `62778A13E946CF221388AB1AE935386C9144256E88C385CA1153210A4478CE43`. Runtime: 1,767,914 bytes, 88.032653 s, Vorbis stereo 44.1 kHz quality 5, SHA-256 `1D2124D6B5C15CE09F8823A57BD2DBB2DEEA01CDDDCA33B297379F1ED1A64E3F`; full duration, metadata stripped, with no gain/EQ/pitch/trim processing. |

The supplied filename is recorded only as provenance; no license or ownership claim is inferred. Source and runtime mean/max measurements are `-12.4/-0.5 dBFS` and `-12.4/0.0 dBFS`. The player applies linear gain `0.10` (`-20 dB`), for an estimated played mean/max near `-32.4/-20.0 dBFS`. The prior v4 music derivative remains preserved but inactive. `supplied_coin_reward_v4.ogg` remains a separate target-only cue.

## Branded production screen flow v1

| Purpose | Preserved source | Active runtime derivative | Audit |
| --- | --- | --- | --- |
| GEM RUSH Home hero | `assets/logo/ChatGPT Image Aug 5, 2026, 03_32_00 AM.png` | `assets/runtime/ui/gem_rush_logo_v1.png` | Source: 1024 x 1024, 1,752,999 bytes, SHA-256 `07341EC3BBCC3113E686CC074556113DC964E14B4C2561A93727D0C4D4BDC303`. Runtime: cropped non-destructively to the meaningful top 1024 x 800 composition, Lanczos-resized to 720 x 563, 1,079,728 bytes, SHA-256 `C2B6A47EF0272CCCEF67230B837CAE8F30B8E8E322A0EFDF7D7178E86D86B123`. No source overwrite, recolor, alpha claim, or gameplay use. |

## Infinite randomized level backgrounds v1

Five preserved 941 x 1672 supplied sources under `assets/bg/` map in sorted filename order to `assets/runtime/backgrounds/level_bg_1.png` through `level_bg_5.png`. Runtime files are non-destructive 720 x 1280 Lanczos derivatives used only for presentation. Their SHA-256 values are `C058360DF4AA02C11A9A5EF6D357E2346377A0D2E975768A8FC684A77B0FAFC2`, `59326738EA32349D7D263313F149D8A73807860A50E89EFAAFD4C014DB3A40BE`, `0F98392083125406F996F3F1523F3717A7FCCC2F78C1C5D458DC5BF9DF4B4CEE`, `9DE42880F94BF3DF3C22AFFDD9EDA42026A8A3B02F8914992707385411FB8888`, and `61D59C0BE7B3AE75F01738CB11015E3140A32A77AFBA76120B33C2D7F8CDE88B`. Background selection has no table, rail, collider, merge, reward, or input authority.

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
# Supplied gameplay SFX corrective activation v2 - 2026-08-16

All eight user-provided originals and byte-identical runtime copies remain preserved. Runtime routing now activates only five replacements: `gems-colide.mp3` (gem contact), `gems-rail-colide.mp3` (rail contact), `merge-target.mp3` (ordinary merge), `mixkit-on-or-off-light-switch-tap-2585.wav` (UI tap), and `merge-basic.mp3` (final level success). `mixkit-fairy-arcade-sparkle-866.wav`, `mixkit-game-flute-bonus-2313.wav`, and `mixkit-game-success-alert-2039.wav` are preserved but inactive. This is a mapping correction only; no audio asset was deleted or re-encoded.
# Supplied gameplay SFX corrective activation v2 - 2026-08-16

All eight user-provided originals and byte-identical runtime copies remain preserved. Runtime routing now activates only five replacements: `gems-colide.mp3` (gem contact), `gems-rail-colide.mp3` (rail contact), `merge-target.mp3` (ordinary merge), `mixkit-on-or-off-light-switch-tap-2585.wav` (UI tap), and `merge-basic.mp3` (final level success). `mixkit-fairy-arcade-sparkle-866.wav`, `mixkit-game-flute-bonus-2313.wav`, and `mixkit-game-success-alert-2039.wav` are preserved but inactive. This is a mapping correction only; no audio asset was deleted or re-encoded.
# Immediate merge runtime derivative v3 - 2026-08-16

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Approved v2 ordinary-merge cue with immediate attack | `assets/sound/merge-target.mp3` — 41,760 bytes — SHA-256 `B68136FA50DD04F5D82BFD8EE05F4E5EB0CE25BA4AC8406AD5639DBCD7711250` | `assets/runtime/audio/merge-target-immediate.ogg` — 14,316 bytes — SHA-256 `05E9EE864FAACBCC73BB7ECF0FE6DC7A2663EB7A82AA1F20B0E7A3A5C541D085` | FFmpeg `atrim=start=0.515,asetpts=PTS-STARTPTS`, Vorbis q5, stereo 24 kHz. Leading silence reduced from `0.523125 s` to `0.008042 s`; source hash unchanged. |
# Immediate merge runtime derivative v3 - 2026-08-16

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Approved v2 ordinary-merge cue with immediate attack | `assets/sound/merge-target.mp3` — 41,760 bytes — SHA-256 `B68136FA50DD04F5D82BFD8EE05F4E5EB0CE25BA4AC8406AD5639DBCD7711250` | `assets/runtime/audio/merge-target-immediate.ogg` — 14,316 bytes — SHA-256 `05E9EE864FAACBCC73BB7ECF0FE6DC7A2663EB7A82AA1F20B0E7A3A5C541D085` | FFmpeg `atrim=start=0.515,asetpts=PTS-STARTPTS`, Vorbis q5, stereo 24 kHz. Leading silence reduced from `0.523125 s` to `0.008042 s`; source hash unchanged. |
# Android system splash derivative v2 - 2026-08-18

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Android native system splash logo | `assets/logo/majestic_gems_logo_source_v3.png` (1448×1086 supplied source) | `assets/runtime/ui/majestic_gems_system_splash_1152_v4.png` | Complete logo is Lanczos-scaled to a 784px longest edge and centered on a transparent 1152×1152 canvas. The platform splash background is unchanged. |

# Soft contact and target-completion derivatives v1 - 2026-08-18

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Soft gem contact | `assets/sound/gems-colide.mp3` | `assets/runtime/audio/gem_collision_soft_v1.ogg` — 8,851 bytes — SHA-256 `0671D9648211C0012E3BAB613D55ABB63734D451D000FE401AB4E3EF0B781871` | 280 ms trim; 180 Hz high-pass, 5.2 kHz low-pass, -4 dB at 2.8 kHz, 12 ms fade-in, 80 ms fade-out; stereo 48 kHz Vorbis. |
| Soft rail contact | `assets/sound/gems-rail-colide.mp3` | `assets/runtime/audio/rail_collision_soft_v1.ogg` — 8,705 bytes — SHA-256 `91857B7CC4EF0294A60CDD50158602771847F71E839BF1E501000BEFBE942850` | 300 ms trim; 160 Hz high-pass, 4.2 kHz low-pass, -5 dB at 2.3 kHz, 16 ms fade-in, 90 ms fade-out; stereo 48 kHz Vorbis. |
| Full-target sparkle | `assets/sound/mixkit-fairy-arcade-sparkle-866.wav` | `assets/runtime/audio/target_complete_soft_v1.ogg` — 21,931 bytes — SHA-256 `2B0A07FAB59A84F4050148A449D7E9B6B85B4E0990114DEA9EB344048499171E` | 720 ms trim with 10 ms fade-in and 150 ms fade-out; stereo 44.1 kHz Vorbis. |

All originals remain preserved. These files are presentation-only and never define contact, merge, target, reward, or physics behavior.

# Coin sink icon derivatives - 2026-08-28

- `assets/runtime/ui/icons/arrows_clockwise_white.svg` - recolored runtime derivative of `addons/at-icons/node/arrows_clockwise.svg`, used by the high-contrast Switch Gem action. It supersedes and removes the prior dice derivative.
- `assets/runtime/ui/icons/fast_forward_lavender.svg` - recolored runtime derivative of `addons/at-icons/node/fast_forward.svg`, used by Level Ready, Pause, and Failed Skip Level actions.
- `export_presets.cfg` excludes `addons/at-icons/*` and `@icons picker.html`; only the selected small runtime SVG derivatives enter Android packages.

# Tester midpoint contact derivatives v2 - 2026-08-18

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Midpoint gem contact | `assets/sound/gems-colide.mp3` | `assets/runtime/audio/gem_collision_medium_v2.ogg` — 9,135 bytes — SHA-256 `70F9879B2C1834D9574138D0C8271282EA1D45CE2ABA9369E1145CD39DD00575` | 300 ms; 160 Hz high-pass, 7 kHz low-pass, -2 dB at 2.8 kHz, 8 ms fade-in, 80 ms fade-out; stereo 48 kHz Vorbis. |
| Midpoint rail contact | `assets/sound/gems-rail-colide.mp3` | `assets/runtime/audio/rail_collision_medium_v2.ogg` — 8,932 bytes — SHA-256 `AFD0F5498E22DBFB8CFA075F57626E547BEB43C001ECA452AF308EB0ABC4E763` | 320 ms; 140 Hz high-pass, 6 kHz low-pass, -2.5 dB at 2.3 kHz, 10 ms fade-in, 90 ms fade-out; stereo 48 kHz Vorbis. |

These v2 derivatives supersede soft v1 at runtime. The original and soft-v1 files remain preserved for provenance and comparison.

# Soft contact and target-completion derivatives v1 - 2026-08-18

| Purpose | Preserved source | Runtime derivative | Processing / verification |
| --- | --- | --- | --- |
| Soft gem contact | `assets/sound/gems-colide.mp3` | `assets/runtime/audio/gem_collision_soft_v1.ogg` — 8,851 bytes — SHA-256 `0671D9648211C0012E3BAB613D55ABB63734D451D000FE401AB4E3EF0B781871` | 280 ms trim; 180 Hz high-pass, 5.2 kHz low-pass, -4 dB at 2.8 kHz, 12 ms fade-in, 80 ms fade-out; stereo 48 kHz Vorbis. |
| Soft rail contact | `assets/sound/gems-rail-colide.mp3` | `assets/runtime/audio/rail_collision_soft_v1.ogg` — 8,705 bytes — SHA-256 `91857B7CC4EF0294A60CDD50158602771847F71E839BF1E501000BEFBE942850` | 300 ms trim; 160 Hz high-pass, 4.2 kHz low-pass, -5 dB at 2.3 kHz, 16 ms fade-in, 90 ms fade-out; stereo 48 kHz Vorbis. |
| Full-target sparkle | `assets/sound/mixkit-fairy-arcade-sparkle-866.wav` | `assets/runtime/audio/target_complete_soft_v1.ogg` — 21,931 bytes — SHA-256 `2B0A07FAB59A84F4050148A449D7E9B6B85B4E0990114DEA9EB344048499171E` | 720 ms trim with 10 ms fade-in and 150 ms fade-out; stereo 44.1 kHz Vorbis. |

All originals remain preserved. These files are presentation-only and never define contact, merge, target, reward, or physics behavior.
