# AI Knowledge Base

## Project at a glance

Gem Merge Rebuild is a lightweight, portrait 2D Godot game. The intended visual theme is precious stones: Pearl (L1), Ruby (L2), Emerald (L3), Sapphire (L4), and Diamond (L5). The current milestone deliberately uses built-in circles and drawing only; final gemstone artwork, UI, sound, scoring, win/fail, persistence, ads, menus, levels, analytics, and backend are deferred.

## Current gameplay loop

An empty board begins with exactly one launcher piece beneath the visual-only danger line. The player drags it horizontally and releases to send it straight upward. `BoardSimulation` advances movement, constrains the side/top borders, captures real contacts before separation, and resolves overlap. `ContactMergeService` accepts only valid same-level contact candidates. The controller waits for motion, merging, and presentation to finish, then advances the current/next queue exactly once and creates the next launcher.

## Launcher state machine

`READY_TO_AIM -> SHOT_IN_FLIGHT -> RESOLVING -> SPAWNING_NEXT -> READY_TO_AIM` is an invariant, not a UI detail. Only `SPAWNING_NEXT` may call `spawn_active_piece()`. Never spawn based solely on an idle board or missing launcher ID: that was the cause of the historical infinite-spawn regression. Restart clears the board and queue state, then returns to one ready launcher.

## Entity and simulation model

`GemPiece` holds the mutable simulation fields: ID, level, position, velocity, radius, consumed state, and launcher state. `ContactPair` is an immutable pair of IDs captured for the current simulation step. Simulation state is authoritative; controller rendering and effects are presentation only.

Update order: controller input -> board movement/border constraints -> capture current physical contacts -> overlap separation -> merge resolution -> local chain resolution -> presentation timers -> settlement/lifecycle transition -> drawing. Do not make visual effects alter positions, IDs, contacts, collision, or merge candidates.

## Merge and chain invariants

- Direct merges use only a contact pair captured during the current simulation step, before separation.
- Both sources must be distinct, unconsumed, equal-level, and within `radius sum + CONTACT_EPSILON`.
- L1 Pearl -> L2 Ruby -> L3 Emerald -> L4 Sapphire -> L5 Diamond; L5 does not merge further.
- Source IDs are consumed before the upgraded piece is inserted at the physical midpoint.
- One piece may merge once per resolution cycle.
- Chains are narrow: only a just-created upgraded gem may test live, equal-level pieces using actual distance. Never perform a global scan, nearest-neighbour search, or reuse contacts from a prior frame.
- Chain depth is capped by `MERGE_CHAIN_DEPTH_CAP`.

## Current/next queue and presentation

The queue is controller-owned and must advance once per completed shot. Presentation events are non-physical ghost/pulse/ring effects. The source pull/fade lasts `MERGE_SOURCE_PULL_DURATION`; the upgraded-gem pulse/ring runs for `MERGE_PRESENTATION_DURATION`. A new launcher waits for board settlement and presentation completion.

## Score, outcomes, and danger timers

- Score is calculated only in `GameController._apply_confirmed_merge_events()`. Never infer it by scanning board pieces or collision pairs.
- `GameConfig.MERGE_SCORE_BY_RESULT_LEVEL` maps L2/L3/L4/L5 to 10/25/60/150. A resolver sequence starts at x1 and increments per confirmed event; x1 is restored when the next launcher becomes ready.
- A confirmed L5 spawn triggers `won` once. A won/failed controller rejects input and cannot spawn another launcher.
- `danger_timers` is keyed by non-active piece ID. A timer accumulates only when a settled piece’s lower edge is below `DANGER_LINE_Y`; `DANGER_GRACE_DURATION` is 0.75 seconds. Clear timers whenever pieces move, become active, merge/disappear, or leave the zone.
- `restart()` is the sole full reset path. It restores exactly one active launcher on an otherwise empty board and clears all gameplay/session fields.

## File and test map

