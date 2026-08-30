# Architecture Addendum - Final HUD/VFX/Audio Boundaries

`GameplayHudLayer` still consumes controller snapshots only. Its centred objective anchor is allowed to occupy the unused horizontal gap between corner utilities, which prevents the optional Shots panel from forcing the progression path onto table art. `GameConfig` table geometry remains authoritative and is read only as a presentation landmark; HUD layout never changes simulation coordinates.

`GameplayEffectsLayer` owns the tiered merge ladder. `GameConfig.merge_vfx_tier_scale()`, `merge_vfx_spark_count()`, and `merge_vfx_shard_count()` map the already-authoritative result tier to bounded drawing parameters. Exact color comes from `GameConfig.gem_color()`. The layer creates no gameplay bodies and caps shards at 90.

`PowerCinematicLayer` owns a single procedural, node-bounded timeline with per-power style multipliers. `GameController` stages the authoritative effect first, applies it only from `impact_reached`, and lets a skip jump to that same signal; presentation length or frame rate cannot change the outcome.

Collision telemetry remains simulation output. `GameController._route_collision_feedback()` removes merge pairs, preserves visual response for every confirmed impact, sorts remaining audio candidates by strength, and forwards at most three. `AudioFeedbackService` separately caps active contact voices at three inside its five-player priority pool, leaving two voices available for higher-priority merge/reward/power/result cues.

# Architecture Addendum - Supplied UI Kit and Typography

`scripts/ui/ui_kit.gd` (`UiKit`) is a new presentation-only module owning the supplied art kit: preloaded runtime textures plus `nine_patch_style()`, which builds a `StyleBoxTexture` from the margins recorded in `UiKit.NINE`. Only assets listed in `NINE` may stretch; fixed-composition art (a coin seated inside a plate, gems along a bar) is rejected by `assert` rather than smeared, and is drawn through `UiKit.texture_rect()` at its natural aspect. `UiKit` must never be consulted by simulation, merge-service, launcher, or collision code.

`UiDesignSystem` consumes `UiKit` and remains the single source of theme truth. It now registers five button families as theme type variations — `Button` (gem pill), `SecondaryButton` (plain gold pill), `HeroButton`, `GreenButton`, and `IconButton` — so the kit reaches every screen and popup through the shared theme instead of per-screen overrides. It also owns three font accessors: `font()` (Nunito Sans 800), `heavy_font()` (Nunito Sans 1000), and `display_font()` (Cinzel Black), plus `style_label()` for the shared outlined-text treatment.

`DailyMissionService` is a pure module: every entry point deep-duplicates the supplied state and returns a fresh Dictionary, and `record()` returns `{state, changed}`. This is what allows `GameController` to persist on an explicit change flag and to grant or deduct only after a successful save — an in-place service makes both impossible, because the caller's "previous" state is the same object it is comparing against.

Overlay layer ordering is a real constraint, not a detail: `GameplayHudLayer` 40, `ResultOverlayLayer` 50, `HomeOverlayLayer` 60, `DailyMissionsOverlayLayer` 65. A popup must sit above whichever surface opens it.

# Architecture Addendum - Skip Level Sink and Current Gem Reroll

Reference refinement V2 changes presentation tokens only: the live Switch Gem control is a 112 px squircle using `arrows_clockwise_white.svg`, and the right utility stack reads compact `NEXT_PANEL_SIZE`/`NEXT_ICON_SIZE` plus an explicit 12 px container separation before Settings. Controller snapshots, input signals, economy authority, and table physics are unchanged.

The finalized presentation distributes one controller intent across three snapshot-only surfaces. `GameplayHudLayer` owns the sole live-board economy control: a 112 px bright-rimmed Switch Gem squircle with a curated runtime clockwise-arrows SVG and transient spend popup; it also owns the Pause Skip action. `HomeOverlayLayer` owns Level Ready Skip and `ResultOverlayLayer` owns Failed Skip. All emit into `GameController`; none mutate progression or coins. Successful Level Complete deliberately exposes no Skip action.

The supplied @icons editor library is not a runtime dependency. `addons/at-icons/*` and `@icons picker.html` remain in `export_presets.cfg`'s exclusion filter; only selected small runtime SVG derivatives under `assets/runtime/ui/icons/` are preloaded by player-facing layers. This supersedes the earlier two-live-button presentation description below.

Skip Level reuses the reroll's crossing pattern: `GameplayHudLayer` exposes `skip_cost`/`skip_enabled` and emits one `skip_level_requested` intent it cannot act on directly. `GameController._on_skip_level_requested()` is the sole authority — it deducts the flat cost from the banked baseline, computes the next level's seed via the same `LevelConfig.seed_for_level()` a normal completion would use, and writes level/seed/coins through one atomic `ProgressionSaveService.save_progress()` call before any in-memory state changes, matching the reroll sink's rollback-safe contract. There is no win state, reward, or interstitial in this path — `won`/`completion_*` are never touched, so it cannot be confused with a real completion in analytics or save data.

Reroll now targets the currently aimable launcher gem (`GameController.get_active_piece()`) rather than the queued Next preview: `_on_reroll_next_requested()` only proceeds while `launcher_state == READY_TO_AIM`, then mutates that `GemPiece`'s `.level`/`.base_radius` in place. `GemSpriteLayer` already re-reads `piece.level` every sync pass and swaps texture/visual-scale/shadow automatically, so no presentation code needed to change.

The Switch Gem action is the only live circular button and shows cost through `_show_sink_cost_popup()`. Skip uses standard modal buttons with permanent price text at the Level Ready, Pause, and Failed decision points.

A Google Play Games Services v2 integration (sign-in autoload, achievements, daily streak, local reminder notification) was built and device-verified in this session, then fully removed at the user's request rather than shipped partially configured — no `PlayGames`/`StreakReminder` autoload, native plugin, manifest entry, or Gradle dependency remains in the tree. `ProgressionSaveService` is back to its original three-field schema (`level_number`, `seed`, `total_coins`).

# Architecture Addendum - Production Analytics and V1 Coin Sink

`GameController` remains the only gameplay/economy authority. It counts attempts and actual launches, observes confirmed merge/target/end transitions, and supplies flat analytics context. `AdManager` owns fullscreen callback truth and carries immutable request context into SDK shown/earned/failure events. Neither analytics result nor Firebase availability feeds ads, rewards, navigation, or simulation.

The Next Gem reroll crosses the existing HUD snapshot boundary through `reroll_cost` and `reroll_enabled`. `GameplayHudLayer` emits one intent and cannot mutate currency or the queue. The controller samples a different entry from the existing weighted launcher sequence, writes the reduced banked balance through `ProgressionSaveService`, then commits the displayed balance and `next_level`. The active launcher and future deterministic queue are untouched.

Banked balance and unresolved run earnings remain distinct through the existing `level_start_coins` baseline. Spending reduces both displayed coins and that banked baseline; only the banked value is written mid-attempt. This preserves Retry rollback and prevents force-close reward duplication. No save-schema migration is required.

# Architecture Addendum - Acknowledged Firebase Custom-Event Pipeline

`Analytics` is an early Autoload and the only GDScript/native Firebase boundary. Callers submit fixed event names plus flat primitive dictionaries. The service validates/sanitizes them, emits a test-visible request signal, discovers the `FirebaseAnalytics` engine singleton via `Engine.has_singleton()`, invokes its exact `logEvent(String, String)` API, and logs the returned acceptance result. Desktop/editor absence remains a safe no-op.

`FirebaseAnalyticsPlugin` remains registered by the persistent custom-template v2 manifest metadata. It exposes `logEvent` through `@UsedByGodot` and an explicit `getPluginMethods()` entry; both mechanisms cause Godot's `GodotPlugin.onRegisterPluginWithGodotNative()` to call `nativeRegisterMethod` for it (confirmed by decompiling the bundled `godot-lib.template_release.aar`). **`analytics_service.gd::_native_bridge()` must never gate the returned singleton on `Object.has_method("logEvent")`** — two release-device runs proved that check unreliably returns `false` even though the method is natively registered and callable; only the actual `logEvent` call's own boolean result is authoritative. It retries `FirebaseAnalytics.getInstance()` when an event arrives if the Godot Activity was unavailable during plugin construction, translates JSON primitives to `Bundle` values, forwards to Firebase, logs native success/failure, and returns a boolean. Firebase automatic collection does not use this bridge.

`GameController` owns per-run start/end duplicate guards and reports only existing confirmed merge/target/win/fail transitions. `AdManager` owns per-fullscreen-session shown guards and reports shown only from `on_ad_showed_full_screen_content`; earned reward remains the only rewarded-completion authority. No analytics result can feed simulation, UI, score, currency, ads, or navigation.

# Architecture Addendum - Rail, Target Blast, and Gem Expansion V1

`AssetCatalog` now preloads 34 alpha-tight runtime textures and immutable metadata entries. The two new identities extend only presentation selection; `LevelConfig` continues mapping selected identities into local L1-L8 roles, and no display name or source pixel enters simulation.

`GameConfig` remains the single geometry and tuning authority. The measured table opening, enlarged L6-L8 radii, five-ring density, blast radius/impulse, and music gain are centralized constants. `BoardSimulation`, renderer, launcher/drag clamp, danger line, and diagnostics continue reading the same rail functions.

The target blast is an exactly-once controller consequence of an already-confirmed active-target merge. `_apply_target_merge_blast()` adjusts only velocity on eligible existing board pieces; it excludes the result and active launcher, creates no bodies, captures no contacts, and never calls the merge service. The next simulation step remains responsible for ordinary damping, containment, collision, and any later confirmed merge.

