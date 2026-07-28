# Architecture

## Clean Contact Merge v1

- `scripts/game_config.gd`: board dimensions, physics tuning, gem labels/colors.
- `scripts/gem_piece.gd`: typed mutable gameplay entity.
- `scripts/board_simulation.gd`: movement, borders, physical pair detection, pre-separation contact capture, and overlap response.
- `scripts/contact_pair.gd`: immutable source-ID pair used for one current step.
- `scripts/merge_service.gd`: isolated contact-only candidate validation, consumption, removal, and upgraded spawn.
- `scripts/game_controller.gd`: launcher queue, pointer input, settlement gate, minimal HUD, and simple drawing.
- `tools/run_clean_contact_tests.gd`: headless integration coverage of the actual simulation → contact → merge path.

Presentation stays in the controller; merge rules have no drawing/UI dependencies.