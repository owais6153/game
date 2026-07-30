# Level 1 Balance v1 report

## Scope and baseline

- Source baseline: commit `4ad1d51e09e0efce75d6842b0310880095ad349c`, tag `level-1-flow-v1`.
- Scope: balance Level 1 only, organize report files, and establish the persistent push/report rule.
- Not added: Level 2, multi-target gameplay, level selection, saving, perspective, new effects, UI redesign, physics changes, collider changes, gem-order changes, or new mechanics.

## Balance change

| Setting | Previous | Final |
| --- | --- | --- |
| Active range | L1-L8 | L1-L8 |
| Launcher tiers | L1/L2 | L1/L2 |
| Launcher sequence | L1, L1, L2 | L1, L1, L2 |
| Target type | L5 (one result) | L4 Sapphire (two results) |
| Starting board | Empty | Empty |
| Shot limit | None | None |
| Failure | Existing overflow/danger rule | Unchanged |

The L1/L1/L2 cycle yields four Pearl-equivalent value in three launches when merged cleanly. Two L4 results each require eight Pearl-equivalent value, giving a deterministic best-case completion of about 12 launches. Real player runs will require more launches because placement and overflow pressure remain part of play. The queue has no direct L3+ launcher tier, so it cannot trivialize the objective or finish through one or two lucky launches.

## Validation

- Godot 4.6.3 parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed; covers fair queue bounds, two-result progress, unique result IDs, victory sequencing, restart, and overflow failure.
- `MOTION_PROFILE`: passed; no gameplay resource loads after initialization, with the existing 20-gem crowded-board profile remaining within its test threshold.
- Headless Godot emits existing resource-cleanup warnings after some controller tests; each suite itself reported `PASS`.
- No Android device was connected, so no device-tested completion timing is claimed.

## Report organization

All 22 root-level `*_REPORT.md` milestone files were moved with Git-tracked renames into `reports/`. Core-document references were updated, and `reports/README.md` now provides a milestone index. New reports must stay in this folder.

## APK

- File: `build/android/level-1-balance-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 09:48:03 +05:00`
- SHA-256: `72883265B690232655C6D62581D4CE3722F8F79007AAF831F83B20E4C576375A`
- Structure: valid ZIP/APK with `AndroidManifest.xml` and `classes.dex`.

## Git/GitHub delivery

The configured `origin` is the existing GitHub SSH remote `github.com/owais6153/game.git` (credentials omitted). This milestone will be committed as `feat: balance level 1 and organize milestone reports`, tagged `level-1-balance-v1`, and pushed without force. The final pushed commit and tag resolution are recorded in the delivery handoff after push verification.
