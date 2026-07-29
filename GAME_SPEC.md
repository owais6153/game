# Game Spec — Clean Contact Merge v1

## Scope

## Sound and haptics v1

- Feedback is presentation-only and subscribes to confirmed controller events; it never changes simulation, collision, merge eligibility, chains, score, launcher lifecycle, danger timing, outcomes, or reset.
- Short procedural tones cover launch, meaningful collision, level-specific merges, chains, win, fail, and button taps. Collision feedback requires a relative impact of at least 170 px/s and is throttled.
- Android haptics use light launch, medium direct merge, stronger chain, success win, and distinct failure feedback. Non-mobile/editor runs safely skip the platform vibration call.
- Compact `S` (sound) and `V` (vibration) HUD controls default to On and are retained for the current session, including Replay/Retry. Persistence is deferred.

This milestone implements one complete prototype level loop. It has scoring, a Diamond target, danger-line failure, and replay/retry. Sound, persistence, menus, ads, final art, and progression remain out of scope.

## Board and input

- Portrait board: left/right/top visible boundaries; empty table at launch.
- One current launcher gem begins below the visible-only danger line.
- Dragging changes only its horizontal position, clamped between side borders.
- Releasing sends it straight upward with negative Y velocity.
- Launcher lifecycle is `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`.
- Exactly one active launcher exists. The next queue advances and one new launcher appears only after the launched piece and all board resolution have settled; idle frames never advance the queue or spawn another piece.
- The danger line is never a collision or movement clamp.
- Unobstructed gems hit the top border, stay inside the board, and settle.

## Gems and merge rules

- L1 Pearl → L2 Ruby → L3 Emerald → L4 Sapphire → L5 Diamond.
- Only contact pairs captured in the current simulation step before separation enter merge resolution.
- Sources must be distinct, same-level, unconsumed, and within radius sum + 1.5 px.
- Sources are marked consumed before the upgraded gem appears at their midpoint.
- A source can merge only once per resolution cycle. Candidates are cleared afterwards.
- Contact-based chains are permitted only for an upgraded gem physically touching an existing equal-level gem by radius distance after the upgrade spawns. Chains are capped at 6 cycles; global, nearest-neighbor, and stale-pair scans remain forbidden.

## Merge presentation

- Simulation removes sources and immediately creates the upgraded gem at the validated midpoint.
- Presentation draws source ghosts pulling inward for 0.12 s, then a 0.22 s upgraded-gem pulse, glow, and ring. It never affects physics or collision.
- The next launcher waits for both board settlement and presentation completion.

## Gemstone visual prototype

- Gameplay pieces retain their existing circular collision radius; only their rendering changes.
- Pearl is round with a soft highlight; Ruby is a faceted red gem; Emerald is an emerald-cut green gem; Sapphire is a faceted blue gem; Diamond is a bright multi-facet diamond.
- The board uses a lightweight jewelry-table treatment with gold rails, a deep green felt inset, soft gem shadows, and no shaders, bloom, or external image assets.
- Source ghosts are rendered behind the immediate upgraded gem during merge presentation so the visual reads as an inward transformation rather than a one-frame pop.

## Visual refinement v1

- Rendering keeps the original simulation coordinate space and collision bounds intact. Board rails, felt inset, HUD panels, overlay dimmer, and safe margins are presentation-only.
- Gem silhouettes remain centralized in `GemVisuals`: Pearl is rounded and luminous; Ruby, Emerald, Sapphire, and Diamond use distinct lightweight facet patterns. Collision radii remain circular and unchanged.
- The merge pulse uses eased presentation timing only. Source ghosts, upgraded gem, ring, and glow have no simulation authority.
- The fixed 720x1280 design canvas uses Godot canvas-item stretching for portrait devices. Safe-bound assertions cover the HUD, action controls, and result overlay.

## Score, chain, and target

- Confirmed merge events are the sole score source; collisions and pushes have no score path.
- Result scores are centralized: Ruby (L2) 10, Emerald (L3) 25, Sapphire (L4) 60, Diamond (L5) 150.
- Every confirmed merge in one resolver sequence increases the chain multiplier from x1 upward. Score is result score times sequence multiplier.
- The multiplier resets to x1 only when the next launcher is ready.
- The level target is one Diamond (L5). Its confirmed upgraded-spawn event triggers win once and freezes launch/spawn input until Replay.

## Danger and reset

- The danger line remains visual-only. It never blocks an active shot.
- A non-active, settled board gem whose lower edge stays below the line for 0.75 seconds loses the level. Moving, merging, presentation-only, or active launcher pieces never accumulate danger time.
- Win and fail overlays display the score and provide Replay/Retry. Either action fully resets the board, queue, launcher state, score, chain state, timers, flags, shot count, contacts, and presentations to one ready launcher on an empty table.

## Gameplay balance v1

- Feel tuning is centralized in `GameConfig`; the rules above remain unchanged.
- Launch speed is 1100 px/s with 285 px/s² delta-based damping and a 9 px/s settle threshold. This keeps clear shots immediate while avoiding long post-impact drift.
- Equal-mass collision restitution is 0.48; side/top/bottom border restitution is 0.20/0.14/0.10. Contact capture and merge eligibility are unchanged.
- Merge logic resolves immediately and deterministically. Only its visual presentation is staggered by 0.07 s per chain depth; source pull/pulse use 0.10 s/0.20 s.
- Once board resolution and presentation finish, the next launcher uses a 0.08 s readiness delay. It still spawns exactly once through the existing lifecycle state machine.

## Physics and pacing parity v1

- The playable board is wider (`x=30..690`) while retaining a fixed portrait design canvas. Gems use a 42 px collision radius, so compact clusters have room to form instead of producing a narrow flat row.
- Launches use 1160 px/s and lower 235 px/s2 damping. Equal-level merge eligibility, contact capture, chains, scoring, outcomes, and launcher state transitions are unchanged.
- Collision response has lower normal restitution plus symmetric tangential contact resistance. It only affects physical sliding/settling; it does not create attraction or inspect gem levels.
- An upgraded gem receives a bounded 35% average-source-momentum handoff (maximum 260 px/s), then immediately returns to normal board physics. The presentation remains visual-only.
- Presentation/launcher waits are shorter: 0.18 s merge presentation, 0.05 s chain visual stagger, then a 0.04 s readiness delay only after resolution is complete.

## Progression preview and HUD v1

- The HUD is presentation-only and reads a single controller snapshot; it has no authority over queue advancement, score, chain, launcher lifecycle, or outcomes.
- Current and next gems are compact procedural previews with concise labels. They always display the controller's actual active/next levels.
- A compact top-edge evolution strip shows Pearl -> Ruby -> Emerald -> Sapphire -> Diamond. Diamond (L5) is the current target and is highlighted; the highest live gem may be brighter as run feedback.
- Score, chain multiplier, shot count, restart, queue previews, and target progression fit above the fixed board. The overlay uses the same jewelry-panel treatment and retains the existing Replay/Retry behavior.
