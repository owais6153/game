# Level 1 Flow v1

## Scope and baseline

- Baseline commit/tag: `306b0c69d3e7f8ecd49887420ea02c67386e61d0` / `18-gem-progression-tested-v1`.
- Scope: one data-driven Level 1 only. No other levels, multi-target support, level progression, saving, economy, shot limit, table/physics tuning, HUD redesign, visual changes, or feedback changes were added.

## Level configuration

- ID/name: `level_1` / `First Facets`.
- Active normal-play range: L1-L8 (exactly eight contiguous tiers).
- Launcher tiers and weights: L1 weight 2, L2 weight 1.
- Deterministic queue: L1, L1, L2 repeating. This honors the conservative 2:1 weighting while avoiding early unlucky streaks.
- Target: create one L5 Peridot.
- Starting board: empty.
- There is no shot limit. The existing danger-line overflow failure remains unchanged.

L5 is reachable from the allowed low tiers through the verified merge ladder and is a short introductory objective without direct high-tier launcher shortcuts. Detailed difficulty balancing is deliberately deferred.

## Target counting and sequencing

- Progress changes only in `GameController._apply_confirmed_merge_events()`.
- A unique confirmed merge `result_id` counts once when its result tier is L5.
- Launcher previews/spawns, debug pieces, restored state, collisions, and non-target merge results never increment progress.
- Qualification freezes launcher progression as before, but the target gem remains present through its merge presentation and existing win hold before the overlay appears.

## Files changed

- `scripts/level_config.gd`
- `scripts/game_controller.gd`
- `scripts/merge_service.gd`
- `tools/run_level_1_flow_tests.gd`
- `tools/run_clean_contact_tests.gd`
- `GAME_SPEC.md`, `ARCHITECTURE.md`, `AI_KNOWLEDGE_BASE.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `BUILD_MANIFEST.md`

## Validation

- Godot 4.6.3 headless import/parse: passed.
- `CLEAN_CONTACT_TESTS: PASS`.
- `GEM18_CHAIN_TESTS: PASS`.
- `LEVEL_1_FLOW_TESTS: PASS`: range, low-tier queue, target reachability/counting, win sequencing, restart, and unchanged danger failure.
- Godot's headless renderer emitted existing RID/resource cleanup warnings after the successful suite output; those warnings did not report a parse or gameplay test failure.

## APK delivery

- Source commit: `4ad1d51e09e0efce75d6842b0310880095ad349c` (`feat: add isolated level 1 flow`).
- Milestone tag: `level-1-flow-v1`.
- Path: `build/android/level-1-flow-v1.apk`
- Size: `99,200,243` bytes.
- Modified: `2026-07-30 09:12:13 +05:00`.
- SHA-256: `E7BDBBE6D1158F113F705980602A769DA64078194A61780E45D6AA4156616D9B`.
- APK/ZIP validation: passed; contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no phone was connected; installation and device testing are not claimed.
