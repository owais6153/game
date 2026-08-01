# AI Knowledge Base

## Production UI simplification guardrails v3

- The approved gameplay HUD visual is `reports/production-ui-simplification-v3/final-screenshots/576x1312/details/screenshot-reproduction-score-1300.png`.
- SCORE, NEXT, TARGET, and LEVEL must keep the shared coral `PanelContainer` badge style. Do not restore atlas ribbon headers, stacked decorative bodies, or separate visual languages for these labels.
- MERGE PATH must show exactly all eight active Level 1 catalog tiers. Keep it horizontal, readable, safe-width compatible, and catalog-driven; do not regress to five tiers or substitute names/duplicate mappings.
- TARGET shows only `TARGET` and the current catalog gem. Do not add its name, `1 / 2`, progress copy, or a progress bar. Sequential target logic remains controller-owned and unchanged even though its count is hidden.
- Keep `TableTargetAnchor` driven from `GameConfig.BOARD_TOP` plus portrait expansion and `TARGET_TABLE_GAP`. This dependency is presentation-only; never move the table to accommodate UI.
- After layout changes, run the production UI, gameplay-feel, Level 1, contact, 18-gem, and motion suites plus the six-resolution capture.

## Production UI corrective guardrails v2

- Treat `reports/production-ui-corrective-pass-v2/final-screenshots/576x1312/details/screenshot-reproduction-score-1490.png` as the minimum visual bar. Do not restore the oversized NEXT gem, low score baseline, floating merge strip, escaped target gem, or detached objective controls visible before `baae648`.
- Keep SCORE/NEXT equal at 170 x 150 and their content inside clipped surfaces. Keep the five-step path in its 296 x 104 panel; do not remove its heading or shrink the 50 px catalog slots.
- Preserve the target hierarchy: header, contained 56 px icon, catalog name, labeled progress, and 12 px bar. Level, Target, and Settings remain centered on the same baseline.
- Keep the top-row minimum safe-inset compatible. Run `PRODUCTION_UI_FINALIZATION_TESTS` after size/margin changes; its containment, baseline, maximum-score, notch, and six-resolution checks are intentional.
- The two-layer danger line is presentation only. Never move its authoritative Y coordinate or change the existing timer/failure logic.

## Production UI finalization guardrails v1

- Use `GameplayHud.tscn`, `ResultOverlay.tscn`, and `UiDesignSystem`; do not restore scattered UI constants, immediate drawing, fixed bitmap text, or parallel popup implementations.
- Keep SCORE and NEXT equal responsive cards. Score formatting is presentation-only and must retain grouped values below 10,000 plus compact K/M/B/T/Q/Qi notation without changing the exact controller integer.
- Keep the Level 1 path to five readable catalog tiers; never squeeze all 18 tiers into the gameplay strip. NEXT, progression, target, and result art must resolve through `AssetCatalog` only.
- The target card must show one current sequential target, its real index, catalog name/icon, numeric progress, and ARRIVING/COMPLETE state. Collection destination is the live target icon center; collection and reward timing are frozen.
- Settings is the only normal-HUD button and retains an 88 px design target. Restart belongs only to Pause. Pause/Result roots must block click-through, remain duplicate-guarded, respect safe areas, and provide normal/hover/pressed/disabled/focus states.
- Preserve Android Back behavior: open Pause during play, close Pause first, and do not dismiss result screens. Do not add an immediate exit path.
- HUD updates are state-driven. Do not add `_process`, runtime `load()`, font/theme creation, image processing, node rebuilding, or repeated signal connections. Run `PRODUCTION_UI_FINALIZATION_TESTS` plus the existing gameplay/contact/18-gem/profile suites after UI changes.
- Before editing this system, read `reports/PRODUCTION_UI_FINALIZATION_V1_REPORT.md` and inspect `reports/production-ui-finalization-v1/final-screenshots/`.

## Final gameplay UI/reward guardrails v1