`GameplayEffectsLayer` reads `ring_layers` and `ring_segments` from the stored merge timeline. Five target rings are one capped immediate-mode record with computed scale/alpha; no particles, physics nodes, texture loads, or per-ring allocations are introduced.

# Architecture Addendum - Gem Registry and Pattern Blocks V1

`AssetCatalog.GEM_DEFINITIONS` is the single immutable metadata authority for all 32 visual identities. Queries filter cached dictionaries by audited shape, color family, color style, rarity, or excluded color; no runtime directory scan, filename inference, display name, or pixel analysis occurs during play. Textures remain preloaded once. Simulation sees only local L1-L8 and `GameConfig.gem_collision_radius()`.

`LevelConfig.pattern_for_level()` reconstructs block history as a pure seeded function. Each deterministic 3-4-level block owns one family/dominant value, and `generated()` selects four Common identities, one support Unique, and three target Unique identities into fixed local roles. The generator returns pattern metadata for debugging/tests; the controller still consumes ordinary local tiers and target dictionaries.

Target authority remains in `GameController`. Confirmed merge state advances once, while presentation reads that event: `GameplayEffectsLayer` draws bounded ring records/coins, `GemSpriteLayer` handles radial feedback, and the controller owns one collection proxy after removing the real result body. The 1.12 target scale and center/HUD path never feed simulation. Audio remains event-service-owned.

`UiDesignSystem` remains the only style authority. Both StyleBoxFancy and StyleBoxFlat factories explicitly disable shadows, so HUD consumers need no per-panel overrides and layout metrics remain untouched.

# Architecture Addendum - Supplied Art and Responsibility-Based Layout V1

## Script boundaries

- `scripts/core`: immutable/shared data and rules (`GameConfig`, `AssetCatalog`, `LevelConfig`, pieces, contacts, score formatting).
- `scripts/gameplay`: simulation, merge resolution, and `GameController` orchestration.
- `scripts/presentation`: sprites and feedback that consume confirmed controller state/events.
- `scripts/ui`: snapshot-only HUD/Home/Result presentation.
- `scripts/services`: ads, audio, haptics, settings, and persistence boundaries.
- `scripts/dev`: development-only reproducible asset preparation; excluded from Android export through its input/output boundaries and the export filter.

## Asset boundary

Preserved source art lives in semantic `assets/backgrounds`, `assets/tables`, `assets/gems`, and `assets/ui` folders. `assets/runtime` contains only optimized resources preloaded by production code. `scripts/dev/prepare_supplied_art_refresh.gd` is the authoritative source-to-runtime transform and writes `assets/runtime/art_refresh_manifest.json`. Android excludes the source folders while including runtime derivatives.

`AssetCatalog` owns presentation selection and generic gem identities; simulation never reads pixels or names. `GameConfig` remains the only table geometry authority for the table sprite transform, rails, board limits, drag clamp, launcher, danger line, containment, and tests. Table pixels are measured offline to calibrate constants but never queried by gameplay.

The HUD consumes controller snapshots only. Gem artwork is the visible identity; no name field or target-name node participates in the UI. Theme tokens remain centralized in `UiDesignSystem`, so the amethyst pass changes surfaces/colors without changing layout ownership.

# Architecture Addendum - Simultaneous Reward Reveal and Immediate Physics V6

## One authoritative coordinate from the first visible frame

`GameController._schedule_bonus_gems()` stores the confirmed result timeline on the pending reward and schedules it for that timeline's `reveal` plus the existing depth stagger. `_update_pending_bonus_spawns()` passes frame overshoot into `_spawn_bonus_reward()`, so every sibling created by one event receives the same elapsed value. `_bonus_result_scale_for()` samples `_merge_result_transform_for()` at `reveal + elapsed`; the result and all siblings therefore use the same pop phase even when a render frame crosses the scheduled time by a fraction.

Each reward is created directly at its collision-safe `GemPiece.position`. `GemSpriteLayer` owns only its temporary uniform presentation scale; the former extraction offset, elevation, tether records, and source recoil path have been removed. There is no second coordinate layer for reward appearance.

## Physics is not gated by presentation

`_spawn_bonus_reward()` assigns the configured 135 px/s velocity before appending the piece. Because pending rewards update before `BoardSimulation.step()` in the controller process, a reward integrates and resolves bounds/pairs in the same frame it first becomes visible. `GemPiece` no longer has activation-delay or pending-velocity state, and `BoardSimulation` no longer has activation holds.

`bonus_merge_grace_remaining` remains a narrow merge-confirmation gate. `_resolve_pair()` always performs physical overlap correction and collision response, but omits `ContactMergeService.capture_contact()` while either piece is fresh. Grace expiry restores ordinary merge eligibility. It does not affect position, radius, velocity, substeps, containment, collision telemetry, sound routing, or shadows.

Population and cascade ownership are unchanged: the controller still applies the three-piece shot budget, COMBO 2 generation ceiling, 24-piece live-plus-pending cap, lower-tier eligibility, and distinct-sibling fallback before creation.

# Architecture Addendum - Reward Split Readability V5

## One real piece, two coordinate layers

The controller still creates each reward once at its collision-safe authoritative `GemPiece.position`. `GemSpriteLayer.set_bonus_extraction_transform()` applies only a visual offset back to the current confirmed-result position, elevates that visual above the result, and stores a bounded draw-only extraction record. The record supplies an origin ring/tether and current visual tip to `_draw()`; it is erased with every presentation clear, stale-piece removal, restart, failure, and viewport shift. Simulation never reads the offset, scale, elevation, tether, color, or shadow.

`bonus_activation_delay_remaining` keeps the real body out of integration and pair contact for the complete 780 ms visual split. On release, `BoardSimulation._resolve_pair()` performs ordinary overlap correction and collision impulse, but omits `ContactMergeService.capture_contact()` while either participant has positive reward release grace. This 650 ms gate intentionally permits a visible collision before a possible later merge. `BoardSimulation.step()` expires the marker and returns the piece to ordinary eligibility; geometry and collision radii are unchanged.

The requested-count ladder and weighted lower-tier selection remain in `GameController._schedule_bonus_gems()`. A uniqueness fallback operates only inside one multi-gem split and only when the eligible range is large enough, so siblings are visually distinct without hardcoded gem identities. The three-piece shot budget, depth ceiling, and population cap remain upstream of creation.

## Live target-reward origin

`GameplayEffectsLayer` stores each coin's cluster offset and arc height. While the group is still unrevealed, `GameController._sync_pending_target_coin_origins()` asks for pending result IDs and re-anchors the group to the live result piece. The anchor freezes when elapsed time reaches zero, giving every token one shared truthful source and a stable later flight. This presentation synchronization does not move a gem or alter the awarded amount.

Coin shadows now draw at each token's computed current position, not its final scatter point. Gem shadows remain supplied Sprite2D artwork under the presentation root; larger lower offsets expose the ellipse below the opaque gem body. Neither shadow is an input to contact capture, merge eligibility, or containment.

# Architecture Addendum - Reward Split Readability V5

## One real piece, two coordinate layers

The controller still creates each reward once at its collision-safe authoritative `GemPiece.position`. `GemSpriteLayer.set_bonus_extraction_transform()` applies only a visual offset back to the current confirmed-result position, elevates that visual above the result, and stores a bounded draw-only extraction record. The record supplies an origin ring/tether and current visual tip to `_draw()`; it is erased with every presentation clear, stale-piece removal, restart, failure, and viewport shift. Simulation never reads the offset, scale, elevation, tether, color, or shadow.

`bonus_activation_delay_remaining` keeps the real body out of integration and pair contact for the complete 780 ms visual split. On release, `BoardSimulation._resolve_pair()` performs ordinary overlap correction and collision impulse, but omits `ContactMergeService.capture_contact()` while either participant has positive reward release grace. This 650 ms gate intentionally permits a visible collision before a possible later merge. `BoardSimulation.step()` expires the marker and returns the piece to ordinary eligibility; geometry and collision radii are unchanged.

The requested-count ladder and weighted lower-tier selection remain in `GameController._schedule_bonus_gems()`. A uniqueness fallback operates only inside one multi-gem split and only when the eligible range is large enough, so siblings are visually distinct without hardcoded gem identities. The three-piece shot budget, depth ceiling, and population cap remain upstream of creation.

## Live target-reward origin

`GameplayEffectsLayer` stores each coin's cluster offset and arc height. While the group is still unrevealed, `GameController._sync_pending_target_coin_origins()` asks for pending result IDs and re-anchors the group to the live result piece. The anchor freezes when elapsed time reaches zero, giving every token one shared truthful source and a stable later flight. This presentation synchronization does not move a gem or alter the awarded amount.

Coin shadows now draw at each token's computed current position, not its final scatter point. Gem shadows remain supplied Sprite2D artwork under the presentation root; larger lower offsets expose the ellipse below the opaque gem body. Neither shadow is an input to contact capture, merge eligibility, or containment.

# Architecture Addendum - Reward Split Readability V5

`GemSpriteLayer.set_bonus_extraction_transform()` visually offsets each already-safe real reward body back to its confirmed result, elevates it, and draws a bounded origin tether. Simulation never reads this transform. The 780 ms activation hold excludes the body from integration/contact; after release, `BoardSimulation` still resolves physical collisions but suppresses merge capture for 650 ms when either participant is a fresh reward. Expiry restores ordinary contact-only eligibility.

