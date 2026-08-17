# 2026-08-16 - Supplied sound and Home privacy-link guardrails

- Preserve `AudioFeedbackService` as the single runtime audio owner and the Music/SFX bus split. Do not add per-screen or per-gem audio players.
- Active supplied mappings are gem contact `gems-colide.mp3`, rail `gems-rail-colide.mp3`, normal merge `merge-basic.mp3`, target merge `merge-target.mp3`, arrival sparkle `mixkit-fairy-arcade-sparkle-866.wav`, objective complete `mixkit-game-flute-bonus-2313.wav`, level success `mixkit-game-success-alert-2039.wav`, and UI tap `mixkit-on-or-off-light-switch-tap-2585.wav`.
- Preserve existing `supplied_background_music_v5.ogg`, the procedural launch stream, and `supplied_coin_reward_v4.ogg`. Music gain is `0.035`; do not reintroduce a lose/game-over sound.
- Merge audio is exclusive: one confirmed result emits `target_merge` or `merge_basic`, never both and never an additional chain tone. Suppress only the collision impact whose exact pair appears in the resolved merge event.
- Keep gem/rail cooldowns at 65/90 ms, collision pitch within `0.96..1.04` / `0.97..1.03`, the five-voice cap, priority protection, and the SFX limiter unless a documented listening pass supersedes them.
- Target sparkle belongs at `_finish_target_collection()` arrival. `target_complete` belongs after full quantity progress and before target advance. `win` belongs only after the victory overlay accepts presentation.
- Privacy Policy must remain the single bottom-centered `HomePrivacyPolicyLink`, outside Home and Pause Settings, using the existing AdManager URL action. Conditional UMP Privacy Options remain in both Settings panels.
- UI layers may emit `ui_tap_requested`; only the controller routes the sound. Never emit a second tap in the action handler.

# 2026-08-16 - Supplied sound and Home privacy-link guardrails

- Preserve `AudioFeedbackService` as the single runtime audio owner and the Music/SFX bus split. Do not add per-screen or per-gem audio players.
- Active supplied mappings are gem contact `gems-colide.mp3`, rail `gems-rail-colide.mp3`, normal merge `merge-basic.mp3`, target merge `merge-target.mp3`, arrival sparkle `mixkit-fairy-arcade-sparkle-866.wav`, objective complete `mixkit-game-flute-bonus-2313.wav`, level success `mixkit-game-success-alert-2039.wav`, and UI tap `mixkit-on-or-off-light-switch-tap-2585.wav`.
- Preserve existing `supplied_background_music_v5.ogg`, the procedural launch stream, and `supplied_coin_reward_v4.ogg`. Music gain is `0.035`; do not reintroduce a lose/game-over sound.
- Merge audio is exclusive: one confirmed result emits `target_merge` or `merge_basic`, never both and never an additional chain tone. Suppress only the collision impact whose exact pair appears in the resolved merge event.
- Keep gem/rail cooldowns at 65/90 ms, collision pitch within `0.96..1.04` / `0.97..1.03`, the five-voice cap, priority protection, and the SFX limiter unless a documented listening pass supersedes them.
- Target sparkle belongs at `_finish_target_collection()` arrival. `target_complete` belongs after full quantity progress and before target advance. `win` belongs only after the victory overlay accepts presentation.
- Privacy Policy must remain the single bottom-centered `HomePrivacyPolicyLink`, outside Home and Pause Settings, using the existing AdManager URL action. Conditional UMP Privacy Options remain in both Settings panels.
- UI layers may emit `ui_tap_requested`; only the controller routes the sound. Never emit a second tap in the action handler.

# 2026-08-16 - Regenerated scene-art guardrails

- This section supersedes the temporary original-table-only guardrail below. Production uses all 19 `LEVEL_BACKGROUNDS` and all 10 `LEVEL_TABLES`; there is no `AssetCatalog.ORIGINAL_TABLE` path.
- Preserve deterministic `LevelConfig` scene indices. Never use global randomness in `GameController`, and never let retry choose a new background/table pair.
- Keep the fixed unstretched table model: outer `400..1185`, board `440..1110`, rails `188/532 -> 62/658`, danger `960`, launcher `1042`, center Y `792.5`, and render scale `0.7391304 x 0.9691358`.
- All table variants must remain transparent 920x810 presentation canvases and use the identical `GameConfig` transform. Never derive rails, gem radius, collision, danger, launcher, clamp, spawn, merge, or score behavior from artwork.
- The measured table-edge arrays in `run_ui_scale_layout_tests.gd` are regression evidence only. Do not move them into runtime code or use them for per-table offsets/scales.
- Preserve replacement originals under canonical `assets/source/` names and make optimized derivatives only under `assets/runtime/`. Run the preparation tool and scene/layout regressions after any replacement.

# 2026-08-16 - Original table restoration guardrails

- The active gameplay table is temporarily `AssetCatalog.ORIGINAL_TABLE` (`assets/runtime/table/new_table_v1.png`). Do not select `LEVEL_TABLES` until the user supplies regenerated rail artwork.
- The rejected `TABLE_ART_HORIZONTAL_COVERAGE_SCALE = 1.15` path is superseded. Keep the original unstretched X scale `0.7391304` and Y scale `0.9691358`.
- Current authoritative base landmarks are outer `400..1185`, board `440..1110`, rails `188/532 -> 62/658`, danger `960`, launcher `1042`, and texture center Y `792.5`.
- Random backgrounds remain active. The ten replacement tables are preserved but presentation-inactive so they can be replaced/calibrated in a later supplied-art task.
- Do not change Coins/Next alignment, Next sizing, stronger text, Target/path hierarchy, gem radii, collision, movement, merge, target, reward, or input behavior as part of this temporary table restoration.

# 2026-08-16 - Table-art containment and HUD legibility guardrails

- The ten supplied table canvases do not have identical visible inner-rail widths. Preserve `TABLE_ART_HORIZONTAL_COVERAGE_SCALE = 1.15` unless a new all-table visual calibration supersedes it.
- This multiplier is artwork-only. Never feed it into `table_left_at/right_at`, board bounds, launcher clamps, danger evaluation, gem radii, collision, merge eligibility, or movement.
- Keep the verified physics landmarks unchanged for this correction: outer `420..1205`, board `460..1130`, rails `188/532 -> 62/658`, danger `980`, launcher `1062`, and base table vertical scale `0.9691358`.
- Coins and Next share a top baseline; Next is `141.075 x 123.75`, Settings stays below it, and Target must remain visually stronger than either utility card.
- Use `run_ui_scale_layout_tests.gd` for the physics-freeze/layout guard and `capture_table_art_containment_hud.gd` for 720-wide ANGLE proofs. Raw 576 subviewport captures bypass normal canvas stretching and are not valid device-composition evidence.

