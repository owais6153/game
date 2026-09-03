# 2026-09-03 - Level templates, analytics instrumentation, shop and input fixes, version 1.0.17 (vc19)

- Fixed the power shop refusing a Buy it had just shown as affordable. The game keeps two coin balances: `coins`, a display value carrying the current attempt's unresolved target earnings, which `restart()` rolls back, and `level_start_coins`, the banked balance every sink actually spends. The shop was handed `coins` and decided affordability from it, while `_purchase_power` checked `level_start_coins` and returned a bare `false` that the caller dropped - so the tap did nothing, silently, and the number "corrected itself" on the next rollback. The daily-mission claim made the two diverge permanently by crediting only `coins`. Banked is now the single authority, exposed as `spendable_coins()`; the shop presents and refreshes from it, daily rewards credit both through `_credit_banked_coins()`, `_purchase_power` returns a reason, and a refused Buy always tells the player why. A purchase lock closes the double-tap race.
- Fixed the same class of bug in two more places: the extra-shots and continue purchases gated on the display balance while deducting from the banked one, which could drive the bank negative.
- Widened the shooter drag area. Pressing anywhere on the table below the danger line now grabs the launcher, not only the gem itself or the narrow aim-guide strip - a player swiping the felt beside the shooter previously got no response and reasonably read the shooter as stuck. Zone geometry lives in `GameConfig.shooter_drag_zone_contains()` and follows the same sloped rails the launcher clamps to. Popups and HUD controls consume their presses before `_unhandled_input` runs, so the wider zone cannot steal a UI tap. The aim-guide grab above the danger line is unchanged.
- Replaced the three independent difficulty ladders with a level-template system. Each ladder capped out - the queue by level 13, target quantities by 26, board rows by 8 - and once all three had, every later level was one of two shapes. 18 templates now name a whole composition (queue band, opening board shape and density, target structure, limited-shot margin), so difficulty is a property of the combination and two levels in the same band can play very differently. 11 layout archetypes, 10 target structures, 5 queue bands. No new mechanics: every field drives a system that already shipped.
- Moved limited-shot cadence off "every third level" to an irregular seven-in-twenty-three pattern with gaps of two to five. 23 is prime and shares no factor with the 8-long pacing cycle, so the two together do not repeat for 184 levels. Two earlier attempts were rejected by inspecting the emitted gap sequence: a 13-length pattern settled into a learnable 2,5,2,4 loop, and a mis-transcribed 23-length one produced only three gap lengths.
- Fixed pool selection picking one template forever. Entries are indexed by a multiplicative hash of the level number rather than `level % pool.size()`; the role cycle has an even length, so a modulo walk handed a two-entry pool the same index every time that role came round, putting levels 50, 60 and 100 all on `expert_volume`.
- Preserved the no-straight-lane guarantee for every layout archetype. An archetype expresses a preference over gap positions and the selector only picks from columns that already satisfy the separation rule; where that starves the pool it now serves fewer gaps rather than abandoning the rule, which the original fallback did - opening real lanes on four levels, caught by the new suite's 60-position sweep across 120 levels.
- Verified across levels 1-100: all 18 templates used, no consecutive repeats, no invalid configurations. Per-level coin income is 12.3% below 1.0.16 because target ladders are shorter, but levels demand 12.6% less material, so the earn rate per unit of merge work is unchanged (1.884 -> 1.890 coins per unit, +0.3%). Coins per minute is flat and the existing sink prices stay calibrated - the per-level figure must not be "corrected" by raising target quantities, which would inflate the economy.
- Instrumented gameplay for real-user difficulty analysis. Every level event carries a compact identifying context (template, layout, band, queue band, target structure, generator version); the three attempt-ending events carry a per-attempt aggregate - shots, merges, chains, max chain depth, combo 1/2/3+ counts, merge and chain rates, targets reached, powers used and which most. One event per attempt rather than one per shot: a merge game fires far too many small events to send each, and the quantities that matter are ratios over an attempt.
- Budgeted every event against GA4's 25-parameter ceiling, which silently drops the overflow. The full composition rides on `level_start`; outcome events carry the nine-field core. `AnalyticsService` warns on overflow and the new suite asserts the budget, so this cannot regress into columns quietly missing from a report.
- Added `level_abandon`, routed through the same once-only latch as completion and failure so an attempt yields exactly one outcome event - a player who failed and then backed out is no longer counted as both. Added the shop, skip, continue and extra-shot funnels, `final_target_complete`, `daily_missions_open`, and `coin_source`/`coin_sink` dimensions. Renamed events to one vocabulary (`retry` -> `level_retry`, `level_skipped` -> `level_skip`, and nine more); each kept its old parameters so existing saved reports resolve.
- Removed `NEXT_GEM_REROLL_COST`, a documented 100-coin sink that no shipped path ever charged. Switching the queued gem is a power spent from inventory, not a coin purchase.
- Corrected `ECONOMY.md`, which had drifted badly enough to mislead any balance work: target rewards were documented as `10..1800` against a shipping table of `2..260`, Skip was listed as both 200 and 800 coins, the daily chest was described as paying 180 coins when `CHEST_REWARD` is 0, and the file claimed no shop exists. Corrections are recorded rather than silently overwritten.
- Added `LEVEL_DESIGN.md` documenting the template system and the sequential-target audit: a merge counts toward a target only if its result tier equals the active card at resolve time, so a gem built above the active tier is never banked for a later card. That behaviour is preserved; templates account for it by keeping target tiers strictly ascending, which `LevelTemplate.validate()` enforces. `LevelSolver` does not model it and is therefore optimistic - its output is a feasibility floor, never a difficulty prediction.
- Added `reports/DIFFICULTY_ANALYTICS_GUIDE.md`: which events to inspect, which parameters matter, and what the numbers mean for too easy, too hard, boring, and good challenge.
- Added `tests/run_level_template_v1_tests.gd` and `tests/run_shop_input_analytics_v1_tests.gd`. Updated five existing suites that asserted the old design's monotonic rows, fixed limited targets, monotonic margins, and pre-rename event names; each now asserts the invariant that still holds. `run_rescue_softlock_blast_safety_v1_tests` zeroed only the display balance to mean "no coins" and had been passing only because it never ran after a test that banked coins.
- Bumped to versionCode 19 / versionName 1.0.17.

# 2026-08-31 - Release packaging, launch-screen colour, and version 1.0.16 (vc18)

- Cut 26.0 MB of packaged asset data by excluding art that no reachable code loads: `assets/ui_kit_source/*` (source sheets whose trimmed derivatives are what the runtime actually uses), `assets/vfx/*`, `assets/fonts/*`, `majestic_gems_logo_v3.png`, system splash v4/v5, and app icon v3/v4. Reachability was established by extracting every `res://` reference in shipped scripts, scenes, `project.godot`, and the export presets - only `assets/runtime/` is referenced. `assets/runtime/ui/kit/` was left intact on purpose: it is loaded dynamically by name, so static analysis cannot prove any of it unused.
- Per-device download is now 49.8 MB on arm64-v8a (51.4 MB on armeabi-v7a), measured with Bundletool on a split APK set rather than inferred from the AAB size.
- Replaced the blue launch screen. `screen/background_color` was `#095579` - a blue that appears nowhere in the game's palette - and it drove both `android:windowBackground` and the baked `--background_color` launch argument. It, `splash_screen/background_color`, and `boot_splash/bg_color` are now `#1C0734`, the same colour as the adaptive launcher-icon background, so the system splash and the window behind the engine read as one continuous deep purple instead of two mismatched screens.
- Bumped the release AAB to versionCode 18 / versionName 1.0.16, strictly above every code previously used in `BUILD_MANIFEST.md` (highest prior 17; last Play upload was 12 / 1.0.10). The debug APK preset was moved to the same identity so device builds match the release.
- Delivered `build/android/majestic-gems-release-v1.0.16-vc18.aab`, signed with the real upload key (`CN=Muhammad Owais Khan, O=Teckvertex Labs`) and version-validated with Bundletool, plus a matching release-signed `majestic-gems-release-v1.0.16-vc18.apk` for sideloading. The APK export preset had no release keystore configured, which is why an earlier release APK attempt failed; it now uses the same upload key as the AAB (credentials live in the gitignored `.godot/export_credentials.cfg`).

# 2026-08-31 - Low-end performance, rescue softlock, and merge presentation

- Cut GPU texture memory on the vivo Y21A from 139.7 MB to 79.3 MB at Home and from 143.3 MB to 82.9 MB in play, a consistent ~60 MB (42%) reduction. Both builds were measured under one identical cold-start protocol against a baseline APK exported from HEAD; total PSS moves far less (404 -> 390 MB) because it is dominated by code and the ad SDK. `AssetCatalog` preloaded all ten backgrounds and all ten tables into `const` arrays, holding roughly 70 MB resident for the one background and one table a level can show; scene art is now addressed by path through a two-entry most-recently-used cache and imports VRAM-compressed (ETC2/ASTC, verified supported on the device). On a 3 GB phone reporting 64 MB free, that pressure was forcing texture eviction, which is felt as stalls rather than as a low frame rate.
- Replaced the O(N^2) collision sweep with a vertical sweep-and-prune broad phase and cached the per-frame table geometry that `_resolve_bounds` was re-deriving through `GameConfig` on every one of thousands of calls. At 40 gems the old path ran roughly 43,000 `_resolve_pair` calls in a single frame. Crowded-board simulation cost is now 4.0x-6.4x lower, which is what removed the stall on merges and pushes.
- Stopped the stabilization sweeps as soon as one separates no overlap and applies no impulse; a settled table costs one sweep instead of seven.
- Proved the simulation change is a pure optimization: `run_broad_phase_equivalence_v1_tests.gd` requires byte-identical positions, velocities, radii and contact telemetry against the pre-optimization simulation preserved at `tools/bench/board_simulation_baseline.gd`, across 48 chaotic boards of 90 frames, plus a brute-force check that no contacting pair is ever omitted.
- Disabled the level-entry table reveal (`LEVEL_ENTRY_PRESENTATION_ENABLED`). The briefing popup already shows the table behind it, so fading it in on START GAME read as the table disappearing and coming back.
- Fixed an unrecoverable softlock in the out-of-shots rescue popup. Tapping the buy button disables every button so a double tap cannot buy twice, GIVE UP included; when the controller declined the request without dismissing the popup, nothing re-enabled them and the player could not buy, give up, or reach Home. Added `clear_pending_actions()` and called it on every declining path.
- Offered a rewarded video instead of a dead end when the player cannot afford the out-of-shots rescue or the continue, matching Skip and the powers. With no ad fill the offer states the price and closes cleanly.
- Stopped the bomb from destroying objective gems (`POWER_BOMB_MAX_CLEARED_TIER := 4`). Tiers above it are pushed by the blast but never removed, so the power can no longer delete the progress the level asks the player to build.
- Fixed the merge burst never being visible. Its sprites carried `z_index = -4096`, which Godot treats as relative to the parent, so inside a gem layer at z 10 they resolved below the table sprite and every burst was drawn behind opaque table art. The only merge feedback ever reaching the screen was the thin ring arcs the effects layer draws. The burst now draws above the gems, where its additive blend lights the result instead of hiding behind it.
- Reworked merge feedback on top of that fix. Removed the radial spark crown, which read as debris and cost a primitive per ray, and replaced it with one additive quad carrying a crisp expanding ring whose rotation rides on the ring itself. Sampling the swirl across the whole interior instead produced broad lobes that read as a spinning fan, and a wide soft bloom read as a milky cloud that covered the result gem and its neighbours.
- Matched the burst to its own sound rather than choosing a duration by eye. `merge-target-immediate.ogg` peaks at 0.10-0.15s and is ~20 dB down by 0.30s, so the burst now runs 0.30s and clears with the cue. A 0.78s version was tried and read as wrong precisely because it outlasted its own sound threefold.
- Kept the burst close to the gem's own footprint (1.05x expansion). Larger versions were louder but less readable: they hid the thing the player had just made.
- Cut the supporting concentric wavefronts from 3-6 to 1-2. Each layer is delayed behind the last, so a stack of them outlived the burst and trailed thin dull rings across the board - a sonar ripple rather than a merge, and the main reason merges read as lasting too long. This reverses the "3-6 delayed concentric wavefronts" introduced on 2026-08-31; the burst shader now carries the merge and these only support it.
- Gave merges per-gem character: each colour family has its own swirl arm count and rotation direction, and objective tiers gain a brighter accent and denser burst so climbing the ladder visibly escalates.

- Added `run_rescue_softlock_blast_safety_v1_tests.gd`. Corrected three existing suites: two sampled pixels from table art that is now GPU-compressed, and `run_gem_pattern_feedback_v1_tests` asserted three targets on every level while limited-shot levels deliberately have two - it was already failing before this work.

# 2026-08-31 - Fast power travel, impact table response, and level-entry reveal

- Kept every power cinematic at 1.65 seconds while moving the shared arrival from 46% (and 74% for Magnet/Switch) to 32%. All four powers now cross the screen quickly, then spend the remaining anticipation beat shaking, orbiting, or tightening at the action point.
- Added a deterministic 160ms presentation-only table/gem shake on the authoritative power-impact signal, centrally bounded to 1.8-4.0 pixels by power.
- Added a 520ms level-entry reveal after the shared navigation cover finishes: the table and live gem sprite layer fade in, rise 28 pixels, and the table settles from 96.5% scale when Level Ready enters play.
- Added `run_power_motion_level_entry_v1_tests.gd` to prove fast arrival, retained duration, bounded motion, exact transform restoration, and unchanged simulation-body positions.
- Pointed the debug APK preset at the distinct power-motion-level-entry artifact name. Release AAB identity/path remain unchanged; no AAB is produced for this milestone.

# 2026-08-31 - Correct fail reason, reward reveal, cinematic powers, wave VFX, and easier shot levels