`GameController._sync_pending_target_coin_origins()` re-anchors unrevealed coin groups to the live result through `GameplayEffectsLayer.reanchor_pending_target_coin_reward()`. The anchor freezes on reveal and cannot affect award authority. Coin shadows use computed current token positions; gem shadows remain supplied presentation-only sprites with lower exposed offsets. No shadow enters physics, containment, telemetry, or merge decisions.

# Architecture Addendum - Reward Feedback Real Gems V4

## Real merge rewards remain inside existing simulation ownership

`GameController._apply_confirmed_merge_events()` schedules one bounded reward record per confirmed result. `_update_pending_bonus_spawns()` later creates ordinary `GemPiece` objects and appends them to the same `pieces` array used by launchers and merge results. No visual service owns, deletes, absorbs, or awards those pieces.

Scheduling is bounded three ways before a record is created. `bonus_spawn_budget_remaining` resets only when the player launches a new piece and permits three generated reward bodies across that shot's entire chain. Depths above COMBO 2 do not generate another reward tier. `BONUS_BOARD_PIECE_CAP` counts live plus already-pending bodies and refuses rewards above 24. Exhausting a bound changes no existing body and blocks no ordinary merge; it only omits additional generated rewards.

`GamePiece` carries only temporary `bonus_event_id` and `bonus_merge_grace_remaining` fields. `BoardSimulation.step()` expires them. `_resolve_pair()` still performs its normal physical collision, but skips `ContactMergeService.capture_contact()` only when both pieces share an active event grace. Contact with pre-existing pieces is unchanged. This is the sole simulation-path change.

Spawn selection consumes `GameConfig` and authoritative table interpolation for bounds/clearance. It does not consult textures, gem names, HUD state, target state, score, or physics eligibility. IDs come from the controller's existing monotonic `next_piece_id` source.

## Radial merge shader stays in the rendering helper

`GemSpriteLayer` owns eight preallocated Sprite2D slots and one canvas-item shader source. Each slot has only its own uniforms so simultaneous chain bursts can vary intensity without compiling separate shaders. The pool is rendered behind live gem sprites and is updated/cleared through presentation methods; simulation never reads it.

Reward pieces are created at collision-safe simulation positions, but `set_bonus_spawn_transform()` initially offsets their visual children back to the merge midpoint. For 340 ms the visual scales up at that center and settles outward while `bonus_activation_delay_remaining` excludes the body from integration, bounds contacts, pair contacts, and merge capture. The stored impulse is released on the following simulation step; the 180 ms sibling grace then begins counting down. This is a deliberate gameplay-pacing gate, while the offset/scale and all gem/coin shadows remain presentation-only.

Non-final target coins share `GameConfig.target_coin_flight_start()`. It accounts for the final token's spawn stagger and a common 260 ms table hold before adding per-coin flight stagger, so no first coin can leave while later members of the same target reward are still arriving.

`GameplayEffectsLayer` retains rings, combo labels, hero effects, reward amount, and visual coins. The removed mini-gem array/API is retained only as a zero-count compatibility query for older tools. HUD target reactions continue to consume controller snapshots and explicit confirmed-presentation callbacks; they do not duplicate target rules.

# Architecture Addendum - Reward feedback v3

## Reward timelines are data, not code paths

`GameConfig.merge_timeline(depth, final_target)` returns one dictionary per reward tier (`MERGE_TIMELINE_NORMAL`, `..._COMBO_1/2/3`, `..._FINAL_TARGET`). Each holds `hitstop`, `pull_start`, `pull_duration`, `reveal`, `duration`, `sound_at`, `ring_at`, `ring_scale`, `start_scale`, `scale_keys`, `mini_gems`, and `pitch`. The controller resolves the timeline once at merge-confirm time and stores it on the merge event, so the draw path, the sprite-transform path, the audio path, and the effects layer all read the same authoritative record. Retuning a reward tier is a data edit; no new branch is added per tier.

`GameController._merge_result_transform_for(elapsed, timeline)` walks `scale_keys` (`[time, scale]` pairs) with an ease-out/back on the reveal segment and a cubic ease-out afterwards. It is pure and takes no controller state, which is what makes the keyframes directly testable.

## Celebration state

`final_celebration_active` is a controller-owned state distinct from `win_qualified` and `win_presented`. It is set when the confirmed merge event completes the final target and cleared when `GameplayEffectsLayer.level_reward_finished` fires. While set it blocks pointer input, keeps the launcher lifecycle from advancing, and prevents `_update_win_presentation` from presenting. `final_celebration_hero_done` sequences the reward coins behind the hero gem's arrival, with a 2 s safety bound so the state can never deadlock the modal.

To let the presentation branch on the confirmed result, `_advance_target_state_authoritative` now runs before the reward presentation inside `_apply_confirmed_merge_events`. The authoritative ordering, values, and exactly-once guards are unchanged; only the point at which presentation reads them moved earlier.

## Hit-stop

`merge_hitstops` maps a confirmed result id to a remaining duration plus its stored merge velocity. `_update_merge_hitstops` runs before `simulation.step`, holds that one body at zero velocity, and restores the exact stored value on expiry. Only the merge result is affected; every other body keeps stepping, so this is a per-body pause rather than a game freeze, and the simulation resumes with the value `ContactMergeService` produced.

## Cosmetic reward channel

`GameplayEffectsLayer` gained five cosmetic record arrays — `mini_gems`, `combo_labels`, `panel_sparkles`, `level_reward_coins`, and the single `hero_effect` — plus a separate level-reward signal channel (`level_reward_wave_launched`, `level_reward_coin_arrived`, `level_reward_finished`). Keeping the level celebration on its own signals rather than reusing `coin_arrived` prevents the staged 20-coin sequence from being confused with the compact per-target four-coin group, and lets the HUD punch once per wave instead of once per coin.

Every entry is an immediate-mode drawn record: no nodes are allocated, nothing enters `pieces`, and nothing is visible to contact capture, merge eligibility, target detection, or the coin economy. All arrays are capped and lifetime-filtered each frame and cleared by `clear()`, which `restart()` and `_trigger_failure()` already call. The reward-coin pile uses deterministic seeded best-candidate sampling so it is even, bounded to a central band of the board, and identical between runs.

## Presentation-only bounds widened

`GemSpriteLayer` presentation scale is now bounded by `PRESENTATION_SCALE_MIN` (0.0) and `PRESENTATION_SCALE_MAX` (1.45) so a merge result can be revealed from zero and overshoot to 1.30. This bound applies only to the visual child; the authoritative root scale, `GemPiece` radius, rail contact, and merge eligibility still never read it.

`AudioFeedbackService.emit_event` accepts an optional bounded `pitch_scale` (0.80-1.40) used by the combo hierarchy. It changes neither which event fires nor what an event means, and it composes with the existing per-event pitch ranges.

# Tester animation/audio revert and Android exit boundary - 2026-08-18

- `GameConfig` again owns the exact `5528ff6` fast presentation values. The later authoritative/display target split and exactly-once queue remain; restoring animation timing must never roll back those state-safety boundaries.
- `AudioFeedbackService` loads the v2 midpoint contact derivatives. Contact telemetry remains presentation-only and continues through impact thresholds, global event cooldowns, per-contact cooldowns, exact merge-pair suppression, and bounded priority voices.
- Home Exit is a platform lifecycle request, not gameplay navigation. On Android, `GameController` asks built-in `AndroidRuntime` for the Activity and posts `finishAndRemoveTask()` on its UI thread. `AdManager.prepare_for_exit()` invalidates asynchronous work first; `_exit_tree()` owns object destruction during lifecycle teardown. Desktop defers `SceneTree.quit()` outside the button callback.

# Animation/audio/Back/privacy boundary - 2026-08-18

- `GameController` remains the authoritative simulation/progression owner. Confirmed results enqueue presentation records; `merge_presentations`, `target_collection_queue`, and `GameplayEffectsLayer` may overlap, while launcher readiness and target/reward accounting do not depend on presentation completion.
- The real target physics piece is retired at confirmed collection. A presentation-only duplicate travels to `GameplayHudLayer`, which pulses the card and counter without writing progression state.
- `AudioFeedbackService` remains the single audio owner with cached streams, five priority-aware SFX voices, Music/SFX buses, and a limiter. Contact telemetry remains read-only and is filtered by type-specific impact thresholds, global cooldowns, a per-contact key cooldown, and exact merge-pair suppression.
- App navigation is controller-owned. `project.godot` disables Android auto-quit; `NOTIFICATION_WM_GO_BACK_REQUEST` and desktop Escape enter one debounced state dispatcher. `HomeOverlayLayer` resolves its topmost popup first, results cannot be bypassed, gameplay uses the existing Pause overlay, and Home owns an explicit exit confirmation.
- The Privacy Policy remains a Home presentation link to the existing `AdManager` URL path. Its intrinsic centered size and safe-area placement are layout-only and do not alter UMP or ad authority.

# Animation/audio/Back/privacy boundary - 2026-08-18

- `GameController` remains the authoritative simulation/progression owner. Confirmed results enqueue presentation records; `merge_presentations`, `target_collection_queue`, and `GameplayEffectsLayer` may overlap, while launcher readiness and target/reward accounting do not depend on presentation completion.
- The real target physics piece is retired at confirmed collection. A presentation-only duplicate travels to `GameplayHudLayer`, which pulses the card and counter without writing progression state.
- `AudioFeedbackService` remains the single audio owner with cached streams, five priority-aware SFX voices, Music/SFX buses, and a limiter. Contact telemetry remains read-only and is filtered by type-specific impact thresholds, global cooldowns, a per-contact key cooldown, and exact merge-pair suppression.
- App navigation is controller-owned. `project.godot` disables Android auto-quit; `NOTIFICATION_WM_GO_BACK_REQUEST` and desktop Escape enter one debounced state dispatcher. `HomeOverlayLayer` resolves its topmost popup first, results cannot be bypassed, gameplay uses the existing Pause overlay, and Home owns an explicit exit confirmation.
- The Privacy Policy remains a Home presentation link to the existing `AdManager` URL path. Its intrinsic centered size and safe-area placement are layout-only and do not alter UMP or ad authority.

