# Architecture

## Clean Contact Merge v1

- `scripts/game_config.gd`: board dimensions, physics tuning, gem labels/colors.
- `scripts/gem_piece.gd`: typed mutable gameplay entity.
- `scripts/board_simulation.gd`: movement, borders, physical pair detection, pre-separation contact capture, and overlap response.
- `scripts/contact_pair.gd`: immutable source-ID pair used for one current step.
- `scripts/merge_service.gd`: isolated contact validation, deterministic consumption, immediate upgraded spawn, and local contact-only chain resolution.
- `scripts/game_controller.gd`: launcher queue, pointer input, explicit one-shot lifecycle state machine, minimal HUD, rendering, and presentation-only merge effect lifecycle.
- `scripts/gem_visuals.gd`: rendering-only procedural Pearl/Ruby/Emerald/Sapphire/Diamond shapes, shadows, highlights, and visual-style mapping. It cannot change simulation state.
- `tools/run_clean_contact_tests.gd`: headless integration coverage of the actual simulation → contact → merge path.

Presentation stays in the controller and `GemVisuals`; merge rules have no drawing/UI dependencies. Source ghosts draw before live pieces, so the immediate upgraded simulation piece remains visually on top throughout a merge.

## Visual layout boundary

`GameConfig` owns fixed-canvas visual-only rectangles for the HUD, overlay, controls, and safe margins. `GameController` draws those values but neither the controller nor `GemVisuals` can feed them into `BoardSimulation`. The portrait canvas scales as canvas items, preserving the original gameplay coordinate space across supported portrait resolutions.

## Playable-level systems

`ContactMergeService` remains the authority for whether a merge occurred. `GameController._apply_confirmed_merge_events()` consumes only those events for score, chain multiplier, presentations, and Diamond win detection. `GameConfig` owns score values, target level, danger grace period, and overlay geometry/timing.

Danger state is controller-owned and keyed by piece ID. It is cleared immediately when a piece becomes active, moves, merges/disappears, or leaves the lower forbidden zone. Win/fail freeze input and launcher advancement; `restart()` owns the single complete reset path used by Restart, Replay, and Retry.

## Merge data flow

`BoardSimulation` captures physical contact → `ContactMergeService` commits immediate simulation changes and emits presentation events → `GameController` advances effect timers → drawing renders non-physical source ghosts, ring, glow, and pulse. Only a just-spawned gem can seed a chain, and all chain cycles are capped at 6.

## Launcher lifecycle

`GameController` owns a narrow launcher state machine: `READY_TO_AIM`, `SHOT_IN_FLIGHT`, `RESOLVING`, and `SPAWNING_NEXT`. Only `SPAWNING_NEXT` may call the idempotent `spawn_active_piece()`, and it returns to `READY_TO_AIM` immediately after one successful spawn. This prevents an unchanged “board settled” condition from generating a launcher repeatedly across frames.