- Passed the authoritative failure reason into `ResultOverlayLayer`; out-of-shots failures no longer falsely blame the danger line.
- Extended Daily Treasure feedback from a lid swap to a staged `YOU RECEIVED` reveal with an icon, name, and count for every persisted power grant.
- Extended the skippable power cinematic to 1.65 seconds and added a targeted Bomb/Hammer brace-and-shake beat over the selected gem before impact applies the board change.
- Removed merge shards, including their record pool, update loop, gravity, polygon draw calls, and tuning constants. Replaced them with 3-6 delayed concentric wavefronts and a denser bounded 12-30-ray crown keyed to exact result tier/color.
- Added gameplay-style edge diamonds to Home's Level and Coins cards, removed `CURRENT LEVEL` and idle `Tap to view today's missions` copy, and inserted 20px between Daily Missions and the status row.
- Made limited-shot rounds materially easier: exactly one L6 and one L7 objective, no L8 objective or repeated quantity, and a 24-shot minimum above the solver result. Normal levels retain their existing target scaling.
- Added `run_player_feedback_repair_v1_tests.gd` and updated merge, powers, and difficulty contracts for the new behavior.
- Pointed the existing debug-APK preset at a distinct player-feedback-repair artifact name; release AAB identity/path are unchanged and no AAB is part of this milestone.

# 2026-08-30 - Final HUD clearance, tiered VFX, power/audio production pass

- Moved the dense limited-shots objective stack upward into unused centre-top space. Counter, Target, and merge path now clear the table instead of overlapping its top frame; focused layout coverage forces the limited-shots state at three portrait sizes.
- Repositioned the input-transparent mission/ad-grant banner to the upper table during its short display, keeping the newly raised Shots and Target panels readable without shifting any HUD or simulation geometry.
- Kept all four 92px power actions in the bottom band outside the playable board and retained the armed-state highlight plus repeating `TAP ON GEM` prompt. This reconciles a partial audio change that had accidentally deleted the prompt cadence.
- Replaced the binary normal/major merge burst with a bounded exact-tier ladder. Result color, ring size/weight, spark count, shard count/scale, and high-tier jewel core now escalate monotonically from L1 through L8 without adding nodes or changing the 420ms merge timeline.
- Extended the skippable power cinematic from 0.92s to 1.08s. Bomb and Hammer now carry stronger flash/ring/debris multipliers than Magnet and Switch.
- Integrated five supplied runtime cues: Bomb, Hammer, Magnet, Switch, and Level Complete. Daily Treasure now uses the previous completion cue. Preserved sources are editor-ignored and export-excluded; runtime Ogg files are the only packaged derivatives.
- Installed FFmpeg 9.0.1 and used it to remove 0.17-0.91s silent tails, shorten Bomb's overlong 3.5s active tail to a 1.70s bounded cue, tighten attack lead-ins, add clean destructive-power fade-outs, and strip Hammer's embedded cover-art video/metadata. Final runtime files are audio-only stereo 48kHz Vorbis.
- Added strongest-first collision-SFX arbitration: at most three impacts per frame and three simultaneous contact voices in the existing five-voice priority pool. Physics and collision visuals still process every confirmed impact.
- Added/updated regressions for limited-shots HUD/table clearance, monotonic tier-to-VFX mapping, cinematic hierarchy, new audio mapping, and collision concurrency.

# 2026-08-30 - ffmpeg installed, power row moved off the table, gem shards, prompt fixed

- **Installed ffmpeg** and extracted the reference video rather than continuing to work from description. What it actually shows: powers live in a dedicated bar **well below** the board, the HUD is a compact top strip, and every routine match throws **coloured fragments** outward plus white star sparkles - localised to the match, never screen-wide.
- **Moved the power row off the table.** It was anchored across the table's lower frame, starting at y1384 while the table ends at y1454 - seventy pixels *inside* the area the player drags across to aim, which is why shots were turning into accidental power taps. The row now sits strictly below the table and was resized (tile 124 -> 92, caption 24 -> 14) so it still fits on screen. A regression asserts no power button ever overlaps the playable board, at four portrait sizes.
- **Added gem shards to merges**, the main thing the reference does that we did not. Every merge now throws coloured fragments from the merged gem's own colour, falling under gravity and fading. Seven on an ordinary merge, eleven on a target merge, pool-capped at ninety and cleared with the layer.
- **Fixed the "TAP ON GEM" prompt, properly this time.** Two of my previous edits had silently failed to apply: the repeat was never wired into `_process` and the arm-time call was never replaced. The prompt therefore fired once for under a second and was effectively invisible. Both are now applied and verified - headless, the prompt is visible in 325 of 400 frames while a power stays armed, and it is confirmed on the device.
- All thirty-one suites pass.

# 2026-08-30 - Merge grace, cluster overlap, chain reach, repeating power prompt

- **Found the "touching but didn't merge" cause: `BONUS_MERGE_GRACE_MS` was 650.** A fresh bonus gem cannot merge during that window, and bonus gems spawn on *every* merge - so there were almost always gems visibly touching a match and refusing to combine for two thirds of a second. Cut to 180ms, enough to keep the spawn pop readable. This also feeds directly into chains, because bonus gems can now join one instead of sitting it out.
- **Found the overlap cause: only three separation sweeps ran per frame.** A gem pressed by several neighbours at once kept a visible overlap, which the code comment already acknowledged. Raised to seven; each extra sweep resolves another layer of a packed cluster.
- **Widened the chain window to the top of its documented range** (22 -> 30px) after the previous value still left chains scarce.
- **Fixed the "TAP ON GEM" prompt being invisible in practice.** It was firing correctly - verified in-engine, the label is created - but a single combo-style label lasts under a second while the power stays armed indefinitely, so it was trivially missed. It now repeats on a 1.35s cadence for as long as a power is armed, in the same style throughout.
- Added `tests/run_merge_physics_v1_tests.gd`: a dense mixed-tier cluster must settle without visible overlap, two touching same-tier gems must always produce a merge at every tier, the bonus grace must stay short, and a chain must continue to a gem placed a fixed 14px beyond touching. That last distance is deliberately a literal rather than a fraction of the tolerance - scaling it with the constant would have made the assertion unfalsifiable, which is exactly the mistake the first draft made.
- Relaxed a contract that pinned separation sweeps to exactly three. Its stated intent was that stabilisation stay *bounded*; it now asserts a range instead of a literal.
- All thirty-one suites pass, twice, with no order dependence.

# 2026-08-30 - Combos made reachable, straight lanes closed, merge feedback raised

- **Found why Combo 2 essentially never happened.** A chain required the freshly merged gem to be already touching another gem *of its new tier* to within `CONTACT_EPSILON` - two pixels. Higher tiers are scarcer, so that was effectively luck and players only ever saw Combo 1. Chains now get their own bounded window, `CHAIN_CONTACT_TOLERANCE` (22px, roughly half a small gem). **The primary merge is unchanged and still strictly contact-only**; only the chain search reaches further.
- The prior contract test asserted chains must never proximity-chain at all. That was a deliberate earlier decision, now superseded by instruction, so it was rewritten rather than deleted: a gem inside the tolerance must chain, one clearly beyond it must not. The bound is the contract.
- **Found and closed the "push everything up one line" exploit.** Opening-board gaps were rolled independently per row and frequently lined up, leaving a channel open through every row. Measured with real gem geometry, every level left a **105-168px lane where a gem is 72px wide** - more than double the clearance needed. Three fixes together: gaps are now chosen by normalised horizontal position so adjacent rows cannot align, boards start at two rows (a single row's gap is open top-to-bottom by definition), and every seeded board uses one offset gap. No level from 2 to 60 now leaves a gem-width lane.
- Two of my own measurement bugs were caught while doing this and are worth recording: the first check sampled a zero-width line, which flagged ordinary spacing between neighbouring gems as an exploit; the second sampled the full 0-720 board rect, which reported the scenery either side of the table as a lane. Only sampling the table interior for a corridor at least a gem wide answers the real question.
- **Raised ordinary merge feedback.** It is the action the player performs most and was the quietest thing on screen. Radial intensity 0.35 -> 0.52, sparks 8 -> 12, and a deeper pop (peak 1.24 -> 1.30, recoil 0.93 -> 0.90). The combo ladder was rescaled to stay monotonic above it, so the hierarchy is unchanged - only the floor moved.
- **Added a "TAP ON GEM" prompt** when bomb or hammer is armed, drawn in exactly the combo-label style: same font, colour, rise, duration and pop timing, so the instruction reads as part of the same feedback language rather than as separate UI.
- Fixed a test that assumed every target needs one gem. Target quantities scale with level, so once the saved level reached a band where the first target asks for two, the analytics suite silently stopped completing anything. It now drives from the level's actual requirement.
- All thirty suites pass, twice in a row, with no order dependence.

# 2026-08-30 - Performance hygiene: unbounded contact-cooldown map

- **Found a slow leak in the contact-cooldown map.** `collision_visual_last_at` was only ever written to. It is cleared on restart, but within a single level it grew one entry per gem id that ever registered a contact, and gem ids are never reused - so a long session accumulated thousands of entries that could never be read again. Measured at 1,280 dead entries over 1,280 contacts. It is now pruned, amortised so the scan only runs once the map exceeds the number of gems that could plausibly be on cooldown at once.
- **Audited the rest of the long-session surfaces and found them clean.** Repeated power use across 40 activations produced no node growth and no orphans; merge hitstops are erased on completion and cleared on restart; the presentation trace, the audio voice pool, the bonus board cap and the per-shot bonus budget are all bounded by construction. Effects, coins, mini-gems and combo labels all returned to zero after the stress run.
- Added `tests/run_performance_hygiene_v1_tests.gd` covering the bounded contact map (including that pruning does not break the cooldown it exists to enforce), node and orphan counts across repeated power use, and the configured caps. Verified it reproduces the unbounded growth.
- All twenty-nine suites pass.

# 2026-08-30 - Coin economy rebalanced: one level paid eight powers

- **Found the economy was broken by roughly 10x.** A single level paid **2,950 coins** (350 + 800 + 1,800 for its three targets) while the most expensive sink in the game was Skip Level at 800 and the priciest power was 350. A player owned every power several times over before finishing level 1, and coins never meant anything again. Every sink price and mission reward had been tuned against an income about ten times smaller than the one actually being paid.
- Nothing caught this because **every number was only ever asserted on its own** - the reward table had an "explicit and auditable" test that checked the literals, and the prices had their own ordering test, but nothing compared the two.
- **Rebalanced the target reward table** (tier 6/7/8: 350/800/1800 -> 55/120/260). A level now pays 435-665, so a power costs roughly one level of play, Skip Level costs about one and a half, and a full day of missions (~295) is worth about two thirds of a level. Buying anything is a decision again.
- Added `tests/run_coin_economy_v1_tests.gd`, which asserts the economy in **proportion** rather than in literals: a power must cost between 0.2 and 2.0 levels of income, Skip must cost more than the priciest power and at least a level's income while staying reachable within a few, rewards must rise with tier and with level, and a day of missions must be worth returning for without dwarfing play. Verified it fails against the old table.
- All twenty-eight suites pass.

# 2026-08-30 - Daily mission variety, gated objectives, four new mission events

- **Missions were a fixed triple.** Every day rolled the same three objectives, so the daily loop read as static grind counters. They are now drawn from an easy/medium/challenging pool with real day-to-day variety.
- **Added the four mission event sources that did not exist.** Only `merge`, `high_tier`, `coins_earned` and `level_complete` were ever recorded, which is why the mission set could not vary in any meaningful way. Now also recorded: `combo` (per chain link, so a deep chain counts for more than one follow-up), `power_used`, `target_complete`, `limited_complete`, and `no_power_complete` (tracked per attempt and cleared on restart).
- **Gated objectives the account cannot reach.** Limited-shots levels do not exist before level 4, so "Beat a Limited-Shots Level" is only offered once the player has one available. The player's level is threaded into the daily roll for this.
- **Fixed a variety bug the new test found immediately:** the roll divided the date by a power of seven, and since consecutive dates differ by one, the quotient only moved every 49 days - the "varied" set was effectively constant across a month, and the limited-shots objective was never reachable at all. Replaced with a proper mix.
- Added `tests/run_daily_mission_variety_v1_tests.gd`, which asserts every rolled objective is driven by an event the controller actually records (a mission whose event is never recorded can never be completed), that sets vary across a month, that a reload cannot reroll a day into easier objectives, that locked content is never asked for and does become reachable later, and that rewards rise with difficulty.
- All twenty-seven suites pass.

# 2026-08-30 - Opening board never placed in play, frame calmed, target escalation

- **Found and fixed the biggest defect of this pass: the opening board was never placed in the real game flow.** Only `restart()` seeded it, and the actual sequence - Home -> Level Ready -> Start Game - never calls `restart()`. Every level of every session opened on a completely empty table, so the entire seeded-layout feature added for the difficulty work was silently absent in play. Caught by looking at the device, not by the tests.
- **The existing coverage passed because it tested a path the game does not take.** `_test_controller_places_the_opening_board` called `restart()` directly. Added `_test_opening_board_survives_the_real_entry_flow`, which never calls `restart()` and walks the real sequence instead. Verified it reproduces the empty board.
- **Confirmed the Settings icon fix on the physical device.** The gear is now optically centred with an even ring of plate on all four sides; previously it sat ~16px left and clipped the border.
- **Calmed the table artwork.** Several supplied table variants carry a bright neon rail that was the loudest element on screen, inverting the intended hierarchy of gems first, frame last. The sprite is now modulated to 0.82/0.84/0.90. Presentation only: rail geometry, containment, drag clamps and the danger line all keep reading the same authoritative `GameConfig` values, asserted by test.
- **Power tiles now rest below full brightness.** Four framed gold tiles at full white competed with the gems they sit under. An owned, usable power rests at 0.88 alpha; the armed one stays unmistakably brighter; a zero-count tile stays at the same resting weight because the green "+" already carries that affordance.
- **Targets now escalate across the sequence.** Only the final target had a distinct cue, so completing target 1 and target 2 felt identical and the objective run read flat until the end. Each successive target lands slightly harder, bounded so the top of the range stays under the level-completion cue.
- Fixed three more brittle source-text probes in `run_sound_privacy_link_tests` that matched whole single-line calls and failed purely because emits were reformatted across lines. They now match the event identity, which is the contract that actually matters.
- Made `run_level_difficulty_v1_tests` state-independent by seeding the save, after it proved order-dependent on a shared `user://`.
- All twenty-six suites pass.

# 2026-08-30 - Consecutive-merge escalation, analytics gaps, hierarchy pinned

- **Added consecutive-merge escalation.** The combo pitch in `MERGE_TIMELINE_*` only escalated *within a single chain*, so a player merging steadily shot after shot heard the same flat cue every time and the moment-to-moment loop read as static. A streak now counts shots that produced at least one merge and applies a small pitch and intensity lift on top of the chain pitch. It caps at 6, resets when a shot produces no merge, and clears on restart and level change so a new level never opens already escalated.
- **Pinned the feedback hierarchy in a test** rather than leaving it as prose: ordinary merge < chain < mission complete < target complete < level complete, every power above an ordinary combo, and a fully escalated combo asserted to stay quieter than the target cue. The escalation cannot be tuned upward past a target by accident.
- **Audited analytics against the required event list.** Coverage was already close to complete - `daily_mission_claimed` exists under the name `daily_mission_reward_claimed`. Three genuine gaps were filled: `power_tutorial_shown`, `power_tutorial_completed` (guarded by the seen list, so it fires once per save rather than on every dismissal), and `shop_opened`.
- Fixed a brittle regression probe in `run_sound_privacy_link_tests` that matched merge-cue source text literally and failed purely because the call was reformatted across lines. It now matches the argument, so the ordering contract it actually checks survives formatting changes.
- All twenty-five suites pass.

# 2026-08-30 - Production polish: icon centring, ad robustness, limited-shot feasibility

- **Root-caused the Settings icon padding properly.** Godot lays a `Button` out as icon + text and reserves `h_separation` *even when the text is empty*, so an icon-only button draws its glyph left of centre - measured on device, the gear sat ~16px left and clipped the plate border. No `icon_max_width` value could fix that, which is why two numeric attempts failed. The glyph is now a full-rect child `TextureRect` with a symmetric inset via `UiDesignSystem.centre_icon_in_button()`. `run_hud_alignment_v1_tests` measures rendered rects rather than configured values and fails any icon-only `Button.icon` anywhere in the HUD.
- **Fixed a trap on the win screen when no ad is available.** When `show_rewarded` returned false, the double-coins path logged the failure and returned without resolving the flow, leaving `app_flow_state` at `AD_SHOWING` and the win screen's actions permanently pending. That is the normal outcome with no ad inventory - i.e. the current production situation.
- **Fixed stacked rewarded requests.** Neither the power nor the coin path guarded against repeated taps, so an impatient player started several videos. Both now bail while a request is pending or a fullscreen ad is showing.
- Added `run_no_ads_available_v1_tests`, which asserts that an unavailable ad grants nothing, that a video dismissed without earning grants nothing, that player-facing copy contains no technical vocabulary, that no WATCH action is dangled when there is no video, and that the coin purchase route still works with ads dead.
- **Found that every shipped limited-shot level was unwinnable.** New `LevelSolver` computes a material floor (merging conserves powers of two, so a tier-T target costs exactly 2^(T-1)) and a greedy play-out under the real per-shot bonus-gem cap. Level 4 needed 46 shots under perfect play and granted 40; level 25 needed 79 and granted 30. The old limit came from a fixed 40 -> 30 ladder that never referenced the targets - a regression from moving limited shots to level 4 and scaling target quantities without checking either against the other.
- Shot limits are now **derived** from `LevelSolver.minimum_shots()` times a margin that decays 1.70 -> 1.30, so every limited level completes with 20-38 spare shots. Locked by `run_limited_shot_validation_v1_tests`, which also proves the solver can reject a starved level.
- Known limitation recorded in the report: because the targets genuinely need 46-79 shots, the derived limits are large (79-113), so limited-shot levels are currently a safety net rather than real pressure. Tightening them needs a target-quantity reduction, which was not taken unilaterally.
- All twenty-four suites pass.

# 2026-08-30 - Rewarded-ad completion never ran: root cause found and fixed on device

- **Found the real cause of "I never see the reward popup after watching an ad."** `AdManager._finish_rewarded` invokes the completion with `callv([earned])` - one argument - but both controller completions were declared `func() -> void:` with **no parameter**. The call failed, so the entire dismissal handler was skipped. The reward itself was still granted, because that runs on a separate callback, so the inventory incremented while the popup that reports it never opened. This shipped that way and is exactly the symptom reported repeatedly. Both completions now accept the flag.
- Verified end-to-end on a physical device (Vivo V2149, 720x1600, real AdMob fill): watched a rewarded video, `power_granted owned=3` logged, and the panel now reads **"+1 BOMB - You now have 3."**
- **Fixed the power overlay rendering behind the screens that open it.** It sat on CanvasLayer 55 while the shop is 66 and Home is 60, so tapping **GET** with no coins opened the offer *underneath the shop* and looked like it did nothing. Now at 80. Verified on device: GET now opens the offer.
- **Fixed the daily-mission badges drawing through the Settings modal.** They raise their own `z_index`, which sorts across the whole canvas layer regardless of tree order. Modal blockers now carry `MODAL_Z_INDEX`, applied to Home and to the gameplay pause modal. Verified on device.
- **Fixed contradictory offer copy.** The shop opens the ad offer when the player cannot *afford* a power, which is not the same as being *out* of it - the panel said "Out of BOMB" over a shop row reading "Owned: 1". The title and body now depend on the owned count.
- **Fixed the HUD panel decorators sitting fully inside their panels** (`PanelContainer` sizes children to its content rect, inset by the stylebox margin) and **gave the settings cog padding** (`expand_icon` stretched the gear to the full button).
- Added `tests/run_ad_callback_contract_v1_tests.gd` and `tests/run_overlay_layering_v1_tests.gd`. Both were verified to reproduce their original defects before the fixes, and the ad suite seeds its own inventory because the rewarded daily cap lives in `user://` and would otherwise make it order-dependent.
- All twenty-one suites pass.

# 2026-08-30 - Overlay layering root cause, restored ad result, decorator and padding fixes

- **Root-caused three separate reported bugs as one defect: CanvasLayer ordering.** `PowerOverlayLayer` sat on layer 55 while the power shop is 66, daily missions 65, and Home 60. Every ad offer and every ad result opened *behind* the screen that launched it. That is why tapping **GET** with no coins looked like it did nothing, and why the **rewarded-result popup was never visible after watching a video** - it was rendering, just underneath the shop. The overlay now sits at 80, above every screen that can open it.
- **Restored the result popup after a successful ad.** It was briefly banner-only; the confirmation after sitting through a video is the moment the player is looking for and has to be unmissable.
- **Fixed the daily-mission badges drawing through the Settings modal.** The status badges raise their own `z_index` so half the badge can hang outside its card, and `z_index` sorts across the whole canvas layer regardless of tree order, so they punched straight through the modal. Every Home modal blocker now carries `MODAL_Z_INDEX` (100), and the same fix was applied to the gameplay pause modal, which the mission banner (z 40) would otherwise have drawn through.
- Added `tests/run_overlay_layering_v1_tests.gd`, which asserts the power overlay outranks every screen that opens it, that every Home modal blocker outranks all content `z_index`, and that no content reaches the modal rank. Modal blockers are discovered by name pattern rather than hardcoded, so a modal added later is covered automatically. Verified it reproduces both original defects.
- **Fixed the HUD panel decorators sitting fully inside their panels.** `PanelContainer` sizes children to its *content* rect, which is inset by the stylebox margin, so the diamonds were placed inside the visible border. They now compensate for that inset and straddle the border with half hanging outside, as intended.
- **Gave the settings cog padding.** `expand_icon` stretched the gear to the full button, jamming it against the frame; a capped `icon_max_width` keeps a ring of plate visible around the glyph on both Home and the HUD.
- **Fixed the power row captions reading as clipped on small screens.** The bottom clearance left only ~16 real pixels under the captions at 360x640; it is now sized to keep visible breathing room at every portrait size, including aspects shorter than 16:9.
- All twenty suites pass.

# 2026-08-30 - No popup after a successful ad, top banner, HUD decorators, Home sizing

- **Removed the popup that appears after watching a rewarded ad.** A completed video now closes the offer and announces the reward in the top banner instead. The player already watched the video; making them dismiss a panel afterwards was a tap for information the count badge and banner already carry. The panel is kept only for genuine failure, where the player must be told plainly that nothing was granted and no daily allowance was spent.
- Worth knowing for debug testing: **in the Godot editor there is no ad fill**, so `is_rewarded_ready()` is always false and every attempt takes the failure path. That is the correct branch, not a bug - real fill only exists on device.
- **Hardened popup dismissal.** `close()` released input immediately rather than at the end of the fade, and hiding is now scheduled unconditionally instead of only from `Tween.finished`. A tween is presentation, not the source of truth for whether a modal is up; if it were killed or failed to advance, the popup would have stayed on screen with no way to dismiss it.
- **Moved the mission banner to the top of the screen** as requested, slimmed it (536x84), and generalised it into one reusable top banner that both mission completions and ad grants use, so an earned thing is announced the same way wherever it came from. It briefly overlays the coin card; the shots counter, target panel, and power row stay clear and a regression enforces that.
- **Added decorative diamonds to the Target, gem-sequence, and NEXT panels**, extracted from `sheet_panels_v2`. Two 30px marks per panel straddling the border, so they read as part of the frame rather than as content.
- **Fixed the decorators landing in the middle of each panel** on top of the target text and the gem strip. `PanelContainer` is a Container: it lays out every direct child to fill its content rect and overrides their anchors. One plain `Control` now absorbs that layout and the diamonds anchor freely inside it.
- Home: logo enlarged 360x220 -> 424x259; **SHOP reduced to 360xBUTTON_HEIGHT on the plain secondary pill** so it reads as clearly subordinate to PLAY rather than a second hero action; settings cog switched from the recoloured generic icon to the kit's own `icon_gear` on both Home and the gameplay HUD.
- All nineteen suites pass with zero script errors.

# 2026-08-30 - In-play mission notification, mission-complete cue, shop icon removed

