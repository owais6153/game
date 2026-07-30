# 18-Gem Chain v1 Report

## Recovery baseline

- Restored exactly from `new-table-shadow-contact-fix-v1` at `0b562d5b85b0b4d0330ecd10da3f832408949ad9`.
- The known-good APK hash was confirmed as `713E25E53E10B36AFA88BB83C1CB3183A11CFA120B6493A1AEE57F29E2B41E19` before implementation.
- All failed multi-target, level, perspective, Y-sort, table, HUD, queue, and launcher changes after that tag were removed before this feature was added.

## Asset preservation and mapping

- The 18 originals are retained unchanged in `assets/gems/` and were copied to `D:\Owais\game-18-gem-source-backup\` before rollback.
- Exact source checksums and deterministic filename-sort mapping are recorded in `assets/runtime/gems18/source-gems-sha256.json`.
- Runtime derivatives are `assets/runtime/gems18/tier_01.png` through `tier_18.png`; their alpha bounds and crop sizes are recorded in `assets/runtime/gems18/normalization_manifest.json`.
- L1–L18 are: Pearl, Ruby, Emerald, Sapphire, Diamond, Amethyst, Topaz, Opal, Garnet, Aquamarine, Citrine, Tourmaline, Peridot, Tanzanite, Spinel, Moonstone, Alexandrite, Black Diamond.
- Each derivative is alpha-trimmed with a two-pixel anti-alias margin. The Moonstone source had an opaque gray exterior, so only its derived copy uses a circular body mask; internal facets/highlights remain. Existing separate runtime shadows remain visual-only.

## Isolated implementation

- The existing contact merge service was not rewritten. Its terminal bound now reads `GameConfig.MAX_GEM_LEVEL`, allowing L1+L1 through L17+L17 and prohibiting L18 merging.
- `AssetCatalog` resolves the normalized tier texture for each level. `GameConfig` holds fixed per-tier body radii; there is no perspective scaling or Y-dependent collider scaling.
- The baseline launcher still generates only its original L1/L2 sequence. The Diamond target, current HUD, table, physics tuning, fail behavior, score, win sequence, pause, restart, audio, and haptics are unchanged.

## Validation

- Godot 4.6.3 parse/import validation: passed.
- Restored baseline suite: `CLEAN_CONTACT_TESTS: PASS`.
- Focused tier suite: `GEM18_CHAIN_TESTS: PASS` (18 textures, deterministic mapping, L1→L18 adjacent upgrades, terminal L18, different/distant rejection, shadows, table/target invariants).
- No Android device was connected; no device install or launch is claimed.

## Delivery

- APK: `D:\Owais\game\build\android\18-gem-chain-v1.apk`
- Size: 106,113,431 bytes; built 2026-07-30 04:37:06 +05:00.
- SHA-256: `177E5F12A1E951DE32092801EA91B0354BD1969A1E9C69D30EFB1263AC05200F`.
- Source commit/tag: `13d9f24bf88e86ff0b887251e3964c29bd23eec4` / `18-gem-chain-v1`.

## Scope statement

No multi-target gameplay, level configurations, target progression, unlimited-shot redesign, perspective scaling, Y sorting, table changes, HUD redesign, menus, saves, boosters, ads, analytics, or backend changes were included.
