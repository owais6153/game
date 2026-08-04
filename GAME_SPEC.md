# Game Spec — Clean Contact Merge v1

## Scope

## Reference target reward correction v3

- Level 1 remains exactly L5, then L7, then L8. Frame review of the supplied reference confirms three coin sequences at approximately `14.6 s`, `46.6 s`, and `58.0 s`; each coincides with a target result. There is no ordinary-merge coin flight.
- Ordinary confirmed merges keep rigid result/impact presentation, tiered gem audio, chain feedback, and exactly-once processing, but award zero run coins and create zero coin-flight records.
- A confirmed result matching the active target is the sole currency/reward source. It uses the existing target-tier reward table and chain multiplier, registers the exact pending HUD value, and creates exactly four ordered foreground coins at the confirmed midpoint. The counter still advances by integer arrival chunks and reconciles exactly.
- No background music is active. The reference recording contains music and reward sounds in one mixed track, so `reference_music_loop.ogg` is preserved only for provenance and is not preloaded or played. The 15 bounded gem one-shots remain active. Clean continuous music and coin audio require separately supplied source files.
- The vertical launcher push/aim guide is removed completely. The coral horizontal danger line remains the only gameplay boundary overlay; table, rails, drag limits, launch coordinates, and input behavior are unchanged.
- Target collection/handoff, four-coin size/path, foreground layering, L5/L7/L8 qualification, final-coin victory gate, launcher lifecycle, physics, contacts, radii, danger grace, and reset behavior remain unchanged.

This section supersedes the reward-source, background-music, and launcher-guide statements recorded below.

## Reference audio and reward layering v2

- Level 1 remains exactly one L5 target, then L7, then L8. No level data, launcher queue, reward integer, merge rule, collision geometry, danger rule, or result qualification changes in this presentation correction.
- The reference-derived music is one `1.80 s` seamless Ogg loop started once by `AudioFeedbackService`. Movement, launch, contact, merge, coin travel, and target travel never start or restart it; the existing session sound toggle controls both music and event cues.
- Confirmed launch/contact/merge/target/result events use the earlier cached gem-tone language. There are 15 bounded one-shots, three reusable players, typed contact thresholds, and existing cooldowns. The four previously extracted event slices and all separate coin sounds are inactive in production.
- Every reward still creates exactly four ordered coin records. Their draw radius is `14.5` design px, and `GameplayEffectsLayer` is attached to the layer-40 HUD's `RewardForegroundHost`, so coin arcs and the collected target proxy stay above live gems and HUD boxes. Pause, target confirmation, and the result overlay retain higher presentation layers.
- Target arrival uses one HUD confirmation. The duplicate world-space arrival burst is removed. After L5 or L7 completes, a prebuilt ghost of the old target moves toward the top-left while fading; the new L7 or L8 target fades and slides in from the right. These transitions allocate no per-snapshot nodes and cannot advance target state.
- The ready-state push guide uses the same centralized coral color as the danger line. It retains the existing rail-derived endpoints and no input, raycast, trajectory, collision, or simulation authority.

This section supersedes the audio, reward-layering, coin-size, and target-arrival presentation statements recorded below.

## Production gameplay parity final v1

- Level 1 uses the existing L1-L4 mixed unlimited launcher and exactly three sequential confirmed-result objectives: one L5, then one L7, then one L8. Collection animation advances each objective; only the final L8 qualifies victory.
- Launch speed remains `1160 px/s`. Reference-feel motion uses centralized delta-based damping `185`, side/top/bottom restitution `0.24/0.22/0.12`, equal-mass piece restitution `0.30`, approach-only tangential friction `0.07`, merge momentum transfer `0.62`, and a `420 px/s` merge-result cap. Rails, radii, contact epsilon, merge eligibility, danger rules, and launcher lifecycle are unchanged.
- The ready aim guide computes its first visible Y from the same sloped-rail interpolation as containment. Its line and start dot stay inside the table at center and legal edge lanes; it retains no input, raycast, trajectory, or simulation authority.
- Merge presentation lasts `0.68 s`: source ghosts pull for `0.12 s`; the result lifts up to `18 px`, tilts, stretches, grows from `0.52` through a `1.26` overshoot, and dampens exactly back to the live physics root. Confirmed impacts squash along their contact normal for `0.22 s`. All transforms stay on presentation children.
- Confirmed merge rewards remain exact run COINS. Each reward creates 10 coins normally or 14 at L6+, using the supplied glossy coin through a 256 px runtime derivative. Coins pop as a varied upward fan, depart in a deterministic permuted order across four curved lanes, pass left of the target, and arrive at the live HUD icon. The visible counter advances only on arrival and reconciles to the authoritative integer.
- Audio remains original and cached: 18 one-shots plus one six-second loop. The production mix uses a rhythmic crystal-island ambience bed and clearer launch/contact/merge/target/coin/result cues behind the existing cooldown, concurrency, sound-toggle, and haptic-service boundaries.
- Final victory waits for the last visible coin, the existing hold, and exactly one result overlay. Restart clears targets, currency, effects, contact animation, danger state, and launcher state to one ready piece.