- The production HUD is `GameplayHudLayer`, not `HudRenderer`. It may read only `hud_snapshot()`. Keep SCORE/NEXT/target/progression gem art on `STRETCH_KEEP_ASPECT_CENTERED`; never restore circular masks, independent-axis stretching, fixed immediate-draw panels, a gameplay Restart button, shot counts, target fractions, or S/V text controls.
- The correct pause Restart is `assets/ui/Generated image 3.png` region `(321,1128,300,100)`. Available arrow assets are BACK, not restart. Settings remains the sole normal-HUD button and at least 88×88 design px.
- Unlimited play is a production state-machine invariant. There is no `shot_limit`, `shots_left`, or decrementing count. Preserve the bounded 0.30 s active handoff, ready-state recovery, collection-during-shot ownership, and the regression that performs 80 additional launches after pause-popup Restart.
- Never animate a `GemPiece`, live radius, perspective root, collider, rail, or physics coordinate for reward feel. Use only the `GemSpriteLayer` visual child or an effects-layer proxy.
- Never travel a live target body toward the HUD. Erase it from `pieces`, danger state, merge registration, occupancy, and live sprite sync before starting the proxy. Preserve the exact final trace: merge confirmed → result created → first visible frame → merge presentation complete → target complete → physics body removed → collection start → collection complete → final confirmation → overlay start.
- Fade target proxies only near arrival (`TARGET_COLLECTION_FADE_START = 0.68`). The next target appears after the first collection completes; final overlay appears only after final collection plus the hold.
- Cache textures into presentation records and synthesize audio streams only during initialization. Do not add frame-time `load()`, image/alpha work, resource/sample creation, signal connection, or unbounded particles/nodes.
- Score formatting is display-only. Do not alter `GameConfig.MERGE_SCORE_BY_RESULT_LEVEL` to make the animation look larger; suppress misleading zero popups instead.
- Before changing this area, read `reports/GAMEPLAY_UI_FEEL_FINALIZATION_V1_REPORT.md` and run `GAMEPLAY_UI_FEEL_TESTS`, `LEVEL_1_FLOW_TESTS`, `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE`.

## Video-verified launcher deadlock guard

- Never use `GemPiece.is_settled()` as the production condition for granting the next launch. A crowded moving body may never sleep. After release, use the bounded centralized handoff delay and demote the fired body without changing its physics.
- Never force `SHOT_IN_FLIGHT` to `RESOLVING` merely because some board pair merged. Confirm that `get_active_piece()` was consumed first, or the stale active marker will make `spawn_active_piece()` refuse forever.
- Regression coverage must include an unrelated merge during a moving shot and target collection during a shot; clearing the board between shots cannot prove the crowded runtime path.
- Restart uses the literal `Generated image 3.png` RESTART asset. No approved circular refresh icon exists; never substitute a BACK arrow. Keep NEXT and GOAL gems centered inside their contain bounds.

## Unlimited launcher runtime proof

- `READY_TO_AIM` without a live active body is invalid in a non-terminal run. Recover by entering `SPAWNING_NEXT`; never leave the player with no launcher or add a numeric limit as a workaround.
- The Level 1 suite must exercise actual `_process()` motion and lifecycle transitions, not only manually assigned launcher states. The GOAL gem preview is a contain box, never a circular crop, and its bounds may be enlarged only within the supplied cream panel.

## Unlimited launcher non-blocking rule

- Never gate `SPAWNING_NEXT` on `all_pieces_settled()`. Only the fired active gem, pending merge presentation, target collection, win, or danger failure may delay a launcher.
- The restart affordance uses the supplied REPLAY source art, never the back-arrow asset. GOAL uses matching header/body supplied regions; the icon must remain contain-scaled inside its cream body.

## Bottom-anchored portrait guardrails