# 2026-08-16 - Scene variety and responsive hierarchy guardrails

- Keep the 19/10 scene catalogs presentation-only. Add new artwork by preserving originals under `assets/source/`, generating runtime derivatives under `assets/runtime/`, and updating both the catalog and scene-variety regression.
- A level's `background_index` and `table_index` are seeded outputs. Do not select either with global randomness during controller setup; retries must reproduce the same pair.
- All table variants must remain 920x810 normalized presentation canvases and use the unchanged `GameConfig` transform. Never derive rails, radii, launcher positions, drag clamps, danger bounds, or merge behavior from pixels.
- The right utility order is Next then Settings vertically. Coins/Next are 12.5% above the previous compact size. Keep Target and the complete eight-gem merge path in their independent centered stack.
- Current baseline table landmarks are outer `420..1205`, board `460..1130`, danger `980`, launcher `1062`, and texture center Y `812.5`. Any future composition move must translate all authoritative landmarks together and update responsive geometry tests.
- `assets/source/*`, tests, reports, and build outputs must remain Android-export excluded. Do not restore retired scene art, reference audio, Crystal Magic/Gem Aim branding, first-generation gem bodies, or unused icon variants unless a new explicit runtime dependency and inventory entry are added.
- Keep the tracked `.webp.import` profiles even though generic `*.import` files are ignored. Backgrounds use lossy quality 0.85 and alpha tables use 0.92 with mipmaps disabled; deleting these profiles restores default lossless package expansion and adds roughly 16.7 MiB to the scene texture payload.

# 2026-08-11 — Majestic Gems branding and push-line guardrails

- Supplied originals: `assets/logo/majestic_gems_logo_source_v1.png` and `assets/logo/majestic_gems_icon_source_v1.jpeg`. Do not overwrite them.
- Active logo: `assets/runtime/ui/majestic_gems_logo_v1.png`. Keep `TextureRect.STRETCH_KEEP_ASPECT_CENTERED`; do not crop it for Home.
- Android icons: `majestic_gems_app_icon_192_v1.png`, `majestic_gems_adaptive_foreground_v1.png`, and `majestic_gems_adaptive_background_v1.png`. The foreground's occupied square is intentionally 68% of 432 px so common launcher masks retain the entire supplied icon.
- Push-line touches are legal only while the same active gem is `READY_TO_AIM` and settled. Never create a second input handler, a trajectory predictor, or a physics line body.
- Both gem and guide dragging must continue through `GameConfig.launcher_drag_x()`. Releasing either must continue through `launch_active_piece()` exactly once.
- Keep obsolete/reference resources out of Android through the export filter. If reactivating one, remove its exclusion and add an explicit production reference in the same change.

# 2026-08-09 knowledge note — static level target, @icons, single Android splash

When modifying Home/level-preview UI, keep `LevelIntroTargetGem` static. Tween Composer remains valid for the Home logo and other approved ambient motion, but the pre-level target gem must not run a breathing/scale loop.

The project now contains `addons/at-icons`. Prefer its icon vocabulary for generic UI actions. Player-facing code should preload the curated runtime derivatives from `assets/runtime/ui/icons/` rather than reaching into the editor dock/plugin API.

Android startup intentionally disables the separate Godot boot splash in the export preset. Do not re-enable it unless there is a product decision to restore a two-stage startup. The system splash uses `crystal_magic_system_splash_icon_v1.png`; the launcher main icon stays `crystal_magic_app_icon_v1.png`.

# AI Knowledge Addendum — 2026-08-09 Fast Feel Motion v1

- If Home Settings appears as a tall translucent bar, inspect `HomeOverlayLayer._build_top_settings_control()`. The settings frame must keep `SIZE_SHRINK_BEGIN` vertically and `SIZE_SHRINK_END` horizontally inside the full-screen HBox.
- `GlobalTweens` is now an autoload. Use it only for presentation feedback; never use its movement helpers to move simulation-owned gems.
- Tween Composer is intentionally limited to approved ambient Control animation such as the Home logo. The Level Intro target gem is static. Do not attach Tween Composer to simulation nodes or use it to replace controller timing gates.
- Fast-feel values are centralized in `GameConfig`: launch 1200, damping 195, sleep 10, merge presentation .36, launcher handoff .22, target collection .40, target swap delay .26, coin flight .92, chain stagger .03.
- The latest supplied ZIP contains the MIT `addons/at-icons` library. Use curated runtime derivatives under `assets/runtime/ui/icons/` for player-facing generic actions and keep the editor plugin API out of runtime logic.

# Android closed-test compatibility v2

- Production Android releases use Gradle AAB export with `arm64-v8a` plus `armeabi-v7a`; do not enable x86 variants without a production requirement.
- The active Poing AdMob/Google Ads/UMP graph packages no native `.so` files. Godot 4.6.3 and `libc++_shared` are the only native libraries and must remain complete for every enabled ABI. Re-audit the generated AAB if any Android plugin or SDK dependency changes.
- Keep package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, GLES 3.0, portrait activity, production AdMob routing, authoritative native UMP `can_request_ads()`, and the existing upload certificate unless a specific release task authorizes otherwise.
- Play infers `android.hardware.faketouch` and `android.hardware.screen.portrait`. They are intentional for the current touch-driven portrait game and must not be removed merely to enlarge the device catalog.

# AI Knowledge Base

## 2026-08-16 - Table / Target / merge-path hierarchy guardrails

- Preserve the current attention order: dominant table, prominent Target, then visible complete merge path.
- Keep Coins alone at top-left and Next plus Settings at top-right. Do not place Target back inside that top utility row.
- Keep Target and the path in `TableObjectiveAnchor`, ordered Target then path, and position the stack from `GameConfig.table_outer_top()` after the controller configures the viewport.
- The merge path must remain above the table and in the gameplay sightline, never return to the bottom navigation edge. Preserve all eight icons, 64 px slots, 88 px tray height, strong connectors, and high-contrast native glass.
- Table rendering and all physics borders must continue to use the same `GameConfig` geometry. Never translate only the artwork, only the colliders, or only the launcher.
- This correction does not authorize gem-radius, movement, collision, merge, target, score, queue, timing, audio/haptic, or result-flow changes.

## 2026-08-08 — Light Glass Gameplay HUD v1