# Supplied sound and Home privacy-link boundary - 2026-08-16

- `AudioFeedbackService` remains the only audio runtime owner. It preloads the eight supplied SFX, preserves the existing music/launch/coin streams, creates five reusable priority-aware one-shot players, and never allocates or loads during gameplay events.
- `default_bus_layout.tres` owns Music and SFX buses. Continuous music routes to Music; confirmed one-shots route to SFX through one limiter. Both buses send to Master.
- `GameController` routes only confirmed events: launch, typed physical contacts, resolved normal/target merges, target animation arrival, full objective completion, accepted victory presentation, and UI intent. It never feeds audio results back into gameplay decisions.
- `BoardSimulation` telemetry is still read-only. The controller resolves merges before routing captured impacts so only the exact contact pair consumed by a merge loses its collision clink; no simulation order, impulse, radius, candidate, or position changes.
- `HomeOverlayLayer`, `GameplayHudLayer`, and `ResultOverlayLayer` emit one `ui_tap_requested` intent per standard button. The controller owns the single quiet tap route, avoiding layered duplicate clicks.
- `HomePrivacyPolicyLink` is presentation-only and bottom-safe-area anchored. It emits the existing Home privacy intent to `AdManager`; Home/Pause Settings retain only conditional UMP Privacy Options. Ad configuration and consent authority remain unchanged.

# Supplied sound and Home privacy-link boundary - 2026-08-16

- `AudioFeedbackService` remains the only audio runtime owner. It preloads the eight supplied SFX, preserves the existing music/launch/coin streams, creates five reusable priority-aware one-shot players, and never allocates or loads during gameplay events.
- `default_bus_layout.tres` owns Music and SFX buses. Continuous music routes to Music; confirmed one-shots route to SFX through one limiter. Both buses send to Master.
- `GameController` routes only confirmed events: launch, typed physical contacts, resolved normal/target merges, target animation arrival, full objective completion, accepted victory presentation, and UI intent. It never feeds audio results back into gameplay decisions.
- `BoardSimulation` telemetry is still read-only. The controller resolves merges before routing captured impacts so only the exact contact pair consumed by a merge loses its collision clink; no simulation order, impulse, radius, candidate, or position changes.
- `HomeOverlayLayer`, `GameplayHudLayer`, and `ResultOverlayLayer` emit one `ui_tap_requested` intent per standard button. The controller owns the single quiet tap route, avoiding layered duplicate clicks.
- `HomePrivacyPolicyLink` is presentation-only and bottom-safe-area anchored. It emits the existing Home privacy intent to `AdManager`; Home/Pause Settings retain only conditional UMP Privacy Options. Ad configuration and consent authority remain unchanged.

# Regenerated scene-art boundary - 2026-08-16

- `AssetCatalog.LEVEL_BACKGROUNDS` and `LEVEL_TABLES` preload the active 19/10 optimized sets. `GameController` selects both only from `LevelConfig.generated()` indices, so a level and retry reproduce one presentation pair.
- `GameConfig` remains the sole runtime geometry authority: outer `400..1185`, board `440..1110`, rails `188/532 -> 62/658`, danger `960`, launcher `1042`, center Y `792.5`, and table-art scale `0.7391304 x 0.9691358`. Raster pixels never define collisions or limits.
- Every table is normalized to a transparent 920x810 presentation canvas. `GameController` applies the same center and scale to every variant; no per-table gameplay transform exists.
- `run_ui_scale_layout_tests.gd` contains offline measured visible-field edges for calibration only. Those constants prove alignment within 10 pixels and are never imported by production code.
- Supplied originals are canonicalized under `assets/source/backgrounds/` and `assets/source/tables/`; runtime derivatives live under `assets/runtime/`. The former single-table path and its selection constant are removed.

# Original table restoration boundary - 2026-08-16

- `AssetCatalog.ORIGINAL_TABLE` is the only gameplay table selected by `GameController` while replacement rail art is being regenerated. The ten normalized replacement tables stay cataloged but inactive.
- `GameConfig` again owns the original single-table transform: center Y `792.5`, scale `0.7391304 x 0.9691358`, outer `400..1185`, board `440..1110`, danger `960`, and launcher `1042`. There is no independent horizontal artwork multiplier.
- The 20-pixel restoration moves the complete authoritative table model together. Rails, board bounds, launcher, danger evaluation, drag clamps, spawn limits, pieces, effects, and table artwork continue to share the same responsive transform.
- Random backgrounds remain seeded presentation data. Generated `table_index` metadata and replacement table assets are dormant until a later supplied-art integration explicitly re-enables them.

# Table-art coverage and HUD legibility boundary - 2026-08-16

- `GameConfig.TABLE_ART_HORIZONTAL_COVERAGE_SCALE` is presentation-only. `GameController` applies it only through `table_texture_render_scale()` to the table `Sprite2D`; no simulation, collision, rail, danger, launcher, drag, spawn, merge, or input path reads it.
- The unchanged authoritative geometry remains outer `420..1205`, board `460..1130`, rails `188/532 -> 62/658`, danger `980`, and launcher `1062`. Responsive Y scaling still transforms art and physical landmarks together; the extra X coverage only compensates for visible inner-rail variation among normalized table canvases.
- `GameplayHudLayer` top-aligns the independent Coins and Next cards. `UiDesignSystem` owns the enlarged Next footprint and gameplay typography remains cached/native; HUD still consumes controller snapshots only.
- The capture harness adds non-running proof pieces at exact legal rail limits after simulation is disabled. It is development-only and cannot alter production gameplay.

# Responsive scene catalog and table-presentation boundary - 2026-08-16

- `AssetCatalog.LEVEL_BACKGROUNDS` and `LEVEL_TABLES` preload the complete optimized runtime sets and expose wrapping presentation lookups. Catalog images never supply coordinates, radii, or rules.
- `LevelConfig.generated()` owns deterministic `background_index` and `table_index` values after the existing generated launcher/mapping work. Reconstructing a level from the same number/seed reconstructs the same presentation without persistence schema changes.
- `GameController` applies both textures during initial presentation and level restart. It continues to position and scale every table texture only through `GameConfig.table_texture_center()` and `table_texture_render_scale()`.
- All ten tables are normalized to the same 920x810 alpha canvas. `GameConfig` remains the sole table geometry authority for rendering, rails, board bounds, drag clamps, spawn limits, launcher, danger line, collision, and containment.
- `GameplayHudLayer` uses an edge-to-center hierarchy: enlarged Coins at left, a right-side `VBoxContainer` with enlarged Next then Settings, and an independent centered Target/path stack. UI remains snapshot-only and has no board input or progression authority.
- Source artwork is isolated under export-excluded `assets/source/`; only explicit runtime derivatives are eligible for the Android package.

# Table / Target / merge-path presentation boundary - 2026-08-16

- `GameConfig` remains the sole geometry authority. Its table texture center, outer bounds, board bounds, danger line, launcher, rails, drag clamp, spawn limits, and containment paths share the same 40-design-pixel baseline translation and existing tall-screen transform.
- `GameplayHudLayer` owns presentation only. `TopUtilityRow` contains Coins and the Next/Settings group; `TableObjectiveAnchor` contains a centered Target then merge-path `VBoxContainer`.
- Objective placement reads the configured `GameConfig.table_outer_top()` during every controller snapshot refresh. This handles the child-HUD-before-controller startup order without duplicating table geometry or progression rules.
- `UiDesignSystem` owns target/path sizes, stack gap, table gap, icon size, and the cached native glass style. The path uses no bitmap panel, framebuffer sampling, shader, physics, or input handler.
- The HUD still consumes controller snapshots only. Collection destinations remain live icon rectangles, and no queue, target, scoring, collision, launch, or merge decision moved into UI code.

# Majestic Gems branding + push-line input boundary — 2026-08-11

- `AssetCatalog.BRAND_LOGO` owns the active Home logo mapping at `assets/runtime/ui/majestic_gems_logo_v3.png`; `project.godot` reuses it for the fallback boot splash.
- Android icon composition is export-only: legacy 192 px plus adaptive 432 px foreground/background derivatives. These images never enter gameplay state or layout authority.
- `GameConfig.aim_guide_contains()` owns the presentation/input hit geometry for the ready push line. `GameConfig.launcher_drag_x()` owns the shared rail clamp for both direct-gem and push-line dragging.
- `GameController._handle_pointer()` is still the sole board pointer authority. Both touch origins set the same `dragging` flag, call `move_active_to()`, and release through `launch_active_piece()`.
- The guide has no simulation authority. Board coordinates, rail interpolation, active gem radius, launch velocity, collision, merge, and danger systems remain unchanged.
- APK cleanup is controlled by `export_presets.cfg`; preserved originals remain under `assets/logo/`, while only active derivatives under `assets/runtime/` are eligible for packaging.

# UI/startup architecture addendum — 2026-08-09

## Icon source

`addons/at-icons/` is an editor icon library. Runtime UI does not depend on its editor plugin API; selected source SVGs are copied/recolored into `assets/runtime/ui/icons/` and preloaded directly by `HomeOverlayLayer`, `GameplayHudLayer`, and `ResultOverlayLayer`. This keeps exported UI deterministic while the @icons editor dock remains available for future selection.