- Never move table artwork independently on tall phones. Call `GameConfig.configure_portrait_bottom()` and use its accessors for every table, rail, launcher, danger, and perspective Y coordinate.
- HUD stays in the fixed top design region. The active target icon must stay within `TARGET_PREVIEW_BOUNDS`; use contain scaling only.
- `RESTART_BUTTON_RECT` is a supplied-art control that calls the existing complete reset. It must not introduce a launch cap, queue reset variant, or parallel gameplay state.

## Reference HUD / unlimited Level 1 guardrails

- Keep HUD gem previews on `HudRenderer._draw_contained_texture()`; never square-stretch or circular-mask a supplied gem texture.
- The visible objective is one active supplied-art GOAL card. Do not reintroduce target fractions, shot counters, or a second future-target card.
- `LevelConfig.level_1()` has no `shot_limit`. Launcher generation must remain cyclic indefinitely, including after `GameController.restart()`, until danger failure or final target qualification.
- With `stretch/aspect="expand"`, cover the current viewport with the supplied background using uniform scale. Never compensate by moving the table or changing gameplay coordinates.

## HUD and sequential target rules

- Never add a parallel gem icon/name mapping; use `AssetCatalog.gem_entry` everywhere.
- Launches are unlimited. There is no production `shot_count` field or hidden launcher cap.
- `AssetCatalog.GEM_TIER_SOURCE_INDEX` and `GEM_TIER_TEXTURES` are an inseparable single mapping: never edit a display name, icon, or source index independently. Run the 18-gem and Level 1 tests after every catalog change.
- For gameplay HUD panels, use the supplied button-sheet regions through `AssetCatalog.HUD_BUTTON_SHEET`; do not redraw visual substitutes when the approved artwork already exists.
- At the start of target collection, remove the result from `GameController.pieces` before creating the fly-to-HUD visual. A collection animation must never retain a simulation entity, danger timer, merge candidate, or board-occupancy entry.
- Event order is confirmed merge, result creation, merge presentation, collection animation, then next target or win overlay.

## Restored rail baseline (read before any table/rail change)

The approved current rail behavior is the table-interpolated implementation from historical commit `0b562d5` (`new-table-shadow-contact-fix-v1`), translated by exactly `+116px` in Y for the bottom-aligned table. Do not reintroduce `_resolve_slanted_rail()`, rail normal helpers, separate rail colliders, or normal-movement side clamps. `BoardSimulation._resolve_bounds()` and `GameController.move_active_to()` must both use `table_left_at(y)` / `table_right_at(y)` with the live gem radius. Before changing this area, read `reports/RESTORED_WORKING_TABLE_RAILS_V1_REPORT.md` and inspect the three development-only overlay captures under `reports/restored-working-table-rails-v1/`.

## Physical rail guard

The custom deterministic solver has no `StaticBody2D` or `CollisionShape2D` rail nodes. Do not add them. The two physical walls are the slanted lines in `GameConfig`: left `(171.4, 413.0) → (40.7, 1226.0)`, right `(547.8, 413.0) → (680.1, 1226.0)`. `BoardSimulation._resolve_slanted_rail()` is the only normal-movement rail resolver. Never restore `table_left_at(y) + radius` / `table_right_at(y) - radius` clamps for moving pieces: that approximation creates visible drift on the trapezoid. Keep F8 diagnostics development-only and read `reports/PHYSICAL_RAILS_MATCH_TABLE_V1_REPORT.md` before a rail or table-art change.

## Matched perspective physics scale v1

For table-depth perspective, never scale a gem sprite independently. Use `GemPiece.apply_perspective_scale()` and `GameConfig.gem_perspective_scale_at(y)` so the visual root, separate shadow, live collision radius, rail containment, pair contact, and merge eligibility share one scale. The custom solver has no `CollisionShape2D` resources; do not introduce shared shape mutation or frame-time alpha/texture work.

## 18-gem progression validation v1