- Do not restore the old purple gameplay HUD unless explicitly requested.
- Current gameplay placement: Coins top-left, Next top-right, Level below Coins, Settings below Next; progression immediately above Target; Target immediately above the table.
- `MERGE PATH` heading is intentionally removed; the eight progression gems/connectors remain.
- `GameplayObjectiveAnchor` is table-relative and must continue to read `GameConfig.board_top()`; do not hardcode a device-specific target Y.
- Gameplay glass surfaces come from `UiDesignSystem._frosted_glass_style()` using StyleBoxFancy, translucent cyan/blue gradients, squircle curvature, rim/highlight borders, and soft shadows.
- There is intentionally no true backdrop blur/screen-sampling shader. Preserve the performant frosted-glass approximation unless a separately profiled mobile shader milestone is approved.
- Buttons and Pause share the light glass style family. Gameplay/table/background/physics remain outside HUD scope.


## Transparent Purple Glass HUD v1 guardrails

- Keep the professional composition and use visibly purple translucent surfaces: shell alpha no more than `0.86`; objective-card alpha no more than `0.78`; blue channel greater than red for the glass tint.
- Maintain white outlined coin/target values and lavender path connectors so background detail never reduces readability.
- Do not simulate glass through screenshots, bitmap panels, runtime blur, viewport capture, or gameplay-sampling shaders. Keep cached `StyleBoxFlat` resources and zero new frame work.
- Preserve hidden gem names/tooltips, all eight path gems, live icon destinations, responsive/notch bounds, and every gameplay/table boundary.

## Professional Glass HUD v1 guardrails

- Preserve the unified composition: translucent beveled purple header containing Level/MERGE PATH/Settings, followed by one aligned Coins / centered Target / Next row. Do not detach Target back to the table edge.
- Keep all eight path gems in the light glass tray and resolve every HUD gem through `AssetCatalog`. Never mask or independently redraw supplied silhouettes.
- Never restore gem names or gem-name tooltips. Target identity is artwork-only with sequence and numeric progress.
- Glass is a cached native presentation treatment: translucent `StyleBoxFlat` surfaces, crisp rims, restrained shadows, and bounded tweens. Do not add raster panel art, runtime blur/capture passes, shaders that sample gameplay, or per-frame resources.
- Target and coin collection destinations must continue to read live icon rectangles. HUD code cannot award currency, advance targets, own queues, handle board input, or alter table/simulation geometry.
- Validate professional HUD hierarchy/glass styles, six portrait resolutions, notch, Pause, target transition, reward flight, crowded board, and danger state; run production UI, gameplay-feel, clean-contact, and the full regression/profile suite.

## Purple Production HUD v1 guardrails

- Preserve the current composition: dominant purple MERGE PATH header; compact Coins left and Next right; independent Target card immediately above the table; Level left and circular Settings control right.
- Never restore gem names or gem-name tooltips in gameplay HUD. Use authoritative artwork plus target sequence/numeric quantity progress so narrow portrait widths cannot overflow.
- HUD layout may read centralized board-top geometry only to place the presentation anchor. It must not write geometry, duplicate progression, create board input, or alter physics/simulation coordinates.
- Keep all eight generated path gems visible. Coins/Next must remain visually secondary to Target, and open tropical breathing room is intentional.
- Use `UiDesignSystem`, native controls, `StyleBoxFlat`, and bounded tweens for this HUD. Do not introduce generated panel images or per-frame node/resource creation.
- Run the production UI finalization, gameplay UI feel, clean-contact, and full regression/profile suites after changing this composition; refresh `reports/purple-production-hud-v1/` at the supported resolutions.

## Production Gameplay UI V2 guardrails

- Preserve `SafeHudMargin/HudShell/HudRows`: Level/MERGE PATH/Settings belong to `ProgressionHeader`; Coins/Target/Next belong to `ScoreNextRow`; the target remains the expanding central objective.
- UI reads controller snapshots only. Never duplicate queue, target, progression, reward, launcher, danger, or simulation rules in the HUD.
- The ready aim guide is presentation-only and must disappear outside `READY_TO_AIM`; it may read `vertical_lane_top_y()` but must never perform input, raycast, trajectory, or launch decisions.
- Danger-line pulse may read proximity only. Never feed warning strength into `danger_timers`, `DANGER_GRACE_DURATION`, overflow, or fail qualification.
- Target identity copy and ghost art must change together during the existing swap cadence. Restart must clear the cached HUD snapshot before its first new-run refresh.
- Preserve the V2 gameplay freeze: no target/launcher generation, scoring, physics, rails, perspective, collider, merge/collection/coin timing, sound/haptic timing, or result-sequence changes in UI work.
- Run `run_production_ui_finalization_tests.gd`, `run_gameplay_ui_feel_tests.gd`, `run_clean_contact_tests.gd`, and the full suite after editing this composition.

## Production foundation v1 guardrails

These guardrails supersede older fixed L5 -> L7 -> L8 progression instructions below.

- Persist Music, Sound FX, and Vibration only through `GameSettingsService`; keep them independent and outside gameplay decisions.
- Never scale a table gem independently on X and Y. Every renderer must use the same `AssetCatalog` texture and preserve its silhouette; physics reads only `GameConfig.gem_collision_radius()`.
- Generated progression contract: L1 `[L5]`; L2 `[L5,L6]`; L3+ uses unique ascending L5-L8 targets, three normally and two when `level_number % 4 == 0`. Preserve deterministic seeds, unlimited launches, L3/L4 availability, and capped `EXPERT` difficulty.
- Preserve `Gem Rush` branding and `assets/runtime/ui/gem_rush_app_icon_v1.png` for project icon and boot splash. Do not restore `icon.svg` or Godot launch branding.
- Run `run_production_foundation_tests.gd` and the full suite after changing these systems.

## Player-facing production UI guardrails

- Never display “infinite levels,” seeds, random gem counts, generated chains, or similar implementation language to players. Infinite generation is an internal progression capability.
- Home should remain a full-bleed lobby: floating logo, Level, Coins, and one primary action. Do not restore the former `ContinueCard` or technical footer.
- Ambient Home motion must be bounded, presentation-only, paused-tree safe, killed on dismiss, and must not create per-frame `_process` work.
- Regression route for Restart: Home -> Continue -> Pause -> Restart must produce a visible HUD, one ready launcher, reset rewards/targets, and an unpaused tree.

## Home visual authority

- Treat `assets/ui/Generated image 2 (3).png` as the composition reference for Home: full tropical backdrop, floating brand hero, coral primary action, and cream secondary/status surfaces.
- Use `AssetCatalog.BRAND_LOGO` for the active transparent runtime logo. Never restore the opaque gradient derivative to Home and never overwrite the uploaded logo source.
- Do not implement the level-tree composition from `assets/ui/Generated image 6.png`; progression remains infinite and forward-only.

