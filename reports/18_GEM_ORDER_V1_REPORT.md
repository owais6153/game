# 18-Gem Order v1

## Scope

- Source baseline: `fc71e2dad781134948d1962dfe2a49ad0b6521fe` / `18-gem-size-collision-fix-v1`.
- Runtime source commit: `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194` (`chore: finalize 18-gem progression order`).
- This is a catalog-only milestone. No assets were generated, resized, retouched, removed, or added.

## Final order

| Tier | Display name | Calibrated asset |
| --- | --- | --- |
| L1 | Pearl | `tier_16.png` |
| L2 | Obsidian | `tier_04.png` |
| L3 | Jade | `tier_05.png` |
| L4 | Aquamarine | `tier_08.png` |
| L5 | Peridot | `tier_02.png` |
| L6 | Pink Tourmaline | `tier_07.png` |
| L7 | Ruby | `tier_01.png` |
| L8 | Sapphire | `tier_03.png` |
| L9 | Emerald | `tier_11.png` |
| L10 | Watermelon Tourmaline | `tier_09.png` |
| L11 | Morganite | `tier_06.png` |
| L12 | Garnet | `tier_10.png` |
| L13 | Amethyst | `tier_14.png` |
| L14 | Citrine | `tier_15.png` |
| L15 | Orange Sapphire | `tier_18.png` |
| L16 | Royal Sapphire | `tier_12.png` |
| L17 | Diamond | `tier_13.png` |
| L18 | Blue Diamond | `tier_17.png` |

The order starts with softer/common materials, moves through distinct color and cut changes, then ends with the most luminous and rare-looking diamonds. Similar blue, red, and green gems are separated by visually distinct shapes or colors so each merge reads as an upgrade.

## Preserved behavior

- The same source asset keeps its calibrated runtime texture, collider radius, display scale, shadow offset, and shadow opacity after moving tiers.
- Merge mechanics remain exactly `L1 + L1 -> L2` through `L17 + L17 -> L18`; L18 is terminal.
- Motion, collision solver, table, UI layout, target logic, launcher flow, scores, sounds, haptics, and win/fail behavior were not changed.

## Files changed

- `scripts/asset_catalog.gd`
- `scripts/game_config.gd`
- `tools/run_18_gem_chain_tests.gd`
- `tools/run_clean_contact_tests.gd`
- `18_GEM_ORDER_V1_REPORT.md`
- `CHANGELOG.md`
- `CURRENT_STATE.md`
- `AI_KNOWLEDGE_BASE.md`
- `BUILD_MANIFEST.md`

## Validation

- Godot 4.6.3 headless import/parse validation: passed.
- `CLEAN_CONTACT_TESTS: PASS`.
- `GEM18_CHAIN_TESTS: PASS`: 18 unique textures, exact source-order mapping, labels, every adjacent merge, L17 -> L18, terminal L18, and preview/catalog lookup coverage.
- `MOTION_PROFILE: PASS`: no gameplay resource loads after initialization and no per-gem process callbacks; all approved motion values remain unchanged.
- APK ZIP contains `AndroidManifest.xml` and `classes.dex`.

## APK

- File: `build/android/18-gem-order-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:43:05 +05:00`
- SHA-256: `95E2279F9BE8DD762FCE196A86D0B6301CDE9001711E3B5AF2E25747AAF62752`
- Device status: no phone was connected; device testing is not claimed.
