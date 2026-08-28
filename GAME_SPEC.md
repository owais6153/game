# Final Pre-Launch Production Readiness Candidate - 2026-08-28

- Reference refinement V2: Switch Gem uses a large white two-arrow glyph inside a bright-rimmed purple 112 px squircle seated across the table's lower frame. Next is compacted to `128x150` with a 48 px gem and a 12 px gap before the independent Settings control.

- Coin-sink presentation correction: live gameplay exposes only one 112 px circular Switch Gem action below the shared table. Skip Level is available only in Level Ready, Pause, and Failed overlays, displays its centralized price there, and is absent from successful Level Complete.
- The shared 64 px table lift translates table art, physics rails, board, danger line, launcher, and containment together. Selected @icons runtime derivatives identify both actions; the editor addon and picker remain excluded from Android export.

- V1 adds one economy action only: spend the centralized 100-coin cost to reroll the currently displayed Next Gem from the existing weighted launcher sequence. The active launcher, later queue, targets, physics, merge rules, and balance tuning are unchanged.
- Reroll spending is save-before-commit, banked-coin-only, retry-safe, non-negative, and protected against rapid duplicate requests. It emits exactly one contextual `coin_spent` event.
- Analytics retain established canonical names (`merge` for gem merge and `rewarded_ad_completed` for earned reward) and now add attempt/shot/economy/ad-placement context plus retry, bounded coin inflow/outflow, ad-request, and ad-failure coverage.
- Ad shown events remain SDK-shown-callback-only; rewarded completion remains earned-callback-only. UMP `canRequestAds()` remains the only ad-request gate.
- No post-launch gameplay modifier, shop, IAP, leaderboard, Play Games, timed/limited-shot mode, blocker, or progression redesign is part of this candidate.

# Firebase custom gameplay analytics pipeline v1 - 2026-08-27

- Firebase automatic collection and custom gameplay analytics are separate paths. Custom events travel only through the `Analytics` Autoload and the acknowledged Android `FirebaseAnalytics` Godot-plugin bridge.
- Confirmed runtime events are fixed-name `level_start`, `merge`, `target_complete`, `level_complete`, `level_fail`, `rewarded_ad_shown`, `rewarded_ad_completed`, and `interstitial_shown`; dynamic values remain primitive parameters.
- `level_start` occurs once when Level Ready starts play or a playable retry begins. `merge` observes accepted merge results only. Target, win, and danger-fail events observe their existing authoritative controller transitions and cannot alter them.
- Fullscreen-ad shown events occur only from the SDK shown callback. Rewarded completion occurs only from the earned-reward callback. Per-run/per-session guards prevent duplicates.
- Analytics diagnostics are bounded to initialization and event requests/forwarding; they never run per frame and never gate gameplay, rewards, ads, or progression.

# Rail, Target Blast, and Gem Expansion V1 - 2026-08-25

- The active presentation registry contains 34 supplied identities: 22 Common and 12 Unique. `gem_33` is a pink gradient circle and `gem_34` a pink gradient rounded square. Names remain prohibited in player-facing data/UI.
- All 34 runtime gems are alpha-tight at threshold 0.01, aspect-preserving, and normalized to a 256 px longest edge. Source pixels and filenames never define physics.
- The authoritative supplied-table opening is outer 420-1215, board 454-1168, back inner rails 140/580, front inner rails 58/662, danger Y 1015, launcher Y 1095, texture center (360,844), and scale (0.9583333,0.752). Rendering, containment, drag clamp, launcher, danger, and diagnostics consume this one model.
- L1-L5 retain radii 36/39/42/45/48. The reachable L6-L8 target ladder is physically and visually larger at 56/61/66; the detached target collection proxy uses 1.18 emphasis.
- A confirmed target completion applies one 220 px bounded radial nudge with a maximum 78 px/s impulse to other nearby board gems. It excludes the result, active launcher, consumed pieces, and distant gems; it does not alter contact or merge eligibility.
- Target and final-target waves use five 52-segment concentric rings. The existing 420 ms merge, 120 ms origin hold, collection authority, score/reward values, and exactly-once guards remain unchanged.
- Background music linear gain is 0.07, up slightly from 0.06. Event routing, buses, limiter, toggles, SFX gains, and gameplay authority are unchanged.

# Gem Categories, Pattern Blocks, and Target Feedback V1 - 2026-08-24