This section supersedes the historical reference-coin and physics-feedback values recorded below.

## Reference-paced coin gameplay feedback v1

- The player's run reward is presented as **COINS**, not score. Confirmed merge events remain the sole currency source, use the same exact L2-L8 reward integers and chain multiplier, and are guarded once per result ID. The controller's legacy `score` property is only a compatibility alias for `coins`.
- While `READY_TO_AIM`, a thin vertical guide runs from the launcher toward the top rail. It disappears whenever aiming is not legal and has no input, raycast, trajectory, or simulation authority.
- Merge presentation lasts 0.62 seconds: sources pull for 0.14 seconds, the result begins at 0.56 scale, and it grows through a 1.20 visual-only pop. Live radii, collision roots, velocities, and merge rules never read this scale.
- Every rewarded merge emits a bounded procedural burst at the confirmed midpoint: 10 coins normally or 14 for L6+. Coins scatter for 0.55 seconds, then follow staggered quadratic arcs into the live HUD coin icon over 1.18-1.32 seconds. The visible counter rises only as those coins arrive; authoritative currency is updated immediately and reconciles exactly.
- Confirmed gem/rail telemetry identifies the impacted simulation IDs. Eligible contact starts a 0.16-second squash/pop on the rendered `Visual` child only; the effect expires without changing position, radius, perspective root, momentum, containment, sound authority, or merge eligibility.
- Coin burst, flight, and collection use three cached original procedural metallic cues. Only the final coin adds a light collection haptic. Victory waits for the final visible coin flight before starting its existing hold and one result overlay.
- Level 1 is unchanged: L1-L4 mixed launcher bag, unlimited launches, then one L7 target followed by one L8 target. Physics constants from Physics + Reward Feedback v1 are unchanged.

## Physics + reward feedback v1

- Level 1 progression is intentionally unchanged: the L1-L4 mixed launch bag, unlimited launcher, sequential L7 then L8 objectives, and existing win/danger flow remain authoritative.
- Equal-mass contact response uses a true `0.22` coefficient of restitution and applies `0.10` tangential friction only on approaching impact. Centralized damping, sleep, wall restitution, and bounded merge momentum values keep motion lively while preserving containment.
- Confirmed L6, L7, and L8 merge results score 350, 800, and 1,800. L6+ uses a larger but bounded presentation-only reward; score still comes only from confirmed controller merge events.
- Audio feedback includes cached procedural one-shots plus a cached six-second looping procedural ambience bed. Contact thresholds/cooldowns/concurrency caps and the session sound toggle remain authoritative. Direct L6+ merges use one major haptic; chains retain their dedicated event.

## Sound and haptics v1

## Reference table + crystal audio v1

- The contained tabletop and its collision bounds share `GameConfig` geometry and sit inside a separate full-screen crystal alcove background.
- Feedback stays presentation-only: typed gem/wall impact telemetry and confirmed controller events route to original procedural crystal audio; sound/haptics never alter simulation or merge decisions.

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
- Exactly one active launcher exists while ready for input. After release, the fired gem retains launcher ownership for a fixed 0.30-second lane-clearance handoff, then becomes a normal simulation body even if it is still moving. After any presentation gate, the queue advances exactly once and creates one replacement; idle frames never duplicate it.
- Unrelated board motion or merges must never prevent that replacement. Only danger failure, final victory, and the short target-collection presentation intentionally block generation.
- The danger line is never a collision or movement clamp.
- Unobstructed gems hit the top border, stay inside the board, and settle.

## Supplied background, table, and gem assets v1

- A supplied tropical background fills the fixed portrait design canvas without distortion and remains presentation-only.
- A supplied transparent coral table is centered over the background. The playable surface is a calibrated trapezoid: its top inner rail is `x=129..594` at `y=224`, widening to `x=0..720` at `y=1080`.
- Side/top containment, launch spawn, horizontal drag clamp, and the dynamic danger line use this same centralized table model. This is coordinate alignment only; merge, collision response, scoring, chain, queue, win, and fail rules remain unchanged.
- Live pieces use Sprite2D textures mapped exactly as Pearl (L1), Ruby (L2), Emerald (L3), Sapphire (L4), Diamond (L5). The Emerald remains visually rectangular but physically circular. Diamond uses the documented clean derived runtime texture.