## New background music guardrails v1

- Keep `supplied_background_music_v5.ogg` as the active continuous track and preserve its original MP3 under `assets/sound/`.
- Keep music gain at `0.10` unless a listening-backed audio-only milestone retunes it; documented safe range is `0.08-0.12`.
- Never route background playback from movement or contact. Keep the v4 coin cue separate and target-only, and do not replace tiered gem/contact sounds with the music stream.

## New background music guardrails v1

- Keep `supplied_background_music_v5.ogg` as the active continuous track and preserve its original MP3 under `assets/sound/`.
- Keep music gain at `0.10` unless a listening-backed audio-only milestone retunes it; documented safe range is `0.08-0.12`.
- Never route background playback from movement or contact. Keep the v4 coin cue separate and target-only, and do not replace tiered gem/contact sounds with the music stream.

## Branded production screen guardrails v1

- Preserve the supplied logo original under `assets/logo/` and use only `assets/runtime/ui/gem_rush_logo_v1.png` at runtime. Keep it as a contained hero; do not stretch it or treat its opaque background as transparent artwork.
- Home must hide the gameplay HUD and expose exactly one primary Play/Continue action. All modal content must remain inside safe bounds at 576 x 1312, 720 x 1600, and tall 1080 canvases.
- Result Home must never resume terminal gameplay: a win prepares the next level; a failure reconstructs the same seeded level. Preserve Next Level after success and Retry after failure.
- Screen polish must remain presentation-only. Do not dim/change gameplay roots or gem modulate from result UI, and do not move table/physics geometry.

## Infinite randomized-level guardrails v1

- A generated level must contain exactly eight unique identities from global catalog L1-L18 and exactly one identity for each local rank L1-L8. Never randomize simulation ranks independently from the saved mapping.
- All visual identity lookups must pass through `AssetCatalog`; physics and merging must remain local-rank-only. Never let artwork identity define radius, eligibility, reward, or containment.
- Launcher ranks remain local L1-L4. Targets remain three unique, strictly ascending local L5-L8 entries. Retry must preserve seed/configuration; only NEXT LEVEL may increment and generate a new configuration.
- Preserve forward-only flow: no level tree, previous-level action, or completed-level replay. Keep Home/Continue, Retry after failure, and NEXT LEVEL after success.

## Reference scale contrast guardrails v1

- Preserve active L1-L8 radii exactly as `30/33/36/39/42/45/48/51 px`; endpoint contrast is `1.70x`. The same centralized value must continue to drive live visual diameter and circular physics after perspective scaling.
- Do not make target status enlarge a live collider. A qualifying result follows the normal `1.20x` merge pop, leaves `pieces`/danger/merge occupancy, then its visual-only collection proxy uses `1.18x` uniform emphasis.
- The collection proxy must start from the exact live gem axis mapping (`diameter / texture.width`, `diameter / texture.height`). Do not return to a single `diameter / max_dimension` scalar, which made narrow textures shrink and change silhouette during collection.
- Keep the TARGET HUD slot at 80 x 80 and aspect-preserving. It is already larger than a normal board presentation and has no physics authority.
- Any future scale adjustment must compare normal same-tier art against the target-result/collection art, preserve the no-body-during-flight rule, and run the exact size, contact, containment, target-proxy, Level 1, UI, and motion suites.

This section supersedes the `36/38/40/42/44/46/48/50` size ladder below.

## Merge animation and active-tier size guardrails v1

- The v4 irregular color splash was explicitly rejected. Preserve the restored pre-v4 merge beat: `0.50 s` total, `0.10 s` pull, uniform `0.62 -> 1.20 -> 1.0` pop with damped settle, flash/ring/eight rays, and major `0.56 s` / `1.16x` emphasis. Do not reintroduce the filled splash or droplets.
- Live gem silhouettes remain rigid. Merge emphasis may use uniform child scale only; contact still causes no squash/stretch. Never write presentation scale, ray/ring geometry, or effect timing into a `GemPiece` or simulation decision.
- Preserve the exact L1-L8 base-radius ladder `36/38/40/42/44/46/48/50 px`. `GameConfig.GEM_COLLISION_RADIUS` must remain the single visual/physics authority; `GemSpriteLayer` derives visible diameter from it and `GemPiece` applies the same perspective scalar to collision radius. L9-L18 remain `42 px` until their levels are scoped.
- Alpha measurements are retained in `assets/runtime/gems18/calibrated/calibration_manifest.json`; runtime code must not scan pixels. Any future size change requires updated monotonic/visual-link/contact/containment tests and a calibration report.
- Preserve every other v4 behavior: target-only four coins, target check and centered fade handoff, continuous supplied music at `0.14`, one supplied target coin cue, push-guide removal, reward values, L5 -> L7 -> L8 order, launcher/danger/reset/result logic, and foreground layer ownership.

This section supersedes only the merge-splash and radius guardrails below.

## Reference animation and supplied-audio guardrails v4

- Preserve target order L5 -> L7 -> L8 and target-only rewards. Ordinary merges create one impact and tiered gem cue but zero coin records, zero currency, and zero coin sound. A qualifying target creates exactly four coin records and one supplied `coin_reward` cue.
- Merge presentation stays rigid and fast: total `0.34 s`, pull `0.08 s`, uniform `0.72 -> 1.12 -> 1.0` pop, `0.26 s` deterministic irregular color splash. Never restore contact deformation, non-uniform scale, rotation, lift, second wobble, ring, or ray sparks.
- Preserve coin count `4`, draw radius `17`, burst `0.22 s`, flights `1.58/1.66 s`, rank stagger `0.15 s`, compact radii `48/52`, foreground host, exact arrival reconciliation, and final-coin victory wait.
- Target collection stays `0.62 s`, opaque through 90%, with a `0.94 s` large green check. Target handoff is centered: hold delay `0.78 s`, outgoing fade `0.24 s`, gap `0.10 s`, incoming fade `0.24 s`, both positional offsets zero.
- Keep originals unchanged at `assets/sound/coin-sound.mp3` and `assets/sound/gem_merge_music_loop.wav`; runtime derivatives belong only under `assets/runtime/audio/`. Music is a dedicated continuous loop at `0.14` linear gain. Only the target-qualified event plays the supplied coin cue. Movement must never control music.
- Keep the earlier gem/contact/merge tones, three-player cap, thresholds, cooldowns, and sound-toggle boundary. Do not merge coin audio into the music asset or extract/reintroduce the mixed reference-video loop.
- Preserve the removed push guide, rigid gem artwork, table/rail geometry, physics constants, collision and merge rules, launcher flow, danger timing, reset cleanup, and isolated results. After related work, run all six suites, capture the six v4 proof states, export, and verify one standalone APK.
- Keep Android export exclusions for both `tools/*` and `build/*`; temporary analysis frames and logs under the git-ignored build directory must never inflate a delivery APK.


