# Architecture

## Clean Contact Merge v1

- `scripts/game_config.gd`: board dimensions, physics tuning, gem labels/colors.
- `scripts/gem_piece.gd`: typed mutable gameplay entity.
- `scripts/board_simulation.gd`: movement, borders, physical pair detection, pre-separation contact capture, and overlap response.
- `scripts/contact_pair.gd`: immutable source-ID pair used for one current step.
- `scripts/merge_service.gd`: isolated contact-only candidate validation, consumption, removal, and upgraded spawn.
- `scripts/game_controller.gd`: launcher queue, pointer input, explicit one-shot lifecycle state machine, minimal HUD, and simple drawing.
- `tools/run_clean_contact_tests.gd`: headless integration coverage of the actual simulation → contact → merge path.

Presentation stays in the controller; merge rules have no drawing/UI dependencies.

## Launcher lifecycle

`GameController` owns a narrow launcher state machine: `READY_TO_AIM`, `SHOT_IN_FLIGHT`, `RESOLVING`, and `SPAWNING_NEXT`. Only `SPAWNING_NEXT` may call the idempotent `spawn_active_piece()`, and it returns to `READY_TO_AIM` immediately after one successful spawn. This prevents an unchanged “board settled” condition from generating a launcher repeatedly across frames.
