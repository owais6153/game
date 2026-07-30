# Identity, UI, Unlimited Play & Target Balance Fix v1

## Baseline

- Source baseline: `4f877da40f10f00902172150a6311bf02f19ee11` (`gameplay-hud-sequential-targets-v1`).
- Scope deliberately excludes the table, rails, table-following alignment, depth scaling, collision radii, motion constants, contact merge rules, sounds, haptics, pause, restart, and danger-line rule.

## Fixed issues

### Authoritative gem identity

The catalog documentation and the runtime texture dictionary had diverged. The screen could therefore label a tier as one gem while drawing another tier's texture. `AssetCatalog.GEM_TIER_SOURCE_INDEX` and `GEM_TIER_TEXTURES` now use the same approved L1-L18 source order:

| Tier | ID | Name | Runtime texture |
| --- | --- | --- | --- |
| L1 | pearl | Pearl | tier_16.png |
| L2 | obsidian | Obsidian | tier_04.png |
| L3 | jade | Jade | tier_05.png |
| L4 | aquamarine | Aquamarine | tier_08.png |
| L5 | peridot | Peridot | tier_02.png |
| L6 | pink_tourmaline | Pink Tourmaline | tier_07.png |
| L7 | ruby | Ruby | tier_01.png |
| L8 | sapphire | Sapphire | tier_03.png |
| L9 | emerald | Emerald | tier_11.png |
| L10 | watermelon_tourmaline | Watermelon Tourmaline | tier_09.png |
| L11 | morganite | Morganite | tier_06.png |
| L12 | garnet | Garnet | tier_10.png |
| L13 | amethyst | Amethyst | tier_14.png |
| L14 | citrine | Citrine | tier_15.png |
| L15 | orange_sapphire | Orange Sapphire | tier_18.png |
| L16 | royal_sapphire | Royal Sapphire | tier_12.png |
| L17 | diamond | Diamond | tier_13.png |
| L18 | blue_diamond | Blue Diamond | tier_17.png |

Current, next, target, launcher, and merge-result presentation all resolve through `AssetCatalog.gem_entry()`.

### HUD

The gameplay reference `assets/ui/Generated image 1 (3).png` is now the layout source: score card left, progression gems centered, and NEXT card right. The current generic dark strip was removed. The target card remains as the minimum gameplay extension required for sequential objectives and stays outside the table transform.

### Unlimited play and balance

Production `shot_count` state was removed. Level 1 can launch indefinitely until all sequential targets complete or the existing danger line fails the run.

Level 1 remains exactly two sequential targets, but changes from `L3 x1 -> L4 x1` to `L3 x2 -> L4 x2`. The theoretical minimum is 24 Pearl-equivalents, rather than the old 6. The queue remains low-tier L1/L1/L2, so no direct high-tier spawn trivializes objectives. Difficulty therefore comes from planning and danger-line pressure, not a shot cap.

### Target collection ghost-body removal

At collection start, the confirmed result is marked consumed, removed from the live `pieces` array, removed from danger timers, and merge candidates are cleared before the fly-to-HUD sprite is created. The collection visual is now the only remaining representation; it cannot collide, merge, block rails, or count toward occupancy.

## Validation

- Godot 4.6.3 headless editor parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed, including the corrected authoritative texture mapping.
- `LEVEL_1_FLOW_TESTS`: passed, including two-step quantities, unlimited queue operation, and removal of target bodies before fly-to-HUD animation.
- `MOTION_PROFILE`: passed: no per-frame texture loads and no per-gem process callback.
- Godot prints known canvas-resource cleanup warnings after the headless Level 1 runner exits, despite the suite printing `LEVEL_1_FLOW_TESTS: PASS`; this pre-existing runner cleanup condition did not change gameplay validation.
- No Android phone was connected; device installation and gameplay testing are not claimed.

## APK

- Path: `build/android/identity-ui-unlimited-target-balance-fix-v1.apk`
- Size: `100,750,262` bytes
- Built: `2026-07-30 21:26:25 +05:00`
- SHA-256: `DC593E97E3B114A7718B6CFA7DDE08EFCA4BBD5B88FCE4690B8C1CC2BB8F2DA0`
- APK structure verified: `AndroidManifest.xml` and `classes.dex` are present.
