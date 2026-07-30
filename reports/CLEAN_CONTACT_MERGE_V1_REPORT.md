# Clean Contact Merge v1 Report

## Delivered gameplay

- Portrait board with visible left/right/top boundaries and an empty initial table.
- One launcher below a visual-only danger line; horizontal drag and straight upward release.
- Side and top containment; unobstructed shots settle inside the top border.
- Minimal HUD: current gem, next gem, shot count, restart.
- Pearl, Ruby, Emerald, Sapphire, and Diamond drawn as simple colored circles.

## Contact-only merge rules

`BoardSimulation` captures overlapping physical pairs in the same simulation step before positional correction. `ContactMergeService` only accepts distinct live source IDs with equal levels and a current distance no greater than radius sum + 1.5 px. It consumes both IDs before spawning exactly one next-level gem at the pair midpoint, then clears all candidates. It has no global scan, nearest-neighbor scan, stale pair reuse, settled-only rule, or chain system.

## Files

- `scripts/game_config.gd`, `gem_piece.gd`, `contact_pair.gd`
- `scripts/board_simulation.gd`, `merge_service.gd`, `game_controller.gd`
- `scenes/Game.tscn`
- `tools/run_clean_contact_tests.gd`

## Validation

- Godot 4.6.3 headless parse/import: passed.
- Headless integration test suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Standalone Android debug export: passed and signed.

## APK

- `D:\Owais\game\build\android\clean-contact-merge-v1.apk`
- 27,707,373 bytes; modified 2026-07-29 03:12:46 +05:00.
- Source commit/tag: `ac795736bbecb4ee83c346a2717276d66a2b483c` / `clean-contact-merge-v1`.

## Phone test checklist

1. Install the APK while no Godot editor or development server is running.
2. Drag the bottom gem sideways, then release.
3. Confirm a clear shot reaches and settles against the top edge.
4. Shoot a Pearl into a touching Pearl and confirm one Ruby appears.
5. Shoot a Ruby into a touching Ruby and confirm one Emerald appears.
6. Confirm Pearl/Ruby only push; they never merge.
7. Press Restart and confirm the board clears to one launcher.

## Known limitations

This is deliberately a mechanics slice: no score, goal, fail condition, chain merge, effects, audio, art, saving, menus, ads, or device test.