- The presentation registry contains 32 audited identities and only the categories visible in supplied art: `circle` / `rounded_square`, practical color family, `solid` / `gradient`, and `common` / `unique`. The pool is 22 Common and 10 Unique; player-facing names remain prohibited.
- Generated levels use deterministic 3-4-level blocks. Same Shape uses four Common plus one non-target Unique in the dominant shape and three opposite-shape Unique targets. Same Color uses at least three dominant-color Common pieces, one same-color Unique support piece, and three contrasting Unique targets. Adjacent blocks cannot repeat the exact family/dominant configuration.
- Local L1-L4 are Common launcher/progression identities, L5 is the non-target Unique support identity, and L6-L8 are three distinct Unique targets in ascending, mechanically reachable order. Strict contact merging and unlimited L1-L4 launches remain unchanged.
- Every target uses a presentation-only 1.12 scale, a brighter three-layer merge wave, a complete 420 ms merge, a 120 ms hold at the actual merge point, then the same center hold and curved HUD collection sequence. Physics bodies/radii do not scale.
- Target sound order is confirmed contact/merge, target reward at collection start, then collection arrival. Every target coin group holds on the table for at least 1.0 s; the last target now uses four visible coins, matching targets 1 and 2, with light 0.24-opacity contact shadows and no vertical idle float.
- HUD style boxes have no box shadows. Dark-amethyst fills, rims, highlights, positions, sizes, anchors, and safe-area behavior are unchanged.
- All 32 runtime PNGs are non-destructive alpha-tight derivatives at threshold 0.01 with preserved aspect ratio and a 256 px longest edge. Transparent padding never changes the centralized local-tier collider radii.
- All ten supplied tables retain the existing normalized shared opening and centralized `GameConfig` trapezoid. In-game rail-contact captures and all-table pixel/geometry regressions found no safe geometry retune was needed.

# Supplied Art, Purple UI, and Repository Cleanup V1 - 2026-08-24

- The active presentation catalog contains exactly 10 supplied portrait backgrounds, 10 supplied transparent portrait tables, and 20 supplied gem identities. Generated levels select eight identities for local L1-L8 progression while gameplay mechanics continue to use local tiers only.
- Gem runtime derivatives must be cropped to the alpha >= 0.01 bounds, clear sub-threshold edge alpha, preserve aspect ratio, and fit within a 256-pixel longest edge. Their complete image rectangle must equal their used-alpha rectangle.
- Player-facing gem names are prohibited. Target, Next, progression, Level Ready, results, and settings may use gem artwork, tier-independent progress, and quantities only. Internal IDs must remain generic.
- The supplied full-portrait table derivative uses the centralized geometry: outer 420-1215, board 455-1165, back rails 130/590, front rails 54/666, danger Y 1015, launcher Y 1095, texture center (360,844), and render scale (0.9583333,0.752). L1-L8 radii remain 36-57.
- UI styling uses dark amethyst glass, violet borders, white/lavender text, purple controls, and lavender utility icons. This theme change must not alter existing sizes, anchors, margins, safe-area rules, touch targets, or HUD ordering.
- Supplied originals belong in semantic `assets/<family>` folders and are excluded from export. Only optimized package-ready derivatives belong in `assets/runtime`. Scripts are grouped by responsibility under `scripts/core`, `gameplay`, `presentation`, `ui`, `services`, and `dev`.
- This milestone does not change movement, merge/contact eligibility, scoring, target authority, queue rules, danger grace, launcher pacing, reward logic, audio/haptics routing, ads, or persistence.

# Reward Split Readability V5 - 2026-08-23

- A confirmed merge reveals its result first, then visibly splits real lower-tier reward gems from that exact result position. Reward visuals render above the result from their first frame, fan outward as complete supplied gem artwork, and retain a short origin tether; they may not appear at their already-safe physics destinations.
- The split begins after 280 ms and lasts 780 ms. Reward physics remains held for the full split; the stored launch is 135 px/s. For 650 ms after release, the new gems resolve physical collisions but cannot confirm a follow-up merge, making contact readable and bounding crowded-board cascades.
- Multi-gem output must use distinct eligible tiers whenever the result has enough lower tiers. The existing three-piece shot budget, depth-2 generation ceiling, 24-piece board cap, and 1/1/2/2/3 requested-count ladder remain authoritative.
- Non-final target coins anchor to the live result gem until reveal, then all four remain together on the table for 1.20 s. The final 16-coin pile remains together for 1.00 s.
- The final-target hero gem stays centered for 1.05 s and its `TARGET COMPLETE!` caption remains readable throughout the hold before anticipation and HUD flight.
- Gem shadows use the supplied presentation-only shadow asset at a visible tier-scaled lower offset and 0.50 opacity. Target/final coin shadows use 0.46 opacity and follow the coin's current table position. No shadow changes collision, merge, containment, telemetry, or scoring.