## Visual-physics calibration v1

- The calibrated table derivative deliberately relaxes the original top convergence. Its inner surface uses `x=90..630` at `y=224`, widening to `x=0..720` at `y=1080`; rendering, rails, spawn, drag clamps, and danger line use this same authority.
- Gameplay textures are non-destructive alpha-trimmed runtime copies. Pearl/Ruby/Sapphire use 42 px circles; Emerald uses a stable 32 px circle; Diamond uses a 33 px circle that excludes decorative sparkle/halo content.
- Contact tolerance is 0.75 design px. Sound is routed only from a confirmed physical contact impulse, carrying the same contact point shown by developer debug diagnostics. Merge sound remains tied to confirmed merge execution.

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
- The next launcher never waits for board settlement. It follows the bounded release handoff and any active merge/target presentation gate.

## Visual sequencing and contact v2

- A Diamond merge now follows `diamond_created -> win_qualified -> merge_visual_complete -> win_overlay_presented`. Qualification blocks launcher creation immediately, while the Diamond texture is synchronized, pulses, and remains visible before victory UI appears after a 0.32-second hold.
- Result UI is an independent `CanvasLayer`; its configurable backdrop does not modulate, recolor, replace, or reparent gameplay gems.
- The table uses a non-destructive runtime shader that widens upper rows for a shallower, near-parallel rail presentation. Physical rails use the same corrected top anchors (`58..662`) and bottom anchors (`0..720`).
- Collision uses stable per-level circles with a 0.20-design-pixel contact epsilon and 0.02 separation epsilon. Runtime gem rendering expands only the opaque main bodies (Pearl/Ruby/Sapphire 1.08, Emerald 1.05, Diamond 1.10); glow, shadows, and padding do not define physics.

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

## Level 1 flow v1

- The default playable level is data-driven `First Facets` (`level_1`) in `LevelConfig`.
- It exposes exactly L1-L8 in normal play. The global L1-L18 catalog and its merge validation remain available outside this level cap.
- Only L1 and L2 launch, in the deterministic L1, L1, L2 sequence (a conservative 2:1 weighting); no high tier launches are introduced.
- The one target type is two L4 Sapphires. Only unique, confirmed merge-result events can increment target progress. Queue previews, launcher spawns, debug pieces, and restored state never count.
- Target qualification blocks launches but preserves the existing merge presentation and victory hold before the result overlay appears. The existing danger-line failure remains unchanged and there is no shot limit.

## Danger and reset

- The danger line remains visual-only. It never blocks an active shot.
- A non-active, settled board gem whose lower edge stays below the line for 0.75 seconds loses the level. Moving, merging, presentation-only, or active launcher pieces never accumulate danger time.
- Win and fail overlays display the score and provide Replay/Retry. Either action fully resets the board, queue, launcher state, score, chain state, timers, flags, shot count, contacts, and presentations to one ready launcher on an empty table.

## Gameplay balance v1

- Feel tuning is centralized in `GameConfig`; the rules above remain unchanged.
- Launch speed is 1100 px/s with 285 px/s² delta-based damping and a 9 px/s settle threshold. This keeps clear shots immediate while avoiding long post-impact drift.
- Equal-mass collision restitution is 0.48; side/top/bottom border restitution is 0.20/0.14/0.10. Contact capture and merge eligibility are unchanged.
- Merge logic resolves immediately and deterministically. Only its visual presentation is staggered by 0.07 s per chain depth; source pull/pulse use 0.10 s/0.20 s.
- Once the bounded handoff and presentation gate finish, the next launcher uses the configured readiness delay. It still spawns exactly once through the lifecycle state machine.

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

## Perspective table view v1

- The approved table composition is lowered as one shared layout: table image center `(360, 770)`, board `y=340..1152`, danger line `y=970`, and launcher `y=1068`. Rails, collision containment, drag clamps, spawn, and danger drawing retain their shared `GameConfig` authority.
- Gems use presentation-only depth scaling from normalized table-local Y: `0.90` at the back/top to `1.05` at the front/bottom. The simulation piece, collision radius, velocity, and physics root remain constant.
- Each gem has a constant-scale visual root and a child visual container for sprite and separate shadow. Stable depth ordering is based on table-local Y, with the piece ID / creation order as the equal-Y tie rule. No visual node is reparented or allocated after creation.
