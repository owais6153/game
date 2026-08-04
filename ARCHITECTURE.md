# Architecture

## Reference feedback correction boundary v1

- `GameController` instantiates `ReferenceAudioFeedbackService`, not the retired procedural `AudioFeedbackService`. The active service preloads four user-reference-derived Ogg resources, maps only allowed typed controller events, uses the existing three-player/cooldown boundary, applies no pitch variation, and owns no ambience player.
- Confirmed contact telemetry remains typed and thresholded but never creates a gem transform. `GemSpriteLayer.set_presentation_transform()` normalizes any requested scale to one uniform scalar and forces zero presentation rotation. This makes a changing live silhouette impossible from the production collision/merge routes.
- `GameplayEffectsLayer` owns exactly four reward records per confirmed merge. They form one compact deterministic cluster, depart in `[0,1,2,3]` order, follow one bounded cubic route, and emit integer arrival chunks; controller coins remain authoritative at confirmation.
- `CoinVisuals` draws `AssetCatalog.COIN_REWARD` without horizontal flip/squash. `AssetCatalog` maps the 256 px keyed derivative, while its generated source is preserved outside Godot import under `assets/generated/`.
- Target qualification remains separate from presentation. The collected body still leaves simulation before proxy travel; arrival calls the snapshot-free `TargetRewardOverlay` owned by layer-40 `GameplayHudLayer`, so the bounded ring/check/spark confirmation renders above the target card. The existing controller path alone advances L5 -> L7 -> L8.
- No physics owner changed: `BoardSimulation`, `ContactMergeService`, `GemPiece`, table/rail geometry, radii, restitution, momentum, currency authority, launcher lifecycle, danger handling, and result qualification are unchanged.

## Production gameplay parity boundary v1

- `LevelConfig.level_1()` is the sole ordered objective definition: L5, L7, then L8. `GameController` still registers only unique confirmed merge results, completes the existing visual collection, advances one index, and qualifies victory only after the third objective.
- `GameConfig` remains the single feel and table authority. `vertical_lane_top_y()` analytically intersects a vertical launcher lane with the same trapezoid used by rendering, drag clamps, containment, and danger width; the guide cannot invent a second table shape.
- `BoardSimulation` still owns motion and equal-mass impulses. Contact telemetry now includes the already-computed normal solely for feedback. `GemSpriteLayer` composes a presentation node, impact-axis node, and inverse-rotated artwork node so squash aligns to contact without rotating the supplied gem identity or modifying the physics-mirroring root.
- Merge lift, tilt, non-uniform scale, temporary local z elevation, source ghosts, impact flash, and sparks are presentation only. `GemPiece.position`, radius, perspective scale, velocity, contact capture, merge eligibility, and rails never read those transforms.
- `AssetCatalog.COIN_REWARD` preloads the documented 256 px runtime derivative. `CoinVisuals` draws the same texture in HUD and rewards. `GameplayEffectsLayer` owns bounded fan/cubic-lane records and arrival signals; controller currency is still updated exactly once at confirmation and the HUD only reconciles presentation arrivals.
- `AudioFeedbackService` still builds 18 reusable mono one-shots and one loop at initialization. The richer ambience and louder event mix cannot feed controller decisions; contact sounds remain thresholded/typed/cooled down and haptics remain service-owned.
- Development tests, capture tool, report, and screenshot evidence remain under `tools/` and `reports/`, which are excluded from Android export.

## Reference gameplay + coin feedback boundary v1