## Reference target reward correction guardrails v3

- The reference-video truth is target-only reward presentation: coin sequences occur near `14.6 s`, `46.6 s`, and `58.0 s`, each at a target event. Do not create coin records or change run coins for an ordinary merge.
- Keep `begin_merge_feedback()` impact-only and route the four coins only through `begin_target_coin_reward()` after controller target qualification. `GameController` owns the exact integer; HUD/effects only queue and reconcile arrival chunks.
- Preserve four coins, draw radius `14.5`, burst `0.38 s`, flight `1.70/1.75 s`, stagger `0.09 s`, compact radii `44/48`, foreground host layering, 32-record cap, and final-coin victory wait.
- No background player is active. `reference_music_loop.ogg` is a contaminated mixed derivative kept for provenance, not a runtime preload. Keep the 15 bounded gem tones, typed contact thresholds, cooldowns, three-player cap, sound toggle, and service-owned haptics. Add clean music/coin audio only from separate supplied files.
- Do not restore the vertical push/aim guide or its constants. Preserve the horizontal coral danger line and all authoritative table/rail/launcher/drag geometry.
- Preserve rigid silhouettes, L5 -> L7 -> L8 target order, target proxy/handoff, unlimited launcher, physics constants, contact-only merge rules, danger grace, reset cleanup, and isolated result overlay.
- After related changes, run gameplay-feel, clean-contact, Level 1, 18-gem, production UI, and motion-profile suites; capture ready/no-guide, ordinary/no-coins, and target/four-coins evidence; then export and verify a standalone APK.

This section supersedes the active-music, every-merge reward, and launcher-guide guardrails below.

## Reference audio and foreground reward guardrails v2

- This section supersedes the Reference Feedback Match audio/layering values below. Preserve Level 1 L5→L7→L8, rigid gem silhouettes, exact confirmed-event coins, four-token reward count, launcher flow, physics constants, and final-coin/hold/overlay order.
- Production audio is `AudioFeedbackService`: one continuously looping `assets/runtime/audio/reference_music_loop.ogg` plus 15 cached earlier gem one-shots. Movement/contact events may emit only their short tone; they must never start, stop, seek, or restart the music player. `ReferenceAudioFeedbackService` and its four Ogg event slices are inactive historical sources.
- Keep separate `coin_burst`, `coin_flight`, and `coin_collect` audio disabled. Coin arrivals may update the visible integer and final light haptic only. Preserve typed gem/wall thresholds, event cooldowns, three-player cap, toggle behavior, and service-only haptics.
- Every merge still creates exactly four ordered coin records. Preserve burst `0.38 s`, flight `1.70/1.75 s`, stagger `0.09 s`, radius `44/48`, draw radius `14.5`, exact integer reconciliation, and the 32-record cap.
- `GameplayEffectsLayer` must remain a child of `GameplayHudLayer.reward_foreground_host`; do not move coin or target travel back to the world canvas. Preserve local order HUD `0` < foreground `10` < target confirmation `20` < Pause `30`, with Results on CanvasLayer `50`.
- Target swaps reuse the two prebuilt foreground sprites. L5/L7 moves top-left while fading and L7/L8 enters from the right. Never allocate target-transition nodes during snapshot updates, count progress in HUD code, or restore the duplicate world `target_arrivals` burst.
- The push guide and danger line share `GameConfig.DANGER_LINE_COLOR`. Guide endpoints remain rail-derived and presentation-only.
- After changes here, run gameplay-feel, clean-contact, Level 1, 18-gem, production UI, and motion-profile suites; capture foreground coin/target evidence; export and verify a standalone APK. Phone listening/haptics require an attached device.

## Reference feedback match guardrails v1

- This section supersedes the older production-parity feedback guardrails below. Level 1 stays L5, L7, L8 with the L1-L4 unlimited queue and the existing final-coin/hold/overlay order.
- Gems must retain rigid silhouettes. Production collision routing must not call an impact transform. Merge presentation may use uniform scale only: no independent X/Y scale, rotation, lift, or kick. Physics roots and calibrated radii remain untouched.
- Every confirmed merge creates exactly four coin records. Preserve burst `0.38 s`, flight `1.70/1.75 s`, stagger `0.09 s`, radius `44/48`, draw radius `12.5`, ordered ranks `[0,1,2,3]`, exact integer reconciliation, and the 32-record safety cap.
- HUD and reward coins must share `assets/runtime/effects/coin_reward_reference_v2.png` through `AssetCatalog.COIN_REWARD`. Preserve the generated source under `assets/generated/`; artwork never owns currency or physics.
- Production audio is `ReferenceAudioFeedbackService` with four preloaded Ogg derivatives and no ambience. Do not restore procedural synthesis, the crystal/mallet/shaker loop, pitch variation, or separate coin burst/flight/collect sounds. Keep typed thresholds, cooldowns, three-player cap, and service-only haptics.
- Target collection is `0.84 s`, late fade begins at `0.78`, and the bounded arrival confirmation lasts `0.58 s`. Preserve the layer-40 `TargetRewardOverlay`; drawing this effect in the world layer hides it behind the target card. It cannot retain a physics body, alter targets early, or block reset cleanup.
- Preserve physics tuning exactly: launch `1160`, damping `185`, restitution `0.24/0.22/0.12` walls and `0.30` pieces, friction `0.07`, merge momentum/cap `0.62/420`, rails, radii, epsilons, and danger grace.
- After feedback changes, run gameplay-feel, clean-contact, Level 1, 18-gem, production UI, and motion-profile suites; capture rigid merge, four-coin cluster/flight, and target check evidence; then export and verify a standalone APK.

## Production gameplay parity final guardrails v1