## Splash separation

`project.godot` owns the engine/editor fallback boot splash. `export_presets.cfg` owns Android system-splash behavior. Android sets `splash_screen/disable_godot_boot_splash=true`, so the native splash persists until the main loop instead of transitioning through a second Godot splash. A dedicated 432×432 transparent padded system-splash logo is used to stay inside Android's masking safe area. Launcher main icon configuration remains independent.

# Architecture Addendum — Third-Party Motion Integration v1

## Global Tweens
`GlobalTweens.gd` is registered as the `GlobalTweens` autoload in `project.godot`. UI layers call only presentation-safe helpers such as `button_press()` and `energy_pulse()`. It has no authority over simulation, merge candidates, score, target progression, or board geometry.

## Tween Composer
The supplied `tween_composer/` scripts are used as runtime composition nodes by `HomeOverlayLayer`. `TweenSequence`, `TweenStepCollection`, and `TweenStepItem` resources define reusable scale loops for the Crystal Magic logo and Level Intro target icon. The existing native gameplay/controller tweens remain authoritative for merge/target sequencing; Tween Composer does not replace gameplay state machines.

## Home settings layout fix
`HomeTopControls` remains a full-screen safe-area MarginContainer, but its `HomeSettingsFrame` explicitly uses shrink-to-begin vertical sizing and shrink-to-end horizontal sizing. This prevents HBox cross-axis fill from turning the compact settings card into a full-height glass strip.

## Fast-feel boundary
Timing/feel changes stay centralized in `GameConfig`. Physics topology, contact-only merge rules, table rails, target rules, and reward authority are unchanged.

# Architecture

## Light Glass HUD layout architecture — 2026-08-08

`GameplayHudLayer` remains a snapshot-only `CanvasLayer`; no gameplay ownership moved into UI. The HUD now has two presentation regions: `SafeHudMargin` owns the compact two-row utility header, while `GameplayObjectiveAnchor` owns the progression/Target stack. `GameplayObjectiveAnchor` computes its vertical bounds from `GameConfig.board_top()` during safe-area refresh, keeping the objective group table-adjacent without modifying table coordinates.

`UiDesignSystem` now centralizes light glass `StyleBoxFancy` construction. `_frosted_glass_style()` creates a translucent gradient surface, Panel8-style squircle curvature, layered rim/highlight `StyleBorder`s, and bounded shadow. This deliberately avoids framebuffer capture/backdrop blur shaders so Android GL Compatibility remains low risk. Button theme states and the gameplay Pause modal reuse the same glass family.


## Transparent purple glass presentation patch v1

- `UiDesignSystem` owns the alpha-tinted purple glass colors for the existing header, path tray, secondary cards, and Target surface. Opacity and hue are cached style data; no new runtime node, frame callback, viewport capture, shader, or texture dependency is introduced.
- `GameplayHudLayer` changes only label contrast and connector color for the tinted surfaces. Snapshot ownership, node hierarchy, signal routes, live icon destinations, and tween cadence are unchanged.
- Rendering remains isolated from simulation and table geometry. Transparency cannot read or influence pieces, contacts, targets, queue, currency, danger, or results.

## Professional Glass HUD v1 presentation boundary

- `GameplayHudLayer` remains a snapshot-only `CanvasLayer`. `SafeHudMargin/HudColumn/HudShell` owns the translucent Level/MERGE PATH/Settings header; `UtilityRow` owns Score, centered `TargetSlot`, and Next in one responsive container.
- Target is no longer positioned from board-top geometry. Its live icon rectangle remains the collection destination, so the controller/effects contract is unchanged while HUD composition becomes independent from table placement.
- `ProgressionPanel/ProgressionGroup/PathGlass` owns the eight catalog-driven path gems and directional connectors. It cannot assign ranks, queue entries, targets, or textures outside `AssetCatalog`.
- `UiDesignSystem` owns the cached translucent colors, beveled borders, rim light, card headers, inset tray, shadows, dimensions, progress styles, and interaction timing. No reference raster, runtime blur pass, per-frame style creation, or simulation coordinate is introduced.
- HUD motion changes Control presentation only. Currency, queue, target progress, reward settlement, physics, input, danger, and results remain controller-owned.

## Purple Production HUD v1 presentation boundary

- `GameplayHudLayer` remains a presentation-only `CanvasLayer` that reads `GameController.hud_snapshot()` and emits existing UI intents. `HudDesignCanvas/SafeHudMargin/HudColumn` owns the purple header and utility row; `TableTargetAnchor` independently positions Target from the authoritative board-top geometry without changing that geometry.
- `HudShell/HudRows/MainRow/Progression` owns Level, all eight MERGE PATH entries, and Settings. `UtilityRow` owns compact Score and Next panels. The Target panel is not nested in either utility card and remains the strongest objective surface.
- `UiDesignSystem` centralizes the purple palette, native `StyleBoxFlat` resources, dimensions, spacing, progress styles, and motion durations. No bitmap panel composition or simulation coordinate is owned by the HUD.
- Target/coin destinations still come from live icon rectangles. UI tweens modify presentation properties only; target progression, reward settlement, queue state, physics, and result qualification remain controller-owned.
- Gem identity copy is intentionally absent from gameplay HUD labels and tooltips. Text authority is limited to level, coins, headings, target sequence, and numeric progress.

## Production Gameplay UI V2 presentation boundary

- `GameplayHudLayer` remains a `CanvasLayer` outside the table transform. Its `SafeHudMargin/HudShell/HudRows` tree owns all top-HUD layout through containers; it consumes only `GameController.hud_snapshot()` and emits existing intent signals.
- `ProgressionHeader` owns Level, MERGE PATH, and Settings. `ScoreNextRow` owns equal secondary Coins/Next cards and an expanding central Target slot. Target and coin destinations are computed from the live icon rectangles, so foreground flights stay aligned after scaling/safe-area changes.
- Target handoff is presentation state: outgoing art/copy remain paired until the approved crossfade's incoming phase. `reset_presentation()` clears only cached UI state so Restart cannot display a ghost from the discarded run.
- `GameController._draw_aim_guide()` and `_danger_warning_strength()` are read-only render helpers. They consume the existing launcher lifecycle, lane/table geometry, and piece positions; they cannot alter input, danger timers, overflow detection, physics, or launch state.
- `UiDesignSystem` owns cached shell, target, utility, setting-row, spacing, icon, typography, touch, and animation tokens. HUD updates do not rebuild nodes, scan catalogs, reload textures/fonts, or create themes per frame.

## Production foundation services and boundaries

- `GameSettingsService` persists `music_enabled`, `sound_enabled`, and `vibration_enabled` in `user://game_settings.cfg`; `GameController` loads before feedback startup and saves HUD toggle events immediately.
- `AudioFeedbackService` has independent music and SFX gates. `GameplayHudLayer` emits intent and renders controller snapshots; it never reads files or touches simulation.
- `LevelConfig.generated()` owns target cadence and capped launcher difficulty. Consumers do not recalculate it.
- `GemSpriteLayer` reads identity from `AssetCatalog` and diameter from `GameConfig`, then applies one uniform scale. Physics remains radius-owned.
- Branding is declarative in `project.godot`; the runtime icon has no gameplay dependency.

## Production UI motion and visibility contract

`HomeOverlayLayer` owns presentation-only entrance and idle tweens that process while the tree is paused; dismiss kills and normalizes them. `GameController.restart()` is the authoritative active-play reset boundary and must call `GameplayHudLayer.show()` before presentation reset/refresh. Home may cover or temporarily hide gameplay UI, but no reset caller may leave the active-play HUD invisible.

## Asset-matched Home presentation

`HomeOverlayLayer` remains a presentation-only `CanvasLayer`. It reads the preloaded tropical background and transparent brand derivative through `AssetCatalog`, while its scalable coral/cream surfaces come from `UiDesignSystem`. It owns no seed generation, progression, simulation, input over the board, reward, or persistence rules.

## New background music routing boundary v1

- `AudioFeedbackService` preloads `supplied_background_music_v5.ogg` into its single dedicated looping music player; no movement, collision, merge, or reward path owns playback position.
- `GameConfig.AUDIO_MUSIC_VOLUME = 0.10` remains the centralized mix value. Target coin and tiered gem one-shots stay on their existing independent cached players and confirmed-event routes.
- The preserved MP3 is source provenance; only its optimized derivative is used at runtime. This presentation-only change does not enter simulation, collision, merge, reward, or controller state.

## New background music routing boundary v1

- `AudioFeedbackService` preloads `supplied_background_music_v5.ogg` into its single dedicated looping music player; no movement, collision, merge, or reward path owns playback position.
- `GameConfig.AUDIO_MUSIC_VOLUME = 0.10` remains the centralized mix value. Target coin and tiered gem one-shots stay on their existing independent cached players and confirmed-event routes.
- The preserved MP3 is source provenance; only its optimized derivative is used at runtime. This presentation-only change does not enter simulation, collision, merge, reward, or controller state.

## Branded screen-flow presentation boundary v1

- `AssetCatalog.BRAND_LOGO` owns the optimized supplied-logo derivative. `HomeOverlayLayer` is a layer-60 modal with its own safe area, layout metrics, cached theme resources, and one play intent signal; it never owns progression decisions.
- `GameController._show_home()` hides `GameplayHudLayer`, pauses the tree, and presents saved snapshot values. Continue restores the HUD and unpauses. Result Home routes through controller state: wins advance/save/reset before Home; failures restart the same seed before Home.
- `ResultOverlayLayer` remains the dedicated layer-50 victory/failure owner. It reads level/coins/final-art arguments, exposes Next/Retry/Home intents, and never alters gameplay roots, gem textures, physics, or qualification timing.