- `GameController.coins` is the canonical exact run currency. `_apply_confirmed_merge_events()` remains the sole reward authority and registers the pending HUD reward before updating the controller integer. `score` delegates to the same value only for compatibility; neither HUD nor effects can award currency.
- `GameplayEffectsLayer` owns bounded coin records, deterministic scatter geometry, staggered quadratic flight, drawing, and arrival signals. It never owns currency, physics pieces, input, merge candidates, or lifecycle. Safety capping emits each removed coin's value so display and controller totals still reconcile.
- `GameplayHudLayer` remains snapshot-only for authoritative state. It owns only `_displayed_coins` and pending presentation accounting so the label advances on arrival. `CoinIcon` and `CoinVisuals` provide one procedural visual language without runtime assets or per-coin nodes.
- COINS and NEXT remain equal 154 x 132 responsive cards; the added coin glyph/value row is contained inside the same clipped panel system.
- `BoardSimulation` adds only impacted piece IDs to its existing confirmed-contact telemetry. `GameController` converts eligible telemetry into a short `GemSpriteLayer` child scale; the physics-mirroring root and `GemPiece.radius` remain untouched.
- `AudioFeedbackService` now caches 18 one-shots plus the separate ambience at initialization. Coin cues are original synthesized metallic transients and share the existing reusable-player, cooldown, toggle, and controller-routing boundary.
- Victory qualification remains controller state. Presentation waits while bounded coin records exist, then begins the existing `WIN_PRESENTATION_HOLD`; this cannot change target qualification, launcher blocking, danger handling, or final score/coin state.
- `tools/capture_reference_gameplay_coin_parity.gd`, tests, reports, and screenshots are development-only and excluded from the Android package.

## Physics and reward feedback boundary v1

- `BoardSimulation` resolves approaching equal-mass contact with `j = -v_rel * (1 + e) / 2`, where centralized `GameConfig.COLLISION_RESTITUTION = 0.22`. Tangential friction is applied once inside the approaching-contact branch; overlap correction without approach cannot repeatedly drain sideways velocity.
- Damping, sleep threshold, wall restitution, merge momentum transfer, and spawn-speed cap remain delta-based centralized `GameConfig` values. Table art, slanted rails, perspective mapping, collision radii, contact/separation epsilon, merge candidates, and launcher speed are not part of this tuning milestone.
- `GameController` remains the only score/reward event authority. It maps confirmed result tiers through `MERGE_SCORE_BY_RESULT_LEVEL`, selects the presentation-only major reward at L6+, and routes either direct major haptic or chain haptic without duplicating simulation decisions.
- `GameplayEffectsLayer` owns bounded rings, sparks, and score labels only. Major parameters never reach `GemPiece`, `GemSpriteLayer` physics roots, colliders, target qualification, launcher lifecycle, or input.
- `AudioFeedbackService` builds 15 reusable one-shot streams and one reusable six-second procedural ambience stream during `_ready()`. Its three one-shot players, thresholds, cooldowns, sound toggle, and ambience player cannot feed physics, score, merge eligibility, or results.

## Production UI polish v4

- `HudRows/MainRow` is now a `CenterContainer` dedicated to the 600 x 138 MERGE PATH card. `ScoreNextRow` is a separate responsive `HBoxContainer` below it, with equal 122 x 132 SCORE/NEXT controls separated by an expanding spacer. `ObjectiveRow` remains LEVEL/spacer/Settings; `TableTargetAnchor` remains independent and table-adjacent.
- The eight progression slots are 58 x 58 `MarginContainer` nodes containing aspect-preserved `TextureRect`s. They use `AssetCatalog.gem_texture(tier)` exactly like table sprites and have no circular `PanelContainer`, mask, alternate array, or runtime load path.
- Pause and result composition share `UiDesignSystem.simple_popup_panel_style()`. Pause is a 420 x 408 `PanelContainer`; Win/Fail share a 440 x 500 `PanelContainer`. Each modal remains safe-area centered, input-blocking, duplicate-guarded, tweened, and state-driven.
- `GameConfig.configure_viewport()` owns both portrait-bottom Y offset and non-negative horizontal table-centering offset. `table_center_x()`, `table_texture_center()`, and rail interpolation consume that shared X value. `GameController` shifts live pieces, merge/collection records, debug contacts, and `GameplayEffectsLayer` by the same vector on resize.
- UI layout remains outside the table transform. The horizontal offset changes only coordinate placement on canvases wider than the 720 design width; it does not change table width, perspective, rail shape, radii, collider scaling, velocity, merge rules, scoring, targets, or timing.

## Production UI simplification v3