# Reward Feedback Real Gems V4 - 2026-08-22

- Confirmed merges request persistent gameplay bonus gems at the normal/COMBO 1/COMBO 2/COMBO 3/COMBO 4+ ladder of 1/1/2/2/3 pieces. A shot may create at most three bonus pieces, COMBO 3+ creates no further reward tier, and delayed rewards may not raise the live population above 24.
- Bonus gems are lower local tiers selected from 1 through result tier N-2 using centralized 50/30/20 low/middle/high weights and safe early fallback. They use the generated progression mapping, never hardcoded gem identities.
- Bonus gems begin 200 ms after confirmation at the merge center, scale `0.28 -> 1.18 -> 1.00`, and fan toward collision-safe positions over 340 ms. Their physics and stored 165 px/s impulse activate only after that pop finishes; afterward they use ordinary rails, danger, settlement, contact capture, and future merge rules.
- Same-event bonus pairs suppress only mutual merge candidates for 180 ms after activation; physical collision then continues and either piece can merge with an existing board gem. The marker is cleared when grace expires.
- Normal merge is 420 ms with 35 ms contact compression, a 35-120 ms snap, synchronized 120 ms impact, and `0.65 -> 1.24 -> 0.93 -> 1.05 -> 1.0` result pop. Combo scale/ring/pitch/hit-stop and requested real-piece count escalate from existing resolver depth.
- Chain presentation is spaced by 180 ms per depth so each result can be understood before the next tier appears. One pooled 180 ms radial canvas shader serves all merge tiers at centralized intensity; it is bounded behind the result gem and never samples or distorts the board.
- Relevant target merges immediately pulse/highlight the target HUD; displayed progress animates on arrival. Final target uses the hero-center/anticipation/curved-HUD sequence, presents the exact reward amount, then releases 16 larger visual coins before Level Complete.
- Every non-final target's four coins finish landing and remain together on the table for at least 260 ms before the first HUD flight. The final 16 coins spawn 4+4+4+4 in a compact center pile, retain a 380 ms readable hold, then vacuum in accelerating groups with the strongest HUD response reserved for the final four. Gems and landed coins use slight presentation-only table shadows.
- Gameplay geometry, collider radii, contact-only eligibility, score/coin authority, target generation, launcher rules, level structure, art direction, ads, persistence, and result actions remain otherwise unchanged.

# Responsive scene variety and HUD hierarchy v1 - 2026-08-16

- Each generated level deterministically selects one of 19 supplied portrait backgrounds and one of 10 supplied transparent table presentations. Retrying the same level/seed must retain both selections.
- Background and table selection are presentation-only. Every table variant uses the same normalized runtime canvas and the one authoritative `GameConfig` rail/board/launcher/danger geometry.
- Gameplay attention order remains table first, Target second, merge path third. The baseline table is translated down another 20 design pixels; all physical and visual table landmarks move together.
- Coins and Next are 12.5% larger. Next remains at the upper-right and Settings sits directly below it. The centered Target/path stack must not overlap either edge utility group on supported portrait viewports.
- Supplied originals remain under `assets/source/`; mobile runtime derivatives remain under `assets/runtime/`. Originals, reports, tests, build output, and calibration manifests must stay outside Android packaging.
- This milestone must not change gem radii, movement, merge eligibility, score/reward authority, launcher pacing, danger timing, target rules, queue behavior, audio/haptics, ads, or result flow.

# Post-AdMob Level Complete flow — 2026-08-11

- Level Complete begins with the existing base reward and current banked total plus `COLLECT` and `DOUBLE COINS`.
- Collect resolves the base reward exactly once, animates the visible total, keeps the modal open, removes both reward choices, and exposes `NEXT LEVEL`.
- Double Coins may add exactly one base-reward bonus only from the rewarded earned callback. Dismissal/failure without earnings restores Collect and never advances the level.
- Next Level is a separate explicit transition. It may show the scheduled every-two-level interstitial, then opens the existing Level Intro/Ready modal. Play explicitly begins gameplay.
- Rewarded dismissal, Android resume, and reward animation never start the next level or trigger an interstitial.
- Physics, gem movement, collision, merge, target generation/counts, difficulty, table perspective, and game-asset quality remain unchanged.

# Majestic Gems branding + draggable push line v1 — 2026-08-11

