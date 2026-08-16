# 2026-08-16 - Regenerated scene art integration v1

- Replaced the previous 19 background sources and 10 table sources with the user's regenerated 941x1672 RGB backgrounds and 1343x1171 RGBA tables, using canonical source filenames.
- Generated 720x1280 background and shared-canvas 920x810 alpha-table runtime WebPs; removed the superseded single-table `assets/runtime/table/new_table_v1.png`.
- Re-enabled deterministic per-level table selection alongside the existing deterministic background selection, preserving retry identity.
- Kept the restored fixed table geometry and unstretched `0.7391304 x 0.9691358` transform; no physics, gem, merge, input, target, reward, queue, or HUD behavior changed.
- Added measured all-ten-table rail/danger-line calibration regression and transparent-corner/runtime-dimension coverage.
- Reviewed 20 real Godot table proofs across 720x1280 and 720x1600; all visible rails contain the fixed legal playfield and danger line.
- Reduced active runtime scene-art files from 3,068,162 to 2,145,764 bytes (30.06%).
- Created no APK or AAB, per the requested Godot-first workflow.

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