- This section supersedes the older reference-coin and physics-feedback guardrails below. Preserve Level 1 objectives in order: L5, L7, L8; the L1-L4 mixed bag; unlimited launcher; confirmed-result collection; and final-coin/hold/overlay ordering.
- Preserve launch speed `1160`, damping `185` (safe `175-205`), sleep `9`, side/top/bottom restitution `0.24/0.22/0.12`, piece restitution `0.30` (safe `0.26-0.34`), approach-only tangent friction `0.07` (safe `0.05-0.10`), merge momentum `0.62`, and cap `420`. Do not change rails, radii, contact epsilon, merge rules, or danger timing as incidental feel work.
- Aim-guide endpoints must use `GameConfig.vertical_lane_top_y()` and the authoritative rail functions. Do not restore a fixed `board_top + offset` start, which escapes the narrow upper table at edge lanes.
- Keep impact and merge transforms on `GemSpriteLayer` presentation children. Contact normals are telemetry only. Never write animation offset/scale/rotation/z into `GemPiece`, its physics root, radii, velocity, merge candidates, or containment.
- Preserve `assets/buttons/ChatGPT Image Aug 4, 2026, 07_10_27 AM.png` as the untouched supplied source and `assets/runtime/effects/coin_reward.png` as its 256 px runtime derivative. HUD and reward flights must resolve the same `AssetCatalog.COIN_REWARD`; artwork never defines currency or physics.
- Reward cadence remains 10/14 records with a 56-record cap, `0.46 s` fan, `1.18/1.28 s` flights, and `0.065 s` rank stagger. Permuted ranks must keep the last record last so visible currency and the final haptic reconcile exactly.
- Audio truth is 18 cached one-shots plus one cached six-second rhythmic ambience loop. Keep the centralized production volumes, three-player cap, contact thresholds/cooldowns, sound toggle, and service-only haptics. On-phone loudness and vibration still require hardware verification.
- After gameplay work, run clean-contact, Level 1, gameplay-feel, 18-gem, production-UI, and motion-profile suites. Inspect the four real captures under `reports/production-gameplay-parity-final-v1/final-screenshots/`.

## Reference gameplay + coin parity guardrails v1

- The current player-facing currency is COINS. Preserve `GameController.coins` as the exact confirmed-event value and `score` only as a compatibility alias. Do not award currency from coin arrival, drawing, contact telemetry, HUD code, or sound.
- Treat `reports/reference-gameplay-parity-v1/final-screenshots/` as the current gameplay-feedback visual proof. COINS and NEXT are equal 154 x 132 cards; do not restore SCORE copy or the narrower pre-coin card that clips the glyph/value row.
- Preserve the bounded reward cadence: 10 normal / 14 major coins, 0.55-second burst, 1.18/1.32-second flights, 0.075-second stagger, and 56-record cap. If capping removes a record, its integer value must still reach the counter.
- The HUD counter intentionally lags authoritative coins until animated arrivals. Register the pending reward before the controller snapshot changes; restart/failure must clear pending effects and presentation totals atomically.
- Aim guide, merge scale, coin paths, counter pulse, and contact squash are presentation-only. Never feed them into `GemPiece`, `BoardSimulation`, `ContactMergeService`, table geometry, launcher input, danger timers, targets, or outcomes.
- Keep coin visuals and audio original/procedural. Do not copy frames, sprites, or sound from the supplied reference. Current audio cache truth is 18 one-shots plus the separate ambience.
- Final victory must wait for visible coin flights, then apply the existing hold, and present exactly one overlay. First-target L7 collection still advances only to L8.
- Level 1 expansion remains deferred. Preserve the L1-L4 mixed bag, unlimited launcher, sequential L7 then L8 targets, and the established physics constants/radii/rails.
- After work in this area, run all six suites and inspect `reports/reference-gameplay-parity-v1/final-screenshots/`; device feel, loudness, and haptics require a connected phone.

## Physics + reward feedback guardrails v1

- Level 1 length/progression was explicitly deferred. Do not change `LevelConfig.level_1()`: preserve its L1-L4 mixed bag, unlimited launcher, and sequential L7 then L8 objectives until the user begins creating other levels.
- Keep launch speed at 1160 and the calibrated table rails/radii/epsilons unchanged. Approved feel values are damping 210 (safe 190-230), sleep 9 (8-11), side/top/bottom restitution 0.20/0.16/0.10, true piece restitution 0.22 (0.18-0.28), and approach-only tangent friction 0.10 (0.06-0.14).
- Equal-mass contact must leave separating relative velocity. Do not restore the legacy `-relative_speed * restitution` impulse or apply tangent damping during resting overlap correction.
- Confirmed L6-L8 scores are 350/800/1,800. L6+ major feedback remains transient and bounded; never enlarge live visuals permanently or let reward scale affect radii, rails, collision, merge eligibility, target state, launcher timing, or score authority.
- Preserve cached-only procedural feedback: 15 one-shots plus one ambience stream initialized once. Contact telemetry stays typed, thresholded, cooled down, concurrency-capped, and presentation-only. The sound toggle controls both ambience and one-shots.
- After physics/reward/audio changes, run contact, gameplay-feel, Level 1, 18-gem, production UI, and motion-profile suites. Inspect the three captures under `reports/physics-reward-feedback-v1/` and complete the report's phone listening/haptic checklist when ADB hardware is available.

## Production UI polish guardrails v4

- Treat `reports/production-ui-polish-v4/final-screenshots/576x1312/details/screenshot-reproduction-score-1300.png` as the current portrait visual baseline and `1000x1280-wide/table-and-physics-centered.png` as the wide-canvas centering proof.
- MERGE PATH owns `MainRow`, shows all eight active Level 1 tiers, and uses 58 px silhouette-preserving slots. Do not restore circular frames/masks, alternate preview arrays, five-gem truncation, or independent UI gem artwork.
- SCORE/NEXT belong in `ScoreNextRow` below MERGE PATH. Preserve their equal 122 x 132 geometry and internal 16 px bottom breathing room; maximum formatted scores must remain contained.
- Pause and result outer panels are native simple `PanelContainer`s using `simple_popup_panel_style()`. Do not restore the oversized ornamental NinePatch outer cards that squeezed content.
- Wide-screen alignment is one shared world-coordinate vector. Never center the table sprite alone: rails, launcher, pieces, merge/collection records, effects, and debug contacts must move by the same `GameConfig.viewport_center_offset_x`.
- `configure_portrait_bottom()` intentionally resets X for deterministic legacy tests; production resize uses `configure_viewport(Vector2)`. Preserve unchanged table width/shape, perspective, radii, motion, collision, merge, target, score, reward, audio, and haptic behavior.
- After HUD/modal/viewport work, run all six suites and the ANGLE capture, including the 1000 x 1280 wide proof.

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

## HUD alignment invariant - 2026-08-08
For `gameplay_hud_layer.gd`, do not remove the horizontal `SIZE_EXPAND_FILL` flags from TopHudColumn, UtilityRow, StatusRow, GameplayObjectiveStack, ProgressionCenter, or TargetSlot. They are required for correct Coins-left / Next-right / Level-left / Settings-right distribution and for centering progression + Target over the table. `TARGET_TABLE_GAP` is 28 design pixels to keep the Fancy glass shadow clear of the table frame.

