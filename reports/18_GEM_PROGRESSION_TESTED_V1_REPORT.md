# 18-Gem Progression Tested v1

## Scope and baseline

- Baseline commit/tag: `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194` / `18-gem-order-v1`.
- Validated runtime source commit: `306b0c69d3e7f8ecd49887420ea02c67386e61d0` (`test: validate complete 18-gem progression`).
- This validation milestone preserves approved motion, fixed colliders, gem sizing, table geometry, HUD, target/score design, launcher queue, sounds, haptics, win/fail flow, and the final L1-L18 order.
- No production gameplay debug control was added. `tools/manual_merge_harness.gd` is a development-only command-line script; no scene, export preset, or runtime input references it.

## Verified progression

The strengthened `GEM18_CHAIN_TESTS` suite verifies all 17 exact upgrades: `L1->L2`, `L2->L3`, `L3->L4`, `L4->L5`, `L5->L6`, `L6->L7`, `L7->L8`, `L8->L9`, `L9->L10`, `L10->L11`, `L11->L12`, `L12->L13`, `L13->L14`, `L14->L15`, `L15->L16`, `L16->L17`, and `L17->L18`.

- L18 is terminal: it creates no L19, event, ID allocation, duplicate, crash, or out-of-range catalog lookup.
- Same-tier pieces merge only from a current physical contact. Different tiers and distant same-tier pieces are rejected.
- Duplicate reports of a contact pair resolve once; simultaneous contacts sharing a source resolve once and do not duplicate result or score events.
- Local physical chain resolution is deterministic, cleans consumed sources/candidates, and has stable depth metadata.
- Each confirmed result has the expected tier, texture, collider, visual-body scale, shadow mapping, midpoint position, and bounded valid inherited velocity.
- Source pieces are marked consumed and removed once. The service owns no node signals or connections, so there are no signal connections to clean up.
- Texture access remains preload-cache only; no runtime resource loading, alpha analysis, or per-piece frame callback occurs during merge paths.

## Development harness

`tools/manual_merge_harness.gd` accepts `--level=N` and optional `--chain=N` (1-4) for quick headless validation. It is excluded from production because tools are not scene-referenced and the script contains no gameplay/UI registration. Its validation run produced `L14 -> L18`; a separate L18 run correctly reported terminal behavior.

## Validation

- Godot 4.6.3 headless import/parse validation: passed.
- `GEM18_CHAIN_TESTS: PASS`.
- `CLEAN_CONTACT_TESTS: PASS`.
- Development harness: passed for L14 four-step chain and L18 terminal behavior.
- No Android device was connected. Phone checks for adjacent pairs, crowded-board contacts, restart during merge, and pause/resume remain pending; device performance/motion is not claimed.

## Files changed

- `scripts/merge_service.gd` (non-authoritative event metadata only)
- `tools/run_18_gem_chain_tests.gd`
- `tools/manual_merge_harness.gd`
- milestone report and required project documentation

## APK

- Path: `build/android/18-gem-progression-tested-v1.apk`
- Size: `99,195,813` bytes
- Modified: `2026-07-30 08:55:02 +05:00`
- SHA-256: `44FB0D04CD65DB1C666A66258E308AE9853D33F26060D4D3C9C6C04B8318559A`
- APK/ZIP verification: contains `AndroidManifest.xml` and `classes.dex`.