## Infinite generated-level boundary v1

- `LevelConfig.generated(level_number, seed)` is the sole generator. Its immutable dictionary owns eight unique catalog identities mapped to local L1-L8, launcher sequence, ascending targets, background index, and seed.
- Simulation, `GemPiece`, `ContactMergeService`, collision, radii, and rewards continue to consume only local L1-L8 ranks. `AssetCatalog.active_gem_identity_by_tier` translates local rank to the selected global identity at the presentation boundary for board sprites, NEXT, TARGET, MERGE PATH, collection, and results.
- `ProgressionSaveService` persists only level number, seed, and banked coins. Retry reconstructs the same definition; NEXT LEVEL advances, derives the next seed, saves, and performs the existing full controller reset.
- `HomeOverlayLayer`, `GameplayHudLayer`, and `ResultOverlayLayer` remain modal presentation owners. They emit intent signals and never duplicate progression, queue, target, physics, or reward rules.

## Reference scale contrast and target-proxy boundary v1

- `GameConfig.GEM_COLLISION_RADIUS` remains the sole live L1-L8 size authority, now `30/33/36/39/42/45/48/51 px`. `GemPiece.base_radius`, perspective-scaled live radius, `GemSpriteLayer` body diameter, pair contact, merge eligibility, rails, and launcher clamp consume that same geometry.
- Target qualification never changes a live radius. `GameController._begin_target_collection()` first removes the confirmed target body, then creates a presentation-only proxy using the exact live-gem axis mapping: `diameter / texture.width` and `diameter / texture.height`.
- `TARGET_COLLECTION_POP_SCALE = 1.18` multiplies both proxy axes uniformly. This makes the reward target visibly larger than an ordinary same-tier gem without changing its silhouette or allowing the enlarged presentation to occupy physics.
- `GameplayHudLayer` retains its existing 80 x 80 aspect-preserving TARGET slot. HUD preview scale, proxy reward scale, and live physics size remain separate responsibilities.
- This boundary supersedes the `36..50` ladder below. Merge animation, target/coin ownership, foreground layering, audio, controller event order, and simulation tuning are unchanged.

## Merge animation and active-tier geometry boundary v1

- `GameConfig.GEM_COLLISION_RADIUS` is the sole L1-L8 size authority: `36/38/40/42/44/46/48/50 px`. `GemPiece.base_radius` initializes from it, `GemPiece.radius` applies the shared table-depth perspective scalar, and `GemSpriteLayer` derives the alpha-trimmed texture diameter from that same base radius. Rendering and physics cannot drift independently.
- `ContactMergeService` creates an upgraded result with `GameConfig.gem_collision_radius(new_level)`, so a confirmed L1+L1 result immediately changes both its Ruby artwork diameter and circular body to L2 size. Rails, pair contact, merge eligibility, launcher clamp, and audio contact telemetry continue to consume the live radius.
- `GameplayEffectsLayer` is presentation-only and again owns the pre-v4 flash/ring/eight-ray records. `GameController` applies only a centered uniform `0.62 -> 1.20 -> 1.0` child scale; neither route changes `GemPiece.position`, radius, perspective, velocity, or merge state.
- The v4 target-only four-coin path, target confirmation and centered handoff, supplied-audio service, and foreground layering are unchanged. This section supersedes only the merge-splash and active L1-L8 radius statements below.

## Reference animation and supplied-audio boundary v4

- `GameController._apply_confirmed_merge_events()` remains the only target/reward authority. Every unique result routes its tiered merge cue and rigid presentation; only the active-target branch awards the integer, creates four coin records, and emits one `coin_reward` event.
- `GameplayEffectsLayer` owns transient drawing only. Merge records contain a deterministic result-color splash seed/duration; target reward records contain exactly four ordered cubic flights. Both remain under `GameplayHudLayer.reward_foreground_host`, above live gems/cards and below confirmation/Pause/Results.
- `GemSpriteLayer` and the merge proxy preserve the original texture aspect. Merge emphasis is a centered uniform scalar only. Splash geometry, coin paths, target proxy travel, and HUD fades cannot write position, radius, velocity, rotation, or scale into simulation state.
- `TargetRewardOverlay` owns one green-check confirmation. `GameplayHudLayer` reuses its two existing target ghosts for an in-place opacity handoff and fades the existing target panel; it does not allocate targets, qualify results, or reorder L5 -> L7 -> L8.
- `AudioFeedbackService` preloads the two runtime Ogg derivatives. A dedicated looping player starts the supplied music during `_ready()` and is never addressed by movement/controller events. Three reusable one-shot players retain the bounded event cache; the supplied coin stream occupies only the `coin_reward` cache entry and is played unpitched.
- The session audio toggle stops/resumes the continuous player and stops active one-shots. Contact thresholds/cooldowns/concurrency remain presentation-only. `BoardSimulation`, `ContactMergeService`, table geometry, launcher lifecycle, danger state, and result state do not depend on audio or animation.
- `export_presets.cfg` excludes `tools/*` and `build/*`. Test logs, frame-analysis derivatives, APKs, and other local build products cannot be packaged into the Godot PCK.


## Reference target reward and audio correction boundary v3

- `GameController._apply_confirmed_merge_events()` remains the sole currency authority, but reward qualification is now explicit: `result_level == active_target_tier()`. Only that branch reads `GameConfig.target_coin_reward_for_result_level()`, registers the HUD pending integer, increments authoritative `coins`, and calls the target-coin API. All unique confirmed events still receive merge presentation/audio/haptics.
- `GameplayEffectsLayer.begin_merge_feedback()` owns merge impacts only. `begin_target_coin_reward()` is the separate target-qualified entry point for the four bounded coin records. This API split prevents ordinary merge animation work from accidentally restoring coin flights.
- `GameplayHudLayer` remains a snapshot consumer and arrival reconciler. It cannot qualify targets or award currency. Coin and target proxies still render in its foreground host above gameplay/HUD cards; Pause and Results keep their higher layers.
- `AudioFeedbackService` initializes 15 cached gem-event streams and three reusable players. It does not preload `reference_music_loop.ogg`, create an ambience player, or derive gameplay decisions from sound. The mixed Ogg stays under `assets/runtime/audio/` only as preserved provenance until separate clean sources are supplied.
- `GameController._draw()` renders the rail-derived horizontal danger line and merge/debug presentation only. No vertical launcher guide method or tuning remains. Launcher position/clamp/input and table geometry are untouched.
- Simulation, merge eligibility, rigid gem rendering, collection removal/travel, L5 -> L7 -> L8 progression, final-coin victory gating, launcher lifecycle, danger timing, and full reset remain outside this correction and unchanged.

This boundary supersedes the reward ownership, active ambience, and aim-guide statements below.

## Reference audio and reward layering boundary v2

- `GameController` again instantiates `AudioFeedbackService`. The service preloads one reference-derived Ogg music resource, duplicates it once, enables `AudioStreamOggVorbis.loop`, and starts one dedicated `AudioStreamPlayer` during `_ready()`. No controller movement/contact route calls the music player.
- Confirmed controller events route only to 15 initialization-cached gem one-shots through three reusable players and centralized cooldowns. `ReferenceAudioFeedbackService` and its four event slices remain historical provenance only and are not instantiated. Coin-flight signals update presentation currency/haptics but do not emit audio.
- `GameplayHudLayer` owns one `RewardForegroundHost` at local z `10` inside CanvasLayer `40`. `GameplayEffectsLayer` is attached there, so its four coin records and the collection proxy draw above the z `0` HUD and default world canvas. `TargetRewardOverlay` uses z `20`, Pause z `30`, and `ResultOverlayLayer` remains CanvasLayer `50`.
- Two `Sprite2D` target ghosts are built once under the foreground host. Snapshot identity changes reuse them for outgoing top-left fade and incoming right-to-center fade. They read the controller snapshot only; they never qualify, count, or reorder targets.
- The old `GameplayEffectsLayer.target_arrivals` world effect was removed. Target completion now has one UI confirmation plus the target-identity handoff. All foreground records remain bounded and reset-safe.
- `GameConfig.DANGER_LINE_COLOR` is the single color authority for both the danger line and launcher guide; existing rail geometry still owns guide containment.
- Simulation, merge service, live gem rendering, table geometry, radii, velocities, currency authority, target sequence, launcher lifecycle, danger, and result qualification are outside this boundary and unchanged.

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

## Gameplay HUD container sizing note - 2026-08-08
Dynamic HUD containers that rely on spacer-based left/right distribution or CenterContainer centering must set `size_flags_horizontal = Control.SIZE_EXPAND_FILL` through the full parent chain. Without this, VBox/HBox/CenterContainer nodes can collapse to minimum content width, causing the right-side utility controls and centered objective stack to bunch toward the left. The current gameplay HUD enforces expand-fill on the top column, utility/status rows, objective stack, progression center, and target anchor.

### Runtime HUD width rule
`GameplayHudLayer` uses a 720px logical design canvas. Runtime `MarginContainer` roots for the top HUD and gameplay objective stack must be assigned explicit `offset_right = UiDesignSystem.DESIGN_WIDTH` geometry before safe-area margins are applied. Do not rely only on anchor presets for these dynamically-created containers; before the first layout pass they can resolve to child minimum width and misalign right/center HUD elements.

## Home and modal presentation flow (2026-08-09)