- Added the **in-play daily-mission notification**. Completing a mission mid-level now shows a non-blocking banner ("✓ Daily Mission Complete!" over the mission's own label) using the same laurel-check badge the missions popup marks a claimed mission with. Previously completion during play was invisible: it only wrote an analytics event.
- Filled the **missing rung in the reward hierarchy**. `mission_complete` had no audio event at all, so the requested merge < combo < mission complete < target complete < level complete ladder had a hole in it. It now has its own chime, volume 0.74 (above chain's 0.70, below target_complete's 0.78) and priority 83 (above chain, below target complete), so a completed mission cuts through an incidental combo but never masks a met target or level completion.
- **Fixed the banner rendering completely invisible.** The first implementation animated it with a `Tween`, which reported `is_running() == true` but never advanced a single property inside a `SubViewport`. It is now driven by an explicit delta timeline stepped from the controller's `_process`, matching how `GameplayEffectsLayer` and the power cinematic already work - and it steps identically in play, in tests, and in offscreen captures.
- **Fixed the test that let that bug through.** It asserted only `visible`, which is set synchronously, so a banner that never animated still passed. It now steps the timeline and asserts the banner actually reaches full opacity, arrives at its settled position, and leaves on its own. Verified it fails against a stalled timeline.
- **Reseated the banner off the HUD readouts.** The first placement sat at the top of the screen and covered the coin count and clipped the NEXT card. It now sits just inside the top of the table - the least information-dense region on screen - and a regression asserts it never intersects the coin panel, shots counter, target panel, NEXT card, or any power button.
- The completion event is logged as `daily_mission_earned`, deliberately **not** reusing `daily_mission_completed`: that name already fires at claim time, and reusing it would mix two different moments into one metric.
- **Removed the shop illustration from the Home SHOP button.** It read as a second focal point beside PLAY and competed with the plate art; the button now carries just its caption, matching PLAY. The icon is dropped from the art pipeline and its derivative deleted; the supplied original stays preserved under `assets/ui/shop/`.
- All nineteen suites pass with zero script errors.

# 2026-08-29 - Level difficulty: opening boards, limited shots from level 4, target scaling

- **Root-caused "levels are too easy because you can push gems up one line."** It was structural, not tuning: every generated level started on an empty table (`starting_board` was always `[]`) and layouts were pure launcher-sequence permutations. With nothing to aim around, horizontal position never mattered.
- Levels from 2 onward now open with a **seeded, staggered cluster** so the centre lane is never clear. Rows are capped at 4 so the launcher always has a landing spot, only spawnable tiers are placed so every seeded gem can be merged into, and the lowest row sits 250px above the danger line so a level never starts near a loss. Layouts derive from the level seed, so a retry is the same puzzle rather than a reroll.
- Fixed the board **going static from level 8**: row count hit its cap and nothing changed after that. Row growth slowed to every 3 levels, and density now keeps rising through gap count instead - two gaps per row below level 12, one from 12 on. The gap is rolled once per row; rolling it inside the column loop had left some rows sealed and others missing several gems.
- **First limited-shots level moved from 10 to 4**, immediately after the three levels that teach the merge loop, and it now recurs every 3 levels so it reads as a returning variant rather than a phase. Never two in a row.
- Added **target quantity scaling** (up to 3x tier 6, 2x tier 7). The top tier stays at 1: it is the longest merge chain in the level, so repeating it would multiply the hardest work rather than deepen the objective. Without this the objective stopped changing once density capped and later levels were indistinguishable.
- Raised the shot floor 26 -> 30 to stay ahead of the new quantities. Across the curve, pressure rises from 13.3 to 5.0 shots per required gem and then holds.
- **Solvability is enforced, not asserted in prose.** `run_level_difficulty_v1_tests` checks every limited level from 4 to 60: the limit clears one full launcher cycle, exceeds `total_target_quantity * 4`, and `total_target_quantity()` is checked against the generated `target_sequence` so a future quantity edit cannot drift away from the floor protecting it. Powers may be strongly encouraged; they are never required.
- All eighteen suites pass with zero script errors - now checked explicitly, because a GDScript runtime error aborts the enclosing test function and can otherwise let a suite report PASS with its remaining assertions silently skipped.
- Caveat recorded in the report: this is a bound, not a proof of play. That the tightest levels are *comfortable* rather than merely possible still needs device playtesting.

# 2026-08-29 - Nine-patch distortion fix, kit plates re-authored, mission cards, padding

- **Root-caused the "stretched assets" report.** Measuring each plate showed the safely stretchable *vertical* band is only 2-5px tall (`btn_pill_gem`: rows 68-70 of 137) - these plates are a continuous bevel with a specular highlight, not a body with a uniform middle. The old margins were squashing ~77px of that bevel into ~28px on every button, smearing the rim and highlight. That is the distortion, and no amount of margin tuning fixes it.
- **Re-authored every kit plate at the exact height it is drawn at**, so the vertical nine-patch scale is exactly 1.0 and nothing stretches vertically. Introduced `BUTTON_HEIGHT` (96), `HERO_BUTTON_HEIGHT` (116), `BANNER_HEIGHT` (92), `ICON_BUTTON_SIZE` (76) as a contract, plus `UiKit.DRAWN_HEIGHT` recording each plate's authored height.
- **Recomputed horizontal margins from silhouette shape rather than colour.** The first attempt compared columns for colour uniformity, which wrongly flagged the smooth horizontal gloss gradient (that stretches fine) and produced 196-232px caps on a 516px hero button. Margins now end where the ornamental cap stops changing the plate's outline.
- Added a regression that walks every real button on every screen and fails when a control is shorter than its plate's caps. It immediately found **six more crushed buttons** that had been shipping distorted - Privacy Options, Settings Done, Start Game, Level Ready Skip, Exit Cancel, and Exit - none of which had been noticed by eye.
- Rebuilt the daily-missions cards toward the reference: each card now carries its own jewel hue (magenta, blue, amber) with a brass rim instead of one flat purple block that read as an undifferentiated slab.
- Fixed padding throughout: card contents were running into the artwork frame (10px -> 16px), panel margins, row separations, and every kit button's content padding rescaled to the new cap widths.
- All fifteen Godot regression suites pass.

# 2026-08-29 - Give Up fix, readable type, level briefings, shots counter rebuild

- **Fixed GIVE UP doing nothing.** `present()` guards against presenting the same result twice, but rescue mode still counted as "already visible", so declining the out-of-shots offer called through to `_trigger_failure()` and the fail screen was swallowed by the guard. The level had already failed underneath while the screen still read OUT OF SHOTS - and because the rescue screen has no Skip button, this is also why Skip appeared unavailable on limited-shots levels. The guard now allows a genuine mode change out of rescue. Reproduced before fixing; covered by `run_retention_daily_missions_v2_tests`.
- Fixed paragraph copy reading as a heavy, cramped block: the shared UI face was Nunito Sans **ExtraBold (800)**, applied to every label including running prose. It is now SemiBold (620), with weight reserved for numbers and headings via `heavy_font()`. Body 25 -> 27, small 21 -> 23, caption 19 -> 21.
- Fixed congested buttons. Plate padding went up across the board (primary 78 -> 86, secondary 52 -> 70, hero 88 -> 100, green 46 -> 62), button face dropped 36 -> 32 so long captions such as "SKIP LEVEL · 800 COINS" clear the ornamental caps, and stacked modal actions grew from 68-72px slabs to 88-92px.
- Rebuilt the limited-shots counter. It was a 72px label with 16px text wedged beside Coins; it is now a framed panel at the top of the centred objective stack, in the same language as the Target panel, with the count at score size and a pulse whenever it changes so a spent shot registers. Low counts turn coral.
- Added first-run level briefings. Starting a level type for the first time opens an explainer (targets and the danger line for normal levels; the real shot limit and what a shot costs for limited-shots), recorded per type in a new `tutorial/seen_level_types` save section so it never re-teaches. Pre-existing saves read as "nothing seen yet" and coin/level saves preserve the record.
- Added `tests/run_level_briefing_shots_v1_tests.gd` (briefing shown once per type, persistence, counter placement/centring/legibility/warning colour) and a viewport-overflow regression in `run_ui_kit_polish_v1_tests` - increasing shared button padding had twice pushed the mission card row past the screen edge, and only a screenshot had been catching it. Both verified to fail against the previous behaviour. All fifteen suites pass.

# 2026-08-29 - UI interaction polish: button states, screen transitions, reward feedback

- Fixed the interaction defect behind the "terrible hover" report. Godot swaps a button's stylebox on hover/press, and the first kit pass pointed those states at *different textures*, so plates morphed mid-interaction: the plain secondary pill sprouted gem caps on hover, and the settings gear turned into swap arrows because `btn_square_swap` has its glyph painted into the artwork. Every family now uses **one silhouette across normal/hover/pressed**, differing only by tint; press motion is carried by scale.
- Fixed inverted hierarchy: secondary plates were rendering *brighter* than the primary action, so four buttons competed at equal weight. Secondary now starts recessed, affirmative actions are green, and paid actions keep the gem plate.
- Fixed two rendering faults found in the proof sheet: `btn_green_off`/`btn_pill_gem_off` were generated but never imported, so `load()` returned null and disabled buttons drew **no plate at all**; and the capture harness reported PASS while the controller script had failed to load, leaving a bare `Node2D` and blank screenshots. The harness now fails loudly, and disabled plates are luma-desaturated derivatives of the same silhouette.
- Removed leftover artifacts from the result overlay: a stray `HSeparator` hairline that read as a rendering glitch, and the empty bordered box with a bare "!" standing in for a fail badge (now real kit art). Applied the type scale to the reward copy, which was still using hardcoded 13-16px sizes.
- Unified modal presentation: Level Complete, Try Again, Out of Shots, Daily Missions, and Settings all announce themselves with the same gold ribbon header. Settings was the last bare-label modal.
- Added `ScreenTransitionLayer` (layer 90) so Home <-> gameplay is a reveal rather than an instant cut. **The swap is applied synchronously and only the reveal is animated** - a first version deferred the swap to a covered midpoint, which made navigation async and broke three suites because callers could no longer read `app_flow_state` after navigating.
- Added popup motion and reward feedback: the daily-missions popup now has the same dim-leads/overshoot/settle entrance as the result overlay and an exit animation, and a confirmed claim kicks the card and floats its coin value. The celebration fires only after the claim is persisted, so it can never imply an unbanked reward.
- Removed a redundant balance readout on the out-of-shots screen that repeated the coin card directly above it.
- Added `tests/run_ui_kit_polish_v1_tests.gd` (6 cases: one-silhouette-per-family, no glyph-bearing plate as a state, every referenced plate importable, disabled plates actually desaturated, transition cover inert when idle, popup animates). Verified it fails against the previous behaviour. All fourteen suites pass.

# 2026-08-29 - Majestic UI kit pass: supplied art + typefaces on every screen, retention V1 defects fixed

- Fixed four defects in the previous retention/daily-missions implementation, each with a regression that fails against the old code (`tests/run_retention_daily_missions_v2_tests.gd`):
  - `DailyMissionService` mutated the caller's Dictionary and returned that same object, so the controller's `daily_state != previous` change check was always false and **daily mission progress was never saved** — it reset on every app restart. The service is now pure and `record()` returns an explicit `changed` flag.
  - `claim_mission()`/`claim_chest()` marked a mission claimed *before* the save was checked, so a failed save **consumed the mission and paid no coins**. The pure service leaves state untouched until the controller assigns the result, which happens only after a successful save.
  - `DailyMissionsOverlayLayer` sat on layer 55 while its only entry point, Home, sits on layer 60 — the popup **opened behind Home and was never visible**. Moved to layer 65.
  - `present_out_of_shots()` relabelled Home to "GIVE UP" and nothing restored it, so **every later win/fail screen showed "GIVE UP"** for the rest of the session.
- Repaired `run_firebase_analytics_pipeline_tests`, left red by the earlier `SKIP_LEVEL_COST` 200 -> 800 change (seven assertions hardcoded the old cost). It now derives expectations from `GameConfig`.
- Adopted the supplied art kit: six sheets sliced into 37 runtime assets under `assets/runtime/ui/kit/`, originals preserved in `assets/ui_kit_source/`, wrapped by the new `scripts/ui/ui_kit.gd`. Slicing used a Godot tool script (connected components with glow-gap bridging; grid slicing for the touching badge rows).
- Adopted the supplied typefaces: Nunito Sans (weights 800/1000) for all UI copy and Cinzel Black for the brand tagline. `NunitoSans-Variable.ttf` defaults its `wght` axis to 200 (ExtraLight), so every variation sets the axis explicitly — loading it plain is why the face looked spindly.
- Raised the type scale: body copy 18 -> 25 canvas units (about 9dp -> 12.5dp on a 360dp phone), with a theme-wide dark text outline so copy survives the jewel backgrounds.
- Registered `HeroButton`, `GreenButton`, and `IconButton` theme variations alongside the restyled primary/secondary, so the kit reaches every screen and popup through the shared theme.
- Rebuilt the daily-missions popup (ribbon header, badge/progress/reward cards, chest row), added a daily-missions summary card to Home, stacked the result-overlay actions (side-by-side kit plates overflowed 720px-wide screens), and made settings ON read green.
- Moved the shared border token from violet to brass to match the artwork; `run_ui_scale_layout_tests` now asserts the brass direction instead of the old violet one.
- All thirteen Godot regression suites pass. Visual proof: `tests/capture_majestic_ui_kit_v1.gd` -> `reports/majestic-ui-kit-v1/screenshots/`. See `reports/MAJESTIC_UI_KIT_V1_REPORT.md`.
- No Android artifact was produced and no device was available in this task; the UI change is broad and warrants a device pass before a release candidate.

# 2026-08-28 - UI polish pass: current-gem reroll, combo-style cost popups, Play Games removed

- Matched the latest supplied gameplay reference: replaced the lavender dice with a bold white @icons clockwise-arrows glyph and changed Switch Gem to a bright-rimmed 112 px purple squircle seated across the lower table frame.
- Reduced Next from `141.075x172` to `128x150`, reduced its gem preview from 54 to 48 px, and increased the Next-to-Settings gap from 8 to 12 px to prevent visual overlap.

- Replaced the live-board sink row with one professional 112 px circular `SWITCH GEM` action using the curated @icons dice glyph, stronger amethyst states, 18 px internal padding, a clear caption, and a transient spend popup.
- Removed Skip Level from live gameplay and placed its @icons fast-forward action in Level Ready, Pause, and Failed overlays with the 200-coin price visible at the decision point. Skip remains absent from successful Level Complete.
- Kept the entire table/art/rail/board/danger/launcher model lifted together by 64 design pixels so the bottom action zone has proper spacing without desynchronizing physics.
- Added UI and export regressions proving live gameplay contains no Skip button and `addons/at-icons/*` plus `@icons picker.html` remain excluded from Android packages.

- Redesigned Reroll to change the **current aimable launcher gem** in place instead of the queued Next preview, per user request; `GemSpriteLayer` picks up the new tier automatically from the piece model.
- Replaced the former compact sink controls with the finalized split presentation described above: one live circular Switch Gem action and overlay-only Skip Level actions.
- Built, device-tested, and then **fully removed** a Google Play Games Services v2 integration (sign-in, achievements, daily streak, local reminder notification) at the user's explicit request, to revisit later as its own dedicated pass rather than ship half-configured. No PlayGames/Streak code, autoloads, manifest entries, permissions, receivers, or Gradle dependencies remain. `ProgressionSaveService` reverted to its original three-field schema.
- All twelve Godot regression suites pass.

# 2026-08-28 - Skip Level coin sink and Google Play Games Services (sign-in, achievements, daily streak) — superseded by the entry above

- Added a second V1 coin sink: **Skip Level** (`GameConfig.SKIP_LEVEL_COST` = 200 coins), which jumps straight to the next level with no win screen, no interstitial, and no level-complete reward — purely a paid escape hatch, save-atomic and double-tap-locked like the existing reroll sink. See `ECONOMY.md`.
- Added a new native Android plugin, `PlayGamesPlugin.java` (Play Games Services v2), following the same `GodotPlugin` pattern and the same has_method()-avoidance lesson already learned from the Firebase custom-event bridge: `scripts/services/play_games_service.gd` trusts `Engine.has_singleton()` plus each call's own result, never `Object.has_method()`. Sign-in is silent and fully fail-open.
- Extended `progression_save_service.gd`'s schema with lifetime counters (`lifetime_coins_earned`, `reroll_uses_total`, `skip_uses_total`), streak state (`streak_count`, `last_streak_date`), and `unlocked_achievement_ids`; all default cleanly on pre-existing saves with no migration step.
- Added `achievement_service.gd` (pure threshold evaluation, no native calls) covering level, gem-tier, lifetime-coin, reroll/skip-usage, and streak milestones, wired into `game_controller.gd` at every natural checkpoint (merge, coin award, reroll, skip, level advance).
- Added `streak_service.gd` (pure date/counter logic): the streak increments once per calendar day on the player's first merge of that day and resets on a missed day; mirrored to Play Games via the Events API.
- Added a second native plugin, `StreakReminderPlugin.java`, plus `StreakReminderReceiver`/`BootReceiver`, for a local "your streak is about to end" notification a few hours before the day ends if it hasn't been secured yet. Uses `AlarmManager.setAndAllowWhileIdle` specifically to avoid requiring `SCHEDULE_EXACT_ALARM`; requests the Android 13+ `POST_NOTIFICATIONS` permission and is a no-op below API 33.
- Added `PLAY_GAMES_SETUP.md` and `scripts/core/play_games_ids.gd`: the exact achievement/event IDs to create in Play Console and the single file where real Play-Console-issued IDs get pasted in, matching the existing AdMob-unit-ID isolation pattern. Every Play Games call checks for the placeholder prefix and no-ops until configured, so the build is release-safe with or without Play Console setup completed.
- Added `tests/run_play_games_progression_tests.gd` (streak day-rollover math, achievement threshold evaluation, save-schema backward compatibility) and extended the existing pipeline test with Skip Level coverage; all thirteen Godot regression suites pass.
- Play Games sign-in/achievements/streak still require Play Console configuration (see `PLAY_GAMES_SETUP.md`) and mandatory device verification before a release candidate ships, per the residual-risk process already established.

# 2026-08-28 - Firebase custom-event bridge genuine fix, device-verified, AAB v1.0.13 (versionCode 15)

- With user authorization, installed the versionCode-14 candidate on the same authorized V2149 device used for the original defect report and reproduced the identical `Firebase singleton exists but logEvent is unavailable` warning: the `getPluginMethods()` change made for vc14 did not fix the root cause. **versionCode 14 / versionName 1.0.12 is also superseded and must not be uploaded.**
- Root-caused the real defect by decompiling the bundled Godot Android plugin runtime (`GodotPlugin.class` inside `godot-lib.template_release.aar`): `logEvent` was in fact natively registered via `nativeRegisterMethod` at plugin load in both vc13 and vc14. The actual defect is that `Object.has_method("logEvent")` on the JNI-backed native singleton unreliably returns `false` even when the method is registered and callable.
- Fixed `scripts/services/analytics_service.gd`'s `_native_bridge()` to stop gating on `has_method()`; it now relies on `Engine.has_singleton()` plus the real call's own accept/reject result.
- Exported, Bundletool-validated, and signature-verified `majestic-gems-production-candidate-v1.0.13-vc15.aab`; all twelve Godot regression suites and a whole-project editor import pass with no errors.
- **Device-verified with user authorization**: reinstalled the exact vc15 build on the V2149, launched, and pressed Start. Logcat confirms `MajestyAnalytics: Forwarded custom event to Firebase: level_start` and, critically, Firebase's own `FA-SVC` module logged `origin=app,name=level_start` with correct gameplay parameters — the first candidate proven to forward custom events end to end. Device left in a clean (app-uninstalled) state afterward.

# 2026-08-28 - Firebase custom-event bridge repair AAB v1.0.12 (versionCode 14) — superseded

- Exported, Bundletool-validated, and signature-verified the repaired `majestic-gems-production-candidate-v1.0.12-vc14.aab`. All twelve Godot regression suites and a whole-project editor import pass with no errors; the compiled DEX contains the `getPluginMethods`/`logEvent` bridge strings confirming the intended fix was packaged.
- Dual `arm64-v8a`/`armeabi-v7a` architectures only, package `com.owais.majestygems`, versionCode 14/versionName 1.0.12 embedded manifest confirmed, unchanged Teckvertex Labs upload signature verified.
- Device testing later showed this static/local validation was insufficient: the `has_method()` runtime defect persisted despite it. See the versionCode-15 entry above for the actual fix.

# 2026-08-28 - Final pre-launch production-readiness candidate

- Real-device release testing found that Firebase automatic events uploaded while the Godot custom-event singleton omitted `logEvent`; versionCode 13 / versionName 1.0.11 is superseded and must not be uploaded.
- Added an explicit Java `getPluginMethods()` contract for `logEvent`, retained `@UsedByGodot`, and advanced the repaired production identity to versionCode 14 / versionName 1.0.12 for a fresh device-validated export.

- Added the single approved V1 coin sink: a centrally priced 100-coin Next Gem reroll using only the existing weighted launcher sequence.
- Made reroll spending save-before-commit, banked-coin-only, retry-safe, non-negative, deterministic, and guarded against rapid duplicate requests.
- Expanded analytics with attempt/shot context, Retry, bounded `coin_earned`/`coin_spent`, ad request/failure events, and placement/reward context on SDK-confirmed shown/earned events.
- Preserved canonical `merge` and `rewarded_ad_completed` event names to avoid duplicate semantic telemetry while documenting their `gem_merge` and earned-reward meanings.
- Added the analytics catalog, economy contract, Play Console production checklist, post-launch roadmap, and consolidated production-readiness report.
- Preserved gameplay, visuals, physics, target progression, rewards, audio assets/mix, AdMob cadence/IDs, UMP gate, package ID, and save-format compatibility.
- Advanced the committed Play identity to versionCode 13 / versionName 1.0.11 and exported the signed dual-ARM `majestic-gems-production-candidate-v1.0.11-vc13.aab`; Bundletool, manifest, archive, signature, hash, and audit-APK checks passed. The V2149 phone became authorized, but its existing debuggable 1.0.1/code-2 package was not replaced; candidate launch and DebugView are not claimed.

# 2026-08-27 - Firebase custom gameplay analytics pipeline v1

- Replaced the silent GDScript-to-Android analytics hop with explicit request/service/native/forwarded diagnostics and an acknowledged `logEvent` bridge call.
- Made native Firebase acquisition retry lazily after Godot Activity startup, validated primitive event parameters, and surfaced malformed payload/native failures without affecting gameplay.
- Added exactly-once run guards and complete schemas for level start, confirmed merge, target completion, win, and danger failure; added the missing Retry level-start hook.
- Moved rewarded/interstitial shown analytics to the SDK shown callback and retained rewarded completion only at the earned callback.
- Replaced the old opaque launcher/splash source with the supplied background logo and generated v5/v6 native derivatives; preserved the transparent Home/fallback logo unchanged.
- Advanced the release identity to versionCode 12 / versionName 1.0.10 and added the permanent non-blocking device-validation AAB delivery rule.
- Exported and validated the signed `majestic-gems-firebase-analytics-pipeline-v1.0.10-vc12.aab`; packaged DEX/GDC audits confirm the newest native bridge and gameplay/ad hooks. No device was connected for DebugView.

# 2026-08-26 - Target achieved and combo readability v1

- Replaced the transient target-collection `ARRIVING` state with truthful `ACHIEVED 1 / 1` feedback after authoritative target confirmation.
- Added a real `TARGET ACHIEVED` board label to confirmed target merges and extended combo-label readability from 0.48 s to 1.10 s; gameplay authority, merge rules, target qualification, rewards, and physics remain unchanged.
- Ignored local input-replay capture folders/logs so generated screenshot evidence is not accidentally committed.

# 2026-08-25 - HUD panel flattening v1

# 2026-08-26 - Majestic branding refresh v1.0.7

- Replaced every active Home, fallback-splash, launcher, adaptive-icon, and Android system-splash branding path with derivatives of the supplied v3 logo, preserving the new root originals under `assets/logo/`.
- Removed superseded active v2 branding assets and changed the Home tagline to `A Majestic World of Gems`.
- Retained package name, production signing, AdMob identifiers, gameplay, and Android version `9 (1.0.7)` as requested.

- Removed the nested Next heading badge, framed settings rows in Home/Pause, and nested Result reward card/margin wrapper.
- Preserved each control and data group with direct layout containers only; responsive HUD, game-flow, and privacy regressions pass.

# 2026-08-25 - HUD and popup simplification v1

- Simplified every shared dark-amethyst panel by removing the white gloss/highlight overlay while retaining violet rims and no box shadows.
- Removed redundant Coins captions, condensed Target to one 340x84 surface without a badge or progress bar, and replaced the nested gameplay/Home settings glass frames with direct cog controls.
- Removed redundant Home Settings/Pause copy and decorative Pause artwork; compacted Settings, Pause, and Result popup heights without changing actions, authority, anchors, or safe-area behavior.
- Added layout regressions for compact Target, unlabelled Coins, and the direct settings cog; focused HUD/game-flow/physics/privacy tests pass.

# 2026-08-25 - HUD density and collision stability v1

- Reduced progression-strip gem artwork from 64 px to 56 px inside its unchanged fixed HUD strip, restoring space between all eight gem silhouettes and connectors.
- Corrected the gameplay settings cog's child size to the existing 64 px utility frame, removing its former 88 px overflow/misalignment.
- Added three bounded collision-separation sweeps per simulation substep. Merge capture and collision telemetry remain first-sweep-only, preventing visible dense-pile overlap without duplicate merge/impact events.
- Added dense-pile separation and settings-frame/progression-density regression coverage; focused reference-feel, UI-layout, and gem-pattern suites pass.

# 2026-08-25 - Rail, target blast, and gem expansion v1

- Added supplied `gem_33` and `gem_34` as alpha-tight 256 px runtime derivatives and audited pink-gradient Unique metadata; expanded the registry to 34 identities without adding display names.
- Re-measured all ten table derivatives at the visible inner lip and recalibrated the centralized opening from board 455-1165/back 130-590/front 54-666 to board 454-1168/back 140-580/front 58-662.
- Enlarged target-tier physical/visual radii from 51/54/57 to 56/61/66 and raised detached target emphasis from 1.12 to 1.18.
- Replaced three target rings with five denser 52-segment rings.
- Added a deterministic one-shot target blast that nudges nearby board gems while excluding the result, active launcher, consumed pieces, and out-of-range pieces.
- Raised music linear gain slightly from 0.06 to 0.07 without changing SFX or routing.
- Added focused crop/rail/contact/target/blast/wave/music regressions and two reviewed production-scene ANGLE captures.

# 2026-08-24 - Gem categories, pattern blocks, and target feedback v1

- Integrated 12 newly supplied gems as normalized `gem_21`-`gem_32` sources and alpha-tight 256 px runtime derivatives, expanding the active catalog from 20 to 32.
- Added one audited metadata registry with circle/rounded-square, color family, solid/gradient, and Common/Unique only; classified 22 Common and 10 Unique and kept all display names empty.
- Replaced unrestricted identity shuffling with deterministic 3-4-level Same Shape / Same Color blocks. L1-L4 are Common, L5 is a supporting Unique, and L6-L8 are three distinct reachable Unique targets that oppose the shape or dominant color.
- Gave every target the same three-ring reward wave, complete merge, 120 ms origin hold, 1.12 visual-only scale, center hold, and HUD flight. Moved target reward audio after merge feedback and kept collection audio at arrival.
- Reduced last-target visible coins from 16 to 4, preserved readable table holds for all targets, removed vertical coin idle float, lightened contact shadows, and fixed the cached level-reward wave schedule.
- Disabled box shadows on all centralized HUD/UI StyleBoxFancy and StyleBoxFlat surfaces while preserving dimensions, positions, fills, rims, highlights, and theme colors.
- Re-audited every table against the centralized trapezoid and captured rail-contact proofs; the current normalized shared geometry required no retune.
- Added focused 32-gem/pattern/target/coin/HUD regressions and nine reviewed GL Compatibility/ANGLE captures under `reports/gem-pattern-feedback-v1/`.
- Excluded `scripts/dev/*` from Android after the first APK audit caught the asset-preparation script in the package; production APKs now contain only runtime code/resources.

# 2026-08-24 - Supplied Art, Purple UI, and Codebase Cleanup V1

- Replaced the active scene catalog with the supplied 10 backgrounds, 10 full-portrait transparent tables, and 20 gems.
- Added a reproducible alpha-tight gem pipeline (0.01 threshold, exact crop, max 256 px), optimized scene derivatives, hash/bounds manifest, and lavender settings-icon derivative.
- Removed all player-facing gem-name display and the unused HUD target-name node.
- Rethemed shared HUD/Home/modal/result styles from light cyan/cream to dark amethyst glass without changing layout dimensions or anchors.
- Recalibrated centralized table rendering/rails/board/danger/launcher geometry to measured supplied-table art while preserving L1-L8 radii and all gameplay rules.
- Organized scripts by responsibility and updated every scene/test/autoload reference.
- Removed unused `HudRenderer`/`GemVisuals`, the obsolete old-art preparation script, retired `assets/source`, `assets/runtime/gems18`, backgrounds 11-19, unused vibration art, and superseded runtime audio copies.
- Added regressions for 20 alpha-tight gems, all catalog coverage, name-free UI, purple theme tokens, and all-table alpha/physics containment; all nine suites print PASS.
- Added six reviewed GL Compatibility/ANGLE proof captures and `reports/SUPPLIED_ART_PURPLE_UI_CODEBASE_CLEANUP_V1_REPORT.md`.

# 2026-08-23 - Release AAB v1.0.5 (versionCode 7)

- Prepared the signed Play AAB for the simultaneous-reward-physics milestone at versionCode 7 / versionName 1.0.5, strictly newer than the previously recorded 6 / 1.0.4 release.
- Verified the embedded bundle manifest with Bundletool, both ARM architectures, release JAR signature, changed compiled scripts, and exclusion of tests/reports. No gameplay behavior changed from the V6 delivery.

# 2026-08-23 - Simultaneous reward reveal and immediate physics v6

- Synchronized every generated reward gem with its confirmed result's reveal frame and scale timeline; multi-gem siblings are created together with identical pop phase.
- Removed the 280 ms delayed split, 780 ms activation hold, merge-origin visual offset, extraction tether, elevated travel, and result-release recoil that made one gem appear while another slid in from behind.
- Assigned each reward's existing 135 px/s launch velocity before its first simulation step, so movement, containment, overlap correction, gem contact, and rail contact begin on the first visible frame.
- Retained the 650 ms reward grace only around merge-candidate capture. Physical collision response remains immediate, and ordinary merging resumes when the grace expires.
- Preserved distinct lower-tier sibling selection, the three-piece-per-shot budget, COMBO 2 generation ceiling, 24-piece cap, 260 ms chain spacing, shadows, coin/hero holds, scoring, target progression, audio, and haptics.
- Replaced extraction/activation regressions and proof frames with same-frame reveal, identical sibling-pop, immediate-motion/contact, persistence, and bounded-cascade coverage.
- Exported and audited `majestic-gems-reward-gem-simultaneous-physics-v6.apk`; AAPT, v2 signing, both ARM ABIs, changed compiled scripts, and development-file exclusion pass. No device was connected.

# 2026-08-23 - Reward split readability, grounded shadows, and held target rewards v5

- Replaced the hidden-behind-result reward pop with a visible front-layer split from the confirmed result: 280 ms start, 780 ms extraction/settle, `0.48 -> 1.12 -> 1.00` scale, result recoil, and a short color-matched origin tether.
- Reduced reward release impulse from 165 to 135 px/s, increased chain presentation spacing from 180 to 260 ms, and changed the 650 ms post-release grace to suppress follow-up merge capture with any contacted gem while preserving physical collision response.
- Preserved the three-piece-per-shot budget, COMBO 2 generation ceiling, 24-piece cap, persistent `GemPiece` ownership, ordinary post-grace merging, and all authoritative reward/score/target rules.
- Made multi-gem splits select distinct eligible lower tiers when possible, preventing repeated siblings from reading as copies of the same gem.
- Re-anchored unrevealed target coins to the live result position, fixed target-coin shadows to follow current coin position, extended every non-final target group hold from 260 ms to 1.20 s, and extended the final pile hold from 380 ms to 1.00 s.
- Extended the final-target center hold from 420 ms to 1.05 s and the caption lifetime from 620 ms to 1.30 s.
- Increased gem shadow opacity from 0.34 to 0.50 and moved the supplied shadow below each tier's visible silhouette; coin shadow opacity is now 0.46. Shadows remain presentation-only.
- Expanded the reward regression and real-scene ANGLE capture to cover causal split travel, distinct output tiers, collision-before-merge grace, live coin origin, full table holds, visible shadows, and readable final-target checkpoints.

# 2026-08-22 - Reward feedback real gameplay gems v4

- Replaced the fading cosmetic mini-gem reward with persistent lower-tier `GemPiece` rewards from confirmed merges; centralized the 1/1/2/2/3 requested-count ladder, 50/30/20 tier weights, safe fan placement, 200 ms spawn delay, and 180 ms post-activation sibling grace.
- Added a hard three-bonus-per-shot budget, a COMBO 2 reward-generation ceiling, and a 24-piece live-plus-pending board cap, preventing generated pieces from sustaining unattended crowded-board cascades while preserving ordinary merges.
- Added a 340 ms activation gate: each bonus scales `0.28 -> 1.18 -> 1.00` at the merge center, settles outward, and only then releases its stored 165 px/s impulse into normal physics/contact processing.
- Retuned normal merge to a more readable synchronized 120 ms impact and 420 ms total with contact compression, visible snap, and `0.65 -> 1.24 -> 0.93 -> 1.05 -> 1.0`; added distinct COMBO 4+ timing/intensity.
- Added one reusable pooled radial merge shader behind live gem art, with centralized tier intensity and no full-screen pass, bloom, distortion, particles, or camera system.
- Added a readable 180 ms-per-depth chain presentation stagger, immediate target-panel/icon acknowledgement, animated target progress numerals, final-target anticipation/arc/panel recoil, a prominent exact reward amount, and a compact 16-coin 4+4+4+4 jackpot with larger coins and final-four HUD impact.
- Made every non-final target's four-coin group finish landing and hold together on the table for at least 260 ms before the first HUD flight.
- Added subtle presentation-only soft shadows beneath gems and landed reward coins without changing colliders, contact telemetry, or merge eligibility.
- Expanded reward regressions to prove persistence, marker expiry, same-event grace, immediate existing-piece eligibility, and later confirmed merging. Updated superseded cadence assertions without weakening contact-only tests.
- Captured and muted-first reviewed `reports/reward-feedback-real-gems-v4/reward-feedback-real-gems-v4.avi` plus stage screenshots using production controller paths under GL Compatibility/ANGLE.

# 2026-08-22 - Reward feedback v3: HUD coin-counter continuity fix

- Fixed a pre-existing regression exposed by the new final-target coin celebration: the top-left HUD coin counter visibly dropped back to the pre-level balance the instant Level Complete opened, then re-climbed on `COLLECT`. Root cause was `GameplayHudLayer.prepare_completion_reward_display` unconditionally overwriting the already-correct live-delivered display value with the pre-level total.
- The fix is display-layer only: the display value is now clamped forward between the pre-level and final total instead of being forced backward, and `COLLECT`'s reward animation now no-ops when the value has already landed (skipping only the redundant re-animation, never the real rewarded-ad "double coins" climb). No authoritative economy state, exactly-once merge-result guard, or persisted save behavior changed.
- Added `_test_hud_coin_counter_continuity`, which drives the real COLLECT/transition/scene-reload flow through the production controller and asserts the HUD balance never regresses at any of: last-coin arrival, Level Complete open, Level Complete settle, after COLLECT, after the level transition, and after a simulated scene reload. Confirmed the test fails against the prior (buggy) code and passes against the fix. All nine repository suites pass.
- Exported a same-identity debug verification APK (`build/android/majestic-gems-reward-feedback-v3-hud-coin-fix.apk`, versionCode 6 / versionName 1.0.4, no version bump since no AAB was generated) to confirm the fix packages correctly; recorded in `BUILD_MANIFEST.md`. No Android device was connected. This work is uncommitted and untagged pending review.

# 2026-08-22 - Reward feedback v3: merge juice, combo hierarchy, and final-target hero moment

- Rebuilt successful-action feedback around one authoritative hierarchy — normal collision < normal merge < combo merge < final target achievement < level complete — expressed as data in `GameConfig.merge_timeline()`. Gem progression, merge eligibility, contact capture, physics constants, board geometry, HUD layout, target rules, level rules, theme, and art direction are unchanged.
- Normal merge is now a 420 ms timeline: 40 ms hit-stop on the confirmed result only, 40-110 ms source pull to 0.82, reveal at 110 ms with the chime, 0.65 -> 1.18 -> 0.96 -> 1.02 -> 1.0, one subtle shockwave ring at 150 ms, and three cosmetic mini gems from 140-430 ms. No camera shake, lightning, screen flash, or shader was added.
- Added a chain-merge combo system driven by the existing resolver `depth`, so it counts only chained merges from the same shot and resets when that chain resolves. COMBO 1/2/3+ escalate ring strength, result overshoot, mini-gem count, and SFX pitch, with `COMBO 4 — AMAZING!` / `COMBO n — PERFECT!` reserved for depth 4+.
- The final target now gets a staged hero moment instead of going straight to the panel: 180 ms Phase A, 250 ms travel to the visual centre of the playable board, a deliberate 500 ms hero hold with a soft radial glow and a `TARGET COMPLETE!` caption, then a 350 ms curved flight into the target HUD panel. The target count changes only when the gem arrives.
- Level completion now spawns 20 visible reward coins across a controlled central band of the board in four waves, holds them on the table for 380 ms, then collects them in staggered waves of three along curved paths. The HUD balance interpolates upward as coins arrive and the counter is punched once per wave, not once per coin. The stored economy value remains mathematically exact.
- Level Complete now waits for the reward animation to finish, dims 70 ms ahead of the panel, and animates the existing modal 0.86 -> 1.04 -> 1.0 with a title -> target gem -> reward hierarchy. Its art, layout, copy, and actions are unchanged. Total celebration settles in about 3.35 s.
- Introduced an explicit `final_celebration_active` state that locks pointer input, launcher spawning, and the Level Complete modal while the sequence runs. All reward exactly-once guards were reused, not replaced; the final target no longer also fires the compact per-target coin group.
- All new visuals are cosmetic-only drawn records with no nodes, no simulation bodies, and no contact or merge participation; every one is cleared on restart and failure. Nine repository regression suites pass, including the new `REWARD_FEEDBACK_V3_TESTS`.

# 2026-08-18 - Restore original procedural gem and rail collision sounds

- Replaced the still-newer supplied MP3 gem/rail collision sounds with the historically original cached procedural crystal cues: gem contact is 1240 Hz at 0.46 gain and rail contact is 760 Hz at 0.32 gain.
- Restored their original 75/110 ms event cooldowns and fixed-pitch behavior. Collision routing, exact merge-pair suppression, voice limits, buses, haptics, physics, and merge rules remain unchanged.
- Advanced Android release identity to versionCode 6 / versionName 1.0.4 for the requested AAB and APK export.

# 2026-08-18 - Restore original procedural gem and rail collision sounds

- Replaced the still-newer supplied MP3 gem/rail collision sounds with the historically original cached procedural crystal cues: gem contact is 1240 Hz at 0.46 gain and rail contact is 760 Hz at 0.32 gain.
- Restored their original 75/110 ms event cooldowns and fixed-pitch behavior. Collision routing, exact merge-pair suppression, voice limits, buses, haptics, physics, and merge rules remain unchanged.
- Advanced Android release identity to versionCode 6 / versionName 1.0.4 for the requested AAB and APK export.

# 2026-08-18 - Original collision sound, fast merge/push, and visible-touch merge repair

- Restored gem-to-gem and gem-to-rail contacts to their original supplied streams, gains (`0.34` / `0.39`), thresholds (`170` / `220 px/s`), cooldowns, pitch ranges, and impact gain scaling.
- Restored the approved fast 270 ms merge and 60 ms source-pull/push animation. The current 700 ms target collection, Next-target transition, and deliberately slower four-coin cadence remain unchanged.
- Expanded only the centralized calibrated visible-touch contact band from 0.20 to 2.0 design pixels, so equal gems that visibly touch will resolve as a contact merge. Collider radii, rails, solver, target/reward rules, and momentum settings are unchanged.

# 2026-08-18 - Original collision sound, fast merge/push, and visible-touch merge repair

- Restored gem-to-gem and gem-to-rail contacts to their original supplied streams, gains (`0.34` / `0.39`), thresholds (`170` / `220 px/s`), cooldowns, pitch ranges, and impact gain scaling.
- Restored the approved fast 270 ms merge and 60 ms source-pull/push animation. The current 700 ms target collection, Next-target transition, and deliberately slower four-coin cadence remain unchanged.
- Expanded only the centralized calibrated visible-touch contact band from 0.20 to 2.0 design pixels, so equal gems that visibly touch will resolve as a contact merge. Collider radii, rails, solver, target/reward rules, and momentum settings are unchanged.

# 2026-08-18 - Reward, coin, and merge cadence restoration release

- Restored the readable post-checkmark-removal presentation from `acb28a5`: 540 ms merge with reveal/chime at 200 ms, 700 ms target collection, 220 ms target pulse, four coins over about 980 ms, and a 420 ms result hold.
- Kept presentation overlapping and non-authoritative: target travel starts 300 ms into merge settle, rewards remain exactly once, controller target truth remains immediate, and launcher readiness does not wait on visual completion.
- Preserved the current 110 ms collision response, 160 ms Next transition, midpoint gem/rail audio, Android Activity-owned Exit, state-aware Back, centered Privacy link, Home flow, gameplay rules, reward values, ads/UMP, saves, gems, and UI design.
- Advanced Android permanently to version code 5 / version name 1.0.3 and exported both the requested signed release AAB and matching tester APK. Google Play's current uploaded version code was confirmed by the user as 3; local code 4 had already been used by tester APKs, so it was not reused. Bundletool, manifest, signature, dual-ABI, Tween Composer, production AdMob, and exclusion audits pass.

# 2026-08-18 - Tester animation revert, collision midpoint, and Android exit correction

- Restored every animation value changed by the rejected slow pass to the `5528ff6` tester-approved cadence: 270 ms merge, 320 ms target travel, prior pop/effect/coin/Next/result timings, and immediate merge audio.
- Retained immediate authoritative target progression, arrival-timed HUD state, exactly-once presentation queueing, and launcher independence so the faster presentation cannot misclassify rapid merges or duplicate rewards.
- Replaced the over-softened gem/rail derivatives with brighter midpoint v2 files and midpoint gains, impact thresholds, cooldowns, pitch ranges, and impact-volume scaling.
- Replaced synchronous Android `SceneTree.quit()` from the Exit button with callback invalidation plus UI-thread `Activity.finishAndRemoveTask()` through Godot's built-in AndroidRuntime; desktop retains a deferred quit fallback.
- Kept the exit confirmation, state-aware Back behavior, Privacy alignment, Home startup, game rules, rewards, gems, UI design, ads/UMP, saves, package, and release version unchanged.
- Exported and audited `build/android/majestic-gems-animation-revert-audio-midpoint-exit-fix.apk`; package/version/SDK, v2 signature, both ARM ABIs, midpoint audio imports, production AdMob App ID, and exclusions pass. No AAB was generated and physical Exit/listening acceptance remains pending.

# 2026-08-18 - Animation, audio, Back, and Privacy production polish

- Re-timed presentation-only feedback from a rushed 270 ms merge/320 ms target path to a readable 540 ms merge, 700 ms target journey, 220 ms target pulse, and about 980 ms four-coin sequence while keeping gameplay/launcher state authoritative and overlapping. Controller target progress commits at the confirmed merge while its separate HUD snapshot advances on visual arrival, preventing rapid follow-up merges from using stale targets.
- Extended final-target presentation to about 1.66 seconds and preserved the responsive 220 ms Next transition; reward lookup values, score/economy, merge/target logic, physics, gem assets, and table geometry are unchanged.
- Added filtered runtime derivatives for gem and rail contact, raised impact thresholds, added global/per-contact cooldown protection, aligned merge audio to the reveal, and separated target arrival, target completion, coin arrivals, and level-complete identities into a clear priority hierarchy.
- Newly implemented proper Android Back ownership with `application/config/quit_on_go_back=false`, `NOTIFICATION_WM_GO_BACK_REQUEST`, shared Escape/debug handling, duplicate-event suppression, overlay-first dismissal, result-modal locking, gameplay Pause behavior, and a Home Cancel/Exit confirmation.
- Fixed the visibly offset Home Privacy Policy text by removing its forced 180-pixel text box and centering its intrinsic control; real 576x1312 and 720x1600 Godot proof frames plus four-aspect geometry coverage pass.
- Added focused animation/audio/Back/privacy regression coverage and updated existing timing, game-flow, sound/privacy, and responsive-layout sentinels. AdMob, UMP, saves, package name, and production signing are unchanged.
- Exported and audited `build/android/majestic-gems-animation-audio-back-privacy-polish-test.apk`; package/version/SDK, v2 debug signature, both ARM ABIs, production AdMob App ID, new audio imports, and export exclusions pass. No AAB was generated and no device testing is claimed.

# 2026-08-16 - Supplied sound integration and Home privacy link v1

- Integrated eight supplied contact, merge, target, success, and UI SFX through the existing reusable `AudioFeedbackService`; preserved the approved music, launch/push, and coin identities.
- Reduced music gain from `0.10` to `0.035`, added dedicated Music/SFX buses and an SFX limiter, expanded the bounded pool to five priority-aware voices, and kept all one-shots initialization-cached.
- Added 65/90 ms gem/rail cooldowns, subtle collision-only pitch ranges, and exact merge-pair collision suppression so normal and target merges each play one exclusive merge cue.
- Routed target sparkle at collection arrival, objective reward only after target quantity completion, and level success only after accepted victory-overlay presentation; removed the existing lose-sound route.
- Routed one quiet supplied tap per standard UI interaction without stacking controller and layer cues.
- Removed Privacy Policy from Home/Pause Settings and added one bottom-centered safe-area-aware Home link using the unchanged published URL/AdManager path. Conditional UMP Privacy Options remain in Settings.
- Added focused stream/bus/priority/cooldown/timing/layout tests and updated AdMob privacy expectations. No gameplay physics, merge, target, reward, timing, ad, or package behavior changed.
- Exported and audited `build/android/majestic-gems-sound-pass-test.apk`; v2 signature, package/SDK, dual ARM ABIs, eight supplied runtime imports, existing music/coin resources, compiled bus layout, and export exclusions pass. No AAB was created and no device installation is claimed.

# 2026-08-16 - Supplied sound integration and Home privacy link v1

- Integrated eight supplied contact, merge, target, success, and UI SFX through the existing reusable `AudioFeedbackService`; preserved the approved music, launch/push, and coin identities.
- Reduced music gain from `0.10` to `0.035`, added dedicated Music/SFX buses and an SFX limiter, expanded the bounded pool to five priority-aware voices, and kept all one-shots initialization-cached.
- Added 65/90 ms gem/rail cooldowns, subtle collision-only pitch ranges, and exact merge-pair collision suppression so normal and target merges each play one exclusive merge cue.
- Routed target sparkle at collection arrival, objective reward only after target quantity completion, and level success only after accepted victory-overlay presentation; removed the existing lose-sound route.
- Routed one quiet supplied tap per standard UI interaction without stacking controller and layer cues.
- Removed Privacy Policy from Home/Pause Settings and added one bottom-centered safe-area-aware Home link using the unchanged published URL/AdManager path. Conditional UMP Privacy Options remain in Settings.
- Added focused stream/bus/priority/cooldown/timing/layout tests and updated AdMob privacy expectations. No gameplay physics, merge, target, reward, timing, ad, or package behavior changed.

# 2026-08-16 - Regenerated scene art integration v1

- Replaced the previous 19 background sources and 10 table sources with the user's regenerated 941x1672 RGB backgrounds and 1343x1171 RGBA tables, using canonical source filenames.
- Generated 720x1280 background and shared-canvas 920x810 alpha-table runtime WebPs; removed the superseded single-table `assets/runtime/table/new_table_v1.png`.
- Re-enabled deterministic per-level table selection alongside the existing deterministic background selection, preserving retry identity.
- Kept the restored fixed table geometry and unstretched `0.7391304 x 0.9691358` transform; no physics, gem, merge, input, target, reward, queue, or HUD behavior changed.
- Added measured all-ten-table rail/danger-line calibration regression and transparent-corner/runtime-dimension coverage.
- Reviewed 20 real Godot table proofs across 720x1280 and 720x1600; all visible rails contain the fixed legal playfield and danger line.
- Reduced active runtime scene-art files from 3,068,162 to 2,145,764 bytes (30.06%).
- Exported and audited `build/android/majestic-gems-regenerated-scene-art-test.apk` after the requested Godot-first source review; package, v2 debug signature, both ARM ABIs, all 19/10 scene imports, and exclusion checks pass. No AAB was created and no device installation is claimed.

# 2026-08-16 - Original table restoration v1

- Stopped and discarded the rejected all-table scale recalibration and its generated proof captures.
- Restored `assets/runtime/table/new_table_v1.png` as the single gameplay table at the original `0.7391304 x 0.9691358` base transform.
- Restored the pre-random-table shared Y landmarks: outer `400..1185`, board `440..1110`, danger `960`, launcher `1042`, and texture center `792.5`.
- Kept the 19 optimized backgrounds active and retained the ten replacement table assets as inactive inputs for the user's upcoming rail regeneration.
- Kept the current HUD hierarchy/legibility changes and all non-positional gameplay tuning unchanged.
- Created no APK or AAB; final Godot visual acceptance is intentionally deferred to the user.

# 2026-08-16 - Table-art containment and HUD legibility v1

- Added a 1.15x horizontal presentation coverage factor to every random table, widening the effective base art scale from `0.7391304` to `0.85` while preserving the existing vertical transform.
- Froze the complete pre-change physical geometry in regression coverage: outer bounds, board bounds, slanted rails, danger line, launcher, radii, and all simulation behavior remain unchanged.
- Top-aligned Coins with Next, enlarged Next by another 10%, kept Settings below it, and strengthened gameplay heading/value typography.
- Added responsive HUD/physics-freeze assertions plus six 720x1280/720x1600 ANGLE proofs with legal rail-edge gems on the three narrowest representative table styles.
- Created no APK or AAB, per the requested Godot-first review workflow.

# 2026-08-16 - Responsive scene variety, layout breathing room, and asset optimization v1

- Integrated 19 supplied portrait backgrounds and 10 supplied alpha-table variants with deterministic per-level selection and stable retry identity.
- Normalized runtime derivatives to 720x1280 background WebP and a shared 920x810 table WebP canvas, reducing the supplied 57.40 MiB source set to a 2.93 MiB runtime set while preserving all originals under `assets/source/`.
- Added tracked 0.85/0.92 lossy Godot import profiles, reducing the imported scene-texture payload from 19.83 MiB to 3.12 MiB; refreshed ANGLE renders show no accepted visible degradation.
- Moved the complete shared table model down 20 design pixels, enlarged Coins and Next by 12.5%, and stacked Settings below the right-side Next card.
- Added catalog bounds/dimensions/wrapping/coverage/retry regressions, updated eight responsive-layout viewports, and reviewed six real Compatibility/ANGLE captures across three scene pairings at 720x1280 and 720x1600.
- Removed 66 dependency-audited legacy asset files (27.83 MiB) and excluded all preserved source originals from Android export. Gameplay, progression, physics, rewards, audio/haptics, ads, and dual-ARM compatibility are unchanged.
- Exported and audited `majestic-gems-responsive-scene-variety-test.apk` at 81,986,750 bytes: 17.57% smaller than the diagnostic default-import build and 3.80% smaller than the prior hierarchy APK despite the 19/10 scene catalogs.

# 2026-08-16 - Table / Target / merge-path hierarchy correction v1

- Separated the top utilities from Target so Coins, Next, Settings, and Target cannot overlap.
- Rebuilt the objective region as a responsive Target -> merge path -> table stack and made it refresh from the controller-configured table geometry on every authoritative HUD snapshot.
- Moved the complete eight-gem path out of the bottom navigation edge, enlarged it from 72 to 88 design pixels high, enlarged gem slots from 56 to 64, strengthened connectors, and replaced the faint tray with a bright rimmed/shadowed glass surface.
- Enlarged Target from 304x118 to 400x120 and strengthened its header/art spacing.
- Shifted the shared table transform down 40 design pixels, including table art, rails, board bounds, launcher, danger line, drag clamp, spawn limits, and containment geometry.
- Added multi-viewport hierarchy/collision assertions and deterministic 720x1280 plus 720x1600 ANGLE visual evidence.
- Preserved all gem radii, collision and merge rules, movement tuning, target/score authority, queue rules, timing, audio/haptics, and result flow.
- Exported and audited `build/android/majestic-gems-target-path-hierarchy-test.apk`; no AAB was generated and the existing release preset was restored.

# 2026-08-14 — Android device compatibility v2

- Audited the actual v1 AAB, Godot 4.6.3 Android template, active Poing AdMob/UMP dependency graph, all bundled Poing AARs, merged manifest, and generated v2 AAB before enabling 32-bit ARM.
- Enabled `armeabi-v7a` alongside `arm64-v8a`; kept `x86` and `x86_64` disabled. The release contains matching Godot engine and C++ runtime libraries for both ARM ABIs and no other native `.so` dependency.
- Incremented Android versionCode from `1` to `2`, normalized versionName from `Majestic Gems` to `1.0.1`, and moved the output to the non-overwriting `majestic-gems-closed-test-v2.aab` filename.
- Verified the two Play-inferred required features as `android.hardware.faketouch` and `android.hardware.screen.portrait`; both are necessary for the current touch/portrait game. Preserved the necessary GLES 3.0, min SDK 24, production AdMob, authoritative UMP, privacy, signing, and failure-safety configuration.
- No gameplay, UI, asset, audio, economy, ad cadence, rewarded behavior, or consent behavior changed.

# 2026-08-11 — Post-AdMob reward flow, package migration, and APK size fix

- Split Level Complete into unresolved reward choices and a resolved `NEXT LEVEL` state; Collect and earned Double Coins now update the visible total while the popup stays open.
- Removed automatic progression after Collect and rewarded-ad dismissal. Next Level now owns the every-two-level interstitial transition and opens the existing Level Intro/Play gate.
- Added exactly-once guards for Collect, rewarded callbacks, duplicate taps, stale/resumed callbacks, and safe early-close retry.
- Changed the Android application ID to `com.owais.majestygems` and renamed the output APK.
- Restored compressed arm64 native packaging and excluded AdMob sample/editor/C#/iOS/mock/doc/media payloads. Disabled the plugin's sample-translation registration so optional ICU data is no longer exported.
- Reduced the debug APK from 108,146,729 to 53,363,440 bytes without changing game asset quality or removing AdMob.
- Gameplay, physics, collisions, gem movement, merge rules, targets, difficulty, table geometry, and AdMob load/reload behavior are unchanged.

# 2026-08-11 — Majestic Gems branding, mask-safe icon, push-line dragging, and APK asset cleanup

- Replaced Home/fallback boot branding with the complete supplied transparent `MAJESTIC GEMS` logo.
- Preserved the supplied square icon and generated non-destructive 192 px legacy plus 432 px adaptive derivatives with 68% centered artwork so Android masking does not crop or zoom the composition.
- Wired Android legacy, adaptive foreground/background, system splash, and project icon paths to the new derivatives.
- Made the visible ready-state push line draggable. It shares the existing launcher drag state and authoritative rail clamp; release still calls the normal launcher path.
- Centralized the guide hit width (`28 px` per side), guide hit geometry, and launcher X clamp in `GameConfig` without changing table geometry or gameplay tuning.
- Removed obsolete `AssetCatalog` preloads for retired UI atlases and five-gem fallback textures; invalid catalog fallback now uses cached tier 1 from the active 18-gem map.
- Expanded Android export exclusions for inactive source/reference/runtime assets and added a focused branding/push-line regression.
- No launch velocity, damping, collision, merge eligibility, target progression, scoring, danger timing, result flow, audio routing, or saved progression changed.

# 2026-08-09 — Splash cleanup + @icons integration + static level preview target

- Removed the Tween Composer breathing loop from the pre-level target gem. The target gem remains visible but static so the START GAME preview reads cleanly.
- Integrated the newly supplied `addons/at-icons` library into player-facing controls. Runtime-safe recolored derivatives now provide Settings, Play, Done, Back, Music, Sound, Vibration, Restart, Home, Next Level, and Retry iconography without changing button behavior.
- Replaced the Home and gameplay Settings atlas art with the @icons cog while keeping the existing glass cards, touch targets, and signals.
- Added @icons to `editor_plugins` so its picker is available in the Godot editor.
- Reworked startup presentation to avoid the previous double-logo sequence on Android: Android export now uses a dedicated padded system-splash logo and keeps the system splash visible until the main loop, while Godot's separate Android boot splash is disabled.
- Desktop/editor fallback boot splash now uses the transparent Crystal Magic logo instead of the square app-icon artwork.
- The adaptive/system splash background fallback is the tropical-teal `crystal_magic_adaptive_bg_v1.png`; launcher main icon remains the existing `crystal_magic_app_icon_v1.png`; launcher branding was not redesigned.
- Existing fast-feel gameplay timings, physics, merge eligibility, target rules, table geometry, HUD placement, scoring, audio, and persistence were not changed in this pass.

# 2026-08-09 — Home Settings Alignment + Fast Feel Motion v1

- Fixed the Home settings control stretching into a full-height glass rail by making the 94×94 settings frame shrink to the top/right inside its full-screen safe-area row.
- Added `GlobalTweens.gd` as an autoload and wired consistent press feedback to Home, Level Intro, Pause, and settings toggle buttons; completed-target HUD feedback also gets a short cyan energy pulse.
- Integrated Tween Composer for reusable ambient scale loops on the Crystal Magic Home logo and Level Intro target gem.
- Added a faster reference-feel tuning pass in `GameConfig`: launch 1160→1200, launcher handoff 0.30→0.22, merge presentation 0.50→0.36, target collection 0.62→0.40, target swap delay 0.78→0.26, coin flight 1.58→0.92, plus shorter reward/chain/overlay timing while preserving contact-only merge rules and authoritative physics geometry.
- No third-party icon-library files were present in the supplied ZIP, so existing Crystal Magic/HUD icon assets remain in use rather than inventing replacements.
- No APK or on-device validation is claimed from this editing environment.

# Changelog

# Light Glass Gameplay HUD v1 — 2026-08-08

- Reworked gameplay HUD composition to keep Coins top-left, Next top-right, Level below Coins, and Settings below Next.
- Removed the `MERGE PATH` heading and moved the eight-gem progression strip directly above the Target card.
- Moved Target to a responsive table-adjacent anchor derived from `GameConfig.board_top()`; table/background/gameplay geometry are unchanged.
- Replaced purple gameplay HUD surfaces with light cyan/blue StyleBoxFancy glass surfaces derived from the addon demo Panel8 language: squircle corners, translucent gradients, layered cyan rim/highlight, and soft blue shadows.
- Applied the same glass visual language to primary/secondary buttons and the Pause modal.
- True framebuffer/backdrop blur was intentionally not added: StyleBoxFancy does not blur underlying pixels, and a screen-sampling blur shader would add GL Compatibility/mobile risk. The implementation uses translucent layered gradients and highlights as a performant frosted-glass approximation.
- No gameplay, physics, merge, target, score, audio, table, background, or gem behavior was changed.


## 2026-08-08 - Transparent Purple Glass HUD v1

- Retinted the professional header, path tray, Coins, Target, and Next surfaces into visibly translucent purple glass so tropical scenery subtly shows through.
- Switched coin and target values to white with restrained deep-purple outlines and changed path connectors to lavender for reliable contrast on tinted glass.
- Added alpha/hue regressions and refreshed all responsive, notch, Pause, transition, reward, crowded-board, and danger-state evidence.
- Preserved HUD hierarchy, all eight catalog gems, hidden gem names/tooltips, collection destinations, motion, gameplay, table, physics, progression, balance, audio/haptics, and results.

## 2026-08-08 - Professional Glass HUD v1

- Replaced the flat/detached purple HUD with one cohesive premium game composition matching the supplied direction: beveled translucent header, glass merge tray, framed Level/Settings, and aligned Coins/Target/Next cards.
- Moved Target from the isolated table-edge anchor into the center of the objective row while preserving its authoritative destination, sequence, numeric progress, and transition behavior.
- Added reusable translucent glass, purple rim, gold accent, inset tray, polished card-header, progress, shadow, and button treatments through cached native Godot styles.
- Preserved all eight supplied gem silhouettes and kept gem names/tooltips hidden to prevent portrait overflow.
- Added six-resolution, notch, pause, crowded-board, target-transition, reward-flight, and danger-state evidence plus hierarchy/glass/baseline regressions.
- Changed no background, table/board geometry, gem art, physics, launcher, collision, merge, target rule, progression, balance, reward, audio/haptic, danger, or result behavior.

## 2026-08-08 - Purple Production HUD v1

- Rebuilt the gameplay HUD with native Godot containers and purple `StyleBoxFlat` surfaces: a dominant MERGE PATH header, compact Coins/Next utilities, and a separate table-adjacent Target card.
- Kept Level and the existing Settings artwork compact in the header while preserving all eight generated path gems.
- Preserved artwork-only target identity and numeric progress; no gem names or gem-name tooltips were restored.
- Added bounded settings press, target progress/pulse, Next refresh, and coin response tweens without adding per-frame allocations or gameplay authority.
- Added six-resolution, notch, pause, crowded-board, target-transition, reward-flight, and danger-state evidence plus responsive layout regressions.
- Left backgrounds, board/table geometry, gem art, physics, launcher, collisions, merges, target generation, progression, balance, rewards, and result qualification unchanged.

## 2026-08-08 - Compact target HUD copy

- Removed gem names from the gameplay HUD, including the compact target label and hover tooltips, so artwork and numeric progress remain readable at narrow portrait widths.
- Preserved authoritative target/path/Next gem textures, target sequence, progress text, and all gameplay behavior.
- Updated the production HUD regression checks to enforce artwork-only gem identity presentation.

## 2026-08-05 - Production Gameplay UI Finalization V2

- Rebuilt the gameplay HUD as one safe-area-aware shell with an integrated Level/MERGE PATH/Settings header and a balanced Coins/Target/Next objective row.
- Added responsive exact-value coin presentation, a prominent target icon/name/quantity/progress treatment, and synchronized target copy/art during handoff and Restart.
- Polished Pause hierarchy, setting rows, dimming, touch targets, and entrance/exit presentation without changing pause/restart behavior.
- Restored a subtle ready-state aim guide and added proximity-only danger-line emphasis using rendering-only reads of authoritative geometry/state.
- Normalized presentation-only gem shadows for crowded-board separation; physics radii, perspective, motion, rails, merge/reward timing, audio/haptics, targets, launcher generation, and win/fail sequencing are unchanged.
- Added six-resolution plus notch/state evidence, a deterministic walkthrough driver, responsive regressions, and final performance validation.

## 2026-08-05 - Production Foundation v1

- Added persistent, independent Music, Sound FX, and Vibration settings to Pause.
- Split continuous music from bounded event-sound enablement without changing confirmed-event routing.
- Unified live table-gem silhouettes with merge, collection, TARGET, NEXT, and path art through aspect-preserved scaling.
- Rebalanced progression to one L5 target on Level 1, L5/L6 on Level 2, then deterministic two/three-target L5-L8 levels.
- Added five capped launcher bands that become gradually less assisted while retaining L3/L4 and unlimited reachability.
- Replaced the generic project name, Godot icon, and default splash with GEM RUSH branding.

## 2026-08-05 - Production UI motion + Restart restoration v1

- Fixed Pause Restart leaving the gameplay HUD hidden after a Home/Continue route.
- Removed “8 random gems,” “new path every level,” “current journey,” and other implementation-facing Home copy.
- Removed the large Home status card; Level and Coins now use floating display typography with the production coin icon.
- Added restrained looping Home logo/primary-action motion after entrance.
- Reworked Pause into a shorter gem-accented modal with primary Resume and a compact Restart/Home row.

## 2026-08-05 - Asset-matched Home + transparent logo v1

- Replaced the opaque framed Home logo with an alpha-matted GEM RUSH runtime derivative while preserving the uploaded source.
- Rebuilt Home as a full-screen tropical composition using supplied background artwork, a floating logo, a cream/gold journey card, and a larger glossy coral primary action.
- Removed the generic dark/card presentation from Home without changing gameplay or infinite progression.

## Branded Production Screen Flow v1 - 2026-08-05

- Preserved the supplied 1024 x 1024 GEM RUSH logo and created a non-destructive cropped 720 x 563 runtime derivative for mobile UI.
- Rebuilt Home as a standalone safe-area-aware hero screen with the logo, saved level/coins, responsive Play/Continue action, tagline, and infinite-level promise; gameplay HUD elements are hidden while Home is active.
- Upgraded Pause to the shared hero surface and clear Resume/Restart/Home hierarchy.
- Upgraded success with completed target art, total coins, explicit Level N -> Level N+1 copy, Next Level, and Home; upgraded failure with danger explanation, deterministic same-chain Retry copy, Retry, and Home.
- Corrected result-to-Home routing so success prepares the next generated level and failure resets the same seeded level before Continue.
- Added narrow/standard/tall Home bounds, supplied-logo mapping, forward/retry copy, and responsive action regressions plus four reviewed 720 x 1600 ANGLE captures.

## Infinite Randomized Eight-Gem Levels v1 - 2026-08-05

- Replaced the single hard-coded level definition with deterministic infinite generated levels.
- Each level selects eight unique identities from all 18 supplied gems, shuffles their local L1-L8 merge order, updates every board/HUD/target/result texture consistently, and shows the full chain in the existing eight-slot MERGE PATH.
- Added seeded local L1-L4 launcher sequences, three ascending local L5-L8 targets, five randomized runtime backgrounds, identical Retry regeneration, saved level/seed/coin continuation, and direct NEXT LEVEL advancement.
- Added mobile Home/Continue plus Home actions on Pause and result screens; removed the completed-level replay route in favor of forward-only progression.
- Added 200-level determinism, uniqueness, reachability, catalog coverage, background coverage, and variety tests while preserving all six existing gameplay/UI/profile suites.

## New Background Music v1 - 2026-08-04

- Preserved the newly supplied MP3 and created a full-duration, metadata-stripped Ogg runtime derivative without gain, EQ, pitch, or trimming changes.
- Replaced only the continuously looping background stream; movement still cannot trigger or restart it.
- Reduced music gain from `0.14` to `0.10` to preserve the established mix priority for target coins and gem/merge cues.
- Kept the supplied target coin cue separate and target-only; no animation, physics, reward, target, launcher, or progression behavior changed.
- Updated routing/gain regressions and passed all six gameplay, UI, contact, lifecycle, catalog, and motion-profile suites.

## Reference Scale Contrast v1 - 2026-08-04

- Re-reviewed reference frames around ordinary clusters and target completions and replaced the too-subtle two-pixel ladder with the L1-L8 `30/33/36/39/42/45/48/51 px` visual/physics ladder (`1.70x` endpoint contrast).
- Confirmed that target status does not need a larger live collider: the reference emphasis occurs during the result/collection presentation.
- Increased only the removed-body target collection proxy pop from `1.10x` to `1.18x`; the normal merge result still uses its existing `1.20x` rigid pop.
- Fixed the collection proxy to inherit the live gem's exact independent X/Y texture mapping before the uniform pop, eliminating the prior apparent shrink and silhouette change on target travel.
- Preserved the 80 px TARGET HUD slot and all merge, coin, handoff, audio, reward, launcher, danger, physics-tuning, and level-flow behavior.
- Added exact size-ratio, proxy mapping, target-pop, collision/contact, containment, flow, UI, performance, and rendered-proof coverage.

## Merge Animation Revert + L1-L8 Size Calibration v1 - 2026-08-04

- Removed the rejected irregular merge color splash and restored the immediately previous rigid `0.50 s` pull/pop/settle plus bounded flash, ring, and eight-ray impact.
- Preserved all v4 coin count/path/layering, target confirmation/handoff, supplied music/coin sound routing, push-guide removal, reward integers, and L5 -> L7 -> L8 progression.
- Replaced the non-monotonic current-level radii with the centralized moderate L1-L8 ladder `36/38/40/42/44/46/48/50 px`; render diameter, perspective scale, physical contact, merge eligibility, and rail containment all consume those same values.
- Kept L9-L18 at their prior `42 px` fallback because they are outside the current Level 1 scope.
- Added regressions for exact monotonic radii, bounded endpoints, sprite/collider diameter linkage, upgraded-result radius assignment, restored impact records, containment, contact-audio timing, and the complete Level 1/result flow.

## Reference Animation + Supplied Audio Polish v4

- Re-reviewed the first reference target sequence frame by frame. Replaced the slow generic ring/ray impact with one short result-color splash and shortened the rigid merge pop to `0.34 s`; no collision or gem presentation path can squash, stretch, rotate, or kick the artwork.
- Preserved the target-only reward rule and exactly four coins, enlarged them from `14.5` to `17 px`, shortened their initial pop, and shaped one higher ordered foreground flight into the COINS counter.
- Replaced the directional old/new target travel with the reference sequence: a held large green check over the completed target, an in-place card fade, a short empty beat, and a centered next-target fade-in.
- Preserved the two user-supplied audio originals under `assets/sound/`. Added separate optimized runtime Ogg derivatives; one dedicated player loops clean background music continuously at `0.14` gain, while one unpitched coin cue fires only on target qualification. Existing gem/contact/merge cues remain separate and dominant.
- Added toggle/readiness, target-only coin-audio, rigid-silhouette, splash, exact-four-coin, centered-target-handoff, timing, layering, and unchanged-physics regressions plus six reviewed ANGLE frames.
- Tightened the Android export filter to exclude `build/*`; a size audit caught and rejected an intermediate APK that had packaged temporary reference-analysis frames.


## Reference Target Reward Correction v3

- Re-reviewed the full supplied reference at one-second cadence and each reward interval at `0.2 s` cadence. Confirmed that visible coins occur only with the three target events near `14.6 s`, `46.6 s`, and `58.0 s`; corrected the previous misclassification of the second event as an ordinary merge reward.
- Split `GameplayEffectsLayer.begin_merge_feedback()` from `begin_target_coin_reward()`. Ordinary merges now create only their bounded impact and gem/chain feedback; active-target results alone award currency, queue the visible counter, and create four ordered foreground coins.
- Retired the mixed `reference_music_loop.ogg` from production routing because its source window contains embedded reward audio. The derivative remains preserved for audit, but `AudioFeedbackService` owns no ambience player until separate clean source files are supplied. The existing 15 cached gem one-shots remain active.
- Removed the vertical push/aim guide, its renderer, and its two centralized tuning constants. The horizontal danger line remains unchanged.
- Added target-only reward, ordinary-merge zero-coin, inactive-mixed-audio, push-guide absence, exactly-once, reset, win-wait, and bounded-effect regression coverage plus a dedicated 720 x 1600 capture tool/report.

## Reference Audio + Reward Layering v2

- Reclassified the previously event-mapped reference-video audio as continuous background music. Added a seamless `1.80 s`, mono 48 kHz runtime loop from the supplied reference and restored `AudioFeedbackService` as the production boundary; movement never controls the music player.
- Restored the earlier cached launch/contact/tiered-merge/chain/target/win/fail/button gem tones, while keeping separate coin burst/flight/arrival sounds disabled. Typed contact thresholds, cooldowns, sound toggle, three-player cap, and haptics remain service-owned.
- Moved `GameplayEffectsLayer` into the layer-40 HUD `RewardForegroundHost`. Four slightly larger coins and the collection proxy now travel above live gems and HUD cards, with confirmation, Pause, and Results kept above them.
- Removed the duplicate world-space target arrival burst. Added reusable outgoing/incoming target ghosts: completed L5/L7 fades toward the top-left, and L7/L8 fades/slides in from the right without rebuilding UI nodes.
- Centralized the coral danger-line color and reused it for the ready-state push guide. No physics, progression, currency, launcher, collision, danger, or result behavior changed.
- Updated focused audio/contact/reward/layering regressions, asset provenance, architecture/knowledge documentation, and milestone reporting.

## Reference Feedback Match v1

- Removed directional contact squash, cross-stretch, kick, merge lift, tilt, and anisotropic scale. Collision telemetry now routes thresholded audio only, while merge results use a centered uniform `0.62 -> 1.20 -> 1.0` pop and preserve their exact silhouette.
- Corrected the reward from 10/14 animated coins to exactly four for every merge. The four coins use a tight `44-48 px` cluster, ordered departures, one compact curved route, stable circular artwork, a `12.5 px` draw radius, and a restrained counter pulse.
- Replaced the ornate supplied coin derivative with a new original simple gold/star-gem token generated for this project. The generated source is preserved under `assets/generated/`; its keyed, cropped 256 px runtime derivative is shared by the HUD and reward effect.
- Strengthened target arrival without adding coins: collection lasts `0.84 s`, remains opaque through 78%, and ends with a `0.58 s` gold ring, large green check, eight sparks, and the existing panel pulse. `TargetRewardOverlay` renders the confirmation above the HUD card so the target artwork cannot hide it.
- Removed the production procedural music/one-shot service from the controller. Production now preloads four Ogg clips derived from exact windows in the user-supplied reference recording; there is no ambience loop and no separate coin burst/flight/arrival sound layering.
- Preserved L5 -> L7 -> L8 progression and all simulation, geometry, currency, launcher, danger, haptic, reset, and final-coin overlay guarantees. Added rigid-silhouette, four-coin, compact-path, target-confirmation, reference-audio provenance/cache, and no-ambience regressions.

## Production Gameplay Parity Final v1

- Changed Level 1's sequential objectives to L5, then L7, then L8 while preserving the L1-L4 mixed unlimited launcher, confirmed-result collection gates, danger failure, full reset, and final overlay ordering.
- Retuned centralized feel values without changing launch speed, table rails, calibrated radii, or merge eligibility: damping `210 -> 185`, side/top/bottom restitution `0.20/0.16/0.10 -> 0.24/0.22/0.12`, piece restitution `0.22 -> 0.30`, tangential friction `0.10 -> 0.07`, and merge momentum/cap `0.45/300 -> 0.62/420`.
- Added rail-contained edge-lane guide geometry, collision-normal telemetry, directional squash/cross-stretch/kick, and a lifted/tilted/anisotropic merge-result overshoot with presentation-only elevated ordering.
- Integrated the supplied glossy coin through a non-destructive 256 px transparent runtime derivative; HUD and rewards now share it. Replaced the former halo/one-curve bead pattern with an upward fan, four varied cubic lanes, permuted departure order, scale/spin variation, and a stronger counter pulse.
- Rebalanced the original procedural mix, added rhythmic crystal/mallet/shaker ambience, and retained the existing cached-stream, threshold, cooldown, concurrency, toggle, and haptic boundaries.
- Added L5/L7/L8 flow, sloped-guide, bounded momentum, directional-impact, supplied-coin mapping, multi-lane reward, mix, and presentation-root regressions; all gameplay/UI suites and the motion profile pass, with four reviewed Compatibility/ANGLE captures.

## Reference Gameplay + Coin Parity v1

- Replaced player-facing SCORE copy with COINS in gameplay and result UI while preserving the exact confirmed-merge reward table, chain multiplication, exactly-once result guard, and a compatibility `score` property for older tools.
- Added a thin ready-state aim guide, retimed merge emergence to 0.62 seconds, and added 0.16-second confirmed-contact squash/pop on `GemSpriteLayer`'s presentation child only. Simulation velocity, collision response, colliders, rails, and merge eligibility are unchanged.
- Replaced local score text with bounded procedural coin rewards: 10 normal / 14 major coins scatter for 0.55 seconds, follow staggered curved paths into the live HUD coin icon, increment the visible counter only on arrival, and finish before the final result overlay.
- Added three cached original procedural coin cues (`coin_burst`, `coin_flight`, `coin_collect`) plus one final-coin light haptic; no reference recording art or audio was copied.
- Added coin/impact/overlay-order regressions, four real 720 x 1600 ANGLE captures, a complete six-suite pass, and one fresh v2/v3-signed Android APK. Level 1 progression remains deliberately unchanged for the later level-creation task.

## Physics + Reward Feedback v1

- Corrected equal-mass collision response to use a true `0.22` restitution coefficient, applied tangential friction only on approaching impact, and centrally tuned damping, sleep, walls, and bounded merge momentum for clearer redirection without changing launch speed or collider geometry.
- Added exact confirmed-result scores for L6-L8 (350/800/1,800), a bounded L6+ double-ring/spark/score celebration, and one major-merge haptic route while preserving the existing chain multiplier and confirmed-event ownership.
- Raised the centralized procedural cue mix, lowered meaningful contact thresholds within cooldown/concurrency guards, and added one cached original procedural ambience loop governed by the existing sound toggle.
- Preserved Level 1's L1-L4 mixed launch bag, unlimited launcher, sequential L7 then L8 targets, table/rail/perspective geometry, radii, contact eligibility, chain rules, danger flow, HUD, and result states.
- Added contact-energy, high-tier score/reward/audio/haptic regressions, three ANGLE evidence captures, a complete motion-profile pass, and a fresh verified debug-signed APK.

## Production UI Polish v4

- Removed the circular progression frames that visually changed gem silhouettes. MERGE PATH, NEXT, TARGET, result art, merge presentation, and table pieces now visibly preserve the same `AssetCatalog`-authoritative source shapes.
- Gave MERGE PATH the full top row at 600 x 138 design pixels with eight 58 px silhouette-preserving slots, then moved the equal SCORE/NEXT cards into a separate lower row with corrected internal breathing room.
- Rebuilt Pause, Win, and Fail as simple responsive cream/gold `PanelContainer` cards so titles, art, scores, and mobile actions fit without ornamental NinePatch compression.
- Added one shared horizontal viewport offset for table artwork, launcher, pieces, rail interpolation, collection presentations, debug contacts, and effects. Wide devices now center the visible table and its physics together.
- Added wide-screen centering regression/evidence, updated hierarchy assertions, 36 ANGLE screenshots, a deterministic walkthrough, a six-suite regression/profile pass, and a freshly exported/verified APK.

## Production UI Simplification v3

- Replaced ornamental SCORE/NEXT/TARGET ribbons and layered card skins with one simple native cream-panel/coral-badge system matching the approved LEVEL 1 label.
- Expanded MERGE PATH from five to all eight active Level 1 gems in a 396 x 122 responsive panel, with catalog-authoritative icons and readable connectors.
- Reduced TARGET to its label and current gem only, removed its name/counter/progress/bar, and anchored it responsively immediately above the table at every supported portrait aspect ratio.

## Production UI Corrective Pass v2

- Corrected the visibly unfinished 576 x 1312 HUD: contained NEXT, restored score breathing room, framed MERGE PATH, rebuilt target content containment/alignment, and aligned Level/Target/Settings on one objective baseline.
- Added crisp native content surfaces, consistent borders/shadows, clearer target progress, a higher-contrast progress track, and a legible two-layer danger-line treatment while preserving its threshold and all gameplay geometry.
- Added icon/card inset and baseline assertions, a reported-state reproduction, and 35 final screenshots across six portrait sizes plus a simulated notch. All six test/profile suites pass.

## Production UI Finalization v1

- Rebuilt gameplay UI around reusable `GameplayHud.tscn` / `ResultOverlay.tscn` CanvasLayers and a cached `UiDesignSystem` theme: equal SCORE/NEXT cards, readable five-tier path, explicit sequential target progress, compact level badge, safe-area margins, and catalog-authoritative icons.
- Replaced temporary modal composition with consistent Pause, Win, and Fail cards; added complete button states, touch targets, dimmers, fast interruptible tweens, duplicate guards, mobile Back routing, and a purposeful Fail badge. Normal gameplay still shows only Settings.
- Added signed-64-bit-safe score formatting through Qi, six-resolution plus notch validation, 34 final screenshots, a reviewed updated walkthrough, lifecycle/input/performance regressions, and a fresh verified Android APK. Gameplay physics, balance, table, rails, targets, unlimited launcher, reward timing, audio, and haptics are unchanged.

## Gameplay UI, Animation, Reward Feel, and Pause/Settings Finalization v1

- Replaced the fixed immediate gameplay HUD with responsive supplied-art Controls for level, SCORE, progression, NEXT, one active target/progress display, and an 88×88 Settings control. Large scores compact safely and every gem preview uses aspect-preserving contain scaling.
- Removed gameplay Restart completely; Settings now freezes the tree behind a full input blocker and exposes only Resume plus the correct supplied pause-only RESTART asset. The single reset path clears board, queue, targets, score, effects, proxies, danger state, overlay, and stale presentation IDs before restoring one ready unlimited launcher.
- Added visual-child-only launch/spawn/merge easing, bounded ring/spark effects, local score feedback, cached audio streams, L6–L8 merge cues, and an arrival-aligned target sound/haptic. Physics roots, radii, colliders, and simulation motion never read presentation scale.
- Reworked target completion into an atomic body removal followed by a 620 ms visual proxy flight with fade delayed until 68% travel. Final victory now follows the traced first-visible → merge-complete → cleanup → collection-complete → confirmation → overlay order exactly once.
- Added comprehensive UI/sequence/responsive/performance regressions, 80 post-popup-restart unlimited launch cycles, real-render evidence, developer-artifact export exclusions, and a freshly signed/verified Android APK.

## Video-Verified Unlimited Launcher + HUD v1

- Eliminated the permanent launcher deadlock caused by an unrelated merge overwriting `SHOT_IN_FLIGHT` while the fired body remained active.
- Replaced settlement-dependent handoff with a bounded 0.30-second lane-clearance handoff, preserving simulation motion while guaranteeing continued cyclic launcher generation.
- Contained NEXT, centered and rebuilt GOAL from supplied art, enlarged settings, and replaced the squashed REPLAY strip with the supplied literal RESTART control.

## Unlimited Launcher Runtime Proof v1

- Added a self-healing ready-state guard: a non-terminal game that is missing its active launcher regenerates one immediately, without introducing a shot count or cap.
- Replaced mocked launcher-only coverage with forty real launch/physics/settle/replacement cycles, and enlarged the aspect-preserving L7/L8 GOAL preview contain area.

## Unlimited Launcher + HUD Final Repair v1

- Removed the global board-settled gate that could leave a live run without a launcher; next launches now wait only for the fired gem and merge/target presentation state.
- Replaced the incorrect back arrow with supplied REPLAY artwork, enlarged settings, and rebuilt the GOAL display from matching supplied red-header and cream-body panel regions.

## Portrait Bottom Table + HUD Repair v1

- Fixed expanded-portrait layout so the supplied table artwork, rails, collision bounds, launcher, drag clamp, danger line, and perspective interpolation move together to the screen bottom.
- Enlarged the supplied settings control, added a supplied restart icon with functional reset behavior, and resized the active GOAL card/icon so target artwork remains contained.
- Added regression coverage for the 1600 px expanded portrait table anchor and HUD restart path; unlimited launcher coverage remains in the Level 1 flow suite.

## Reference-Accurate HUD + Unlimited Level 1 v1

- Enlarged and repositioned supplied SCORE/NEXT artwork to the reference composition; score typography now has matching visual prominence.
- Added supplied-art settings and a single active GOAL card. The L7/L8 objective icon changes only after collection completes; visible `1/2`, shot, Restart, and S/V gameplay controls remain absent.
- Added aspect-preserving contain scaling for HUD gems and cover scaling for expanded portrait backgrounds, preventing distorted/clipped previews and black bars.
- Added regression coverage for unlimited post-restart launcher generation and portrait cover at 720x1600, 1080x1920, and 1080x2400.

## Reference HUD + Unlimited Launches v1

- Removed target-count, restart, and feedback controls from the gameplay HUD; it now shows only the reference SCORE, progression, and NEXT composition.
- Enabled expanded portrait aspect handling to remove black letterboxing on taller phones.

## Supplied HUD Art + L7/L8 Balance v1

- Replaced the hand-drawn SCORE and NEXT HUD panels with direct regions from the supplied button sheet.
- Changed Level 1 to exactly two sequential targets: L7, then L8.
- Replaced the repeating L1/L1/L2 launcher sequence with a controlled mixed L1-L4 cycle to make straight-line play less automatic.

## Identity, UI, Unlimited Play & Target Balance Fix v1

- Corrected the 18-tier runtime texture order so each approved gem name and icon resolve to the same catalog identity.
- Reshaped the gameplay HUD to follow the supplied gameplay reference: score left, progression center, next card right, with the sequential target card outside the table layer.
- Removed production shot-limit state; danger-line overflow is the only non-win level end.
- Rebalanced Level 1 to sequential Jade x2 then Aquamarine x2 and removed collected targets from the live simulation before their HUD animation.

## Gameplay HUD + Sequential Targets v1

- Added authoritative 18-tier catalog entries for every gem ID, display name, texture, and calibration reference.
- Rebuilt the gameplay HUD using current controller state; the production shot counter is removed.
- Level 1 now has unlimited launches and sequential Jade (L3), then Aquamarine (L4) targets. The danger-line failure rule is unchanged.
- Target result collection now completes its merge presentation, travels to the HUD, and only then advances or presents final victory.

## Restored Working Table Rails v1

- Restored the table-interpolated rail containment and launcher clamp from the verified `new-table-shadow-contact-fix-v1` source instead of retaining the later perpendicular slanted-line rail solver.
- Applied only the table's exact `+116px` bottom-alignment translation to the proven rail, launcher, and danger-line geometry.
- Added development-only visual proof captures that read the same rail data as the live solver; the diagnostic is disabled by default in the APK.

## Physical Rails Match Table v1

- Replaced the old `rail_x + radius` side containment approximation with true circle-to-slanted-line containment using the measured inner felt edges of `new_table_v1.png`.
- The four anchors now drive physical rails, launcher drag limits, and the F8 development-only rail overlay.
- No merge, motion, table-position, scoring, target, UI, audio/haptics, launcher-lifecycle, or result-flow rule changed.

## Table Perspective Matched Physics v1

- Packaged and independently revalidated the existing matched perspective/physics/rail implementation as a fresh standalone APK.
- No gameplay source changed in this packaging milestone.

## Matched Perspective Physics Scale v1

- Added one conservative table-local-Y scale (`0.85` back to `1.00` front) shared by each gem's visual root and live simulation radius.
- Rail containment, collision, contact capture, merge eligibility, and visual body/shadow now use the same per-gem scale, preventing invisible pre-contact gaps while keeping gems aligned to the trapezoid rails.
- Preserved gameplay rules, table placement, UI, targets, scores, launcher lifecycle, sounds, haptics, and result flow.

## Pre-Shared-Perspective Restored v1

- Reverted the pushed shared-projection and final-win-sequencing change (`2c7114c`) without rewriting Git history.
- Restored the exact pre-task source state from `70733c0`, retaining the approved visible-touch milestone at `3316d2d` / `visible-touch-table-alignment-fix-v1`.
- Removed only the reverted task's generated source, screenshots, report, and APK artifacts; no replacement gameplay or perspective change was added.

## Visible-Touch Table Alignment Fix v1

- Removed the Y-based gem perspective multiplier and the uncalibrated tier-growth multiplier from live gem presentation. Both made a fixed collider start contact before a rendered gem body visually touched.
- Restored fixed per-gem body rendering from the approved `18-gem-size-collision-fix-v1` calibration: the physics-mirroring root, visual container, sprite, and collider now share one centered position and a fixed scale throughout movement.
- Preserved the lower table composition, centralized table rails/spawn/danger geometry, stable Y/ID ordering, Level 1 content and balance, merge rules, motion profile, and result sequencing.

## Level 1 Balance v1

- Kept the approved L1-L8 range, empty starting board, L1/L1/L2 launcher queue, unlimited shots, overflow failure, physics, visuals, collision calibration, and merge rules unchanged.
- Changed the single Level 1 target type from one L5 result to two L4 Sapphire results. This keeps the introductory queue deterministic and makes a clean completion require twelve Pearl-equivalent launches rather than allowing an early lucky finish.
- Moved historical root-level milestone reports into `reports/`, added its index, and updated core-document references.

## Level 1 Flow v1

- Added only the data-driven default Level 1 flow: active L1-L8 range, deterministic L1/L1/L2 low-tier launcher sequence, and one L5 Peridot target.
- Target progress now consumes unique confirmed merge-result events only, then retains the approved merge presentation and victory hold before displaying the existing win overlay.
- Added scoped Level 1 regression coverage while preserving the full L1-L18 catalog suite, launcher lifecycle, danger failure, motion, collision calibration, table, HUD structure, sounds, and haptics.

## 18-Gem Progression Tested v1

- Added a development-only command-line merge harness plus focused coverage for every L1-L18 transition, terminal L18, duplicate/simultaneous contacts, deterministic chains, result metadata, source cleanup, launcher safety, score single-counting, and cached runtime resources.
- Preserved approved motion, collision/sizing calibration, gem order, table, UI, targets, scoring design, queue, feedback, and outcomes.

## 18-Gem Order v1

- Locked the final L1–L18 asset order and display names without changing any supplied gem asset.
- Remapped calibrated colliders and visual-only shadow metadata with their original assets, preserving all motion and contact calibration.
- Added exact-order, unique-path, label, merge-chain, and terminal-tier regression coverage.

## 18-Gem Size & Collision Fix v1

- Added alpha-calibrated, non-destructive runtime derivatives for all 18 gem bodies and retained every original asset.
- Mapped only the calibrated presentation textures to existing fixed circle colliders; no motion or gameplay constants changed.
- Extended the existing separate visual-shadow calibration to every tier and added regression coverage for the calibrated asset manifest.

## 18-Gem Chain v1

- Rolled back to the verified `new-table-shadow-contact-fix-v1` baseline before making this isolated change.
- Added a deterministic 18-tier source/runtime asset catalog and L1→L18 contact-merge bounds; L18 is terminal.
- Preserved baseline table, HUD, launcher flow, target, physics, score, fail/win, pause, restart, sound, and haptics behavior.

## 18-Gem Motion Smoothness Fix v1

- Removed per-frame dynamic tier texture loading; all 18 runtime textures are now preloaded once and cached.
- Reduced non-destructive runtime gem derivatives to a maximum 256 px long edge for mobile rendering.
- Restored the baseline fixed collision bodies and motion constants; merge presentation remains visual-only.

## Unreleased

- Delayed victory presentation until the spawned Diamond has synchronized and completed its merge pulse; qualification still blocks any launcher/spawn immediately.
- Moved results to a dedicated CanvasLayer backdrop so win/fail UI no longer changes gem textures or modulation.
- Applied a shallower runtime-only table perspective and narrowed physical contact tolerance while retaining contact-only merge rules.

- Calibrated the tropical table presentation and gem visible-contact physics: a shallower derived table now shares the authoritative rail model, runtime gem bodies are alpha-trimmed, and per-level simple colliders match their visible main bodies.
- Reduced contact tolerance from 1.5 px to 0.75 px; collision telemetry now carries the confirmed gem or rail contact point used for audio feedback and developer-only diagnostics.
- Added F8 calibration debug rendering (off by default) for physical rails, gem colliders, and recent confirmed contact points.

- Integrated supplied tropical background, coral table, and Pearl/Ruby/Emerald/Sapphire/Diamond runtime textures.
- Replaced live procedural gem drawing with presentation-only Sprite2D synchronization; merge ghosts and HUD previews now use the same supplied texture catalog.
- Centralized the supplied trapezoid table’s visual and physical layout so rail containment, launcher clamp, danger line, and spawn coordinates use matching geometry.
- Added asset inventory, runtime derivation documentation, clean-Diamond provenance, texture mapping, and table-layout regression coverage.

- Inset the physical gameplay table into a separate procedural crystal alcove background; visual rails and collision geometry now share centralized bounds.
- Replaced generic sine feedback with original runtime crystal/glass synthesis; gem and wall contacts are distinct, thresholded, and throttled while confirmed-event routing remains intact.

- Added lightweight procedural sound routing and Android haptic feedback for launch, meaningful impacts, confirmed level merges, chains, results, and buttons.
- Added compact session-only Sound (`S`) and Vibration (`V`) controls; both default to On and survive Replay/Retry without affecting gameplay.
- Added feedback routing regression coverage while preserving all simulation, merge, lifecycle, score, danger, result, and HUD checks.

- Added a compact Pearl -> Ruby -> Emerald -> Sapphire -> Diamond progression strip with the Diamond target highlighted.
- Replaced text-heavy current/next status with procedural gem previews and concise labels; cleaned score, chain, shots, and restart layout without changing gameplay state.
- Added controller HUD snapshots, visual queue/restart/layout regression coverage, and portrait safe-bound checks for representative device sizes.

- Tuned board width, gem scale, launch/damping, restitution, contact resistance, merge momentum handoff, merge presentation cadence, and launcher readiness toward the supplied comparison recordings.
- Preserved strict same-level current-contact merge eligibility, local contact-only chains, launcher lifecycle, score, win/fail, restart, and gem mapping.
- Added portrait board/scale and bounded merge-momentum regression coverage.
- Added `*.mp4` to `.gitignore`: the two WhatsApp recordings are local comparison inputs and must never be committed.

- Tuned centralized launch, damping, settle, collision/border response, merge presentation, chain display, and next-launcher pacing constants for smoother mobile feel without changing gameplay rules.
- Added balance regression coverage for launch timing, settling/no-jitter, representative frame-step stability, border containment, chain presentation cadence, existing contact-only merges, queue lifecycle, and danger grace behavior.

- Refined the procedural jewelry-table, gem silhouettes, gem facet/highlight treatment, HUD hierarchy, result overlay, and presentation-only merge pulse.
- Added fixed-canvas visual safe-bound regression coverage; gameplay coordinate, collision, merge, launcher, score, chain, danger, and outcome behavior remain unchanged.

- Added the first procedural gemstone visual prototype: level-specific Pearl, Ruby, Emerald, Sapphire, and Diamond silhouettes; soft highlights/shadows; a lightweight luxury jewelry-table board; and clearer HUD/overlay styling.
- Fixed one presentation-only merge-readability issue by drawing source ghosts behind the upgraded simulated gem. Merge eligibility, contact capture, chains, physics, queue timing, danger rules, and launcher lifecycle are unchanged.
- Added a regression test for the fixed level-to-procedural-gem visual mapping.

- Added the complete prototype level loop: confirmed-event scoring, same-resolution chain multipliers, Diamond target/win, settled danger-line fail timing, result overlays, and full Replay/Retry reset.
- Added controller-path regression coverage for score, chain reset, win spawn blocking, danger-line rules, and full reset alongside all prior movement, merge, animation, and launcher lifecycle tests.

- Hardened the AI handoff documentation with a reusable `docs/SESSION_HANDOFF_TEMPLATE.md` and an expanded codebase knowledge map. No gameplay behavior changed.

- Added lightweight presentation-only merge polish: source-gem pull/fade, midpoint pulse, glow, and ring burst.
- Added deterministic, capped, contact-based chain merges. Only a just-created gem can chain via real radius contact with an equal-level gem.
- Added chain, animation-lifecycle, and next-launcher presentation-gate regression coverage.
- Fixed the launcher lifecycle so a settled shot advances the queue and spawns exactly one next launcher instead of spawning repeatedly every frame.
- Added runtime controller-path regression coverage for first/second shots, idle-frame spawn prevention, queue advancement, active-launcher count, and restart.
- Implemented clean gameplay milestone 1: portrait board, horizontal launcher input, straight upward shots, top/side containment, settlement-gated queue, and minimal HUD.
- Added isolated current-step contact-only merge service for Pearl → Ruby → Emerald → Sapphire → Diamond.
- Added headless integration tests for valid contact merges, rejection cases, one-merge-per-cycle, and top-border settling.

## Baseline

- Initialized clean-room Godot rebuild governance and blank portrait baseline.
- Added Android ETC2/ASTC texture-import support through `[rendering/textures/vram_compression] import_etc2_astc=true` in `project.godot`.
- Exported and package-validated the standalone blank Android baseline APK.

## New table + shadow separation v1

- Replaced the active table with the newly supplied table and centralized its measured UI-reference layout in `GameConfig`.
- Replaced live gem artwork with non-destructive body-only derivatives; added independent presentation-only soft shadows.
- Added regression coverage that shadow proximity cannot trigger collision/merge behavior and that the old table is not active.
# Perspective Table View v1

- Lowered the shared table/gameplay composition to reveal more background above the table while keeping rails, launcher, danger line, drag clamps, and collision bounds aligned.
- Added bounded presentation-only gem perspective (`0.90..1.05`) and stable table-local-Y depth ordering with separate shadows under each gem.
- Added regression coverage proving collider/root scale constancy, bounded monotonic visual scale, stable depth ordering, and shared table landmark alignment.
# Complete Perspective View & Variety v1

- Bottom-anchored the shared table, rails, launcher, danger line, and collision model as one reference-aligned composition.
- Added visual-only tier growth, stronger depth perspective, stable front/back occlusion, and Level 1 silhouette variety.
- Deferred target completion until its merge result has visibly completed presentation, preventing the win overlay from hiding the final gem.

## 2026-08-08 - HUD Alignment Fix
- Fixed the light glass HUD alignment after device testing.
- Forced the top HUD column, utility row, status row, objective stack, progression center, and target anchor to expand to the full design width so left/right and centered placements resolve correctly.
- Coins/Level remain on the left; Next/Settings now resolve against the right edge instead of collapsing beside the left group.
- Merge progression and Target now center against the full gameplay width/table rather than a minimum-width container.
- Increased Target-to-table clearance from 16 to 28 design pixels to prevent the glass card/shadow from visually overlapping the table frame.
- No gameplay, table geometry, physics, merge rules, target rules, scoring, or asset changes.

## 2026-08-08 - HUD Alignment Fix v3
- Fixed runtime HUD containers collapsing to minimum width on portrait layouts.
- Header now uses explicit 720px design-canvas geometry so Coins/Level stay left and Next/Settings stay right.
- Gameplay objective anchor now also spans the full 720px design canvas, centering merge progression and Target over the table.
- Preserved safe-area margins, responsive scale, table geometry, gameplay logic, and the light glass StyleBoxFancy visual system.

## 2026-08-09 — Home, Settings, Level Preview, and Pause Modal Polish

- Upgraded the Crystal Magic home overlay from a sparse logo/status/play layout into a more deliberate mobile-game front screen while preserving the approved tropical background and transparent Crystal Magic logo.
- Added matching frosted-glass Level and Coins status cards and a top-right Settings control using the existing supplied cog artwork.
- Added a dedicated Home Settings modal with Music, Sound FX, and Vibration controls. These controls emit the same controller settings signals as the in-game pause menu, so both surfaces persist through `GameSettingsService`.
- Replaced the cramped checkbox-like setting controls in the pause menu with consistent ON/OFF glass switch buttons while retaining their existing persisted behavior.
- Rebuilt pause modal sizing/alignment: settings rows use one shared content width, Resume is full-width, and Restart/Home split the same row evenly.
- Changed Home Play/Continue behavior: the first tap now opens a Level Preview modal showing level number, current target index, target gem art, target quantity/name, and a START GAME button. Gameplay only unpauses after START GAME.
- Added reusable `SettingsSwitch` and `home_status_card_style()` theme treatments to the UI design system so Home and Pause share one glass visual language.
- No table, gem physics, merge rules, launcher rules, target rules, score rules, or simulation coordinates changed.

- v8 polish: fixed home-screen music to continue while the tree is paused, replaced the launcher and system splash icons with a borderless icon treatment, and upgraded the Godot boot splash to a full tropical-background Crystal Magic splash image.

- v8.1 icon/splash refinement: rebuilt the launcher and native splash icons from the generated Crystal Magic logo with proper padding and a beach background, and rebalanced the full-screen boot splash composition for a cleaner fit.

- v8.2 branding correction: replaced all branding references with the exact supplied Crystal Magic transparent logo, removed the boot-splash background image in favor of the standalone logo, rebuilt the launcher/adaptive/native splash icons with padded logo-on-beach treatment, switched settings cogs to theme blue, and enlarged the Home logo region to avoid edge cutting.

## 2026-08-10 — Unified Result Modal + Home Play Label
- Home primary action now always reads `PLAY`; the Level Preview popup remains the gate before gameplay begins.
- Win and failed result overlays now use the same light frosted-glass modal shell, spacing, typography, button sizing, and primary/secondary button language as Pause/Home Settings.
- Removed the legacy cream/gold/coral result-card styling. Result content remains state-specific, but the modal shell no longer changes visual systems.
- Added the same Global Tweens press feedback to Result actions. Gameplay, scoring, targets, persistence, board geometry, and result qualification are unchanged.


- Branding hotfix: Home now uses `assets/runtime/gem-aim-logo.png`, Android/game icon now uses `assets/runtime/gem-aim-icon.png`, settings icon was switched to a crisp PNG derivative, and the home tagline size was increased for readability.
# 2026-08-11 - AdMob Integration v1

- Added Poing Studios Godot AdMob v5.0.0 as the Android fullscreen-ad bridge and registered one `AdManager` autoload.
- Centralized debug/release unit selection and the every-two-completed-level cadence in `scripts/ad_config.gd`; debug exports use Google's official Android interstitial and rewarded test units, while release IDs remain explicit placeholders.
- Added initialization-once, preload/readiness signals, duplicate fullscreen guards, load retry, consumed-ad destruction/reload, fail-open completions, and a lifecycle safety timeout.
- Added Collect and Double Coins to the existing Level Complete modal without altering result qualification or gameplay presentation roots.
- Routed the extra reward only from the rewarded callback with manager- and controller-level exactly-once guards; early close, unavailable inventory, and show failure grant no bonus and restore Collect.
- Routed interstitials only through natural completed-level transitions after levels divisible by two. Pause, Settings, active gameplay, Retry, and failure never request ads.
- Added `tests/run_admob_integration_tests.gd` for ID routing, cadence, readiness/reload, unavailable/failure behavior, duplicate callbacks/taps, confirmed reward, early close, and result fallback.
- No physics, collision, launcher, merge, target, difficulty, danger, or normal scoring rules changed.
# 2026-08-12 - Game flow, reward experience, and splash polish

- Moved Level Ready off the Home composition: Home PLAY now reveals the game/table screen first, then presents the level/target/START GAME gate.
- Removed the resolved `NEXT LEVEL` action and state. Reward completion now closes Level Complete automatically and routes through optional interstitial to the next Level Ready gate.
- Added explicit `STARTUP`, `HOME`, `LEVEL_READY`, `PLAYING`, `LEVEL_COMPLETE`, `REWARD_PROCESSING`, and `AD_SHOWING` controller flow states.
- Locked Collect/Double immediately, added a 0.72-second interpolated gameplay HUD count-up plus final pulse, and added quick title/completed-gem/result emphasis without redesigning the glass modal.
- Changed Double Coins presentation to remain on the same popup and defer `+base -> x2 -> +double` animation until rewarded dismissal; earned currency remains exactly-once at the SDK earned callback.
- Kept interstitial cadence after even-numbered levels, but moved it after reward feedback and before Level Ready. Unavailable interstitials fail open; no ad callback starts gameplay.
- Added one short in-engine Majestic Gems splash using the existing logo and the same blue as Android native/Godot fallback startup. The extra Godot Android boot splash stays disabled.
- Updated the application display label from Gem Aim to Majestic Gems without changing `com.owais.majestygems`, AdMob identifiers/configuration, saves, gameplay, physics, collisions, merges, targets, difficulty, backgrounds, tables, HUD layout, sound, or vibration.
- Added focused flow/reward/splash regression coverage and updated the AdMob result-action suite.

# 2026-08-12 - Splash and reward UI correction

- Removed the extra `StartupSplashLayer` and its controller wiring.
- Made startup a brief presentation state of the existing Home overlay, reusing `assets/runtime/backgrounds/level_bg_1.png` with centered aspect-cover behavior and the existing aspect-contained Majestic Gems logo.
- Replaced the plain `REWARD +N | TOTAL N` line with a game-like `YOU EARNED` coin/value row and a secondary `TOTAL` coin/value row.
- Reused the exact gameplay `CoinIcon` component backed by `assets/runtime/effects/coin_reward_reference_v2.png` for both reward values.
- Added a clearer `WATCH AD ×2` action and retained the same-popup x2 pop, interpolated popup/HUD totals, immediate input locking, exactly-once rewards, and post-animation transition.
- No gameplay, physics, targets, ads, level rules, package name, or general layout changed.

# 2026-08-12 - Single splash correction

- Removed the `startup_intro` Home mode and its timed hidden-controls/logo-only tween, which still appeared as a second splash.
- Mobile startup now routes directly from Android's one platform splash to the complete Home menu.
- Kept Godot's additional Android boot splash disabled and retained the existing mask-safe Majestic system-splash icon.
- Documented the Android 12+ platform constraint: its system splash requires an opaque color plus icon and cannot provide a full-screen cover bitmap without adding a second in-app phase.
- Reward presentation, gameplay, physics, targets, ads, level logic, package name, and Home layout remain unchanged.
# 2026-08-12 — Poing UMP authoritative consent gate patch

- Added a local one-method patch to Poing v5.0.0's Android `PoingGodotAdMobConsentInformation` bridge, exposing Google UMP `canRequestAds()` as `can_request_ads()` without changing dependency versions or unrelated native APIs.
- Rebuilt and installed matching debug/release Poing Ads AARs; retained the reviewable upstream source delta under `patches/`.
- Gated Android Mobile Ads initialization and every load/request behind the authoritative value, including update failure with a prior valid consent state, while keeping the game usable when ads are not authorized.
- Prevented consent callbacks from duplicating SDK initialization or interstitial/rewarded preloads and discard cached ads if permission becomes unavailable.
- Added Privacy Policy and conditional official UMP Privacy Options actions to Home and Pause Settings.
- Added debug-only EEA/not-EEA UMP testing controls that are forcibly disabled in release builds.
- Preserved interstitial cadence, rewarded exact-once rewards, ad IDs, gameplay, level flow, physics, UI theme, splash, and package ID.

# 2026-08-13 — Google Play Closed Testing release configuration

- Configured the Android preset to export a Gradle release App Bundle named `majestic-gems-closed-test.aab`.
- Added the supplied production interstitial and rewarded units to the non-debug AdMob branch while retaining Google test units exclusively for debug builds.
- Added regression assertions for the exact production release routing and preserved the every-two-completed-level interstitial and exactly-once rewarded behavior.
- Kept production UMP behavior unchanged: no forced geography, consent reset, temporary test-device hash, custom consent form, or bypass of authoritative `canRequestAds()`.
- Added an explicit Git ignore rule for the local upload keystore; no keystore, password, credential, or generated AAB is tracked.
- Produced and inspected the signed release AAB without changing gameplay, physics, collisions, progression, rewards, presentation, audio, splash, or save data.
# 2026-08-16 — Responsive reference UI + scale test v1

- Rebuilt gameplay HUD hierarchy as Coins / centered Target / Next + Settings, removed the redundant Level box, and moved the complete eight-gem path into a centered bottom-safe panel.
- Recalibrated the supplied table through one responsive `GameConfig` transform shared by rendering and every table/rail simulation landmark; tested 576×1312 through 1080×2400, including simulated top and bottom cutouts.
- Enlarged L1-L8 from `30/33/36/39/42/45/48/51` to `36/39/42/45/48/51/54/57 px`, keeping visual and circle-collision radii identical and the endpoint ratio bounded at 1.583×.
- Reduced only the presentation opacity/weight of the aim guide and danger warning so gem artwork remains visually dominant. No input, merge, physics timing, targets, scoring, progression, ads/UMP, audio, result, or animation behavior changed.
- Added `tests/run_ui_scale_layout_tests.gd` for responsive HUD bounds/centering/safe areas, table geometry, texture mapping, removal of Level, and the eight-tier size ladder.
# 2026-08-16 - Sound mapping correction v2

- Kept only the five requested supplied replacements: gem contact, rail contact, ordinary merge (`merge-target.mp3`), UI tap, and final success (`merge-basic.mp3`).
- Restored original procedural target-producing merge, chain, and target-arrival cues; removed the supplied objective-completion route. Existing launch and coin identities remain unchanged and no lose sound is routed.
- Raised background music gain from `0.035` to `0.06`; reduced the five replacement gains to `0.34`, `0.39`, `0.70`, `0.32`, and `0.84` respectively.
- Preserved collision cooldown/pitch spam controls, exact merge-pair suppression, priority voice pool, Music/SFX buses, and limiter. No gameplay, physics, UI, privacy, ads, or build configuration changed.
- Updated focused routing/mix regressions and documentation; exported and audited `build/android/majestic-gems-sound-mapping-v2-test.apk`. No AAB was generated and device installation was unavailable.
# 2026-08-16 - Sound mapping correction v2

- Kept only the five requested supplied replacements: gem contact, rail contact, ordinary merge (`merge-target.mp3`), UI tap, and final success (`merge-basic.mp3`).
- Restored original procedural target-producing merge, chain, and target-arrival cues; removed the supplied objective-completion route. Existing launch and coin identities remain unchanged and no lose sound is routed.
- Raised background music gain from `0.035` to `0.06`; reduced the five replacement gains to `0.34`, `0.39`, `0.70`, `0.32`, and `0.84` respectively.
- Preserved collision cooldown/pitch spam controls, exact merge-pair suppression, priority voice pool, Music/SFX buses, and limiter. No gameplay, physics, UI, privacy, ads, or build configuration changed.
- Updated focused routing/mix regressions and documentation. No APK or AAB was generated.
# 2026-08-16 - Immediate merge-sound synchronization v3

- Measured `0.523125 s` of leading silence in the supplied `merge-target.mp3`, explaining why its audible attack followed result-gem appearance despite same-frame event routing.
- Preserved the source unchanged and generated `assets/runtime/audio/merge-target-immediate.ogg`, trimming `0.515 s` and leaving a measured `0.008042 s` pre-attack lead-in.
- Routed the selected merge cue immediately after confirmed merge classification and before any result-presentation setup in the same frame.
- Added timing/path/duration regression coverage. Gameplay, physics, merge/target rules, animation duration, gains, other audio, UI, ads, and Android configuration are unchanged. Exported and audited `build/android/majestic-gems-merge-sound-sync-v3-test.apk`; no AAB was generated and device installation was unavailable.
# 2026-08-16 - Immediate merge-sound synchronization v3

- Measured `0.523125 s` of leading silence in the supplied `merge-target.mp3`, explaining why its audible attack followed result-gem appearance despite same-frame event routing.
- Preserved the source unchanged and generated `assets/runtime/audio/merge-target-immediate.ogg`, trimming `0.515 s` and leaving a measured `0.008042 s` pre-attack lead-in.
- Routed the selected merge cue immediately after confirmed merge classification and before any result-presentation setup in the same frame.
- Added timing/path/duration regression coverage. Gameplay, physics, merge/target rules, animation duration, gains, other audio, UI, ads, and Android configuration are unchanged. TEST APK pending; no AAB will be generated.
# 2026-08-17 - Immediate merge-sound release AAB v3

- Exported `build/android/majestic-gems-merge-sound-sync-v3.aab` from the validated immediate merge-sound milestone using the unchanged production Android preset and upload certificate.
- Bundletool, JAR signature, release manifest, package/SDK, production AdMob App ID, dual-ARM native libraries, immediate merge-audio payload, and export-exclusion audits pass.
- Preserved package `com.owais.majestygems`, versionCode 2/versionName 1.0.1, ads/UMP, signing, gameplay, physics, UI, and audio behavior. The prior `majestic-gems-closed-test-v2.aab` was not overwritten.
# 2026-08-17 - Android release versionCode 3 correction

- Persisted Android `version/code=3` after Play rejected reuse of already-published versionCode 2.
- Added a mandatory repository workflow rule: before every future release APK/AAB export, select and save an integer greater than the highest versionCode recorded in `BUILD_MANIFEST.md`; never reuse or revert a released code.
- Marked the prior merge-sound versionCode-2 AAB as superseded and exported `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab` with embedded versionCode 3.
- Bundletool, JAR/upload-certificate, package/SDK, production AdMob App ID, dual-ARM, immediate merge-audio payload, and export-exclusion audits pass. Package ID, versionName, signing, ads/UMP, gameplay, UI, physics, and audio remain unchanged.

# 2026-08-17 - Prepare monotonic Android release versions

- Prepared the next Android release as versionCode `4` and versionName `1.0.2`; no APK or AAB was generated.
- Extended the release guardrail so every future AAB must increase both values, persist and commit them before export, include them in the filename, and pass Bundletool embedded-manifest verification before delivery.
# 2026-08-18 - Animation/reward/audio/large-screen polish APK

- Tightened confirmed merge presentation from 0.36 s to 0.30 s and calibrated the result pop from 1.23x to 1.18x.
- Added subtle, cooldown-protected collision compression below each gem's simulation-mirroring root; merging contact pairs remain excluded from collision feedback.
- Added focused timing/deformation contracts and wide/resizable table containment tests.
- Audited Android 16 behavior: retained portrait on phones, the game category, adaptive `expand` canvas, centered fixed-width table, and background fill. No AdMob, UMP, economy, progression, physics, gem asset, or UI-layout behavior changed.
- Produced only the requested debug APK; no AAB export was performed.

# 2026-08-18 - Video audit and Tween Composer packaging cleanup

- Completed an end-to-end decode, 0.5-second contact-sheet review, focused 10 fps sequence review, waveform comparison, and loudness analysis of `current-gameplay-ours.mp4` and `refrence.mp4`.
- Confirmed the existing target flight, Target handoff, coin arrivals, Next response, and audio hierarchy are worth retaining; no new sound, mix, gameplay, UI, or gem change was justified.
- Excluded the disabled, unused `tween_composer/*` source from Android packaging after the APK audit found 38,988 uncompressed bytes still present. Global Tweens remains active and packaged.
- Exported and audited `build/android/majestic-gems-animation-large-screen-polish-v2.apk`; it is 16,676 bytes smaller than the first polish APK and contains no Tween Composer entries.
- Kept the APK-only release scope. No AAB was generated.
# 2026-08-18 - Reference-driven game feel v2

- Rebuilt the merge feedback cadence around a 270 ms presentation, 1.26x result pop, brighter 10/12-ray crystal burst, and faster settle.
- Removed the target-completion checkmark and replaced it with a short artwork-preserving glow/ray confirmation.
- Accelerated target travel from 0.40 s to 0.32 s and coin travel from 0.92/1.00 s to 0.54/0.60 s; shortened target handoff and strengthened HUD arrival response.
- Preserved all supplied music/SFX identities while reducing normal-contact gains and raising merge, target-arrival, and final-success emphasis.
- Fixed missed fast/visually touching contacts with displacement-bounded simulation substeps and same-step confirmed-contact authority. Merge distance, collider radii, progression, rewards, UI layout, ads, and saves are unchanged.
- Added `REFERENCE_GAME_FEEL_V2_TESTS` for separation, exact contact, overlap, unlike tiers, fast shots, resting pushes, contact-only chains, feedback timing, tick removal, and sound hierarchy.
# 2026-08-18 - Reference-driven game feel v2

- Rebuilt the merge feedback cadence around a 270 ms presentation, 1.26x result pop, brighter 10/12-ray crystal burst, and faster settle.
- Removed the target-completion checkmark and replaced it with a short artwork-preserving glow/ray confirmation.
- Accelerated target travel from 0.40 s to 0.32 s and coin travel from 0.92/1.00 s to 0.54/0.60 s; shortened target handoff and strengthened HUD arrival response.
- Preserved all supplied music/SFX identities while reducing normal-contact gains and raising merge, target-arrival, and final-success emphasis.
- Fixed missed fast/visually touching contacts with displacement-bounded simulation substeps and same-step confirmed-contact authority. Merge distance, collider radii, progression, rewards, UI layout, ads, and saves are unchanged.
- Added `REFERENCE_GAME_FEEL_V2_TESTS` for separation, exact contact, overlap, unlike tiers, fast shots, resting pushes, contact-only chains, feedback timing, tick removal, and sound hierarchy.
# 2026-08-18 - Fix Home startup and return navigation

- Fixed builds that opened directly into a level when the runtime did not expose Godot's `mobile` feature flag.
- Fixed Pause HOME so it clears the paused gameplay modal and reliably presents Home.
- Changed Level Ready Back from a no-op into a controller-owned return to Home.
- Extended game-flow regression coverage to instantiate the production controller and exercise startup, Level Ready, active play, Pause, and Home return.
# 2026-08-18 - Android Back, idle stability, settings, and splash repair

- Replaced the stale gameplay-only mobile Back callback with app-state-aware Home exit, Level Ready return, and Playing Pause/resume behavior.
- Added an explicit AdManager exit shutdown gate for delayed loader callbacks, retry timers, cached ads, and completion callables.
- Made the bottom Privacy Policy container span the viewport before centering.
- Removed unsupported Vibration controls and snapshot/signal wiring from Home and Pause Settings; persisted default is disabled.
- Replaced the 432x432 Android system-splash icon input with a dedicated 1152x1152 runtime derivative while keeping the approved blue background and single native splash.
- Audited and documented the unchanged target-only coin table and per-level target composition.
- Added Back/idle/ad-shutdown/privacy/vibration/splash/reward regressions and reran the broader gameplay/layout/art suites.
- Exported and audited `build/android/majestic-gems-back-idle-settings-splash-repair.apk`; package, SDK, v2 signature, dual ARM ABIs, and packaged splash resource pass. No AAB or device test is claimed.
# 2026-08-18 - Last-AAB Home dependency and Android Back correction

- Audited every change from the version-code-3 release AAB source `aa3a1e1` through current HEAD.
- Identified post-AAB commit `9f83eb7` as the Android Home regression: it excluded `tween_composer/*` while `HomeOverlayLayer` still preloaded and instantiated that runtime package.
- Restored Tween Composer to Android export, explicitly hid gameplay while Home owns the screen, and made Home visibility precede optional presentation work.
- Debounced the two platform Back entry points for 350 ms so one physical press cannot execute two transitions.
- Added source and export-contract coverage for Home dependency retention, hidden gameplay, and duplicate Back suppression.
- Exported and audited `build/android/majestic-gems-last-aab-home-back-repair.apk`; the four required Home Tween Composer bytecode files, current project payload, both ARM ABIs, package/API metadata, and v2 signature pass inspection. No AAB or device test is claimed.
# 2026-08-25 - Rail target blast release AAB v1.0.6 (versionCode 8)

- Prepared and exported the signed Play-ready AAB for the already validated rail/target blast/gem-expansion milestone.
- Advanced Android release identity from versionName `1.0.5` / versionCode `7` to `1.0.6` / `8` before export; verified the embedded AAB manifest with Bundletool.
- Recorded dual-ARM native libraries, 34 runtime gems, packaging exclusions, focused regression result, and device status in the AAB delivery report and build manifest.
# 2026-08-25 - Android targeting and launcher branding v1.0.7 (versionCode 9)

- Added the required touchscreen feature to the persistent Godot Gradle-template manifest; phone and tablet support, portrait orientation, package/signing, game category, and AdMob settings remain unchanged.
- Replaced launcher branding inputs with non-destructive v2 derivatives from the supplied transparent Majestic Gems logo: 192px legacy icon plus 432px adaptive foreground/background with conservative mask-safe padding.
- Verified the final AAB merged manifest with Bundletool: touchscreen required, portrait activity, game category, no Leanback/Automotive/Wear/XR declarations, dual ARM ABIs, package/version invariants, and development-file exclusions.
# 2026-08-25 - Complete Majestic logo refresh v1.0.8 (versionCode 10)

- Replaced the remaining old Home/fallback and Android system-splash logo paths with derivatives of the supplied v2 transparent logo.
- Removed obsolete Majestic v1 source, Home, legacy launcher, adaptive-icon, and old system-splash assets.
- Bundletool verified versionCode 10 / versionName 1.0.8, new v3 splash packaging, and zero packaged legacy Majestic logo assets.
# 2026-08-25 - Firebase Analytics Android integration v1.0.7

- Added persistent custom-template Firebase Analytics configuration and a desktop-safe GDScript/native Android bridge.
- Routed the eight requested events only from confirmed gameplay and ad lifecycle boundaries; gameplay, package, signing, and AdMob IDs are unchanged.
- Restored the user-confirmed Play release identity to versionCode 9 / versionName 1.0.7.
# Retention, Coin Economy, and Daily Missions Sprint (unreleased)

- Added data-driven `normal` and `limited_shots` level types. The first conservative limited-shot introduction is level 10; shots decrement only when the controller commits a valid launch and out-of-shots waits for all resolution/target work before offering rescue.
- Added controller-owned +5 Shots and one-per-attempt Continue rescues, safe non-negative save-before-commit spending, and daily missions/chest persistence.
- Added a compact Home Daily Missions surface, a gameplay shots indicator, Firebase retention events, and local-device-clock daily reset documentation.
- Repriced Skip Level to retain the deliberate economy hierarchy: reroll 100, extra shots 300, continue 500, skip 800.