- `MainRow` is a 652 design-pixel minimum responsive HBox: equal 122 x 122 SCORE/NEXT controls surround a 396 x 122 eight-gem merge panel. SCORE, NEXT, TARGET, and LEVEL use the same native `PanelContainer` coral badge helper; dynamic boxes use `simple_hud_panel_style()` and no decorative bitmap headers.
- The merge strip is the full active Level 1 chain, tiers 1 through 8, resolved only through `AssetCatalog`. Eight 42 px slots and seven 6 px connectors fit the safe-width budget without a second row or icon overlap.
- TARGET is outside the top `HudRows` in `TableTargetAnchor`. It is a 178 x 148 simple card containing only a `TARGET` badge and one 80 px aspect-preserved icon. There are no target-name, target-index, progress-copy, or ProgressBar nodes.
- `_refresh_safe_margins()` computes the target's presentation Y from the authoritative `GameConfig.BOARD_TOP`, base viewport height, current expanded portrait height, and a presentation-only 46 px table gap. It never changes table or simulation coordinates.
- The top utility row contains only LEVEL and Settings separated by an expanding spacer. Target collection still reads the live target icon center, so the approved collection path/timing remains intact after repositioning.

## Production UI corrective composition v2

- SCORE/NEXT use equal 170 x 150 outer NinePatch cards plus clipped native `ContentSurface` panels, keeping dynamic values/icons clear of headers and borders.
- `ProgressionCenter` contains a 296 x 104 cream/gold panel with five catalog-driven 50 px slots. The objective row uses a 116 x 58 Level badge, a 412 x 116 clipped target card, and the existing 88 px Settings button, all vertically centered by one container.
- Target decoration and content are separate layers: body, content surface, header, then margin/HBox with one 56 px aspect-preserved catalog icon and a VBox for name, labeled progress, and a 12 px cached-theme ProgressBar.
- The maximum row minimum is 652 design px, so simulated 24 px side insets plus safe padding fit the 720-wide canvas. Tests assert icon insets and objective baselines at every supported portrait size.
- The danger threshold still reads only `GameConfig.danger_line_y()` and the same rail functions. A dark dashed backing beneath the coral foreground changes contrast only, never failure state, bounds, timing, or collision.

## Production UI system v1

- `scenes/ui/GameplayHud.tscn` and `ResultOverlay.tscn` are the reusable runtime entry points. Both are CanvasLayers outside the table transform and are instantiated once by `GameController`.
- `UiDesignSystem` owns cached theme/font resources, palette, typography sizes, spacing, safe-area padding, panel/button geometry, full button states, ProgressBar styling, and animation timings. Runtime UI code never creates these per frame.
- The HUD is a 720-wide design canvas scaled down only for narrower viewports. A safe `MarginContainer` holds a `VBoxContainer` with a SCORE/progression/NEXT row and a level/target/Settings row. Dynamic cards use NinePatch skins, content margins, aspect slots, and labels rather than fixed-position image hacks.
- `GameplayHudLayer.update_snapshot()` is event-driven and compares controller-owned state before updating. It has no `_process`, runtime load, catalog scan, or node rebuilding path. Score, queue, target, and animation changes kill/replace their bounded tween.
- Result and Pause roots own full-screen input blockers and safe-area-centered cards. Duplicate visibility guards prevent parallel modal instances. Escape/Android Back routing opens/closes Pause first and leaves result actions explicit.
- `AssetCatalog` remains the sole icon/name/texture authority. `ScoreFormatter` remains display-only. Target collection reads the live target icon center but does not change body cleanup, travel duration, reward timing, or win sequencing.
- `reports/.gdignore` and `tools/*` export exclusion keep all audit/capture/test artifacts out of Android packages.

## Gameplay UI and reward-presentation boundary v1