The current approved base is `18-gem-order-v1`. Run `tools/run_18_gem_chain_tests.gd` for all 17 upgrades and safety guards; use `tools/manual_merge_harness.gd` only as a development command-line helper. It must never be added to `Game.tscn`, autoloads, Android runtime input, or a production UI. Preserve current-step contact capture, pair de-duplication, consumed-source lock, local-chain behavior, terminal L18, and cached texture access.

## Current isolated catalog milestone

The repository was deliberately restored to `new-table-shadow-contact-fix-v1` before the 18-gem work. Do not reintroduce multi-target levels, unlimited-shot rules, perspective scaling, Y sorting, table changes, or HUD redesign when working on this catalog. Read `reports/18_GEM_CHAIN_V1_REPORT.md` and preserve `assets/gems/` originals; modify only runtime derivatives if asset work is required.

## 18-gem motion guard

Never use `load()`/`ResourceLoader.load()` from `AssetCatalog.gem_texture()` or `GemSpriteLayer.sync_gems()`. Runtime textures are preloaded and must remain at or below a 256 px long edge. The layer may update sprite/shadow positions per frame, but texture assignment, scale calculation, alpha processing, and physics-body radius changes are creation/tier-change work only. Read `reports/18_GEM_MOTION_SMOOTHNESS_FIX_V1_REPORT.md` before any 18-gem rendering change.

## Level 1 flow v1

Read `reports/LEVEL_1_FLOW_V1_REPORT.md` before changing the default game flow. `LevelConfig.level_1()` is the only authority for Level 1's L1-L8 active range, L1/L2 launcher sequence, and one target type. Target progress may be updated only inside `GameController._apply_confirmed_merge_events()` from a unique merge `result_id`; never derive it from the board, queue previews, launcher pieces, debug helpers, or restore state. Keep the full 18-tier merge-service default for development tests; the controller applies the normal-play cap from level data.

## Sound + Haptics v1 update

- Never call audio or `Input.vibrate_handheld` directly from simulation, merge, score, or HUD drawing code. Route confirmed events through `AudioFeedbackService` / `HapticsService` in `GameController`.
- Collision feedback must use `BoardSimulation.consume_collision_impacts()` and the central threshold/cooldown values. Do not add feedback to overlap separation.
- `reports/SOUND_HAPTICS_V1_REPORT.md` records the event map and phone test checklist. Settings are session-only by design until the later save milestone.

## Project at a glance

Gem Merge Rebuild is a lightweight, portrait 2D Godot game. The intended visual theme is precious stones: Pearl (L1), Ruby (L2), Emerald (L3), Sapphire (L4), and Diamond (L5). The current milestone deliberately uses built-in circles and drawing only; final gemstone artwork, UI, sound, scoring, win/fail, persistence, ads, menus, levels, analytics, and backend are deferred.

## Supplied art integration v1

- Source art is preserved under `assets/`; only named copies under `assets/runtime/` are loaded by gameplay.
- `AssetCatalog` is presentation-only: L1 Pearl, L2 Ruby, L3 Emerald, L4 Sapphire, L5 clean Diamond. `GemSpriteLayer` uses Sprite2D for live pieces; `GemVisuals` uses the same catalog for HUD previews and merge ghosts.
- The background is a full-screen Sprite2D and cannot intercept game input. The table is a Sprite2D at `GameConfig.TABLE_TEXTURE_CENTER`.
- Never derive collision shapes from artwork. The circular `GemPiece.radius`, current-step physical contact capture, merge rules, score, danger timers, and launcher lifecycle remain authoritative.
- The table is trapezoidal. Always use `GameConfig.table_left_at(y)` / `table_right_at(y)` for any new rail-sensitive presentation or gameplay coordinate; do not reintroduce a mismatched visual rectangle.

## Visual-physics calibration v1

