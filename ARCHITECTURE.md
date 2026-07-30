# Architecture

## 18-gem progression validation harness v1

`tools/manual_merge_harness.gd` is development-only CLI support, not a gameplay node. It creates contact-valid GemPiece pairs through `ContactMergeService` and is excluded from production by having no scene, autoload, export-preset, or input reference. `ContactMergeService` now includes immutable result metadata (source IDs, result ID, texture path, collider, visual scale, shadow mapping) with confirmed events. The controller consumes only its existing level/depth fields; the metadata cannot influence physics, merge eligibility, score, lifecycle, or rendering decisions.

## 18-gem catalog boundary

`AssetCatalog` maps presentation textures only. `GameConfig.MAX_GEM_LEVEL` is the sole catalog bound consumed by `ContactMergeService`; it does not alter launcher generation, target flow, table geometry, or rendering depth. Per-tier collider values are fixed board-space data and shadows remain presentation-only.

For the 18-tier catalog, `AssetCatalog.GEM_TIER_TEXTURES` preloads each mobile-sized runtime texture exactly once. `GemSpriteLayer` performs tier-dependent texture, scale, and shadow setup only at piece creation/tier change; its frame sync only copies simulation positions into sprites. Texture loading, alpha analysis, collider resizing, perspective scaling, and shadow generation are forbidden in the frame path.

## 18-gem body calibration v1

`tools/calibrate_18_gem_bodies.gd` is the only alpha-analysis path for the 18-tier catalog. It creates `assets/runtime/gems18/calibrated/` derivatives and the accompanying data manifest before runtime. `AssetCatalog` preloads those derivatives; `GameConfig` supplies the fixed display-body mapping and visual-only shadow offsets. `GemPiece.radius`, `BoardSimulation`, and `ContactMergeService` remain unaware of PNG bounds and shadows.

## Visual-physics calibration v1

- `assets/runtime/gems_calibrated/` contains alpha-trimmed derived textures; originals and earlier runtime sources remain preserved.
- `GameConfig.gem_collision_radius(level)` is the collision-radius authority. `GemSpriteLayer` maps each trimmed visual box onto that simple calibrated body; textures never decide merge eligibility.
- `BoardSimulation` attaches a confirmed contact point to gem/wall impact telemetry. `GameController` forwards that telemetry to audio and, only when F8 debug is enabled, renders temporary contact markers.

## Clean Contact Merge v1

- `scripts/game_config.gd`: board dimensions, physics tuning, gem labels/colors.
- `scripts/gem_piece.gd`: typed mutable gameplay entity.
- `scripts/board_simulation.gd`: movement, borders, physical pair detection, pre-separation contact capture, and overlap response.
- `scripts/contact_pair.gd`: immutable source-ID pair used for one current step.
- `scripts/merge_service.gd`: isolated contact validation, deterministic consumption, immediate upgraded spawn, and local contact-only chain resolution.
- `scripts/game_controller.gd`: launcher queue, pointer input, explicit one-shot lifecycle state machine, minimal HUD, rendering, and presentation-only merge effect lifecycle.
- `scripts/gem_visuals.gd`: rendering-only procedural Pearl/Ruby/Emerald/Sapphire/Diamond shapes, shadows, highlights, and visual-style mapping. It cannot change simulation state.
- `scripts/asset_catalog.gd`: presentation-only mapping from gem level to supplied runtime texture and visual normalization scale.
- `scripts/gem_sprite_layer.gd`: Sprite2D synchronization layer for live gems. It reads entities and never writes simulation data.
- `scripts/hud_renderer.gd`: rendering-only HUD and progression-strip drawing. It consumes `GameController.hud_snapshot()` and cannot mutate controller or simulation state.
- `tools/run_clean_contact_tests.gd`: headless integration coverage of the actual simulation → contact → merge path.

Presentation stays in the controller and `GemVisuals`; merge rules have no drawing/UI dependencies. Source ghosts draw before live pieces, so the immediate upgraded simulation piece remains visually on top throughout a merge.

## Visual layout boundary

`GameConfig` owns fixed-canvas visual-only rectangles for the HUD, overlay, controls, and safe margins. `GameController` draws those values but neither the controller nor `GemVisuals` can feed them into `BoardSimulation`. The portrait canvas scales as canvas items, preserving the original gameplay coordinate space across supported portrait resolutions.

`GameController.hud_snapshot()` is the one-way UI data boundary for current/next level, score, chain, shots, target, and highest live gem. `HudRenderer` has no input code; board drags remain owned solely by the controller.

## Playable-level systems