- `GameplayHudLayer` is the production layer-40 `CanvasLayer`. Its Control/container tree reads only `GameController.hud_snapshot()` and owns no queue, target, score, input-on-board, collision, or simulation rule. Supplied SCORE/NEXT skins retain their source aspect; stretchable target/pause/button skins use NinePatch regions; all gem icons use contained `TextureRect` children.
- Settings is the only normal-HUD button. `GameController` owns the three one-time UI signal routes: pause freezes the scene tree after showing a full-screen blocker, Resume restores it, and pause-only Restart delegates to the sole complete `restart()` path.
- `GameplayEffectsLayer` owns bounded, non-physical launch rings, merge impacts, score popups, and target-arrival effects. `GemSpriteLayer` exposes only a transient scale on each gem's `Visual` child; the perspective-mirroring root and `GemPiece.radius` remain authoritative and unchanged.
- Confirmed merge `result_id` values pass through one exactly-once controller guard. Presentation records cache source/result textures at confirmation, so the frame path performs no resource loading, image analysis, or catalog lookup. Procedural sound streams are likewise generated once during `AudioFeedbackService._ready()` and reused.
- A target result becomes presentation-only atomically: erase/consume the `GemPiece`, erase danger state, clear merge registration, trace `physics_body_removed`, then create a separate proxy. The proxy's completion advances L7→L8 or qualifies final victory. `ResultOverlayLayer` starts only after final collection and the post-collection hold.
- `ScoreFormatter` is presentation-only; controller score remains the exact integer and still comes from the unchanged confirmed-event score table.
- `HudRenderer` is retained only as a no-op compatibility type. Production does not instantiate or route input through it.
- `reports/.gdignore` and the Android `tools/*` export exclusion keep test/evidence artifacts out of the runtime package.

## Video-verified bounded launcher handoff v1

- `launcher_handoff_elapsed` separates launcher ownership from simulation motion. A released body keeps normal physics but loses launcher ownership after `GameConfig.LAUNCHER_HANDOFF_DELAY`; queue creation therefore has bounded latency without changing velocity, collision, or settling behavior.
- Merge resolution may advance the launcher lifecycle only when it consumed the actual active launcher. Unrelated board merges cannot overwrite `SHOT_IN_FLIGHT`. `SPAWNING_NEXT` repairs stale ownership before its single idempotent spawn.
- Target collection blocks input while preserving launcher ownership. HUD rendering remains snapshot-only; NEXT and GOAL share aspect-preserving contain scaling and supplied source regions.

## Unlimited launcher runtime recovery v1

- `READY_TO_AIM` verifies that its active body still exists. If it does not, the controller returns to `SPAWNING_NEXT` and creates one configured low-tier launcher. This is a non-terminal recovery path only; danger failure, collection, and win still intentionally block launch generation.
- `tools/run_level_1_flow_tests.gd` runs forty real `_process()` launch-to-replacement cycles, retaining only the new ready body between cycles so launcher continuity is measured independently from normal danger-line capacity.

## Unlimited launcher readiness v1

- `GameController._advance_launcher_lifecycle()` treats only the fired active gem as the readiness gate. Unrelated board motion cannot suppress the next launcher; pending merge and target-collection presentation remain the only intentional temporary blocks.
- HUD restart renders the supplied `Generated image 4.png` REPLAY region and routes to the existing `restart()` method. GOAL is composed from supplied button-sheet header/body regions and displays one contained active target icon.

## Expanded portrait bottom anchor v1

- `GameConfig.configure_portrait_bottom()` owns the sole runtime Y offset for expanded screens. `table_texture_center()`, `board_top()`, `board_bottom()`, `danger_line_y()`, `launch_y()`, and `table_interpolation()` all derive from it.
- `GameController._refresh_background_fill()` applies that offset to the table sprite and any live gameplay/presentation positions after a resize; `BoardSimulation`, launcher spawn, drag bounds, danger evaluation, and debug rails read the same GameConfig accessors.
- The supplied restart region is presentation-only in `HudRenderer`; `GameController._handle_pointer()` is its one input route and delegates to the existing full `restart()` reset.

## Reference-accurate HUD + portrait fill v1