- Home and fallback boot branding use the complete supplied transparent `MAJESTIC GEMS` logo without cropping or aspect distortion.
- Android launcher branding uses the supplied square icon through a 192 px padded legacy icon plus 432 px adaptive foreground/background derivatives. The complete supplied composition stays inside the mask-safe center instead of being zoomed or cropped.
- While the launcher is ready, the visible vertical push line is a touch target. Pressing or sliding it moves the active gem through the exact same horizontal rail clamp as direct gem dragging; releasing uses the unchanged launch path.
- The push line remains input/presentation-only. It does not raycast, predict trajectory, change launch velocity, alter collision geometry, or affect merge, danger, target, queue, or score rules.
- Historical source/reference assets remain preserved but are excluded from Android packaging when they are not active runtime dependencies.

# Startup and iconography requirements — 2026-08-09

- The pre-level modal keeps its target gem static. Do not add idle breathing, wobble, spin, or scale-loop animation to that gem; START GAME and popup entrance motion are enough.
- Use the supplied `@icons` library for generic interface affordances instead of inventing new raster icons. Runtime derivatives may be recolored to the Crystal Magic white/navy palette, but the source library remains untouched.
- Settings uses the @icons cog on Home and gameplay. Primary/secondary actions may use Play, Done, Back, Restart, Home, Next, Retry, Music, Sound, and Vibration glyphs where they improve readability.
- Android startup should not show two separate branded splash phases. Keep the Android system splash visible until the main loop and disable the extra Godot Android boot splash.
- The Android system-splash icon must be padded inside the safe area to prevent the Crystal Magic mark from being cropped by system masking.
- The launcher main icon remains the supplied Crystal Magic app icon; startup cleanup must not silently replace the launcher artwork.

# Crystal Magic — Fast Feel + Motion Integration v1

- Home Settings is a compact top-right control that respects the same safe-area margins as the Home content; it must never stretch vertically with the screen.
- Button/toggle feedback is immediate and bounded. Global Tweens may animate presentation scale/color only and must never feed simulation values.
- Tween Composer is used for the reusable Home-logo ambient loop only; the Level Intro target gem is intentionally static. Presentation tweens remain pause-safe and never affect simulation.
- Fast-feel tuning is centralized in `GameConfig`: launch speed 1200, damping 195/s, sleep threshold 10, launcher handoff 0.22 s, merge presentation 0.36 s, target collection 0.40 s, target swap start 0.26 s, normal coin flight 0.92 s, chain visual stagger 0.03 s.
- Contact-only merging, table/rail geometry, target qualification, level generation, scoring, coin authority, persistence, and all collider sizes remain unchanged.

# Game Spec — Clean Contact Merge v1

## Table / Target / merge-path hierarchy correction v1

- Gameplay attention order is table first, Target second, and the complete eight-gem merge path third.
- Coins remains top-left; Next and Settings remain top-right. The top safe-area row contains utilities only, so those controls cannot collide with Target.
- Target and the merge path form one centered stack immediately above the table. Target precedes the path vertically; the path is no longer attached to the bottom navigation edge.
- The merge path uses a bright high-contrast native glass tray, 64-design-pixel gem slots, strong connectors, and all eight authoritative `AssetCatalog` textures.
- Baseline table geometry moves down by 40 design pixels. Table art, rails, board bounds, danger line, launcher, drag clamp, spawn limits, containment, and collision geometry consume the same shared `GameConfig` transform.
- Gem radii, merge eligibility, scoring, targets, queue rules, launch speed, timing, audio/haptics, result qualification, and progression rules are unchanged.

## Light Glass Gameplay HUD v1

This presentation milestone supersedes the purple gameplay HUD composition while preserving all gameplay rules.

- Top utility layout is Coins left / Next right, with Level below Coins and Settings below Next.
- The `MERGE PATH` title is not rendered. The eight authoritative progression gems remain visible, ordered, and centered directly above Target.
- Target is centered directly above the table and follows the authoritative `GameConfig.board_top()` layout rather than a fixed phone-specific Y coordinate.
- Gameplay HUD surfaces use a light cyan/blue StyleBoxFancy glass language derived from the addon demo Panel8: translucent gradients, squircle corners, layered highlight/rim borders, and soft shadows.
- Buttons and Pause use the same glass family. True backdrop blur is excluded for mobile GL Compatibility safety; the frosted appearance is achieved without sampling gameplay pixels.
- Background, table, board geometry, gems, physics, launcher, collisions, merges, targets, progression rules, score/rewards, audio/haptics, danger, and results qualification are unchanged.


## Transparent Purple Glass HUD v1

This presentation patch supersedes the surface colors in Professional Glass HUD v1 while preserving its composition.