- Use `assets/runtime/gems_calibrated/`, never alter user-source artwork. Final runtime boxes are Pearl 421x477, Ruby 448x476, Emerald 368x474, Sapphire 476x483, Diamond 460x368.
- Collider radii are deliberately level-specific: 42/42/32/42/33 for Pearl through Diamond. Do not revert to one 42 px collider or derive complex polygons from artwork.
- Keep `CONTACT_EPSILON` at 0.75 px unless a dedicated calibration task supplies evidence. Contact sound must route from `BoardSimulation` confirmed impact records, never proximity/broad-phase checks.
- F8 enables rails/collider/contact debug only in desktop/editor inspection. It must remain off by default and must never change simulation state.

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

All current tuning lives in `scripts/game_config.gd`. Do not retune them in unrelated work.

| Feel value | Approved default | Safe range | Notes |
| --- | ---: | --- | --- |
| Launch speed | 1100 px/s | 1000–1180 | Straight upward only. |
| Velocity damping | 285 px/s² | 250–330 | Delta-based; never use frame constants. |
| Sleep speed | 9 px/s | 7–12 | Below this, velocity becomes exactly zero. |
| Collision restitution | 0.48 | 0.40–0.58 | Equal-mass normal impulse only. |
| Side/top/bottom restitution | 0.20 / 0.14 / 0.10 | 0.15–0.25 / 0.10–0.20 / 0.08–0.14 | Containment feel only. |
| Source pull / merge pulse | 0.10 s / 0.20 s | 0.08–0.14 / 0.16–0.26 | Presentation only. |
| Chain visual stagger | 0.07 s | 0.05–0.10 | Logic stays immediate/deterministic. |
| Next launcher ready delay | 0.08 s | 0.05–0.12 | Does not alter one-spawn invariant. |
| Danger grace | 0.75 s | 0.65–0.90 | Settled, non-active board pieces only. |

## Gemstone visual prototype

The current visual set is intentionally procedural and asset-free: Pearl is circular with a creamy highlight, Ruby and Sapphire are faceted, Emerald is emerald-cut, and Diamond is multi-faceted. `GemVisuals.visual_style_name()` is covered by the headless test suite. Rendering has no physics authority. The safe merge-presentation ordering is ghosts/ring/glow first, then live gems; retain it unless a dedicated presentation task verifies an alternative.

## Visual refinement v1

The visual system is still asset-free and low-cost: flat layered drawing calls only, with no shaders, blur, bloom, post-processing, or scene-node-per-particle effects. `GameConfig.HUD_RECT`, `OVERLAY_RECT`, `OVERLAY_BUTTON_RECT`, and `SAFE_VISUAL_MARGIN` are visual layout constants only. Do not use them to alter the board, launcher, danger line, collision, or input coordinates. `run_clean_contact_tests.gd` asserts that the HUD and result controls fit the fixed portrait design canvas; Godot canvas-item stretching carries that layout to portrait devices.

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

## Physics and pacing parity v1

## Reference table + crystal audio v1

Never redraw a differently sized table without changing the same centralized physical bounds and viewport tests. Gem/wall impact telemetry is feedback-only. `AudioFeedbackService` is the project-safe crystal identity: keep the inharmonic transient design or replace it only with clearly licensed original assets, never generic beeps or commercial samples.

## Progression HUD v1

`HudRenderer` is a presentation-only helper. It receives `GameController.hud_snapshot()` (current level, next level, score, chain multiplier, shots, target level, highest live level) and draws the compact queue cards plus the Pearl-to-Diamond strip. Do not put queue advancement, target logic, drag input, or simulation state in this renderer. `GameConfig` owns its visual rectangles; their values must never enter board/collision math.

The active reference comparison files are intentionally local and ignored by Git: `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4` (target) and `WhatsApp Video 2026-07-29 at 6.53.59 AM.mp4` (current build). Do not commit, rename, or treat them as game assets.