### 2026-08-08 HUD alignment lesson
For dynamically-created gameplay HUD containers, keep `SafeHudMargin` and `GameplayObjectiveAnchor` explicitly 720 logical pixels wide. Apply device safe-area padding as MarginContainer theme margins inside that width. This ensures spacer-based left/right rows and CenterContainers resolve against the complete design canvas instead of collapsing to their minimum child width.

## 2026-08-09 UI flow note — Home / level preview / settings

Do not wire Home PLAY directly to gameplay in future edits. `HomeOverlayLayer` first presents `LevelIntroPanel`; only its START GAME action emits `play_requested`. The level preview is presentation-only and consumes `hud_snapshot()` data supplied by `GameController`.

Home settings and pause settings must stay on the same persistence path: both emit Music/Sound/Vibration signals to `GameController`, which updates audio/haptics services and calls `GameSettingsService.save_settings()`. Do not add a second settings store inside either UI layer.

For settings controls, use the `SettingsSwitch` toggle Button variation with ON/OFF text. Do not revert to unstyled `CheckButton` widgets, which previously rendered as cramped/default-looking controls inside the glass modal.


- Branding hotfix: Home now uses `assets/runtime/gem-aim-logo.png`, Android/game icon now uses `assets/runtime/gem-aim-icon.png`, settings icon was switched to a crisp PNG derivative, and the home tagline size was increased for readability.
# AI Knowledge Addendum - 2026-08-11 AdMob Integration v1

- Keep production ad-unit IDs only in `scripts/ad_config.gd`: `INTERSTITIAL_AD_UNIT_ID` and `REWARDED_AD_UNIT_ID`. Never paste production units into controllers, scenes, reports, or the manager.
- Debug builds must continue using Google's Android test units. Do not test production units or replace the AdMob application ID without explicit authorization.
- `AdManager` is the sole owner of SDK initialization, loaders, readiness, fullscreen callbacks, retry/reload, and consumed-ad destruction. Never create ad objects in UI or gameplay code.
- Interstitial eligibility is a completed-level transition rule: positive level number divisible by `AdConfig.INTERSTITIAL_LEVEL_INTERVAL`. Do not trigger ads from Pause, Settings, failure, Retry, launch, merge, or target events.
- A rewarded bonus is valid only after `OnUserEarnedRewardListener`. Load, show, impression, resume, dismissal, or button press cannot award currency. Preserve both exactly-once guards.
- Result UI may display readiness and suppress pending taps, but currency and level progression remain controller-owned. Unavailable/early-close/failure must always restore or continue the normal Collect path.
- After plugin/API upgrades, rerun the focused suite and validate the Android merged manifest, test-ad rendering, earned callback, early close, interstitial cadence, process background/resume, and post-consumption reload on a device.
# AI Knowledge Addendum — Post-AdMob Reward and Size Fix

- Never advance from Collect or rewarded dismissal. Resolve the reward in-place, expose `NEXT LEVEL`, and require a separate press.
- Only `OnUserEarnedRewardListener` may grant the one bonus copy. Preserve manager session guards, controller reward guards, and the overlay's immediate double-tap guard.
- Early close/unavailable/show failure must grant zero, clear the pending result action, preserve Collect, and allow a safe retry when readiness returns.
- Interstitial cadence belongs to explicit completed-level departure after reward resolution. It must never run from the rewarded callback or during the reward-total animation.
- The next generated level is paused behind `HomeOverlayLayer.present_level_intro()` until Play. Do not resume gameplay from Next Level itself.
- Android application ID authority is `export_presets.cfg` and must remain `com.owais.majestygems`.
- Keep `gradle_build/compress_native_libraries=true`, arm64 as the only production ABI, and the focused AdMob export exclusions. Do not restore sample translation registration or optional ICU/sample/editor payloads.
- Do not remove required Poing bridges, Google Mobile Ads SDK/transitives, or runtime GDScript API classes to chase size.
# 2026-08-12 - Game-flow/reward/splash guardrails

- Never restore a post-reward `NEXT LEVEL` button, signal, or resolved confirmation state. Reward animation completion owns automatic departure to optional interstitial and then Level Ready.
- Home PLAY must emit a request to `GameController`; the controller changes to `LEVEL_READY`, reveals the gameplay surface, and asks `HomeOverlayLayer` to show only the Level Ready modal. Do not show that modal over the Home backdrop/logo.
- START GAME is the only Level Ready -> PLAYING action. Rewarded/interstitial dismissal, Android resume, Home PLAY, and reward animation must not unpause gameplay.
- Keep earned-callback currency authority separate from rewarded presentation. Persist the bonus exactly once at earned callback; begin x2 animation only from rewarded finished/dismissed after returning to the surviving Level Complete popup.
- Collect/Double lock immediately. On failure/early close, restore the same Level Complete choices and `LEVEL_COMPLETE` state with no bonus or navigation.
- `GameplayHudLayer` completion count-up is visual reconciliation only. Controller/save integers remain authoritative and must never be incremented from tween callbacks.
- Interstitial cadence remains positive even levels only and starts after reward feedback. Unavailable inventory must fail open directly to Level Ready.
- Preserve `StartupSplashLayer` as the only custom startup phase: existing contained Majestic logo, Majestic blue, 1.05-second hold, 0.20-second fade. Keep Android Godot boot splash disabled and native system colors/icon matched as closely as Android allows.

## Splash and reward UI correction - 2026-08-12

- The `StartupSplashLayer` rule above is superseded: that module is deleted. Mobile startup must use the existing `HomeOverlayLayer` tree, background, and logo, with Home controls temporarily hidden and then revealed.
- The authoritative shared startup/Home background is `assets/runtime/backgrounds/level_bg_1.png`, resolved by `AssetCatalog.background_texture(0)`. It must remain centered aspect-cover; never stretch, letterbox, or substitute a solid-color custom splash.
- Result reward icons must be `CoinIcon`, which renders the same `AssetCatalog.COIN_REWARD` texture as the gameplay coin HUD. Do not introduce emoji or a second coin asset.
- Keep result animation presentation-only. `GameController` remains the authority for persisted totals, exactly-once rewarded bonuses, ad completion, and next-level transition.

## Single splash correction - 2026-08-12

