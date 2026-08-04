# Changelog

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