| Feel value | Parity default | Guardrail | Notes |
| --- | ---: | --- | --- |
| Board horizontal bounds | 30..690 px | fixed design canvas | Wider cluster room; all collision geometry uses the same bounds. |
| Gem radius | 42 px | keep collision and rendering aligned | Larger gems without narrowing the table. |
| Launch / damping | 1160 / 235 | 1120–1200 / 210–260 | Delta-based and straight upward only. |
| Normal / tangential collision | 0.34 / 0.18 | 0.28–0.42 / 0.12–0.24 | Tangential resistance is symmetric; never use it for merge decisions. |
| Merge momentum | 35%, max 260 px/s | 25–45%, 200–300 px/s | Applied after a valid merge only. |
| Presentation / ready delay | 0.18 s / 0.04 s | 0.16–0.22 / 0.03–0.06 | Launcher still waits for full settlement and presentation completion. |
# Visual sequencing contact milestone

For Diamond wins, never present the overlay directly from confirmed merge handling. Set `win_qualified`, synchronize the spawned Diamond, wait until `merge_presentations` finishes plus `WIN_PRESENTATION_HOLD`, then set `win_presented`. Result overlays must use `ResultOverlayLayer` and must never modulate `GameController`, `GemSpriteLayer`, or individual gem sprites.

Visible contact is calibrated through `GEM_COLLISION_RADIUS`, `GEM_VISUAL_BODY_SCALE`, `CONTACT_EPSILON`, and `SEPARATION_EPSILON` in `GameConfig`. Do not change one without updating the focused contact tests and report.

# 18-gem size and collision calibration v1

For L1-L18, use `assets/runtime/gems18/calibrated/` only through `AssetCatalog.GEM_TIER_TEXTURES`. These assets were measured once by `tools/calibrate_18_gem_bodies.gd`; do not load source files, read alpha pixels, resize colliders, or calculate texture bounds while the game is running. `GEM_VISUAL_BODY_SCALE` and the per-tier shadow maps are presentation-only. Their circle radii remain stable in `GEM_COLLISION_RADIUS`; changes to them require the calibration report and `run_18_gem_chain_tests.gd` coverage.

## New table + shadow separation v1

## 18-gem final order v1

`AssetCatalog.GEM_TIER_SOURCE_INDEX` is the sole tier-to-artwork authority: do not infer an asset from its old `tier_XX.png` filename. A catalog reorder must move the matching `GEM_COLLISION_RADIUS` and shadow metadata with the artwork, then update the exact-order test. The final order and names are documented in `reports/18_GEM_ORDER_V1_REPORT.md`; gameplay still merges numeric levels only.

- The active table is `AssetCatalog.NEW_TABLE`, not the old coral derivative. Its visual scale and physical rail coordinates are centralized in `GameConfig`.
- Live gems load from `assets/runtime/gems_body_v2/`. Former calibrated textures remain source/provenance only. Never allow shadows, glows, sparkles, or transparent padding to influence `GemPiece.radius`.
- `GemSpriteLayer._shadows` is presentation-only. Shadow overlap is not a physical contact and cannot trigger merge, sound, score, or wall handling. F8 shows shadow bounds in cyan and remains disabled by default.
# Visible-touch table alignment v1 guardrails

- Dynamic gem perspective and uncalibrated tier scaling are disabled. `GameConfig.gem_visual_scale_at()` must return the fixed approved scale for every level and board Y.
- `GemSpriteLayer` uses a constant-scale `PieceVisualRoot` plus a centered, fixed-scale `Visual` container. Never scale or offset either node during movement.
- Depth order comes from `GameConfig.gem_visual_z_index(piece_id, table_y)`. It uses normalized table-local Y and stable ID tie handling. Do not reparent sprites during play.
- Table image position and all playable landmarks must move together through `GameConfig`; do not introduce isolated visual offsets.
# Complete Perspective View & Variety v1 guardrails

- The earlier visual-only Y perspective/tier growth has been removed because it created invisible collision gaps. Do not restore it without a separate static per-silhouette collider-calibration milestone.
- Keep the table image, rails, launcher, drag clamp, spawn, and danger line in the shared `GameConfig` table transform.
- Target merge IDs enter `pending_target_presentations`; only `_update_merge_presentations()` may count them and qualify victory.