- Header, path tray, Coins, Target, and Next use visibly translucent purple glass. Tropical scenery may show subtly through each surface while lavender rims, controlled shadows, and white outlined values preserve contrast.
- The glass treatment remains native and cached. It uses alpha-tinted `StyleBoxFlat` resources rather than raster panels, runtime blur, backdrop capture, or gameplay-sampling shaders.
- Gem names and tooltips remain hidden. HUD hierarchy, icon mapping, live collection destinations, interaction motion, and every gameplay/table rule remain unchanged.

## Professional Glass HUD v1

This section supersedes the Purple Production HUD v1 composition below.

- Gameplay uses one cohesive premium HUD: a translucent beveled purple header with Level, MERGE PATH, and Settings, followed immediately by one aligned Coins / Target / Next objective row.
- MERGE PATH retains all eight authoritative gem silhouettes inside a light glass tray with directional connectors. Level has a compact gold-rimmed purple badge; Settings retains its supplied gear artwork inside a circular layered frame.
- Coins and Next are compact translucent glass cards. Target is the wider center card with authoritative artwork, sequence, numeric progress, and progress bar.
- Gem names and gem-name tooltips remain forbidden. Artwork carries identity so narrow portrait layouts cannot overflow.
- Glass, bevel, rim light, shadows, progress treatment, and interaction motion use cached native Godot controls and `StyleBoxFlat`; no raster panel or copied reference artwork is used.
- The HUD remains snapshot-only and presentation-only. Background, table/board geometry, gem art, physics, launcher, collision, merges, target rules, progression, balance, rewards, audio/haptics, danger, and results are unchanged.

## Purple Production HUD v1

- Gameplay uses a rich purple native-control HUD: one dominant MERGE PATH header, a compact Coins/Next utility row, and one independent Target card anchored immediately above the unchanged table.
- The header keeps Level at the left and the existing Settings icon inside a circular purple frame at the right. All eight generated path gems remain visible and ordered.
- Target identity is artwork-only. Gem names and gem-name tooltips are forbidden because they overflow narrow portrait layouts; sequence and authoritative numeric quantity progress remain visible.
- Coins and Next are deliberately smaller than Target. The open tropical space between the utility row and table-adjacent Target is intentional and responsive across safe areas/aspect ratios.
- Panels, borders, progress fills, typography, and press/refresh motion use native Godot controls, `StyleBoxFlat`, and bounded tweens. No raster panel asset was introduced.
- This milestone is presentation-only. Board/table geometry, backgrounds, gem artwork, physics, launch, collision, merge, targets, progression, balance, rewards, and result qualification are unchanged.

## Production Gameplay UI Finalization V2

- Gameplay presentation uses one safe-area top shell. Its first row integrates Level, the authoritative eight-gem MERGE PATH, and Settings; its second row balances Coins and Next around a larger central Target objective.
- Coins show exact values through 9,999, compact suffixes afterward, and retain the exact integer authority. The Next and all eight path icons resolve through the current generated level mapping.
- Target UI exposes sequential position, authoritative identity/name, quantity progress, and a progress bar. Target travel and coin flight terminate at the current target/coin icon rectangles and remain foreground-only.
- Pause is a centered, input-blocking modal with primary Resume, secondary Restart/Home, independent persistent settings, Android Back handling, and no duplicate instance.
- The ready-state aim guide and near-danger pulse are visual affordances only. They do not change launch, simulation, rail, overflow, grace, or failure behavior.
- This milestone freezes every gameplay rule and timing listed in the baseline: targets, quantities, chain, launcher pool/weights, unlimited launches, score/reward logic, physics, table/rails, perspective, colliders, feedback timing, and win/fail sequencing.

## Production foundation v1

This section supersedes older fixed L5 -> L7 -> L8 Level 1 statements below; those sections remain historical milestone records.

- Settings are player-owned and persistent across levels and app launches. Pause exposes independent `MUSIC`, `SOUND FX`, and `VIBRATION` switches; changing one must not change either of the others or any gameplay state.
- All table, merge-result, collection, TARGET, NEXT, result, and MERGE PATH gems resolve through `AssetCatalog`. Runtime sprites preserve source aspect ratio with uniform scale; artwork never changes collider geometry.
- Generated difficulty is bounded and reachable: Level 1 has one L5 target, Level 2 has L5 then L6, and Level 3 onward has two targets every fourth level and three otherwise, selected uniquely and sorted upward from L5-L8. Launcher assistance decreases through `INTRO`, `EASY`, `NORMAL`, `CHALLENGE`, and capped `EXPERT` bands, but every cycle retains L3 and L4 and launches remain unlimited.
- Player-facing application name, launcher icon, and boot splash use the GEM RUSH brand. The generic Godot icon/splash is not part of the shipped configuration.