`ContactMergeService` remains the authority for whether a merge occurred. `GameController._apply_confirmed_merge_events()` consumes only those events for score, chain multiplier, presentations, and Diamond win detection. `GameConfig` owns score values, target level, danger grace period, and overlay geometry/timing.

Danger state is controller-owned and keyed by piece ID. It is cleared immediately when a piece becomes active, moves, merges/disappears, or leaves the lower forbidden zone. Win/fail freeze input and launcher advancement; `restart()` owns the single complete reset path used by Restart, Replay, and Retry.

## Merge data flow

`BoardSimulation` captures physical contact → `ContactMergeService` commits immediate simulation changes and emits presentation events → `GameController` advances effect timers → drawing renders non-physical source ghosts, ring, glow, and pulse. Only a just-spawned gem can seed a chain, and all chain cycles are capped at 6.

## Launcher lifecycle

## Sound and haptics v1

## Reference table + crystal audio v1

`GameConfig` owns the inset table geometry used by both renderer and simulation. `BoardSimulation` publishes presentation-only typed `gem`/`wall` impact telemetry; `AudioFeedbackService` synthesizes original inharmonic crystal cues from that telemetry and confirmed controller events. Neither path may influence collision, merge, score, lifecycle, or outcomes.

## Supplied asset layout v1

`GameConfig` owns the one authoritative trapezoid table layout: texture center/size, top and bottom inner rail anchors, `table_left_at(y)`, and `table_right_at(y)`. `GameController` places the background/table Sprite2D nodes and draws the dynamic danger line from this model. `BoardSimulation` uses the same functions for rail containment, while launcher dragging uses them for clamping. `GemSpriteLayer` maps only the already-authoritative `GemPiece` position/level/radius to textures; no artwork feeds back to simulation.

`AudioFeedbackService` owns lightweight procedural tone routing, reusable-player limits, and per-event cooldowns. `HapticsService` owns platform vibration calls and safely records editor/headless requests without calling a vibrator. `BoardSimulation` exposes impact strengths only; `GameController` routes eligible impacts and confirmed merge/chain/result events. Neither feedback service belongs in the simulation or merge service. All feedback constants live in `GameConfig`.

`GameController` owns a narrow launcher state machine: `READY_TO_AIM`, `SHOT_IN_FLIGHT`, `RESOLVING`, and `SPAWNING_NEXT`. Only `SPAWNING_NEXT` may call the idempotent `spawn_active_piece()`, and it returns to `READY_TO_AIM` immediately after one successful spawn. This prevents an unchanged “board settled” condition from generating a launcher repeatedly across frames.

## Gameplay balance boundary

`GameConfig` owns all mobile-feel constants: drag hit range, launch speed, damping, settle threshold, equal-mass collision restitution, border restitution, separation epsilon, merge-presentation timing, chain display stagger, next-launcher readiness delay, and danger grace. `BoardSimulation` consumes those values using `delta`; it does not own balancing literals. `GameController` uses the timing values only for presentation and lifecycle pacing, never for contact eligibility, scoring, chains, outcomes, or queue cardinality.

## Physics and pacing parity boundary

`BoardSimulation` additionally applies a symmetric, centralized tangential contact-resistance value after the normal collision impulse. It only reduces relative tangent velocity and clamps both resulting velocities through `GameConfig.MAX_PIECE_SPEED`; it must never query levels, contacts, chains, score, or launcher state. `ContactMergeService` assigns each upgraded gem a bounded average of its two source velocities through `GameConfig.MERGE_MOMENTUM_TRANSFER` and `MERGE_MAX_SPAWN_SPEED`. Eligibility remains the exact current-step contact rule; momentum handoff happens only after that rule has accepted the pair.
# Visual sequencing and contact v2

- `GameController` owns win qualification and presentation timing, but `ResultOverlayLayer` owns result UI in its dedicated `CanvasLayer`.
- `GemSpriteLayer` remains the only owner of gem sprite texture, transform, and modulation. Overlay presentation has no reference to gameplay sprites.
- `assets/runtime/table/shallow_table.gdshader` is a presentation-only derivative; `GameConfig.table_left_at/right_at` remains the authoritative collision, launcher, danger, and visual-bound model.

## New table and shadow separation v1

`AssetCatalog.NEW_TABLE` loads `new_table_v1.png`; `GameConfig` owns its render scale and every rail. `GemSpriteLayer` pairs a clean body Sprite2D with a separate soft-shadow Sprite2D for each simulation ID. The shadow map cannot reach `BoardSimulation` or `ContactMergeService`; collider and audio truth remain the existing `GemPiece.radius` and confirmed narrow-phase impacts.