- `scenes/Game.tscn`: minimal scene entry point.
- `scripts/game_config.gd`: all board, physics, merge, chain, and animation tuning constants.
- `scripts/gem_piece.gd`: gameplay entity.
- `scripts/contact_pair.gd`: current-step contact record.
- `scripts/board_simulation.gd`: movement, borders, current-step contacts, and separation.
- `scripts/merge_service.gd`: deterministic direct and local chain merge resolution.
- `scripts/game_controller.gd`: input, lifecycle, queue, drawing, and presentation-only effects.
- `scripts/gem_visuals.gd`: procedural gemstone artwork only. Keep it draw-only; never pass its output into collision or merge code.
- `tools/run_clean_contact_tests.gd`: headless controller/simulation integration tests.
- `BUILD_MANIFEST.md`: authoritative delivered-APK provenance.

## Tuning constants

All current tuning lives in `scripts/game_config.gd`: `VIEWPORT_SIZE`, board bounds, launch/damping/sleep constants, `CONTACT_EPSILON`, `SEPARATION_EPSILON`, `MERGE_SOURCE_PULL_DURATION`, `MERGE_PRESENTATION_DURATION`, `MERGE_PULSE_SCALE`, and `MERGE_CHAIN_DEPTH_CAP`. Do not retune them in unrelated work.

## Gemstone visual prototype

The current visual set is intentionally procedural and asset-free: Pearl is circular with a creamy highlight, Ruby and Sapphire are faceted, Emerald is emerald-cut, and Diamond is multi-faceted. `GemVisuals.visual_style_name()` is covered by the headless test suite. Rendering has no physics authority. The safe merge-presentation ordering is ghosts/ring/glow first, then live gems; retain it unless a dedicated presentation task verifies an alternative.

## Fragile areas and known-good milestones

- `clean-contact-merge-v1-spawn-fix` preserves the one-launcher lifecycle and is the recovery reference for spawn behavior.
- `clean-contact-merge-v2-chain-polish` adds presentation-only merge effects and capped contact-only chains.
- `blank-android-baseline-verified` proves standalone Android export.
- Past regressions: spawning from an idle condition created endless launchers; broad/stale merge candidates caused wrong or distant merges; merge effects must never join the collision system.
- Read `CURRENT_STATE.md`, `CHANGELOG.md`, `BUILD_MANIFEST.md`, and the latest task report before deciding what is currently verified.

## Project at a glance

Gem Merge Rebuild is a lightweight, portrait 2D Godot game. The intended visual theme is precious stones: Pearl (L1), Ruby (L2), Emerald (L3), Sapphire (L4), and Diamond (L5). The current milestone deliberately uses built-in circles and drawing only; final gemstone artwork, UI, sound, scoring, win/fail, persistence, ads, menus, levels, analytics, and backend are deferred.

## Current gameplay loop

An empty board begins with exactly one launcher piece beneath the visual-only danger line. The player drags it horizontally and releases to send it straight upward. `BoardSimulation` advances movement, constrains the side/top borders, captures real contacts before separation, and resolves overlap. `ContactMergeService` accepts only valid same-level contact candidates. The controller waits for motion, merging, and presentation to finish, then advances the current/next queue exactly once and creates the next launcher.

## Launcher state machine

`READY_TO_AIM -> SHOT_IN_FLIGHT -> RESOLVING -> SPAWNING_NEXT -> READY_TO_AIM` is an invariant, not a UI detail. Only `SPAWNING_NEXT` may call `spawn_active_piece()`. Never spawn based solely on an idle board or missing launcher ID: that was the cause of the historical infinite-spawn regression. Restart clears the board and queue state, then returns to one ready launcher.

## Entity and simulation model

`GemPiece` holds the mutable simulation fields: ID, level, position, velocity, radius, consumed state, and launcher state. `ContactPair` is an immutable pair of IDs captured for the current simulation step. Simulation state is authoritative; controller rendering and effects are presentation only.

Update order: controller input -> board movement/border constraints -> capture current physical contacts -> overlap separation -> merge resolution -> local chain resolution -> presentation timers -> settlement/lifecycle transition -> drawing. Do not make visual effects alter positions, IDs, contacts, collision, or merge candidates.