## Production UI motion + Restart restoration v1

- Home communicates only player-facing state: GEM RUSH branding, Level, Coins, and Play/Continue. Internal implementation copy about random gems, generated paths, seeds, or infinite levels is forbidden in production UI.
- Home uses a full-bleed tropical scene, floating status typography, the real coin icon, one coral primary action, entrance motion, and a bounded ambient logo/action loop. It does not use the former journey/status card.
- Pause uses one focused modal, gem accent, primary Resume, and a compact Restart/Home utility row. Restart always restores the gameplay HUD, resets the same seeded level, and returns one ready launcher.
- These changes are presentation/state-restoration only. Infinite forward generation remains an internal rule; physics, merges, targets, rewards, audio, table geometry, and persistence are unchanged.

## New background music v1

- `assets/runtime/audio/supplied_background_music_v5.ogg`, derived without trim or signal processing from the preserved user-supplied MP3, is the active continuous background track.
- The dedicated player uses linear gain `0.10`; it starts independently and movement/contact cannot trigger or restart it.
- Target coin audio remains a separate target-only stream. Gem/contact/merge cues, animations, physics, rewards, and Level 1 L5 -> L7 -> L8 progression are unchanged.

## New background music v1

- `assets/runtime/audio/supplied_background_music_v5.ogg`, derived without trim or signal processing from the preserved user-supplied MP3, is the active continuous background track.
- The dedicated player uses linear gain `0.10`; it starts independently and movement/contact cannot trigger or restart it.
- Target coin audio remains a separate target-only stream. Gem/contact/merge cues, animations, physics, rewards, and Level 1 L5 -> L7 -> L8 progression are unchanged.

## Infinite randomized eight-gem levels v1

- Every level selects eight unique identities from the full 18-gem catalog, shuffles them, and assigns them to that level's local L1-L8 merge ranks. Two equal local ranks still merge only through confirmed contact into the next local rank; local L8 remains terminal for that level.
- The complete generated eight-gem order is shown in the existing MERGE PATH. Launcher entries use only local L1-L4. Three unique targets use local L5-L8 and are sorted strictly upward; Level 1 retains the verified L5 -> L7 -> L8 rank pacing while its identities are randomized.
- A level seed deterministically owns gem order, launcher sequence, targets, and one of five backgrounds. Retry preserves the same configuration; completing the final target exposes NEXT LEVEL, increments without limit, generates a new seed, and saves level/seed/coins. No level-tree or previous-level route exists.
- Home/Continue, Pause, Level Complete/Next Level, and Fail/Retry/Home are modal UI states outside simulation. Physics, colliders, merge eligibility, target-only coins, feedback animation, audio, danger, and table geometry remain unchanged.

## Branded production screen flow v1

- Home is a standalone modal presentation: the gameplay HUD is hidden, the preserved supplied GEM RUSH logo derivative is the primary hero, and saved Level/Coins lead to one PLAY or CONTINUE action.
- Pause uses Resume, deterministic Restart, and Home. Success presents the completed target, total coins, explicit `LEVEL N -> LEVEL N+1`, NEXT LEVEL, and Home. Failure presents the danger reason, total coins, same-chain Retry promise, Retry, and Home.
- Home after success banks and prepares the next generated level; Home after failure resets the same seeded level. Continue never returns to a consumed win/fail state. These screens remain outside simulation and do not change physics, targets, rewards, or infinite generation.

## Scope

## Reference animation and supplied-audio polish v4