`HomeOverlayLayer` remains presentation-only and now owns two modal surfaces: Home Settings and Level Preview. `present(level_number, coins, snapshot)` receives an immutable presentation snapshot from `GameController`; it does not calculate progression or gameplay rules. Pressing the Home Play/Continue button only opens Level Preview. Pressing START GAME emits `play_requested`, after which `GameController` dismisses Home and unpauses the tree.

Home Settings emits `music_toggled`, `sound_toggled`, and `vibration_toggled`. `GameController` connects these to the same `_on_*_toggled` handlers already used by `GameplayHudLayer`, keeping settings persistence centralized in `GameSettingsService` and avoiding duplicate state ownership.

`UiDesignSystem` now supplies a `SettingsSwitch` Button variation and a frosted `home_status_card_style()`. Pause and Home settings therefore share the same glass/switch language while keeping gameplay simulation isolated.
# Architecture Addendum - AdMob Integration v1

`AdConfig` is the single source for fullscreen ad-unit selection and interstitial cadence. `AdManager` is an always-processing autoload that owns the Poing AdMob v5.0.0 listener/loader/ad objects and all fullscreen lifecycle state. It initializes once, loads each format independently, emits readiness, rejects overlapping shows, destroys consumed objects, retries failed loads, and invokes transition completions on every unavailable/dismiss/failure path.

`GameController` remains the progression and currency authority. On a qualified result it derives the displayed level reward from confirmed run coins. Collect asks the manager for an eligible interstitial and advances from the completion callback. Double Coins asks for rewarded playback; only `_on_rewarded_bonus_earned()` may persist one extra base reward, guarded by both the manager session ID and the controller's `rewarded_bonus_granted` flag. Dismissal without the earned callback restores result actions. `ResultOverlayLayer` owns presentation/button state only.

No ad module imports, updates, or participates in `BoardSimulation`, `ContactMergeService`, `GemPiece`, launcher state, target collection, danger timers, or HUD snapshots. Ads are reachable only from terminal victory UI and may never block gameplay when inventory is unavailable.
# Architecture Addendum — Reward Resolution and Android Packaging

`GameController` owns a one-way completion reward state (`completion_reward_resolved`) independent of fullscreen-ad state and level-transition state. `ResultOverlayLayer` is presentation-only: it emits Collect/Double/Next requests, suppresses duplicate taps, animates the displayed total, and cannot mutate coins or level numbers. `AdManager` remains the sole SDK owner and reports earned/dismissed results without navigation authority.

The transition boundary is now reward resolved → explicit Next Level → optional cadence interstitial → generated-level reset → `HomeOverlayLayer.present_level_intro()` → explicit Play. This prevents rewarded dismissal or Android lifecycle resume from composing with progression. Interstitial cadence remains controller/config owned and is not called by reward callbacks.

Android export remains Gradle-based and uses compressed native packaging. Closed-test v2 enables `arm64-v8a` and `armeabi-v7a`; `x86` and `x86_64` remain disabled. The Poing export plugin still supplies its two Java/Kotlin Android bridges and Google Ads dependencies, while export filters remove editor/sample/C#/iOS/mock resources from the game pack. The generated bundle's only native dependencies are Godot and `libc++_shared`, with matching files for both enabled ARM ABIs. The plugin settings service must not register demo translations in consuming projects because that adds unrelated translations and optional ICU data.
# Game flow, reward, and startup architecture - 2026-08-12

`GameController.AppFlowState` is the single coarse screen-flow authority: `STARTUP`, `HOME`, `LEVEL_READY`, `PLAYING`, `LEVEL_COMPLETE`, `REWARD_PROCESSING`, and `AD_SHOWING`. These states gate navigation only and never participate in simulation, merge, target, launcher, collision, or danger decisions.

`HomeOverlayLayer` retains Home and Level Ready presentation, but they are mutually exclusive surfaces. Home PLAY emits `level_intro_requested`; the controller reveals `GameplayHudLayer` and calls `present_level_intro()`, which hides every Home-specific visual before showing the modal. START GAME emits `play_requested` and is the only path to unpause PLAYING.

`ResultOverlayLayer` owns one Level Complete instance and emits `reward_animation_finished`. It no longer owns or emits a Next Level action. `GameController` resolves currency once, starts the result/HUD presentation, waits for that completion signal, dismisses the popup, optionally asks `AdManager` for the even-level interstitial, resets the generated level, and presents Level Ready.

Rewarded currency authority remains the earned callback. Presentation authority is deliberately later: `_on_rewarded_ad_finished()` begins the x2/result/HUD sequence only after fullscreen dismissal, preventing animation behind Android's ad activity. Failure resets the result controls and state to `LEVEL_COMPLETE`; it has no navigation authority.

`GameplayHudLayer.prepare_completion_reward_display()` and `animate_completion_reward()` are presentation-only. They interpolate the visible bank from the pre-level total to the controller's final exact integer, then pulse the existing coin HUD. They cannot mutate saved/controller coins.

`StartupSplashLayer` is a dedicated layer-80 presentation module. It contains the existing `AssetCatalog.BRAND_LOGO` with aspect preservation over the same Majestic blue configured for native/Godot fallback startup, holds for 1.05 seconds, fades for 0.20 seconds, and emits `finished` to show Home. Android's separate Godot boot splash remains disabled, so startup is native system splash -> matched custom splash -> Home.

## Splash and reward UI correction

The dedicated `StartupSplashLayer` described above is removed and superseded. `GameController` now calls `HomeOverlayLayer.present(..., startup_intro=true)` on mobile. Home owns one background node for both startup and menu: `AssetCatalog.background_texture(0)` with `STRETCH_KEEP_ASPECT_COVERED`. Its startup state hides Home controls, keeps the existing logo contained, then reveals the same Home tree after a bounded tween. No scene or CanvasLayer handoff occurs.

`ResultOverlayLayer` remains presentation-only. Its reward card now owns two `CoinIcon` instances plus separate earned and total labels. `CoinIcon -> CoinVisuals -> AssetCatalog.COIN_REWARD` is the same rendering dependency used by `GameplayHudLayer`; currency authority and reward lifecycle remain in `GameController`.

## Single splash correction

The Home-owned startup state described above is superseded and removed. `GameController._ready()` now calls `_show_home()` with no startup mode on mobile, and `HomeOverlayLayer.present()` always builds the complete normal Home composition immediately. Startup ownership is solely Android's native launch theme; Godot's Android boot splash remains disabled. This avoids both a second CanvasLayer and a second timed state within Home.
# Ad consent architecture — local Poing v5.0.0 patch

`AdManager` remains the sole ad runtime owner. On Android its startup boundary is now UMP consent rather than direct Mobile Ads initialization: update consent information, show the existing Poing/Google form only when required, evaluate native `can_request_ads()`, then enter the existing one-time initialization/preload path. Update failure follows the same authoritative evaluation so a valid previous-session decision can proceed without inventing state. Game/UI startup does not await or depend on ad authorization.

The native extension is deliberately minimal: Poing's existing `PoingGodotAdMobConsentInformation` class forwards `can_request_ads()` to Google UMP `ConsentInformation.canRequestAds()`. The existing GDScript `ConsentInformation` wrapper forwards the method. `patches/poing-admob-v5.0.0-can-request-ads.patch` is the maintenance authority; the rebuilt debug/release Ads AARs are the runtime artifacts.

`_ads_start_committed` serializes consent callbacks into the existing `_initializing`/`_initialized` and per-format loading guards. `_ads_requests_allowed` gates readiness, preload, and late load callbacks. Privacy Options can revoke cached readiness without changing fullscreen ownership or reward authority. `GameController` only routes Settings actions and availability to `HomeOverlayLayer`/`GameplayHudLayer`; it does not acquire ad or consent rules.
# Responsive reference composition boundary — 2026-08-16

- `GameplayHudLayer` is still a snapshot-only `CanvasLayer`. Its top layout uses equal-width side slots around Target, preventing Coins or Next/Settings content from shifting the objective off the physical screen center. The eight-gem path is a separate bottom-safe container. Neither region creates board input or progression authority.
- `GameConfig._configure_table_height()` owns the portrait table transform. `table_texture_center()`, `table_texture_render_scale()`, `board_top()`, `board_bottom()`, `danger_line_y()`, `launch_y()`, and trapezoid rail interpolation consume that same state.
- `GameController` only applies the shared table transform to presentation and continues delegating containment, launcher clamping, collision, merging, danger, and scoring to their existing authorities.
- `GEM_COLLISION_RADIUS` remains the one source for both `GemSpriteLayer` visual-body diameter and physics circles. Artwork padding, HUD previews, and progression icons do not enter collision or merge decisions.
# Sound mapping correction boundary - 2026-08-16

- `AudioFeedbackService` remains the single audio owner. Its five supplied replacements are gem contact, rail contact, ordinary merge, UI tap, and final success; restored procedural merge-tier, chain, target-arrival, and launch streams remain initialization-cached alongside the existing supplied coin/music streams.
- `GameController` selects `normal_merge` only for an ordinary result. A result satisfying the active target routes its original `merge_<tier>` cue, with original chain feedback retained for chained resolution. Objective completion advances without a separate audio event; target arrival and final victory retain distinct routes.
- Music/SFX bus separation, limiter, five reusable priority-aware voices, collision cooldown/pitch variation, post-resolution contact routing, and exact merged-pair collision suppression remain presentation-only and cannot affect simulation decisions.
# Sound mapping correction boundary - 2026-08-16