## Merge and chain invariants

- Direct merges use only a contact pair captured during the current simulation step, before separation.
- Both sources must be distinct, unconsumed, equal-level, and within `radius sum + CONTACT_EPSILON`.
- L1 Pearl -> L2 Ruby -> L3 Emerald -> L4 Sapphire -> L5 Diamond; L5 does not merge further.
- Source IDs are consumed before the upgraded piece is inserted at the physical midpoint.
- One piece may merge once per resolution cycle.
- Chains are narrow: only a just-created upgraded gem may test live, equal-level pieces using actual distance. Never perform a global scan, nearest-neighbour search, or reuse contacts from a prior frame.
- Chain depth is capped by `MERGE_CHAIN_DEPTH_CAP`.

## Current/next queue and presentation

The queue is controller-owned and must advance once per completed shot. Presentation events are non-physical ghost/pulse/ring effects. The source pull/fade lasts `MERGE_SOURCE_PULL_DURATION`; the upgraded-gem pulse/ring runs for `MERGE_PRESENTATION_DURATION`. A new launcher waits for board settlement and presentation completion.

## File and test map

- `scenes/Game.tscn`: minimal scene entry point.
- `scripts/game_config.gd`: all board, physics, merge, chain, and animation tuning constants.
- `scripts/gem_piece.gd`: gameplay entity.
- `scripts/contact_pair.gd`: current-step contact record.
- `scripts/board_simulation.gd`: movement, borders, current-step contacts, and separation.
- `scripts/merge_service.gd`: deterministic direct and local chain merge resolution.
- `scripts/game_controller.gd`: input, lifecycle, queue, drawing, and presentation-only effects.
- `tools/run_clean_contact_tests.gd`: headless controller/simulation integration tests.
- `BUILD_MANIFEST.md`: authoritative delivered-APK provenance.

## Tuning constants

All current tuning lives in `scripts/game_config.gd`: `VIEWPORT_SIZE`, board bounds, launch/damping/sleep constants, `CONTACT_EPSILON`, `SEPARATION_EPSILON`, `MERGE_SOURCE_PULL_DURATION`, `MERGE_PRESENTATION_DURATION`, `MERGE_PULSE_SCALE`, and `MERGE_CHAIN_DEPTH_CAP`. Do not retune them in unrelated work.

## Fragile areas and known-good milestones

- `clean-contact-merge-v1-spawn-fix` preserves the one-launcher lifecycle and is the recovery reference for spawn behavior.
- `clean-contact-merge-v2-chain-polish` adds presentation-only merge effects and capped contact-only chains.
- `blank-android-baseline-verified` proves standalone Android export.
- Past regressions: spawning from an idle condition created endless launchers; broad/stale merge candidates caused wrong or distant merges; merge effects must never join the collision system.
- Read `CURRENT_STATE.md`, `CHANGELOG.md`, `BUILD_MANIFEST.md`, and the latest task report before deciding what is currently verified.

## Non-negotiable rebuild rules

- This is clean-room code; do not copy code from the deleted project.
- Gameplay source of truth is `GAME_SPEC.md`.
- The build must be standalone: no development server is required to open the APK.
- Preserve Git traceability and document each task as required by `AGENTS.md`.
- Do not add mechanics outside the current scoped task.

## Merge invariant

The only allowed initial merge input is a current-step physical contact captured by `BoardSimulation` before separation. `ContactMergeService` must not scan all gems, search nearest neighbors, reuse candidates from previous frames, or require pieces to be settled. A chain is the narrow exception: a just-created upgraded gem may only be checked against live equal-level pieces using actual radius distance. Chains cap at 6 cycles.

## Launcher invariant

There is exactly one active launcher while the game is ready for input. Launcher creation is lifecycle-gated, not merely “board settled”-gated: a shot must enter `SHOT_IN_FLIGHT`, finish resolution, enter `SPAWNING_NEXT`, create one launcher, and then return to `READY_TO_AIM`. Do not reintroduce frame-by-frame spawning conditions based only on a missing active ID or settled board.