- `HudRenderer` still consumes only `GameController.hud_snapshot()`. It draws supplied SCORE, NEXT, white GOAL, and settings regions from `AssetCatalog.HUD_BUTTON_SHEET`; it has no launcher, target, or input authority.
- `_draw_contained_texture()` is the one HUD preview path. It computes `min(bounds.x/source.x, bounds.y/source.y)`, so supplied gem artwork remains fully visible at its native aspect ratio in NEXT, progression, and the single active target card.
- `GameController._refresh_background_fill()` covers the expanded viewport with the supplied background at a uniform scale. It is presentation-only: the table sprite, GameConfig board coordinates, rails, collision, and motion are not changed.

## HUD and sequential targets v1

- `AssetCatalog.gem_entry(tier)` is the sole presentation identity source for IDs, names, textures, and calibration references.
- `GameController.hud_snapshot()` is controller-owned; `HudRenderer` is presentation-only.
- `LevelConfig.target_sequence` is one visible target at a time. A confirmed merge result completes presentation, collects to HUD, then advances or qualifies victory.
- `GameController._begin_target_collection()` transfers a target result from simulation to presentation atomically: it erases the result from `pieces`, clears its danger/candidate state, then creates the independent fly-to-HUD sprite.
- The top HUD follows the approved gameplay reference composition: score panel left, progression strip center, next preview right. `HudRenderer` remains read-only and outside table coordinates.

## Restored working table rails v1

`GameConfig.table_left_at(y)` and `table_right_at(y)` are again the sole authoritative side-bound model. `BoardSimulation._resolve_bounds()` and `GameController.move_active_to()` use the same interpolation plus the live gem radius. The table artwork remains at `(360, 846)` and the proven historical rail landmarks are translated by its exact `+116px` Y offset. The F8 overlay reads those identical interpolation functions; `tools/capture_rail_debug.gd` is a development-only evidence harness and has no runtime scene reference.

## Physical rails match table v1

`GameConfig.LEFT_RAIL_TOP`, `LEFT_RAIL_BOTTOM`, `RIGHT_RAIL_TOP`, and `RIGHT_RAIL_BOTTOM` are the rail source of truth. `BoardSimulation._resolve_slanted_rail()` resolves each gem by its perpendicular distance to the appropriate physical line and uses the gem's live perspective-scaled radius. `GameController.move_active_to()` derives drag limits from the same line normals. The F8-only diagnostic overlay draws those exact vectors; it has no simulation authority and is disabled by default.

## Matched perspective physics scale v1

`GemPiece` owns an immutable calibrated `base_radius`, a shared `perspective_scale`, and a live `radius = base_radius * perspective_scale`. `BoardSimulation` updates this from authoritative table-local Y before bounds, pair contact, separation, and merge capture. `GemSpriteLayer` applies the same scale only to the whole visual root; its calibrated body/shadow children add no independent depth transform. This project uses a custom deterministic solver rather than `RigidBody2D`, so each gem's scalar radius is independent and no shared collision-shape resource is changed at runtime.

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

## Isolated Level 1 flow v1

`scripts/level_config.gd` is the smallest level-data boundary: it supplies the one default level's active tier range, low-tier weighted deterministic launcher sequence, target tier, target quantity, and empty starting board. `GameController` consumes that configuration for launcher queueing, target snapshots, unique confirmed-result counting, and the normal-play merge cap. `ContactMergeService.max_result_level` defaults to the full catalog maximum, so development tools and the L1-L18 regression suite retain their complete contract. No level-selection, progression, persistence, multi-target, or economy framework is present.

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
# Visible-touch table alignment v1

`GameConfig` owns the authoritative table landmarks, while `GemSpriteLayer` mirrors each `GemPiece` through a constant-scale `PieceVisualRoot` and a centered fixed-scale `Visual` child. The visual-body scale is fixed for the whole piece lifetime; only position and stable Y/ID z-index change during sync. This prevents a sprite from looking smaller or larger than its immutable collision radius. `BoardSimulation`, `GemPiece`, collision radii, merge services, and controller lifecycle remain independent of table presentation.
# Complete perspective view & variety v1

`GameConfig` owns table landmarks and stable z-order. The prior depth math and tier display scales were removed by the visible-touch repair because they did not have matching static collider calibration. `GameController` owns deferred target completion so overlay presentation cannot race the merge result.