- Do not recreate `startup_intro`, a logo-only Home state, `StartupSplashLayer`, or any other timed in-app startup phase. Android system splash must transition directly to complete Home.
- Keep `splash_screen/disable_godot_boot_splash=true` for Android.
- Android 12+ native splash supports an opaque color and constrained icon, not a full-screen cover/cropped bitmap. Never claim the Home background can be placed there cross-version; doing so requires a second in-app splash and violates the one-splash requirement.
- Package ID stays `com.owais.majestygems`; AdMob App ID, test/production unit selection, saves, gameplay, physics, collision, merges, targets, difficulty, table/background/HUD layout, audio, and haptics are out of scope.
# 2026-08-12 — Poing UMP patch maintenance guardrails

- The project intentionally carries a local patch against Poing v5.0.0. Before any Poing upgrade, inspect whether upstream native and GDScript `ConsentInformation` expose `canRequestAds()`; remove the local patch if upstream owns the capability.
- Never replace `_can_request_ads_authoritatively()` with consent-status inference. Google UMP can retain a valid previous-session decision after an update failure.
- Never call `MobileAds.initialize()` or an ad loader directly from consent callbacks. All callbacks converge on `_refresh_ad_request_permission()` and `_start_mobile_ads_once()`.
- Keep `UMP_DEBUG_GEOGRAPHY` disabled normally. Release helper functions must continue returning disabled geography and no test-device IDs.
- Privacy Policy is always available in Settings. Privacy Options is UMP-owned and visible only for `PrivacyOptionsRequirementStatus.REQUIRED`; do not build a custom consent popup.
- Native reapplication steps, artifact hashes, tests, and manual dashboard requirements are in `reports/POING_UMP_CAN_REQUEST_ADS_PATCH.md`.
# 2026-08-16 knowledge note — responsive reference UI and gem scale

- Do not restore a gameplay Level box. The approved top order is Coins / centered Target / Next + Settings, with equal side-slot widths so Target remains centered.
- Keep all eight mapped gems in the bottom-safe progression panel. It reads controller snapshots only and must never own level or merge logic.
- For portrait layout changes, update the centralized `GameConfig` table transform; never move the texture independently from rails, bounds, launcher, danger line, or perspective calculations.
- Active L1-L8 radii are `36/39/42/45/48/51/54/57 px`. Preserve strict monotonic growth, identical visual/collider authority, and the 57/36 bounded endpoint unless a later gameplay-calibration task explicitly supersedes it.
- The focused guard is `tests/run_ui_scale_layout_tests.gd`; it covers eight viewport/cutout cases, table containment, all eight progression icons, texture resolution, Level removal, and Target/path centering.
# 2026-08-16 - Sound mapping correction v2 guardrails

- The only active newly supplied replacements are gem contact `gems-colide.mp3`, rail contact `gems-rail-colide.mp3`, ordinary merge `merge-target.mp3`, UI tap `mixkit-on-or-off-light-switch-tap-2585.wav`, and final success `merge-basic.mp3`.
- Target-producing merge, chain, target arrival, launch/push, and coin retain their prior identities. Do not route the supplied sparkle, flute, or success-alert files unless a later request explicitly re-enables them. Objective completion has no separate sound and lose/game-over has no audio route.
- Current linear gains: music `0.06`, gem `0.34`, rail `0.39`, ordinary merge `0.70`, UI `0.32`, final success `0.84`, coin `1.0`; tier/chain/arrival procedural gains remain defined in `GameConfig`.
- Preserve 65/90 ms contact cooldowns, `0.96..1.04` / `0.97..1.03` pitch ranges, exact merge-pair collision suppression, the five-voice priority pool, Music/SFX buses, and limiter.
# 2026-08-16 - Sound mapping correction v2 guardrails

- The only active newly supplied replacements are gem contact `gems-colide.mp3`, rail contact `gems-rail-colide.mp3`, ordinary merge `merge-target.mp3`, UI tap `mixkit-on-or-off-light-switch-tap-2585.wav`, and final success `merge-basic.mp3`.
- Target-producing merge, chain, target arrival, launch/push, and coin retain their prior identities. Do not route the supplied sparkle, flute, or success-alert files unless a later request explicitly re-enables them. Objective completion has no separate sound and lose/game-over has no audio route.
- Current linear gains: music `0.06`, gem `0.34`, rail `0.39`, ordinary merge `0.70`, UI `0.32`, final success `0.84`, coin `1.0`; tier/chain/arrival procedural gains remain defined in `GameConfig`.
- Preserve 65/90 ms contact cooldowns, `0.96..1.04` / `0.97..1.03` pitch ranges, exact merge-pair collision suppression, the five-voice priority pool, Music/SFX buses, and limiter.
# 2026-08-16 - Immediate merge-sound synchronization v3 guardrails

- `assets/sound/merge-target.mp3` has `0.523125 s` measured leading silence. Keep it untouched; production must use `assets/runtime/audio/merge-target-immediate.ogg` for the approved `normal_merge` mapping.
- The runtime derivative trims `0.515 s` and has about `0.008042 s` of silence before the audible attack. Do not restore the untrimmed runtime mapping or add a timer/animation delay workaround.
- Emit merge audio immediately after confirmed result classification and before presentation setup. It must remain downstream of merge resolution and must never influence physics, eligibility, result IDs, targets, or animation timing.
- Preserve v2 mappings/gains, exact-pair collision suppression, cooldowns, pitch ranges, five-voice pool, Music/SFX buses, limiter, and no-lose route.
# 2026-08-16 - Immediate merge-sound synchronization v3 guardrails

- `assets/sound/merge-target.mp3` has `0.523125 s` measured leading silence. Keep it untouched; production must use `assets/runtime/audio/merge-target-immediate.ogg` for the approved `normal_merge` mapping.
- The runtime derivative trims `0.515 s` and has about `0.008042 s` of silence before the audible attack. Do not restore the untrimmed runtime mapping or add a timer/animation delay workaround.
- Emit merge audio immediately after confirmed result classification and before presentation setup. It must remain downstream of merge resolution and must never influence physics, eligibility, result IDs, targets, or animation timing.
- Preserve v2 mappings/gains, exact-pair collision suppression, cooldowns, pitch ranges, five-voice pool, Music/SFX buses, limiter, and no-lose route.
# 2026-08-17 - Android release versionCode guardrail

- Current persisted Android release code is `3`. VersionCode `2` has already been used in Google Play and must never be exported as a new release again.
- Before any release APK/AAB build, inspect `BUILD_MANIFEST.md` for the highest delivered Play versionCode, set `export_presets.cfg` `version/code` to a strictly higher integer, commit/persist that value before Gradle export, and record it with the artifact afterward.
- Do not reset the preset to an older code after export. Package `com.owais.majestygems`, versionName `1.0.1`, production signing, AdMob/UMP, and all gameplay remain independent of this monotonic code.