- Level 1 remains L5, then L7, then L8. Ordinary merges never award coins; only a unique confirmed result matching the active target creates the target reward and exactly four visible coins.
- A merge uses the restored pre-v4 `0.50 s` presentation: source pull `0.10 s`, one centered uniform result pop (`0.62 -> 1.20 -> 1.0`) with its damped settle, plus the bounded flash/ring/eight-ray impact. The rejected irregular color splash is absent. There is no squash, stretch, rotation, or physics transform.
- Active Level 1 gem radii use the reference-contrast ladder `30, 33, 36, 39, 42, 45, 48, 51` design px, a `1.70x` L8/L1 range. The same `GameConfig` radius drives both the alpha-trimmed sprite body and its simple circular collider, including perspective scaling.
- Target status never enlarges a live physics body. After a qualifying result finishes its normal merge pop, its body is removed and the collection proxy inherits the exact live sprite X/Y mapping, then receives a presentation-only `1.18x` target-reward pop before flying to the already-large TARGET preview.
- Target coins use the shared supplied-art token at `17 px` draw radius. They pop for `0.22 s`, then follow four ordered foreground arcs over `1.58-1.66 s`; their integer values still reconcile only at HUD arrival.
- The collected target remains a foreground-only proxy, reaches the card over `0.62 s`, and leaves no physics body. A large green check holds for `0.94 s`; the completed card then fades in place for `0.24 s`, pauses for `0.10 s`, and the new centered target fades in for `0.24 s`.
- `assets/sound/gem_merge_music_loop.wav` is the preserved clean background source. Its runtime Ogg loops continuously from service initialization at linear gain `0.14`; movement and gameplay events never start or restart it.
- `assets/sound/coin-sound.mp3` is the preserved clean target-reward cue. One trimmed runtime Ogg plays once per target qualification, independently of the background player. The existing bounded launch/contact/tiered-merge/target/result gem cues remain dominant event layers.
- The sound toggle controls both players. Physics, colliders, rails, momentum, contact/merge eligibility, launcher timing, danger behavior, reward integers, and result qualification are unchanged.

This section supersedes the animation and audio presentation values recorded below.

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

## Home and pre-level flow

- Home must show the Crystal Magic brand, current level, current coin total, Play/Continue, and a Settings affordance.
- Play/Continue must open a level-preview modal before gameplay starts.
- The level-preview modal must show the current level and target objective from controller-owned snapshot data and provide START GAME plus a way back to Home.
- START GAME is the only Home-flow action that dismisses Home and resumes gameplay.
- Home Settings contains Music, Sound FX, and Vibration only; it must not contain Resume, Restart, or Home actions.
- Pause contains the same wired settings controls plus Resume, Restart, and Home.
- Home and Pause must share the light frosted-glass UI language and consistent button/switch sizing.

## Unified production modal rule — 2026-08-10
- Home Settings, Pause, Win, and Failed overlays must share one light frosted-glass visual language. Result outcome may change content, never the modal shell styling.
- Result primary action is 424×82 design units and Home is a 424×72 secondary action, matching the Pause hierarchy.
- Home primary action text is always `PLAY`; the pre-level preview remains responsible for showing level/target details before `START GAME`.


- Branding hotfix: Home now uses `assets/runtime/gem-aim-logo.png`, Android/game icon now uses `assets/runtime/gem-aim-icon.png`, settings icon was switched to a crisp PNG derivative, and the home tagline size was increased for readability.
# AdMob Integration v1 - 2026-08-11

- AdMob is presentation/transition infrastructure only. It must never affect board simulation, collision, merge eligibility, targets, difficulty, launcher behavior, or score qualification.
- Debug Android exports use Google's published Android test units. Release exports read production unit IDs only from `scripts/ad_config.gd`; an empty release placeholder means that format fails open and gameplay continues without an ad.
- Interstitials are eligible only when leaving a naturally completed even-numbered level. No ad may start from gameplay, Pause, Settings, Retry, or failure.
- A completed result exposes Collect and Double Coins. Collect immediately banks the already-confirmed run reward. Double Coins adds exactly one extra copy of that level's reward only after the rewarded SDK callback, then follows the normal completion transition.
- Loading, show failure, early rewarded close, unavailable inventory, duplicate taps/callbacks, and lifecycle restoration must never duplicate currency or trap the normal Collect path.
# Game Flow + Reward Experience + Splash Polish - 2026-08-12

- Android launch uses the configured Majestic blue native system splash, then one short in-engine Majestic Gems logo hold/fade, then Home. The separate Godot Android boot splash remains disabled.
- Home PLAY changes the visible surface to the gameplay screen before presenting Level Ready. Level Ready shows only level, target, and START GAME; it never appears over Home and never starts play automatically.
- Level Complete has one reward decision. COLLECT or earned DOUBLE COINS locks both choices, plays the reward/count-up sequence, closes automatically, runs the scheduled even-level interstitial if available, and then opens Level Ready.
- The former resolved `NEXT LEVEL` button/state is removed. Interstitial dismissal and rewarded dismissal never begin gameplay; START GAME remains the sole transition from Level Ready to PLAYING.
- Rewarded earnings are persisted exactly once from the earned callback, but the visible `+base -> x2 -> +double` sequence starts only after the fullscreen ad has dismissed back to the same Level Complete instance.
- Rewarded failure/early close grants nothing, restores the same Level Complete choices, and cannot progress. Interstitial unavailability fails open to Level Ready.
- Gameplay physics, collision, merging, target generation/counts, difficulty, launcher behavior, table/background/HUD layout, sound, vibration, package ID, AdMob App ID, and debug/production unit routing are unchanged.