- `AudioFeedbackService` remains the single audio owner. Its five supplied replacements are gem contact, rail contact, ordinary merge, UI tap, and final success; restored procedural merge-tier, chain, target-arrival, and launch streams remain initialization-cached alongside the existing supplied coin/music streams.
- `GameController` selects `normal_merge` only for an ordinary result. A result satisfying the active target routes its original `merge_<tier>` cue, with original chain feedback retained for chained resolution. Objective completion advances without a separate audio event; target arrival and final victory retain distinct routes.
- Music/SFX bus separation, limiter, five reusable priority-aware voices, collision cooldown/pitch variation, post-resolution contact routing, and exact merged-pair collision suppression remain presentation-only and cannot affect simulation decisions.
# Immediate merge-audio boundary - 2026-08-16

- `GameController._apply_confirmed_merge_events()` emits the selected merge cue immediately after classifying the confirmed result and before caching or starting result presentation. The route remains downstream of `ContactMergeService.resolve()` and cannot affect merge acceptance, result creation, physics, or animation.
- `AudioFeedbackService` preloads the trimmed runtime derivative `merge-target-immediate.ogg` for the existing `normal_merge` mapping. No seek, decode, load, or player allocation occurs at merge time.
- The original supplied MP3 remains provenance-only under `assets/sound/`. Its runtime derivative changes leading silence only; event mapping, gain, voice priority, cooldown, limiter, and all other audio identities are unchanged.
# Immediate merge-audio boundary - 2026-08-16

- `GameController._apply_confirmed_merge_events()` emits the selected merge cue immediately after classifying the confirmed result and before caching or starting result presentation. The route remains downstream of `ContactMergeService.resolve()` and cannot affect merge acceptance, result creation, physics, or animation.
- `AudioFeedbackService` preloads the trimmed runtime derivative `merge-target-immediate.ogg` for the existing `normal_merge` mapping. No seek, decode, load, or player allocation occurs at merge time.
- The original supplied MP3 remains provenance-only under `assets/sound/`. Its runtime derivative changes leading silence only; event mapping, gain, voice priority, cooldown, limiter, and all other audio identities are unchanged.
# Presentation polish boundary - 2026-08-18

`GameController` converts confirmed, non-merge collision telemetry into short-lived visual feedback records. `GemSpriteLayer` applies those records only to `ImpactAxis`, below the root that mirrors `GemPiece.position` and perspective. Artwork counter-rotation preserves identity while the axis-local scale supplies a small contact compression. Neither `BoardSimulation` nor `ContactMergeService` imports or reads presentation state.

Merge timing remains a controller presentation gate over already-confirmed merge results. Gameplay state does not depend on effects-layer particles, target/coin proxies, or collision deformation completing successfully.

Large-screen containment remains configuration-driven: Godot's expanding canvas exposes additional width, `GameConfig.configure_viewport()` centers the unchanged 720-design-pixel table model, and the background uses aspect-preserving cover. The table is not horizontally scaled for wide windows.

## Animation tooling packaging boundary - 2026-08-18

`GlobalTweens.gd` is the active shared tween autoload. Tween Composer is also a runtime dependency of `HomeOverlayLayer` for the Home logo loop and must remain packaged on Android. Gameplay feedback continues to use controller-owned state plus built-in Godot tweens/transforms; neither animation utility may own simulation or progression state.
# Reference-driven contact and feedback v2

- `BoardSimulation.step()` chooses 1-8 substeps from maximum frame displacement and the smallest live radius. Every substep uses the existing circle/border solver; no swept proximity query or expanded merge radius exists.
- `ContactMergeService` consumes only pairs captured by `BoardSimulation._resolve_pair()` inside the current confirmed-contact branch. It does not invalidate a genuine early-substep contact because later substeps have already separated the bodies. Generated chain candidates still require result-to-neighbor physical contact.
- Target completion presentation remains isolated in `TargetRewardOverlay`; it now draws only a bounded glow/ray accent. Merge and coin drawing remain bounded dictionaries in `GameplayEffectsLayer` and cannot influence simulation.
# Reference-driven contact and feedback v2

- `BoardSimulation.step()` chooses 1-8 substeps from maximum frame displacement and the smallest live radius. Every substep uses the existing circle/border solver; no swept proximity query or expanded merge radius exists.
- `ContactMergeService` consumes only pairs captured by `BoardSimulation._resolve_pair()` inside the current confirmed-contact branch. It does not invalidate a genuine early-substep contact because later substeps have already separated the bodies. Generated chain candidates still require result-to-neighbor physical contact.
- Target completion presentation remains isolated in `TargetRewardOverlay`; it now draws only a bounded glow/ray accent. Merge and coin drawing remain bounded dictionaries in `GameplayEffectsLayer` and cannot influence simulation.
# Home flow authority repair

- `GameController._ready()` always calls `_show_home()` after loading/configuration. Platform feature flags no longer choose the initial app-flow state.
- Pause HOME routes through `_on_pause_home_requested()`, which removes Pause ownership, briefly clears the tree pause, and delegates to `_show_home()`; Home immediately becomes the always-processing, input-owning paused layer.
- `HomeOverlayLayer` emits `home_requested` from Level Ready Back. The controller remains the sole authority for changing `AppFlowState`.
# Android Back and shutdown boundary - 2026-08-18

- `GameController._handle_back_request()` is the single native Back policy and branches only on `AppFlowState`. UI layers may dismiss their own Home popup through `HomeOverlayLayer.handle_back_request()`, but they do not decide application exit or gameplay pause state.
- A bare Home Back calls `AdManager.shutdown_for_exit()` before `SceneTree.quit()`. Shutdown is idempotent, blocks new loads/retries, invalidates timer generations, clears external completion callables, and discards cached ads.
- Home remains the paused owner of the tree. No Back path may show Pause over Home or unpause the hidden board.
- Vibration is not a shipped setting. `HapticsService` remains a disabled event sink so confirmed controller event routes require no gameplay rewrite.
# Last-AAB Home/export boundary correction - 2026-08-18

- `HomeOverlayLayer` has a real runtime dependency on `tween_composer/`; Android export must include it while those preloads and the Home logo composer remain.
- `GameController._show_home()` owns both logical and visual state: it hides `GameplayHudLayer`, presents Home, and pauses the tree. Overlay coverage alone is not a valid state boundary.
- Android window Back and key-style Back enter through `_dispatch_platform_back_request()`, which suppresses duplicate representations inside 350 ms before calling the state policy.
# Android Targeting and Launcher Branding

Persistent Android targeting is defined by `android/build/src/main/AndroidManifest.xml` inside the installed Godot Gradle template; Godot injects package, version, orientation, screen support, and app-category values from `export_presets.cfg` during export. The template contributes only the explicit touch requirement, avoiding generated-build-only edits. Launcher resources are sourced from the three `launcher_icons/*` paths in `export_presets.cfg`; Godot generates density-specific legacy/adaptive Android resources at export time. The logo source and presentation reference remain under `assets/logo/`, while runtime launcher inputs stay under `assets/runtime/ui/` and are excluded from the Godot asset pack because Android consumes them as native resources.
# Architecture Addendum - HUD Density and Collision Stability V1

`UiDesignSystem.PROGRESSION_ICON_SIZE` owns the fixed-strip gem artwork scale. `GameplayHudLayer` keeps the original panel/anchor geometry and binds the settings `TextureButton` to `TOP_SETTINGS_SIZE`, matching its containing utility frame.

`BoardSimulation._step_subframe()` retains one authoritative pair sweep for merge capture and impact telemetry. It then runs `GameConfig.COLLISION_SEPARATION_PASSES - 1` additional pair sweeps with both capture and telemetry disabled. This is a bounded positional stabilization stage, not a second merge path.
# Architecture Addendum - HUD and Popup Simplification V1

`UiDesignSystem._frosted_glass_style()` now creates one gradient/rim surface without a separate white highlight border. Gameplay Target is one `PanelContainer` built by `GameplayHudLayer`; it has no nested target panel, badge, or `ProgressBar`. Target completion/progress continues to animate only the numeric `TargetProgressText` from controller snapshots.

Gameplay Settings is a direct `Button` styled through `utility_frame_style()`; Home Settings is a direct cog texture button. No UI node added by these presentation paths participates in board input, physics, merge, score, or target qualification.
# Architecture Addendum - HUD Panel Flattening V1

`GameplayHudLayer.NextPanel` contains one outer `PanelContainer` plus direct label/art layout; its old nested heading panel is removed. Settings rows and Result reward information now use layout-only `HBoxContainer`/`VBoxContainer` nodes. Surface ownership remains with their parent modal/card only.
# Architecture Addendum - Firebase Analytics Bridge

`scripts/services/analytics_service.gd` is the GDScript-facing, no-op-safe `Analytics` autoload. On Android it calls the `FirebaseAnalytics` Godot singleton. `android/build/src/main/java/com/owais/majestygems/analytics/FirebaseAnalyticsPlugin.java` parses flat JSON event payloads and sends them to Firebase; it cannot call gameplay code.

`GameController` reports only confirmed level/target/merge/loss/win boundaries. `AdManager` reports only committed fullscreen shows and confirmed earned rewarded callbacks. Analytics remains observational and never gates simulation, scoring, rewards, progression, or ads.
# Retention services (unreleased)

`LevelConfig` declares `level_type` and `shot_limit`; `GameController` decrements only committed shots and evaluates out-of-shots after the merge/collection lifecycle settles. `DailyMissionService` is a deterministic, event-driven local-state transformer stored as `retention.daily_state` by `ProgressionSaveService`. `DailyMissionsOverlayLayer` and HUD read controller snapshots/signals only. Currency mutations remain controller save-before-commit transactions.