# Splash and Reward UI Correction - 2026-08-12

- No separate in-engine splash layer or intermediary scene exists. Mobile startup presents the existing Home overlay with its controls briefly hidden, then reveals those controls on the same mounted surface.
- Startup and Home share `assets/runtime/backgrounds/level_bg_1.png` through one centered `TextureRect.STRETCH_KEEP_ASPECT_COVERED` backdrop. The existing Majestic Gems logo remains aspect-contained and centered.
- Level Complete presents a distinct `YOU EARNED` coin row and a smaller `TOTAL` coin row. Both reuse the exact `CoinIcon` component and `AssetCatalog.COIN_REWARD` texture used by the gameplay HUD.
- Collect and confirmed Double Coins retain the existing exactly-once controller/ad lifecycle. Only presentation hierarchy, tweening, and button copy change.

# Single Splash Correction - 2026-08-12

- Android startup has one branded launch phase only: the platform system splash, followed immediately by the fully populated Home menu.
- Home must never hide its controls or run a timed logo-only startup state. The former `startup_intro` path is removed.
- Godot's Android boot splash remains disabled. Android 12+ system splash constraints require an opaque color plus a mask-safe icon; a full-screen background bitmap would require a second in-app splash and is therefore intentionally not used.
# AdMob UMP authoritative consent gate — 2026-08-12

- Android must update Google UMP consent information before Mobile Ads initialization or any ad load/request.
- Only native `ConsentInformation.canRequestAds()` authorizes ads. Update failure may still proceed when that method reports a valid previous-session decision; otherwise the game continues without ads.
- Consent/ad callbacks share one initialization guard and must never duplicate interstitial or rewarded preload work.
- Settings opens the published Majestic Gems privacy policy and exposes Google's official Privacy Options form only when UMP requires the entry point.
- UMP geography forcing is debug-only and disabled by default. Release builds never accept forced test geography or test-device IDs.
- Every-two-level interstitial cadence, rewarded Double Coins exact-once behavior, ad IDs, rewards, gameplay, package ID, splash, and UI theme remain unchanged.
# Responsive reference UI + scale test v1 — 2026-08-16

- Gameplay HUD order is Coins left, Target centered and dominant, Next right, and Settings adjacent to Next. A separate Level box is forbidden.
- The complete L1-L8 merge path is centered at the bottom and must remain inside horizontal and bottom safe areas without clipping or overlap.
- The supplied table remains centered and dominant. Rendering, rails, board bounds, launcher, danger line, containment, and perspective must consume one responsive `GameConfig` geometry model.
- Active L1-L8 base radii are `36/39/42/45/48/51/54/57 px`; alpha-trimmed sprite bodies and simple circular colliders use the same values. Visual tier growth must be clear but not exaggerated.
- Backgrounds cover the portrait viewport without distortion. Aim/danger guides remain subtle presentation only.
- Merge rules, launch/movement tuning, target/scoring/progression rules, rewards, ads/UMP, audio, results, and animation sequencing are frozen for this milestone.
# Reference-driven game feel v2 - 2026-08-18

- A confirmed merge presents over 0.27 s: 0.06 s source pull, result scale 0.64 -> 1.26 -> 1.0, and a bounded 10-ray crystal impact (12 rays for L6+). Presentation never feeds simulation.
- Target collection travels over 0.32 s and confirms with a short glow/ray card reaction; no tick/checkmark success glyph is rendered. Sequential target handoff begins after 0.12 s.
- Target-only coins retain four authoritative chunks and unchanged values, but travel over 0.54 s normally or 0.60 s for L6+, with 0.045 s stagger and a 0.18 s HUD pulse.
- Existing music and sound assets remain authoritative. Normal contacts are subordinate to ordinary merge, target arrival, and final success through centralized gains.
- Physical merging remains contact-only. The simulation may use up to eight displacement-bounded substeps, and a pair captured inside the confirmed-contact branch remains valid for that resolution batch even if later substeps separate it. No collider radius or proximity threshold is enlarged.
# Home startup and return-flow repair - 2026-08-18

- Every runtime target enters the complete Home screen after initialization; Home visibility must never depend on `OS.has_feature("mobile")`.
- Home PLAY opens Level Ready, START GAME alone begins play, and Level Ready Back returns Home.
- Pause HOME synchronously closes Pause and presents Home as the input-owning paused layer. It must never resume gameplay or leave the player trapped behind a hidden modal.
