# Player Feedback and Limited-Shots Repair - 2026-08-31

- Try Again now uses the controller's fail reason: giving up after an exhausted shot budget says `YOU RAN OUT OF SHOTS`; danger-line failures retain the danger copy.
- Daily Treasure opens into a persistent `YOU RECEIVED` row with staged Switch, Magnet, and Hammer icons/counts matching the already-saved payout.
- Bomb/Hammer cinematics last 1.65 seconds and visibly brace/shake over the tapped gem before `impact_reached` applies the staged effect; any tap may still skip directly to impact.
- The shard array, per-frame shard physics, and shard drawing path are removed. Merge feedback now uses 3-6 delayed colored wavefronts and 12-30 bounded rays plus the existing tier core.
- Home Level/Coins cards now carry edge diamonds. The redundant `CURRENT LEVEL` and idle `Tap to view today's missions` copy are gone; claim-ready text remains, and a 20px spacer separates missions from the status row.
- Limited-shot levels now ask for one L6 and one L7 target, never L8 or repeated quantities, and always grant at least 24 shots. Normal target scaling is unchanged.
- Focused parse and four behavior suites pass. The Windows runner still returns its known post-PASS access violation in some suites; assertions complete first.

# Final HUD, VFX, Power, and Audio Test Candidate - 2026-08-30

- The reported limited-shots composition is corrected: Counter/Target/merge path now ends above the table at 720x1280, 720x1600, and 1080x2340; the counter moves upward into unused centre-top space rather than dragging the objective stack onto the board.
- The temporary mission/ad-grant banner now floats just inside the upper table, input-transparent, because the persistent limited-shots readouts occupy the centre-top band; it no longer covers Shots or Target.
- Four 92px power tiles remain below the playable table. Their buttons no longer intercept aiming/pushing gestures, including the 720x1280 limited-shots layout captured in `reports/powers-v1/screenshots/limited-shots-720x1280.png`.
- Merge feedback now changes continuously with result tier and exact gem color. L1-L8 scale from 0.92x to 1.34x, spark/shard counts rise within hard caps, and high tiers receive a bounded white-hot core. The existing simulation, contact eligibility, result tier, and timing remain unchanged.
- Power cinematics are 1.08s and skippable. Bomb/Hammer flashes and debris are brighter than Magnet/Switch; supplied per-power cues replace procedural placeholders. The incomplete Claude edit that removed repeating targeted-power guidance was reconciled, so `TAP ON GEM` repeats every 1.35s while armed.
- FFmpeg 9.0.1 is installed. Runtime power/result cues are trimmed, audio-only stereo 48kHz Vorbis: Bomb 1.70s, Hammer 1.05s, Magnet 0.56s, Switch 1.76s, Level Complete 2.85s. Originals and source hashes are preserved.
- Collision sound uses strongest-first selection (maximum three candidates per frame) plus a maximum of three simultaneous contact voices inside the existing five-voice priority pool. Merge pairs remain suppressed and reward/power/result cues retain priority.
- FFmpeg installation, complete regressions, APK packaging, and final artifact metadata are recorded in the task report and `BUILD_MANIFEST.md`.

# Ad Popup Removal, Top Banner, HUD Decorators - 2026-08-30

- A completed rewarded ad no longer opens a result popup. The offer closes and the grant is announced in the shared top banner. The popup remains only for a failed or cancelled video.
- `PowerOverlayLayer.close()` releases input immediately and schedules hiding unconditionally, so a killed or stalled tween can no longer leave a modal stuck on screen.
- The mission/reward banner sits at the top of the screen, is 536x84, and is shared by mission completions and ad grants. It clears the shots counter, target panel, and power row; it briefly overlays the coin card by design.
- Target, gem-sequence, and NEXT panels carry two 30px kit diamonds straddling their left and right borders, added through a plain `Control` overlay because `PanelContainer` overrides direct children's anchors.
- Home: larger logo, smaller secondary-pill SHOP button beneath PLAY, and the kit `icon_gear` for settings on Home and the HUD.
- In the Godot editor there is no ad fill, so rewarded attempts always take the failure path; this is expected and not a defect.
- 19/19 regression suites pass with zero script errors.

# Mission Notification and Shop Icon Removal - 2026-08-30

- Completing a daily mission during play shows a non-blocking banner inside the top of the table, animated in and out over 2.6s and driven by an explicit delta timeline from the controller's `_process` (not a Tween, which does not advance inside a SubViewport).
- The banner never covers the coin count, shots counter, target panel, NEXT card, or the power row; `run_mission_notification_v1_tests` asserts this by rect intersection.
- `mission_complete` is now a real audio event sitting between combo and target-complete in both volume and voice priority, completing the reward hierarchy.
- Completion during play logs `daily_mission_earned`; `daily_mission_completed` still means "claimed" and is unchanged.
- The Home SHOP button is caption-only. `icon_shop.png` is removed from the runtime kit and the preparation script; the supplied original is preserved.
- 19/19 regression suites pass with zero script errors.

# Level Difficulty V1 - 2026-08-29

- Generated levels no longer start on an empty table. From level 2 onward a seeded, staggered opening cluster is placed, so horizontal aiming matters and a level can no longer be cleared by pushing gems up one line. Rows cap at 4, only spawnable tiers are placed, and the lowest row stays 250px above the danger line.
- Opening-board density keeps rising after the row cap: two gaps per row below level 12, one gap from 12 on. Layouts are seeded from the level seed, so a retry presents the identical puzzle.
- Limited-shots levels now begin at level 4 (previously 10) and recur every 3 levels, never back to back. Shots tighten from 40 by 2 per limited level to a floor of 30 (raised from 26).
- Target quantities scale with level to a cap of 3x tier 6 and 2x tier 7; the top tier stays at 1.
- Solvability without powers is enforced by `run_level_difficulty_v1_tests` for every limited level from 4 to 60, including a check that `total_target_quantity()` matches the generated `target_sequence`.
- `scripts/dev/print_level_curve.gd` prints the curve as data for balance review. Developer aid only; nothing loads it at runtime.
- 18/18 regression suites pass with zero script errors. Device playtesting of the tightest levels (19+) is still outstanding.

# Nine-Patch Distortion Fix and Kit Re-Authoring - 2026-08-29

The "stretched assets" defect is fixed at its source. Measurement showed the supplied plates have a safely-stretchable vertical band only 2-5px tall - they are a continuous bevel with a specular highlight, so the old margins were squashing ~77px of bevel into ~28px on every button. Every plate is now authored at the exact height it is drawn at, making the vertical nine-patch scale exactly 1.0, and horizontal margins are derived from silhouette shape rather than colour uniformity.

Button geometry is now a contract: `UiDesignSystem.BUTTON_HEIGHT` (96), `HERO_BUTTON_HEIGHT` (116), `BANNER_HEIGHT` (92), backed by `UiKit.DRAWN_HEIGHT`. A regression walks every button on every screen and fails when a control is shorter than its plate's caps; it found six additional crushed buttons across the settings, level-intro, and exit dialogs that had been shipping distorted.

Daily-mission cards now carry the reference's per-card jewel hues (magenta, blue, amber) with brass rims, and padding was corrected throughout - card contents had been running into their own artwork frame.

All fifteen Godot regression suites pass.

# Give Up Fix, Readable Type, Level Briefings, Shots Counter - 2026-08-29

Declining the out-of-shots rescue now actually reaches the fail screen. `present()`'s double-presentation guard had been treating rescue mode as "already visible", so GIVE UP did nothing while the level had already failed underneath; because the rescue screen carries no Skip button, that also explains Skip appearing unavailable on limited-shots levels.

Typography is readable: the shared UI face dropped from ExtraBold to SemiBold with weight reserved for numbers and headings, and the body/small/caption steps each moved up. Button plates gained padding and height while the button face dropped a step, so long captions clear the ornamental caps.

The limited-shots counter is now a framed panel at the top of the centred objective stack, matching the Target panel, with a score-sized count that pulses on change and turns coral when low. Starting a level type for the first time opens a briefing explaining that type; it is recorded per type in a new `tutorial/seen_level_types` save section and never shown again.

All fifteen Godot regression suites pass, including new coverage for the briefing rules, counter placement, and a viewport-overflow guard. Still no device pass and no Android artifact for this work.

# UI Interaction Polish - 2026-08-29

Button states now use one silhouette per family and vary only by tint, which removes the plate-morphing that made hover and press look broken (the secondary pill grew gem caps on hover; the settings gear became swap arrows). Hierarchy is explicit: green for affirmative, gem plate for primary and paid actions, recessed plain plate for navigation. Disabled controls keep their silhouette and use luma-desaturated derivatives.

Every modal - Level Complete, Try Again, Out of Shots, Daily Missions, Settings - now announces itself with the same gold ribbon. The result overlay lost a stray separator hairline and its placeholder "!" fail badge, and its reward copy uses the shared type scale.

`ScreenTransitionLayer` (layer 90) turns Home <-> gameplay into a reveal instead of a cut. Its state swap is synchronous by contract; only the reveal animates, so callers can still read `app_flow_state` immediately after navigating. The daily-missions popup has a real entrance and exit, and a confirmed claim kicks the card and floats its coin value - fired only after the reward is persisted.

Two rendering faults were found and fixed via the proof sheet: disabled plates were referenced before being imported (drawing nothing at all), and the capture harness reported PASS over blank screenshots when the controller script failed to load. Both are now covered by `tests/run_ui_kit_polish_v1_tests.gd`. All fourteen Godot regression suites pass.

# Majestic UI Kit V1 - 2026-08-29

Every screen and popup now renders with the supplied art kit and typefaces. Nunito Sans (weights 800/1000) carries all UI copy and Cinzel Black carries the brand tagline; the type scale rose from 18 to 25 canvas units for body copy, with a theme-wide dark outline. The shared border token is brass rather than violet, matching the artwork's rims. Six supplied sheets were sliced into 37 runtime assets under `assets/runtime/ui/kit/`, wrapped by `scripts/ui/ui_kit.gd`, with originals preserved under `assets/ui_kit_source/`.

Home gained a daily-missions summary card (today's three badges plus progress) and a hero PLAY plate. The daily-missions popup was rebuilt with a ribbon header, per-mission cards, and a chest row. Result overlay actions are stacked vertically because the kit's wide ornamental caps overflow a shared row at 720px. Settings ON now reads green.

Four defects in the previous retention/daily-missions work are fixed: daily progress was never persisted (aliased service state defeated the change check), a failed save consumed a mission without paying it, the daily popup opened behind Home and was invisible, and the out-of-shots screen permanently relabelled Home to "GIVE UP". `tests/run_retention_daily_missions_v2_tests.gd` covers all four. `run_firebase_analytics_pipeline_tests`, left red by the earlier `SKIP_LEVEL_COST` 200 -> 800 change, is repaired and now cost-agnostic. All thirteen Godot regression suites pass. See `reports/MAJESTIC_UI_KIT_V1_REPORT.md`.

No Android artifact was produced and no device was available in this task, so nothing is recorded in `BUILD_MANIFEST.md` for this pass; the UI change is broad and warrants device verification before a release candidate.

# Skip Level and Current Gem Reroll Redesign - 2026-08-28

Reference refinement V2 supersedes the earlier circular/dice treatment: Switch Gem is now a high-contrast 112 px purple squircle with a large white clockwise-arrows glyph, intentionally seated across the table's lower frame. Next is reduced from `141.075x172` to `128x150`, its gem from 54 to 48 px, and the Settings gap from 8 to 12 px so those controls remain visually separate. See `reports/COIN_SINK_VISIBILITY_NEXT_SPACING_V2_REPORT.md`.

UI placement correction: live gameplay now exposes only one prominent 112 px circular `SWITCH GEM` control below the uniformly lifted table. Skip Level is confined to Level Ready, Pause, and Failed overlays, where its 200-coin price is explicit, and remains absent from successful Level Complete. Both actions use curated @icons runtime SVGs; the 5.7 MB editor addon and picker remain export-excluded. This supersedes the earlier two-live-button description below. See `reports/COIN_SINK_UI_POLISH_V1_REPORT.md`.

A second V1 coin sink, Skip Level (`GameConfig.SKIP_LEVEL_COST` = 200 coins), jumps directly to the next level with no win screen, reward, or interstitial — a save-atomic, double-tap-locked paid escape hatch alongside the existing reroll. The reroll itself changes the tier of the currently aimable launcher gem in place; `GemSpriteLayer` re-syncs its texture/radius/shadow automatically. Switch Gem is the sole live circular action, while Skip is placed in Level Ready, Pause, and Failed overlays with its explicit price. See `ECONOMY.md`.

A Google Play Games Services v2 integration (sign-in, achievements, daily streak, local reminder notification) was built and device-tested in this same session, then fully removed at the user's request — no PlayGames/Streak code, autoloads, manifest entries, or Gradle dependencies remain. It is queued in `POST_LAUNCH_ROADMAP.md` as a future dedicated pass rather than left half-integrated.

# Final Pre-Launch Production Readiness Candidate - 2026-08-28

On-device validation superseded the versionCode-13 candidate before Play upload: Firebase automatic first-open/session data uploaded successfully, but Godot registered the `FirebaseAnalytics` singleton without its callable `logEvent` method. The Java plugin now explicitly lists `logEvent` through `getPluginMethods()` in addition to `@UsedByGodot`. The repaired release identity is versionCode 14 / versionName 1.0.12; 13 / 1.0.11 must not be uploaded.

The versionCode-14 candidate was locally validated (Bundletool, manifest, DEX, signature) but **device testing, performed with explicit user authorization, proved the fix did not work**: the same `Firebase singleton exists but logEvent is unavailable` warning reproduced on the authorized V2149 phone. versionCode 14 / versionName 1.0.12 is superseded and must not be uploaded, alongside 13 / 1.0.11.

Decompiling the bundled Godot Android plugin runtime (`GodotPlugin.class` inside `godot-lib.template_release.aar`) showed `logEvent` was in fact natively registered in both builds; the real defect is that `Object.has_method("logEvent")` on the JNI-backed native singleton unreliably returns `false` even when the method is registered and callable. `scripts/services/analytics_service.gd` no longer gates on `has_method()`; it now trusts `Engine.has_singleton()` plus the actual call's accept/reject result. The repaired release identity is versionCode 15 / versionName 1.0.13.

The versionCode-15 / versionName-1.0.13 AAB (`build/android/majestic-gems-production-candidate-v1.0.13-vc15.aab`) is exported, Bundletool/manifest/signature-validated, and **device-verified with explicit user authorization**: reinstalled on the same V2149, launched, and pressed Start. Logcat confirms `MajestyAnalytics: Forwarded custom event to Firebase: level_start`, and Firebase's own `FA-SVC` module logged `origin=app,name=level_start` with correct gameplay parameters (`pattern`, `coin_balance`, `attempt_number`, `level_number`) — the first candidate proven to forward custom events end to end. The device was left with the app uninstalled afterward. Full evidence is in `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md` and `BUILD_MANIFEST.md`.

The source candidate now includes one production-safe coin sink: a 100-coin Next Gem reroll inside the existing Next card. It deterministically selects a different valid L1-L4 entry from the current level's weighted launcher sequence, persists banked spending before committing UI/game state, cannot be double-spent by rapid taps, and cannot be refunded by Retry. It changes no active gem, target, physics, collision, merge, or later queue rule.

Analytics now cover true attempts/shots, Retry, bounded coin earnings/spending, requested/shown/completed/failed rewarded flow, and requested/shown/failed interstitial flow. Shown events still originate only from SDK shown callbacks; earned completion still originates only from the official earned callback. Existing UMP, production ad IDs, privacy link, dual ARM export, save clamping, audio ownership, and gameplay mechanics remain intact. Bundle validation of `1.0.11 (13)` passed, but real-device custom-event validation failed and superseded it. The repaired `1.0.12 (14)` identity is committed before its replacement export. Full evidence is in `reports/FINAL_PRELAUNCH_PRODUCTION_READINESS_REPORT.md` and `BUILD_MANIFEST.md`.

# Firebase Custom Gameplay Analytics Pipeline v1 - 2026-08-27

- `Analytics` remains registered in `project.godot`. Its facade now validates Firebase-compatible names and primitive parameters, reports service/native availability, emits an observable request boundary for tests, calls the exact native `logEvent` method, and records the returned acceptance status.
- The Android bridge initializes Firebase lazily as well as at construction, so early Activity ordering cannot permanently remove the custom-event path. It logs registration, forwarding, JSON rejection, and Firebase exceptions and returns success/failure to GDScript.
- Live controller hooks now provide `level_number`, generated pattern, mapped gem identity/local type, target involvement/index, earned coins, and danger fail reason. Run-end and run-start guards prevent duplicate start/complete/fail events; Retry now emits its own real `level_start`.
- Interstitial/rewarded shown events moved from the pre-`show()` request to the Poing SDK `on_ad_showed_full_screen_content` callback. Rewarded completion remains exactly-once at `OnUserEarnedRewardListener`.
- The user-supplied opaque 512x512 logo is preserved as `assets/logo/majestic_gems_logo_with_background_source_v5.png` and replaces the retired opaque presentation reference for launcher/native-splash derivatives. The active transparent Home/fallback `majestic_gems_logo_v4.png` is unchanged.
- The next release identity is persisted as versionCode 12 / versionName 1.0.10. Code 11 / 1.0.9 is skipped because a prior local AAB already used that identity, even though the latest delivered record is code 10 / 1.0.8.
- The final signed AAB is `build/android/majestic-gems-firebase-analytics-pipeline-v1.0.10-vc12.aab`; Bundletool, manifest, DEX, packaged-bytecode, archive, and upload-certificate validation passed. No ADB device was connected, so DebugView remains separately unverified and does not block delivery.

# Current State Addendum - Target Achieved and Combo Readability V1

Confirmed target collection now reads `ACHIEVED 1 / 1` in the existing compact HUD and produces a literal `TARGET ACHIEVED` board label during the genuine target reward sequence. Combo labels remain visible for 1.10 seconds and target-achieved labels for 1.40 seconds, improving readability at low frame rates without changing simulation, merge eligibility, target qualification, coins, physics, or layout. Local replay screenshots and capture logs remain ignored review artifacts. See `reports/TARGET_ACHIEVED_COMBO_READABILITY_V1_REPORT.md`.

# Current State Addendum - HUD Panel Flattening V1

# Current State Addendum - Majestic Branding Refresh v1.0.7

The active Home/fallback logo, legacy launcher icon, adaptive icon pair, and Android system-splash icon now derive from the two supplied v3 root branding images, preserved under `assets/logo/`. The old active v2 logo/icon derivatives are removed. Home now displays the exact tagline `A Majestic World of Gems`. Package `com.owais.majestygems`, signing, AdMob identifiers, version `9 (1.0.7)`, and gameplay remain unchanged.

Next now uses a direct label inside its one outer card; Home/Pause settings rows no longer each create a glass panel; and Result reward data is grouped directly in the modal instead of inside another card. All remaining panel surfaces are intentional top-level cards, modals, or distinct status elements. Responsive HUD, game-flow, and privacy tests pass. See `reports/HUD_PANEL_FLATTENING_V1_REPORT.md`.

# Current State Addendum - HUD and Popup Simplification V1

The UI now uses a single restrained dark-amethyst surface per visual unit: the shared white gloss layer is removed, HUD Coins is icon-plus-value only, and Target is a compact 340x84 single panel with gem, target index, and numeric quantity only. The Target badge, nested target surface, and progress bar are gone. Gameplay Settings is now one 64px framed button, Home Settings has no separate glass cog frame, and redundant popup decoration/copy was removed while actions and safe-area behavior remain unchanged. Focused HUD, game-flow, feel, and privacy tests pass. See `reports/HUD_UI_SIMPLIFICATION_V1_REPORT.md`.

# Current State Addendum - HUD Density and Collision Stability V1

Gameplay HUD anchors and panel dimensions remain unchanged, but the fixed eight-gem progression strip now uses 56 px artwork so adjacent silhouettes and arrows have clear breathing room. The in-game settings cog now fits its existing 64 px utility frame instead of its former 88 px child minimum overflowing the frame. Dark-amethyst styling and the no-box-shadow rule remain intact.

Crowded board contact now uses three bounded pair-separation sweeps per simulation substep. Only the first captures contact/telemetry; the remaining two are physics-only, eliminating residual gem overlap without duplicate merge or audio events. Focused reference-feel, responsive HUD, and gem-pattern tests pass. No Android export or device test was run for this source-only polish milestone. See `reports/HUD_DENSITY_COLLISION_STABILITY_V1_REPORT.md`.

# Current State Addendum - Complete Majestic Logo Refresh v1.0.8

All active Home, fallback boot, launcher, adaptive-icon, and Android system-splash paths now use derivatives of `assets/logo/majestic_gems_logo_source_v2.png`. The obsolete v1 Majestic source/logo/launcher/adaptive assets and old system-splash derivative were removed. Signed AAB `build/android/majestic-gems-logo-refresh-v1.0.8-vc10.aab` is versionCode 10 / versionName 1.0.8; Bundletool confirms the v3 splash asset is packaged and no old Majestic v1 or splash-v2 asset is present. Branding and splash-flow tests pass; no device was connected.

# Current State Addendum - Android Targeting and Launcher Branding v1.0.7

The signed Android App Bundle `build/android/majestic-gems-android-targeting-icons-v1.0.7-vc9.aab` is ready for Play upload as versionCode 9 / versionName 1.0.7. The persistent Gradle-template manifest now requires `android.hardware.touchscreen`; the final merged AAB manifest confirms that requirement alongside unchanged package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, portrait orientation, tablet support, and game category. It contains no Leanback, Automotive, Wear, or XR declarations.

Launcher branding now derives from the supplied transparent `assets/logo/majestic_gems_logo_source_v2.png` (1254x1254). Godot's persistent launcher-icon preset references the generated 192px legacy icon and 432px adaptive foreground/background pair under `assets/runtime/ui/`. The foreground preserves the complete logo within a 288px mask-safe square; the adaptive background uses the existing dark-amethyst brand color. The final AAB has dual ARM libraries and no packaged tests/reports/dev scripts. Branding and responsive phone/tall-phone/tablet layout regressions pass; no Android device was connected, so installation and physical launcher-mask checks are not claimed.

# Current State Addendum - Rail, Target Blast, and Gem Expansion Release v1.0.6

The signed Android App Bundle `build/android/majestic-gems-rail-target-blast-v1.0.6-vc8.aab` is ready for Play upload. It is versionCode 8 / versionName 1.0.6, which advances the prior released versionCode 7 / versionName 1.0.5. Bundletool confirms package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, dual `arm64-v8a` and `armeabi-v7a` native libraries, all 34 runtime gem assets including `gem_33` and `gem_34`, and no packaged tests, reports, or development scripts. Focused rail/target/gem regression passed before export; the matching standalone APK exists, and `adb devices -l` found no Android device.

# Current State Addendum - Rail, Target Blast, and Gem Expansion V1

The active catalog contains 34 supplied gems. The two Aug-24 additions are preserved byte-for-byte as stable `gem_33` and `gem_34` sources and classified from visual inspection as pink gradient Unique artwork (circle and rounded square). Runtime derivatives are exactly alpha-tight at `256x253` and `256x254`; the catalog remains name-free and now totals 22 Common / 12 Unique.

Fresh image-row and centerline measurements across all ten runtime tables replace the previous permissive alpha-only rail assumption. The one shared `GameConfig` opening is now board `454..1168`, back rails `140..580`, and front rails `58..662`. Table drawing, L8 containment, launcher/drag clamps, danger geometry, rail telemetry, and F8 diagnostics still consume that same trapezoid.

Target tiers now have larger live visual/physical bodies: L6-L8 radii are `56/61/66` while L1-L5 remain `36/39/42/45/48`; collection emphasis rises from `1.12` to `1.18`. Target waves use five 52-segment rings. Each confirmed target applies one bounded `220 px` radial nudge (maximum `78 px/s`) to nearby non-launcher gems, and background music gain rises slightly from `0.06` to `0.07`.

All eleven repository suites pass. Two 720x1280 production-scene ANGLE frames were reviewed under `reports/rail-target-blast-gem-expansion-v1/screenshots/`. Final standalone APK `build/android/majestic-gems-rail-target-blast-gem-expansion-v1.apk` is 82,310,470 bytes with SHA-256 `4FBEC0C511EABB8B838F4B8672FAEBE512736CFBE2A32D0F76AB9735424A6D33`; AAPT/version, v2 signature, dual-ARM, 34-gem, compiled-script, and exclusion audits pass. Source is `21637cb` / `rail-target-blast-gem-expansion-v1-source`; ADB found no connected device.

# Current State Addendum - Gem Categories, Pattern Blocks, and Target Feedback V1

The active gem catalog now contains 32 alpha-tight runtime identities backed by one `AssetCatalog.GEM_DEFINITIONS` registry. Visual inspection classified only circle/rounded-square shape, practical color family, solid/gradient color style, and Common/Unique rarity: 22 Common and 10 Unique. New sources are normalized as `assets/gems/gem_21.png` through `gem_32.png`; matching runtime derivatives are 243-256 px on the short edge, exactly 256 px on the long edge, and have no transparent border pixels. Gem display names remain empty everywhere.

`LevelConfig` now emits deterministic 3-4-level Same Shape / Same Color blocks. L1-L4 are Common, L5 is a pattern-supporting non-target Unique, and three distinct reachable Unique targets always occupy L6-L8. Shape targets use the opposite shape; color targets exclude the dominant color. Retry reconstructs the same mapping, and adjacent blocks do not repeat an exact configuration.

All three target completions now share one reward sequence: enhanced three-layer wave, full merge feedback, 120 ms table-position hold, 1.12 presentation-only target scale, center travel/hold, and HUD collection. The target reward cue starts after the merge; collection audio remains tied to visible arrival. Final visible coins are reduced from 16 to 4, all target groups retain at least a one-second table hold, and coin idle motion/shadows are flattened to read as table contact. HUD StyleBoxFancy and StyleBoxFlat shadows are disabled globally without changing UI layout.

The ten tables were re-audited through their normalized derivatives, the shared `GameConfig` transform, all-table pixel bounds, and fresh in-game rail-contact captures. Existing board/rail constants already align with the visible opening, so no speculative physics retune was made. Strict contact-only merge, movement, launcher, danger, scoring, reward authority, ads, persistence, and local-tier radii are unchanged.

Android export now explicitly excludes `scripts/dev/*` in addition to tests, reports, build output, and source art. This was verified after the first artifact audit exposed the preparation script as packaged development code.

All ten suites print PASS and nine GL Compatibility/ANGLE production frames were reviewed. Source is `8f93d1c` / `gem-pattern-feedback-v1-source`; intake is `64cc6df` / `gem-pattern-feedback-2026-08-24-intake`. Final standalone APK `build/android/majestic-gems-gem-pattern-feedback-v1.apk` is 82,140,536 bytes with SHA-256 `D86997A3C132F2A99C663C44D863A487D0517EAB60758210D1C45A924B3E26CB`; AAPT/version, v2 signature, dual-ARM, 32-gem, compiled-script, and exclusion audits pass. ADB found no connected device.

# Current State Addendum - Supplied Art, Purple UI, and Codebase Cleanup V1

The active art set is now the newly supplied 10 backgrounds, 10 portrait tables, and 20 gems. Originals use stable names in `assets/backgrounds`, `assets/tables`, and `assets/gems`; `scripts/dev/prepare_supplied_art_refresh.gd` generates the only active mobile derivatives under `assets/runtime` and records hashes/bounds in `assets/runtime/art_refresh_manifest.json`. Every runtime gem is alpha-tight and no larger than 256 pixels on its longest edge.

The full portrait table compositions are retained instead of being converted into the retired 920x810 normalized artwork. Measured alpha/rail bounds informed a small centralized `GameConfig` update: outer 420-1215, board 455-1165, back rails 130/590, front rails 54/666, danger 1015, and launcher 1095. All L1-L8 radii and gameplay behavior remain unchanged.

The HUD and all shared UI surfaces now use dark amethyst glass, violet rims, white/lavender text, purple controls, and lavender icons. Existing positions and sizes are unchanged. The HUD no longer creates `TargetName`; Level Ready uses quantity-only `MERGE TARGET x N`; catalog display names are empty.

Active scripts are organized under `core`, `gameplay`, `presentation`, `ui`, `services`, and `dev`. Retired source/runtime pipelines, unused renderers, superseded audio copies, old backgrounds 11-19, and the vibration icon are removed. `assets/runtime` remains the deliberate package boundary between large originals and optimized shipped files.

All nine regression suites print PASS. Six GL Compatibility/ANGLE gameplay captures at 720x1280 and 720x1600 were reviewed under `reports/supplied-art-purple-ui-cleanup-v1/screenshots/`; rail-edge proof gems remain contained and the visual hierarchy matches the supplied purple reference. Debug APK `build/android/majestic-gems-supplied-art-purple-ui-cleanup-v1.apk` passes AAPT, v2 signature, dual-ARM, compiled-script, 20-gem, and packaging-exclusion audits; ADB found no connected device. Source: `a2d8372` / `supplied-art-purple-ui-cleanup-v1-source`; delivery: `supplied-art-purple-ui-cleanup-v1`.

# Current State Addendum - Simultaneous Reward Reveal and Immediate Physics V6

Release delivery: signed Play AAB `build/android/majestic-gems-reward-gem-simultaneous-physics-v1.0.5-vc7.aab` is now prepared at versionCode 7 / versionName 1.0.5. Bundletool validates the bundle and its embedded manifest; both ARM architectures and all V6 gameplay scripts are present. The previous standalone V6 debug APK remains available; no device was connected. See `BUILD_MANIFEST.md` and `reports/REWARD_GEM_SIMULTANEOUS_PHYSICS_V6_REPORT.md`.

Merge results and every generated reward sibling now appear on the same confirmed-result reveal frame. The controller stores the merge timeline with the pending reward, creates all siblings together at their real collision-safe positions, and samples the same result-pop phase for every sibling. There is no merge-origin visual offset, extraction tether, elevated behind/front travel, or separate source recoil, so one gem cannot pop while another slides into place.

Reward physics is active immediately. Each new `GemPiece` receives its 135 px/s velocity before the same frame's `BoardSimulation.step()`, allowing motion, rail contact, gem contact, overlap correction, and collision response from the first visible frame. The 650 ms reward grace now delays only follow-up merge capture; it never delays motion or physical contact. The three-piece shot budget, COMBO 2 generation ceiling, 24-piece board cap, distinct sibling-tier fallback, 260 ms chain spacing, shadows, target-coin holds, final-target hold, target authority, scoring, and audio/haptics remain unchanged.

All nine repository suites print PASS, including new assertions for reveal-frame scheduling, identical sibling pop phases, immediate velocity/motion/contact, merge-only grace, persistence, and cascade bounds. GL Compatibility/ANGLE capture passes with 33 production-path PNGs under `reports/reward-gem-simultaneous-physics-v6/screenshots/`; the normal 150/280 ms and COMBO 2 670/800 ms pairs show synchronized appearance followed by immediate separation. Debug APK `build/android/majestic-gems-reward-gem-simultaneous-physics-v6.apk` passes AAPT, v2 signature, dual-ARM, compiled-script, and packaging-exclusion checks. ADB found no connected device. Source: `6fcdb44` / `reward-gem-simultaneous-physics-v6-source`; delivery: `reward-gem-simultaneous-physics-v6`. See `reports/REWARD_GEM_SIMULTANEOUS_PHYSICS_V6_REPORT.md` and `BUILD_MANIFEST.md`.

# Current State Addendum - Reward Split Readability V5

Merge rewards now read as a conversion from the confirmed result rather than a new object appearing elsewhere. After the result reveal, each real reward gem starts visibly at the live result position at 0.48 scale, renders above it, separates with a short color-matched tether and result recoil, grows to 1.12, settles at its collision-safe position, and only then enters physics. The split lasts 780 ms after a 280 ms delay; release impulse is 135 px/s. Multi-gem splits use distinct lower eligible tiers when possible.

Fresh rewards now resolve visible physical contacts for 650 ms after release without confirming another merge. After that bounded grace they are completely ordinary merge candidates. Existing cascade bounds remain three generated pieces per shot, generation through COMBO 2 only, and a 24-piece live-plus-pending cap. Chain presentation spacing is 260 ms.

Unrevealed non-final target coins re-anchor to the live result position until their first frame, so they originate at the gem instead of a stale merge midpoint. Every four-coin target group holds together for 1.20 s; the final 16-coin pile holds for 1.00 s. The final target gem holds at center for 1.05 s with a 1.30 s caption lifetime. Gem shadows are now visibly exposed below their silhouettes at 0.50 opacity, while target/final coin shadows are 0.46 and track current coin position.

All nine repository suites pass, including split origin/elevation/travel, tier diversity, activation/release grace, current-position coin anchoring, complete coin holds, hero readability, reset, persistence, audio/privacy, ads, game flow, scene assets, branding, and responsive layout. GL Compatibility/ANGLE capture passes with 33 production-path screenshots under `reports/reward-gem-extraction-v5/screenshots/`. Debug APK `build/android/majestic-gems-reward-gem-split-readability-v5.apk` passes AAPT, v2 signature, dual-ARM, compiled-script, and packaging-exclusion checks. ADB found no connected device. Source: `f5d76b5` / `reward-gem-split-readability-v5-source`; delivery: `reward-gem-split-readability-v5`. See `reports/REWARD_GEM_SPLIT_READABILITY_V5_REPORT.md` and `BUILD_MANIFEST.md`.

# Current State Addendum - Reward Feedback Real Gems V4

Reward Feedback V3 is now corrected so merge rewards are real persistent `GemPiece` objects, not fading draw records. Requested counts are 1/1/2/2/3 for normal through COMBO 4+, selected from lower local progression tiers with 50/30/20 weighting. A hard three-piece budget resets on each player launch, COMBO 3+ schedules no further reward tier, and a live-plus-pending population cap of 24 prevents crowded-board reward cascades from running indefinitely. Safe placement, delayed activation, impulse, and the 180 ms post-activation same-event grace live in `GameConfig`; the grace marker clears automatically.

The active merge cadence is 420 ms with contact compression through 35 ms, snap/reveal at 120 ms, a `1.24` normal peak, and stronger combo peaks spaced by 180 ms per depth. Bonus visuals begin at the merge center, scale `0.28 -> 1.18 -> 1.00`, and ease outward over 340 ms; their stored 165 px/s impulse and all collision/contact processing begin only after that pop. `GemSpriteLayer` pools eight slots for one reusable 180 ms radial shader. Claude's cosmetic mini-gem channel remains inactive.

Target-relevant merges pulse and highlight the current objective immediately, while the displayed number/bar animate on collection arrival. Every non-final target's four coins now finish landing and hold together on the table for at least 260 ms before any HUD flight. Final target creation peaks at 1.40, adds a 70 ms launch anticipation and 310 ms curve, then stages 16 larger coins in a compact 4+4+4+4 pile before Level Complete. Gems and landed coins have slight presentation-only table shadows.

All nine repository suites pass. GL Compatibility/ANGLE produced a muted-first reviewed AVI plus 31 screenshots, including merge-center emergence, spaced chains, the COMBO 3 generation cutoff, persistent bonus participation, held target coins, and visible shadows. Final debug APK `build/android/majestic-gems-reward-feedback-real-gems-v4.apk` passes AAPT and v2 signature validation with both ARM ABIs; ADB found no connected device, so physical performance, touch feel, listening, and haptics are not claimed. Source: `071d1ba` / `reward-feedback-real-gems-v4-source`; delivery: `reward-feedback-real-gems-v4`. See `reports/REWARD_FEEDBACK_REAL_GEMS_V4_REPORT.md`.

# Current State Addendum - HUD coin-counter continuity fix

The top-left HUD coin counter no longer drops back to the pre-level balance when Level Complete opens. This was a pre-existing defect (present before the reward-feedback-v3 pass) made visually obvious by the new 20-coin final-target celebration: `GameplayHudLayer.prepare_completion_reward_display` was unconditionally resetting the already-correct, live-delivered display value to the pre-level total right as the modal presented, and `COLLECT` then re-animated it back up — a redundant second animation of a reward already granted at merge time. The fix clamps the display forward only (`clampi(_displayed_coins, previous_total, final_total)`) and makes `COLLECT`'s reward animation a no-op once the value has already landed, while still animating forward for the genuinely-additive rewarded "double coins" bonus. No authoritative coin state, exactly-once merge-result guard, or persisted save behavior changed — `coins` is still granted exactly once at the confirmed merge event, and `ProgressionSaveServiceType` persistence is unchanged.

`tests/run_reward_feedback_v3_tests.gd` gained `_test_hud_coin_counter_continuity`, which drives the real COLLECT/transition/scene-reload flow and asserts the HUD balance never regresses at last-coin arrival, Level Complete open, Level Complete settle, after COLLECT, after the level transition, or after a simulated scene reload; it was confirmed to fail against the prior code and pass against the fix. All nine repository suites pass. A same-identity debug verification APK (`build/android/majestic-gems-reward-feedback-v3-hud-coin-fix.apk`, versionCode 6 / versionName 1.0.4, no bump since no AAB was generated) was exported and validated; see `BUILD_MANIFEST.md`. No Android device was connected. See `reports/REWARD_FEEDBACK_V3_REPORT.md` (Addendum). This work, together with the rest of reward feedback v3, remains uncommitted and untagged pending review.

# Current State Addendum - Reward feedback v3

Successful-action feedback is now driven by one authoritative hierarchy: normal collision < normal merge < combo merge < final target achievement < level complete. Each tier is a timeline dictionary returned by `GameConfig.merge_timeline(depth, final_target)`, which owns hit-stop length, source-pull window, reveal time, result-scale keyframes, ring strength, mini-gem count, and SFX pitch. Gem progression, merge eligibility, contact capture, physics constants, board geometry, HUD layout, target rules, level rules, theme, and art direction are unchanged.

A normal merge runs 420 ms: a 40 ms hit-stop that freezes only the confirmed result gem (its merge momentum is stored and restored exactly), a 40-110 ms source pull to 0.82, reveal at 110 ms with the merge chime, then `0.65 -> 1.18 -> 0.96 -> 1.02 -> 1.0`, one subtle shockwave ring at 150 ms, and three cosmetic mini gems between 140 and 430 ms. Chain merges from a single shot escalate through COMBO 1/2/3+ with stronger rings, larger overshoot, more mini gems, higher pitch, and a floating label; `COMBO 4 — AMAZING!` and `COMBO n — PERFECT!` are reserved for depth 4 and above. There is no camera shake, lightning, screen flash, or shader anywhere in the pass, and the project still has no camera to shake.

Completing the final target of a level now plays a staged hero moment: 180 ms Phase A, a 250 ms ease-out travel to the visual centre of the playable board, a deliberate 500 ms hold at 1.27-1.38 with one soft expanding radial glow and a `TARGET COMPLETE!` caption, then a 350 ms curved flight into the target HUD panel with a small 0-10-0 degree tilt. The panel anticipates to 0.95 before impact and answers with `0.95 -> 1.12 -> 1.0`; the HUD target count advances only at that arrival, never earlier. Level completion then drops 20 visible reward coins across a controlled central band of the board in four waves, holds them on the table for 380 ms, and collects them in staggered waves of three along curved paths into the top-left counter. The counter interpolates upward as coins arrive and is punched once per wave. Level Complete opens only after the coins finish, dims 70 ms ahead of the panel, and animates the existing modal `0.86 -> 1.04 -> 1.0` revealing title, then the completed target gem, then the reward card and buttons. The whole celebration settles about 3.35 s after the final merge.

Presentation remains non-authoritative. `final_celebration_active` is an explicit state that locks pointer input, launcher spawning, and the Level Complete modal for the duration; the existing exactly-once guards (`processed_merge_result_ids`, `counted_target_result_ids`, `pending_target_presentations`) are reused unchanged, and the final target no longer also fires the compact four-coin per-target group. Mini gems, rings, combo labels, panel sparkles, the hero glow, and reward coins are cosmetic drawn records inside `GameplayEffectsLayer`: no nodes, no simulation bodies, no contact or merge participation, all cleared on restart and failure. The stored economy value stays mathematically exact throughout; as before, the HUD balance returns to the pre-level total when Level Complete opens because the reward is banked by `COLLECT`.

Godot 4.6.3 import/parse passes and all nine repository suites pass, including the new `REWARD_FEEDBACK_V3_TESTS`. Stage-by-stage screenshots produced from the production controller are in `reports/reward-feedback-v3/screenshots/`. No Android device was connected and no APK/AAB was exported in this task; no version value changed. See `reports/REWARD_FEEDBACK_V3_REPORT.md`.

# Current State Addendum - Original procedural gem and rail collision restoration

The supplied MP3 and derivative collision assets are no longer active for gem-to-gem or gem-to-rail impacts. The game again generates and caches its pre-supplied-audio procedural crystal contacts: gem is 1240 Hz / 55 ms at linear gain 0.46; rail is 760 Hz / 65 ms at gain 0.32. They retain their earlier 75/110 ms global cooldowns and fixed pitch. This restores the older, distinctly different contact sound requested by the player.

Audio remains presentation-only: the existing confirmed-contact telemetry, exact merge-pair suppression, five-voice pool, buses/limiter, settings, haptics, and all gameplay physics/merge rules remain unchanged. Android release identity is permanently versionCode 6 / versionName 1.0.4. Release AAB `build/android/majestic-gems-procedural-collision-restore-v1.0.4-vc6.aab` (70,072,285 bytes; SHA-256 `FF5A2EE1F2A75B093DA8BAC34780D0A42F0B56A03656604E9708EEC471982419`) passes Bundletool with embedded code 6/name 1.0.4. Matching APK `build/android/majestic-gems-procedural-collision-restore-v1.0.4-vc6.apk` (82,227,532 bytes; SHA-256 `C9C3DFEF0C1E4929FC0FB1000E0066D8BE612A47B14A69B90BBE5C60D4041EEB`) passes AAPT, v2 signature, and dual-ABI audit. No device was connected. See `reports/PROCEDURAL_COLLISION_SOUND_RESTORE_RELEASE.md`.

# Current State Addendum - Original collision sound, fast merge/push, and visible-touch merge repair

Gem-to-gem and gem-to-rail impacts again use the original supplied sound files at their original gains (`0.34` / `0.39`), thresholds (`170` / `220 px/s`), global cooldowns (65 / 90 ms), pitch ranges, and impact scaling. Exact confirmed merge-pair suppression and the bounded priority voice pool remain in place; contact telemetry remains presentation-only.

The merge and source-pull/push presentation is again the approved fast 270 ms / 60 ms cadence with an immediate `0.64 -> 1.26 -> 1.0` pop. Target collection stays at its current 700 ms pace, the next-target transition is unchanged, and target coins retain their slower 260 ms delayed, ~980 ms visible sequence.

Matching gems now merge when they fall within the calibrated 2-design-pixel visible-touch band, avoiding the observed case where equal gems look touching but fail to merge. This changes only centralized contact tolerance; collider radii, physics geometry, impulse tuning, chain eligibility, target/reward authority, and launcher behavior remain unchanged. The APK-only delivery is `build/android/majestic-gems-original-contact-fast-merge-touch-fix.apk` (82,227,624 bytes; SHA-256 `C3EAC8417D9566F4E10E011A7838BA514D15C5FD299B3B80E2B68AF757364A8C`). AAPT, v2 signature, dual-ABI ZIP audit, and four focused regression suites pass; no device was connected. See `reports/ORIGINAL_COLLISION_FAST_MERGE_VISIBLE_TOUCH_REPAIR.md` and `BUILD_MANIFEST.md`.

# Current State Addendum - Original collision sound, fast merge/push, and visible-touch merge repair

Gem-to-gem and gem-to-rail impacts again use the original supplied sound files at their original gains (`0.34` / `0.39`), thresholds (`170` / `220 px/s`), global cooldowns (65 / 90 ms), pitch ranges, and impact scaling. Exact confirmed merge-pair suppression and the bounded priority voice pool remain in place; contact telemetry remains presentation-only.

The merge and source-pull/push presentation is again the approved fast 270 ms / 60 ms cadence with an immediate `0.64 -> 1.26 -> 1.0` pop. Target collection stays at its current 700 ms pace, the next-target transition is unchanged, and target coins retain their slower 260 ms delayed, ~980 ms visible sequence.

Matching gems now merge when they fall within the calibrated 2-design-pixel visible-touch band, avoiding the observed case where equal gems look touching but fail to merge. This changes only centralized contact tolerance; collider radii, physics geometry, impulse tuning, chain eligibility, target/reward authority, and launcher behavior remain unchanged. See `reports/ORIGINAL_COLLISION_FAST_MERGE_VISIBLE_TOUCH_REPAIR.md`.

# Current State Addendum - Readable reward, coin, and merge cadence release

Tester feedback supersedes the all-fast animation revert for successful actions only. The active cadence restores the post-checkmark-removal `acb28a5` presentation: merge 540 ms, result reveal and merge chime at 200 ms, target duplicate begins at 300 ms and completes over 700 ms, target-card pulse 220 ms, four coin visuals start after 260 ms and span about 980 ms, and final result hold 420 ms. The removed tick/checkmark remains absent. Collision response remains 110 ms and Next remains 160 ms.

These longer success visuals do not change authority. Confirmed target progression and coin values commit once immediately, the HUD target advances once at collection arrival, target/merge/coin effects overlap, and the next launcher remains independent. Current midpoint collision audio, Back/Exit behavior, Privacy alignment, Home flow, ads/UMP, saves, package name, table/gameplay geometry, and gem assets remain unchanged.

Android release identity is permanently version code 5 / version name 1.0.3. The user confirmed Play's current uploaded version code is 3; code 4 had already identified local tester APKs and was intentionally not reused. RELEASE AAB `build/android/majestic-gems-reward-coin-merge-restore-v1.0.3-vc5.aab` (70,072,704 bytes; SHA-256 `9A976CA0639E74F98FECC8B0AB5F9C0E57318C47F8E77E493E622037E22ED966`) passes Bundletool 1.18.3, upload-key signing, manifest, dual-ABI, dependency, AdMob, and exclusion audits. TEST APK `build/android/majestic-gems-reward-coin-merge-restore-v1.0.3-vc5.apk` (82,228,028 bytes; SHA-256 `966CF3DED40427BA70D2F8256434C1EB722E40B7C04672DEFDA5B5121EC61CDB`) passes AAPT, v2 signature, dual-ABI, dependency, AdMob, and exclusion audits. No device was attached and no Play upload is claimed. See `BUILD_MANIFEST.md` and `reports/REWARD_COIN_MERGE_TIMING_RESTORE_RELEASE.md`.

# Current State Addendum - Tester animation revert, contact midpoint, and Android lifecycle exit

The rejected slow animation pass is superseded. Presentation is restored exactly to the pre-pass `5528ff6` cadence: collision 110 ms, merge 270 ms with a 60 ms pull and immediate `0.64 -> 1.26 -> 1.0` result pop, major effect 360 ms, target collection 320 ms, target pulse 380 ms, four coins over an 855 ms bound, Next 160 ms, and result hold 240 ms. Immediate confirmed merge audio is restored. Controller target truth remains immediate and separate from arrival-timed HUD presentation, preserving exactly-once rewards and correct rapid follow-up classification.

Gem/rail contacts now use midpoint v2 derivatives rather than the harsh originals or over-softened v1 files. Gains are 0.23/0.24, thresholds 182.5/235, global cooldowns 92.5/115 ms, per-contact cooldown 120 ms, and pitch ranges `0.95-1.02` / `0.95-1.01`. The five-voice pool, event priorities, merge suppression, Music/SFX buses, limiter, and reward identities remain unchanged.

Confirmed Android Exit keeps the Cancel/Exit popup but no longer synchronously kills SceneTree. It invalidates delayed ad callbacks, posts `finishAndRemoveTask()` to the current Activity through Godot AndroidRuntime on the UI thread, and leaves teardown to Android lifecycle. Desktop uses a deferred SceneTree fallback. See `reports/ANIMATION_REVERT_AUDIO_MIDPOINT_ANDROID_EXIT_FIX.md`.

All eight regression sentinels pass. TEST APK: `build/android/majestic-gems-animation-revert-audio-midpoint-exit-fix.apk` (82,226,968 bytes; SHA-256 `371F47693B0019696152E0C1CB0E753522160BB9B6CBD2123D4CD9237E020FE2`). Package/version/SDK, v2 signature, both ARM ABIs, midpoint audio imports, production AdMob manifest ID, and export exclusions pass. No device was attached, so the tester must confirm Activity exit and perceived contact balance. No AAB was generated.

# Current State Addendum - Animation, audio, Back, and Privacy polish

The current presentation rhythm is fast input followed by readable, overlapping success feedback: collisions are 140 ms, merges are 540 ms, target UI collection is 700 ms with a 220 ms card pulse, four reward coins remain visible for about 980 ms, and final-target-to-result presentation is about 1.66 seconds. Next remains 220 ms. Confirmed controller target state and launcher readiness no longer wait for merge, collection, particle, coin, or audio completion; the HUD keeps a separate presentation snapshot and advances at collection arrival. Presentation is queued exactly once and cannot grant duplicate targets or rewards. Reward values remain 10/25/60/150/350/800/1800 for result levels 2-8.

Gem and rail contacts use softened filtered derivatives at gains 0.18/0.16, thresholds 195/250, global cooldowns 120/140 ms, and a 140 ms per-contact cooldown. Merge audio lands on the 200 ms reveal; target arrival has a separate soft crystal chime; full target completion has a richer sparkle; staggered coin arrivals have individual ticks and a final reward cue. The five-voice pool, Music/SFX buses, limiter, settings authority, and 0.06 supportive music gain remain centralized.

Proper Back behavior is newly implemented rather than restored: Godot Android auto-quit is disabled, the controller owns `NOTIFICATION_WM_GO_BACK_REQUEST`, Escape uses the same path, top overlays dismiss first, active gameplay opens/resumes the existing Pause overlay, result modals consume Back, and bare Home shows a Cancel/Exit confirmation. The Home Privacy Policy link's artificial 180-pixel text box was removed so the visible text—not only its anchors—is centered. Viewport proofs exist at 576x1312 and 720x1600. See `reports/ANIMATION_AUDIO_BACK_PRIVACY_POLISH.md`.

All eight Godot regression sentinels pass, and the Home main scene survived a manually stopped three-minute-plus idle soak without error output. TEST APK: `build/android/majestic-gems-animation-audio-back-privacy-polish-test.apk` (82,210,382 bytes; SHA-256 `D1CF50AF7664ACFE377D26DC0342061EE33E1CA377E61099AE8B896EA81FFF21`). Package/version/SDK, v2 debug signature, both ARM ABIs, production AdMob manifest ID, filtered audio imports, and export exclusions pass. No device was attached, so physical Back/listening/lifecycle verification is not claimed. No AAB was generated.

# Current State Addendum - Supplied sound integration and Home privacy link v1

The eight newly supplied SFX are active through the existing centralized `AudioFeedbackService`: gem/rail contact, normal merge, target-producing merge, target-arrival sparkle, completed-objective reward, final level success, and UI tap. The existing background music, procedural launch/push cue, and supplied coin cue are preserved. Music service gain is reduced from `0.10` to `0.035` linear (-9.12 dB relative); there is no lose/game-over audio route.

Confirmed merge contacts suppress their matching collision clink, gem contact uses a 65 ms cooldown and `0.96x..1.04x` pitch range, rail contact uses 90 ms and `0.97x..1.03x`, and five reusable priority-aware SFX voices prevent quiet contacts/taps from interrupting reward cues. Dedicated Music/SFX buses are active; the SFX bus has a -0.8 dB ceiling limiter. Physics, merge eligibility, targets, scoring, reward values, animation durations, ads, and production signing are unchanged.

Privacy Policy is no longer a button in either Home Settings or Pause Settings. It is one underlined, bottom-centered, safe-area-aware `HomePrivacyPolicyLink` on the Home screen and continues through the existing `AdManager.open_privacy_policy()` path. Conditional UMP Privacy Options remain in both Settings panels. Focused sound/link, AdMob/privacy, game-flow, responsive layout, and push-line regressions pass by their sentinels. TEST APK: `build/android/majestic-gems-sound-pass-test.apk` (81,303,547 bytes; SHA-256 `8CB63641D116907647A1C81161E59686EA6008901DF36B79622CB0EDB6EC08D3`). Package, signature, dual-ARM, audio payload, bus-layout, and exclusion audits pass; no device was connected. See `reports/SOUND_INTEGRATION_PRIVACY_LINK_V1_REPORT.md`.

# Current State Addendum - Supplied sound integration and Home privacy link v1

The eight newly supplied SFX are active through the existing centralized `AudioFeedbackService`: gem/rail contact, normal merge, target-producing merge, target-arrival sparkle, completed-objective reward, final level success, and UI tap. The existing background music, procedural launch/push cue, and supplied coin cue are preserved. Music service gain is reduced from `0.10` to `0.035` linear (-9.12 dB relative); there is no lose/game-over audio route.

Confirmed merge contacts suppress their matching collision clink, gem contact uses a 65 ms cooldown and `0.96x..1.04x` pitch range, rail contact uses 90 ms and `0.97x..1.03x`, and five reusable priority-aware SFX voices prevent quiet contacts/taps from interrupting reward cues. Dedicated Music/SFX buses are active; the SFX bus has a -0.8 dB ceiling limiter. Physics, merge eligibility, targets, scoring, reward values, animation durations, ads, and production signing are unchanged.

Privacy Policy is no longer a button in either Home Settings or Pause Settings. It is one underlined, bottom-centered, safe-area-aware `HomePrivacyPolicyLink` on the Home screen and continues through the existing `AdManager.open_privacy_policy()` path. Conditional UMP Privacy Options remain in both Settings panels. Focused sound/link, AdMob/privacy, game-flow, responsive layout, and push-line regressions pass by their sentinels. TEST APK delivery is pending the source milestone export. See `reports/SOUND_INTEGRATION_PRIVACY_LINK_V1_REPORT.md`.

# Current State Addendum - Regenerated scene art integration v1

All 19 regenerated beach backgrounds and all 10 regenerated transparent table styles are active through the existing deterministic per-level `background_index` and `table_index` selection. Retries retain the same scene pair. The previous background/table source images and the temporary single-table runtime asset were removed as requested; the supplied replacements are preserved under canonical `assets/source/` names and optimized runtime WebPs remain under `assets/runtime/`.

The new table set uses the restored fixed layout without changing physics: outer `400..1185`, board `440..1110`, rails `188/532 -> 62/658`, danger `960`, launcher `1042`, table center Y `792.5`, and render scale `0.7391304 x 0.9691358`. Offline alpha/color measurements for all ten tables and 20 real Godot captures at 720x1280/720x1600 verify that their visible inner rails meet the physical back edges and the intentionally inset danger-line endpoints within a 10-pixel tolerance. Gem radii, collision, solver, movement, input, merge, target, queue, reward, and HUD behavior were not changed.

The active runtime scene-art payload is 2,145,764 bytes, down from 3,068,162 bytes (922,398 bytes / 30.06%). Asset preparation, Godot import/parse, scene-catalog tests, responsive layout/calibration tests, branding/push-line tests, and reward/game-flow tests pass by their sentinels. The requested Godot-first review APK is now `build/android/majestic-gems-regenerated-scene-art-test.apk` (80,913,394 bytes; SHA-256 `18D35421FFFF50627732E37C70EA6E155198078421502B67B62E3EBDD1368CD4`). Package, v2 signature, dual-ARM ABI, scene-import, and exclusion audits pass; no device was connected, so installation is not claimed. See `reports/REGENERATED_SCENE_ART_INTEGRATION_V1_REPORT.md`.

# Current State Addendum - Original table restoration v1

The rejected multi-table width calibration has been removed. Gameplay now renders the restored single original table, `assets/runtime/table/new_table_v1.png`, at its original unstretched scale and pre-random-table position. The complete shared geometry returned by 20 design pixels to outer `400..1185`, board `440..1110`, danger `960`, launcher `1042`, and texture center Y `792.5`; rail X coordinates, gem radii, collision response, merge rules, movement tuning, targets, rewards, and input behavior were not retuned.

The 19 optimized random backgrounds remain active. The ten replacement table files remain preserved but are not selected by gameplay while new rail artwork is being regenerated. Coins/Next alignment, larger Next card, stronger text, Target placement, and merge-path hierarchy remain unchanged. No APK/AAB was created, and no final Godot acceptance run is claimed because the user stopped the calibration to replace the artwork. See `reports/ORIGINAL_TABLE_RESTORE_V1_REPORT.md`.

# Current State Addendum - Table-art containment and HUD legibility v1

All ten random table textures now receive a presentation-only 1.15x horizontal coverage factor around the unchanged 920x810 normalized canvas. The effective base render scale is `0.85 x 0.9691358` instead of `0.7391304 x 0.9691358`, so the narrowest supplied inner rails wrap the existing legal gem extents and complete danger line. Physics remains exactly at outer `420..1205`, board `460..1130`, rails `188/532 -> 62/658`, danger `980`, and launcher `1062`; no solver, radius, collision, input, merge, or movement value changed.

Coins and Next now share the same top baseline. Next is an additional 10% larger at `141.075 x 123.75`, Settings remains directly below it, and stronger headings/value outlines plus larger coin/target copy improve readability while Target remains the dominant objective card.

Godot parse/import, responsive UI/table coverage, all-ten-table catalog, launcher/input, and game-flow tests pass by their sentinels. Six real Compatibility/ANGLE captures at 720x1280 and 720x1600 show legal edge gems plus the danger line contained by supplied tables 02, 05, and 08. No APK or AAB was created, as requested; editor/device review remains the user's next acceptance step. Details are in `reports/TABLE_ART_CONTAINMENT_HUD_LEGIBILITY_V1_REPORT.md`.

# Current State Addendum - Responsive scene variety and asset optimization v1

Generated levels now use all 19 newly supplied tropical backgrounds and all 10 newly supplied table styles through deterministic seed-based indices. A retry preserves its scene pairing. The raw PNG originals are organized under `assets/source/backgrounds/` and `assets/source/tables/`; 720x1280 background and 920x810 alpha-table WebP derivatives under `assets/runtime/` reduce the new scene payload from 57.40 MiB to 2.93 MiB without giving artwork any gameplay authority.

Tracked high-quality Godot import profiles prevent those WebPs from expanding into the editor's default lossless package representation: imported scene textures are 3.12 MiB instead of 19.83 MiB. Quality was rechecked in the final six ANGLE frames after the import change.

The table and its shared physics model move down another 20 design pixels. Coins and Next are 12.5% larger, Next is top-right, and Settings is stacked below it. The centered Target and high-contrast merge path remain immediately above the table without collisions across the tested 576x1312 through notched 1080x2400 portrait set.

Sixty-six proven-unused legacy asset files totaling 27.83 MiB were removed, including retired backgrounds/table art, old brand sets, reference-only audio, first-generation gem bodies, and unused icon variants. Active branding sources, coin provenance, calibrated L1-L18 gems, production music/reward audio, AdMob, and dual-ARM Android support remain intact. Source milestone/APK details are recorded in `reports/RESPONSIVE_SCENE_VARIETY_ASSET_OPTIMIZATION_V1_REPORT.md`.

Final source is `081eb1c` / `responsive-scene-variety-v1-optimized-source`. TEST APK `build/android/majestic-gems-responsive-scene-variety-test.apk` is 81,986,750 bytes with SHA-256 `22A7F145E45EF306F79BD8FFB873455D09D3DD2C2F87177E344E0CEC82DA8249`; package, signature, both ARM ABIs, all 29 scene imports, and exclusion checks pass. ADB did not return within the device-check window, so no installation or physical-device result is claimed.

# Current State Addendum - Table / Target / merge-path hierarchy correction v1

The gameplay screen now reserves the top safe-area row for Coins, Next, and Settings only. A separate centered stack places the larger Target card above a bright, enlarged eight-gem merge path immediately before the table. The progression strip is no longer hidden at the bottom edge, and its opaque glass body, rim, shadow, larger icons, and stronger connectors remain readable over both sky and beach scenery.

The baseline table composition moved down by 40 design pixels to create this hierarchy. Table art, rails, board bounds, launcher, danger line, drag clamp, spawn limits, and containment still read one shared `GameConfig` geometry model. No gem radius, movement, merge, target, scoring, queue, timing, or result behavior changed.

Responsive geometry assertions pass across 576x1312, 720x1280, 720x1440, 720x1560, 720x1600, 1080x1920, 1080x2340, and notched 1080x2400. Real 720x1280 and 720x1600 ANGLE renders were visually reviewed. Source: `c7d03f0` / `target-path-hierarchy-fix-v1-source`. TEST APK: `build/android/majestic-gems-target-path-hierarchy-test.apk` (85,221,515 bytes; SHA-256 `6A56FE2DC9FD7D14369B0352C08D2A1CB900A45FFFC1D0AB2634223EE4FB34B8`). Package/signature/ABI checks pass; no device was connected.

# Current State Addendum — Majestic Gems branding + draggable push line v1

The current source uses the newly supplied 1536×1024 transparent `MAJESTIC GEMS` logo on Home and the fallback Godot boot splash. Android uses a 192×192 padded legacy launcher icon and paired 432×432 adaptive foreground/background assets derived non-destructively from the supplied 1254×1254 icon. The foreground artwork occupies 68% of the canvas, keeping the full composition inside common Android masks.

The ready-state vertical push line now accepts pointer/touch presses within a centralized 28-design-pixel half-width. It enters the existing controller `dragging` state, calls the same `GameConfig.launcher_drag_x()` rail clamp used by direct gem dragging, and releases through the existing `launch_active_piece()` lifecycle. Physics, launch speed, rails, collision, merging, targets, score, danger, and queue behavior are unchanged.

The Android export filter now excludes retired UI atlases, legacy branding, old five-gem fallback textures, inactive reference audio, unused effect art, source/reference media, tests, reports, tools, and build outputs. Active dependencies remain explicitly preloaded.

Fresh APK: `build/android/majestic-gems-branding-push-line-v1.apk`, 42,831,666 bytes, SHA-256 `1E27A1E54DCDE2A782E9536CE18006EA37D90D763B7630982A4AF08D5F25072B`. This is 17,685,982 bytes (29.22%) smaller than the prior `gem-aim0.2.apk`. Package structure and v2/v3 signatures pass; no Android device was connected.

# Current State Addendum — Startup + @icons polish v1

The current source keeps the previously approved fast-feel timing pass and fixes the latest presentation issues. The pre-level objective gem is static (no Tween Composer breathing). `addons/at-icons` is now integrated for settings/action/status affordances, with recolored runtime SVG derivatives under `assets/runtime/ui/icons/`.

Android startup is configured as a single native system-splash phase using `crystal_magic_system_splash_icon_v1.png`; `splash_screen/disable_godot_boot_splash=true` prevents the second Godot splash from appearing after it. The project-level boot splash remains a clean transparent Crystal Magic logo as a non-Android/editor fallback. The existing square Crystal Magic artwork remains the launcher main icon. Android's adaptive/system-splash background fallback is the tropical-teal `crystal_magic_adaptive_bg_v1.png`.

No simulation, physics, table, merge, target, score, or fast-feel timing values were changed in this pass.

# Current State Addendum — Home Settings Alignment + Fast Feel Motion v1

The current source fixes the Home settings control visible in the supplied screenshot: it is now a compact top-right 94×94 glass card instead of a vertically stretched rail. Home, Level Intro, Pause, and settings controls share quick `GlobalTweens` press feedback. Tween Composer owns the reusable Home-logo breathing loop only; the Level Intro target gem is intentionally static.

Gameplay pacing is intentionally quicker without changing merge eligibility or board geometry. Central `GameConfig` timings now use a 1200 launch speed, 0.22 s launcher handoff, 0.36 s merge presentation, 0.40 s target collection, 0.26 s target swap delay, and ~0.92 s normal coin flight. This is a feel/presentation pass; target rules, score authority, collision geometry, table placement, and merge contact rules remain unchanged.

The latest supplied archive also contains `addons/at-icons`; curated runtime derivatives are now integrated for generic UI affordances while the original library remains intact.

# Current State Addendum — Android Device Compatibility V2

The closed-test release preset now produces `build/android/majestic-gems-closed-test-v2.aab` with versionCode `2`, versionName `1.0.1`, and both `arm64-v8a` and `armeabi-v7a`. The previous arm64-only delivery was caused by the preset explicitly disabling v7a, not by an unsupported AdMob/UMP native dependency.

The generated AAB contains only `libgodot_android.so` and `libc++_shared.so`, with a complete pair for each ARM ABI. Bundletool validation, manifest/package/version/SDK checks, existing-upload-certificate verification, production AdMob/UMP probes, and non-debuggable verification pass. Play's two inferred required features are faketouch and portrait; both remain necessary. GLES 3.0 and min SDK 24 also remain intentional. See `reports/ANDROID_DEVICE_COMPATIBILITY_V2.md`.

The matching release-configured sideload artifact is `build/android/majestic-gems-v2-test.apk` (74,123,752 bytes; SHA-256 `10D9515CBD513358AABE337896D90DC072DD1672A4205487F64C3AD9C2413961`). It is signed with the existing upload certificate and contains both ARM ABIs. No connected device was available for installation or launch.

# Current State

# Light Glass Gameplay HUD v1 — Current Presentation

The gameplay HUD now uses a light cyan/blue frosted-glass presentation. Coins and Next occupy the top left/right row; Level and Settings sit directly beneath them. The former `MERGE PATH` heading is removed. The authoritative eight-gem progression strip is centered immediately above Target, and Target is centered immediately above the unchanged table using `GameConfig.board_top()` as the responsive placement authority.

HUD panels and buttons use `StyleBoxFancy` squircle geometry with translucent gradients, layered cyan/white rim highlights, and soft blue shadows. This is a mobile-safe glassmorphism approximation; there is no framebuffer blur or screen-sampling shader. All gameplay rules and table geometry remain unchanged.


**Current UI patch:** Transparent Purple Glass HUD v1 (2026-08-08). The professional HUD composition is preserved, but its header, path tray, and Coins/Target/Next surfaces now use visibly translucent purple glass instead of pale near-opaque cards. White outlined values and lavender rims keep the supplied gems and numeric progress readable while tropical scenery subtly shows through. No gem names/tooltips or gameplay/table behavior changed. Source: `adab9e8813d8bc7b20b7e7023e2a4870e6b469e9` / `transparent-purple-glass-hud-v1-source`. APK: `build/android/transparent-purple-glass-hud-v1.apk` (122,882,166 bytes; SHA-256 `6BE8A23787D9187D86E2A9BD66E0504C3FF30793037F2B3916D4007C82248966`). All seven suites, motion profile, captures, package audit, and v2/v3 signatures pass. The ADB query timed out, so phone testing is not claimed. Evidence and provenance are in `reports/TRANSPARENT_PURPLE_GLASS_HUD_V1_REPORT.md` and `reports/transparent-purple-glass-hud-v1/`.

**Current milestone:** Professional Glass HUD v1 (2026-08-08). The prior flat/detached purple composition is replaced by one cohesive game-ready system inspired by the supplied visual direction: a beveled translucent purple Level/MERGE PATH/Settings header, a light glass path tray, and one aligned Coins/Target/Next objective row. Gem names/tooltips remain removed. Source: `7b0d18467a6a4bcf506b099d63bd04c36ae759b7` / `professional-glass-hud-v1-source`. APK: `build/android/professional-glass-hud-v1.apk` (122,882,166 bytes; SHA-256 `92F5D1E85CF2710C44D6AAD0640987A65CD5E7560A33CFDAD024F61C5C60AF3D`). All seven regression suites, motion profile, responsive/state captures, package audit, and APK v2/v3 signature audit pass. The final ADB query did not complete, so no phone testing is claimed. Evidence and provenance are in `reports/PROFESSIONAL_GLASS_HUD_V1_REPORT.md` and `reports/professional-glass-hud-v1/`.

**Current milestone:** Purple Production HUD v1 (2026-08-08). The gameplay HUD now uses a rich purple native-control hierarchy: MERGE PATH is the dominant top read, Coins/Next form a compact secondary row, and the numeric-only Target card is positioned immediately above the unchanged table. Level and Settings remain compact header utilities. Gem names/tooltips stay removed to prevent narrow-screen overflow. Source: `2b626434cf7116c6f36bed7d12438650c564fae1` / `purple-production-hud-v1-source`. APK: `build/android/purple-production-hud-v1.apk` (122,882,166 bytes; SHA-256 `1FA79BBF64743CA3BE0F60E3478809556531299823AAA6653DD1291DE1B6BDEF`). All seven regression suites, motion profile, responsive/state captures, package audit, and APK v2/v3 signature audit pass. No connected device was available. Evidence and provenance are in `reports/PURPLE_PRODUCTION_HUD_V1_REPORT.md` and `reports/purple-production-hud-v1/`.

**Current UI patch:** Compact target HUD copy (2026-08-08). Gameplay HUD no longer renders gem names or gem-name tooltips; target identity remains authoritative through its artwork, while sequence and quantity progress remain visible. No gameplay, progression, board, physics, or simulation paths changed. Validation is recorded in `reports/COMPACT_TARGET_HUD_COPY_REPORT.md`.

**Current milestone:** Production Gameplay UI Finalization V2. Gameplay remains frozen at `production-gameplay-ui-v2-baseline` (`39f1082112cee3d2d9d948a9d0ac9c110d163daf`). Source: `48ed83f6ce2377c30c886ef3448c941d7d6d00fc` / `production-gameplay-ui-v2-source`. The gameplay HUD is now one safe-area shell with an integrated Level/MERGE PATH/Settings header and balanced Coins/Target/Next row; target identity, quantity, and transition copy stay synchronized; Pause uses a stronger production hierarchy; and the ready-state aim guide, proximity-only danger emphasis, and normalized gem shadows are presentation-only. Seven regression suites and the motion profile pass. APK: `build/android/production-gameplay-ui-v2.apk` (122,882,166 bytes; SHA-256 `3326C2714ED0B29551D3FD209B6B643A95BE4C0B156C4B2D93A5B3F26AC7FCE1`). Package/signature audit passes; no connected device was available.

## Production Gameplay UI Finalization V2 (2026-08-05)

- Container-driven HUD composition is proven at 576×1312, 720×1600, 1080×1920, 1080×2340, 1080×2400, 540×1320, and a simulated top notch.
- Coin totals preserve exact integers and format responsively; target name/progress and incoming/outgoing art remain paired during handoff; Restart clears discarded-run UI state.
- Coin and target flights retain their approved controller timing and render above the board/HUD; danger feedback reads piece positions without affecting failure timers; the aim guide reads authoritative lane geometry without affecting input or launch behavior.
- Deterministic ANGLE screenshots and a short local walkthrough are under `reports/production-gameplay-ui-v2/`.

**Current milestone:** Production Foundation v1. Persistent independent settings, consistent catalog silhouettes, bounded beginner-to-expert target/launcher progression, and GEM RUSH application branding are implemented. Source: `8fe30ea652b2ac49c3369fcc9013df64dcaf1692` / `production-foundation-v1-source`. APK: `build/android/production-foundation-v1.apk` (122,878,070 bytes; SHA-256 `F93ADAF33DDA308D3B7F9FFE3E9210D7601B75ECEA77971EA260C8A9632ED1FD`). Eight regression/profile routes pass; package/signature audit passes. No connected device was available.

## Production Foundation v1 (2026-08-05)

- Audio preferences persist globally with independent Music, Sound FX, and Vibration switches in Pause. Changes survive Restart, Next Level, Home, and process relaunch.
- `GemSpriteLayer` preserves catalog aspect ratio with one uniform scale, matching merge proxies and HUD previews without changing physics radii.
- Level 1 uses one L5 target; Level 2 uses L5 then L6; later levels use deterministic two/three-target L5-L8 cadence and capped `INTRO` through `EXPERT` launcher bands that retain L3/L4 and unlimited launches.
- The application is named `Gem Rush` and uses the generated GEM RUSH app icon for launcher branding and boot splash instead of Godot defaults. See `reports/PRODUCTION_FOUNDATION_V1_REPORT.md`.

## Production UI motion + Restart restoration v1 (2026-08-05)

- Review of `WhatsApp Video 2026-08-05 at 4.39.25 AM.mp4` confirmed static, box-heavy Home/Pause presentation and a Restart defect: after Home -> Continue -> Pause -> Restart, the board reset but the HUD stayed hidden.
- Restart now explicitly restores the gameplay HUD. Home removes all internal/random/infinite-level copy and its large journey card, using floating Level/Coins status, the real coin icon, and bounded logo/primary-action idle motion. Pause uses a shorter game modal with one Resume action and compact Restart/Home utilities.
- Infinite seeded forward progression remains internal and unchanged. Gameplay physics, merge rules, targets, coins, sounds, and table behavior remain unchanged.

**Current milestone:** Asset-matched Home + transparent logo v1. Home now uses the supplied tropical full-screen direction with a floating alpha-matted GEM RUSH logo, responsive Level/Coins card, and glossy coral Play/Continue action. The infinite forward-only eight-gem level system and all gameplay behavior remain unchanged. Source: `84d855a` / `assets-ui-screen-match-v1-source`; clean export record: `403624d` / `assets-ui-screen-match-v1-export-source`; delivery tag: `assets-ui-screen-match-v1`. APK: `build/android/assets-ui-screen-match-v1.apk` (118,277,818 bytes; SHA-256 `7AAB0C4A93F29DC6B40B44D511BDC3A2DB40AC04C4456E6342791F932319824F`). All seven suites and the reviewed ANGLE capture pass. ADB found no device, so physical-device review is not claimed.

## Asset-matched Home + transparent logo v1 (2026-08-05)

- Home now follows the supplied tropical UI direction: full-bleed beach artwork, a floating transparent GEM RUSH hero, a compact cream Level/Coins card, and a large coral Play/Continue action. The prior dark dimmer and generic framed-logo/card composition are retired.
- The uploaded logo remains untouched. A generated chroma source is preserved under `assets/generated/`; the active alpha-matted derivative is `assets/runtime/ui/gem_rush_logo_transparent_v2.png`.
- Infinite randomized eight-gem levels, forward-only progression, gameplay HUD, physics, rewards, audio, targets, Pause behavior, and result qualification are unchanged. No level-tree screen was added.

**Current milestone:** Branded Production Screen Flow v1. The supplied GEM RUSH logo now anchors a standalone responsive Home/Continue screen with saved Level and Coins. Pause, Level Complete/Next Level, and Fail/Retry use one cream/gold/coral production language, clear forward or recovery copy, safe touch targets, and Home routing that prepares a playable state instead of reopening a terminal run. Four reviewed 720 x 1600 ANGLE captures and all seven automated suites pass. Infinite generation, randomized gem/background data, gameplay HUD, physics, animations, rewards, and audio remain unchanged. Source: `fea8710fd9e16a8c79f95d0cf12727731ef75d16` / `production-screen-flow-v1-source`; clean export source: `de96c7f45684414a4e98c87c6500f8dd5c82accb` / `production-screen-flow-v1-export-source`; delivery tag: `production-screen-flow-v1`. APK: `build/android/production-screen-flow-v1.apk` (116,811,201 bytes; SHA-256 `104DE160B3B4C14432DFB89C9C657D921F2C0D2C15B4F9D5348EBDA6B9DE3972`). ADB found no device, so physical-device review is not claimed. See `reports/PRODUCTION_SCREEN_FLOW_V1_REPORT.md`.

**Current milestone:** Infinite Randomized Eight-Gem Levels v1. Every seeded level uses eight unique identities drawn from all 18 gems and shuffles them into the complete local L1-L8 MERGE PATH. Launchers use local L1-L4, three targets move strictly upward through local L5-L8, five backgrounds rotate through generated configurations, Retry is deterministic, and NEXT LEVEL advances and saves forever without a level tree or backward route. Mobile starts at Home/Continue; Pause and result screens provide the required forward/retry/home actions. All seven automated suites, including 200-level generator validation, pass. Source: `2754502f2481239535427df29b9335988a15200d` / `infinite-random-levels-v1-source`; clean export source: `436b3a4d40b62223fee2517886f3d1c47bf1796e` / `infinite-random-levels-v1-export-source`; delivery tag: `infinite-random-levels-v1`. APK: `build/android/infinite-random-levels-v1.apk` (114,869,209 bytes; SHA-256 `E60C83AB649F7F184285770555485F858ACFE03A643ECF1C1D0EF756DB381FBC`). ADB found no device, so installation and physical-device review are not claimed. See `reports/INFINITE_RANDOM_LEVELS_V1_REPORT.md`.

**Current milestone:** New Background Music v1. The user-supplied `sonican-uplifting-loop-cheerful-happiness-297034.mp3` is preserved unchanged and now drives the dedicated continuous background-music player through `assets/runtime/audio/supplied_background_music_v5.ogg`. Runtime gain is reduced from `0.14` to `0.10` so target coins and gem feedback remain dominant; movement never starts or restarts music. Target-only coin routing, merge cues, animations, physics, rewards, targets, and progression are unchanged. All six automated suites pass. Source: `25f83f74b23a1fa19bc121a950b834f7d8bcdc4c` / `new-background-music-v1-source`; clean export source: `1a4a026bccb95c004dfbc13167428fa9c1c90a87` / `new-background-music-v1-export-source`; delivery tag: `new-background-music-v1`. APK: `build/android/new-background-music-v1.apk` (109,063,713 bytes; SHA-256 `615AAA1A67040EDCE68BAA45FF01740A3C85E0EFFDFFF3D486935E3064CD3BF8`). ADB found no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/NEW_BACKGROUND_MUSIC_V1_REPORT.md`.

**Current milestone:** Reference Scale Contrast v1. Direct frame review corrected the overly subtle prior size ladder. Reference board tiers grow much more clearly, while the achieved target gets a temporary enlarged collection beat rather than a permanently larger collider. Active L1-L8 radii are now `30/33/36/39/42/45/48/51 px` (`1.70x` L8/L1); the same values drive live sprite diameter, perspective scaling, physical contact, merge eligibility, and containment. A qualified target body is removed first, then its proxy inherits the exact live gem X/Y scale and receives a uniform `1.18x` reward pop, preventing the previous shrink/shape change during travel. The 80 px TARGET HUD preview remains unchanged. Merge animation, coins, target handoff, audio, physics tuning, rewards, launcher, danger, and L5 -> L7 -> L8 progression remain unchanged. All six suites and two reviewed 720 x 1600 ANGLE proof frames pass. Source: `0f410a56f8396a22fedaa108dc07dde8f44ae2f7` / `reference-scale-contrast-v1-source`; clean export source: `3886dbff6479bfd1bdea5408e9b79a49ab38d766` / `reference-scale-contrast-v1-export-source`; delivery tag: `reference-scale-contrast-v1`. APK: `build/android/reference-scale-contrast-v1.apk` (104,471,551 bytes; SHA-256 `61CDB16C4CDB8654108E540ACA3526AE743683A3D8D3630996ADFC0BC09AD9AF`). ADB found no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/REFERENCE_SCALE_CONTRAST_V1_REPORT.md`.

**Current milestone:** Merge Animation Revert + L1-L8 Size Calibration v1. The rejected v4 irregular color splash is removed and the immediately preceding rigid merge presentation is restored exactly: `0.50 s` total, `0.10 s` pull, uniform `0.62 -> 1.20` pop with damped settle, and bounded flash/ring/eight-ray feedback (`0.56 s`, `1.16x` for L6+). Coins, target animation, supplied continuous music, supplied target coin cue, push-guide removal, Level 1 L5 -> L7 -> L8 flow, and all other v4 behavior remain unchanged. L1-L8 now use a moderate strict size ladder of `36/38/40/42/44/46/48/50 px`; each alpha-trimmed sprite body and simple circular physics collider reads the same authoritative base radius and the same table-depth perspective scalar. L9-L18 remain `42 px` outside the current level scope. All six regression/profile suites pass. Source: `c5487a5d` / `merge-animation-size-calibration-v1-source`; clean export source: `5d5e7867d4e465a75dbead63c5aefdef584f4e17` / `merge-animation-size-calibration-v1-export-source`; delivery tag: `merge-animation-size-calibration-v1`. APK: `build/android/merge-animation-size-calibration-v1.apk` (104,471,551 bytes; SHA-256 `93B8FD867E9389CAC584007EE22523B05F5211A953E01E7AA29D7C3408D41565`). ADB found no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/MERGE_ANIMATION_SIZE_CALIBRATION_V1_REPORT.md`.

**Current milestone:** Reference Animation + Supplied Audio Polish v4. Frame-level comparison now matches the three requested beats: one quick color splash plus rigid uniform gem pop on every merge; exactly four larger foreground coins only when L5/L7/L8 is the active target; and a rewarding large green check followed by an in-place completed-card fade, short gap, and centered next-target fade-in. Supplied `coin-sound.mp3` plays once only on target qualification. Supplied `gem_merge_music_loop.wav` is a separate continuously looping background player at linear gain `0.14`, so coin and gem events remain dominant and movement never triggers music. The push guide remains removed. All six regression/profile suites and six reviewed 720 x 1600 Compatibility/ANGLE captures pass. The Android preset excludes `build/*` and `tools/*`, and the clean APK contains no build, report, tool, or generated-source entries. Physics, rails, radii, collision/merge rules, launcher flow, target order, reward integers, danger flow, and result qualification are unchanged. Gameplay source: `2aa255ea14dcf1349d339916539e953f82bc8268` / `reference-animation-audio-polish-v4-source`; clean export source: `038fa786c11a25c7fe3122cd1d87306d8b1c3b08` / `reference-animation-audio-polish-v4-export-source`; delivery tag: `reference-animation-audio-polish-v4`. APK: `build/android/reference-animation-audio-polish-v4.apk` (104,471,551 bytes; SHA-256 `8300A29ECCEA586DF4A681306AB68D8E87FF1A5F2695583892B791C4982F6F7F`). ADB returned no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/REFERENCE_ANIMATION_AUDIO_POLISH_V4_REPORT.md`.

**Current milestone:** Reference Target Reward Correction v3. A new frame-by-frame review of the supplied reference found coin sequences only at the three target events (about `14.6 s`, `46.6 s`, and `58.0 s`); the earlier `46.55-48.45 s` "ordinary reward" classification was wrong. Production now awards and animates coins only for the active L5/L7/L8 target result. Ordinary merges keep rigid impact/gem/chain feedback but change neither the coin total nor coin-effect state. The mixed reference-video music derivative is preserved but inactive because it contains embedded reward sounds; production currently has no background player and retains only 15 bounded gem one-shots pending separate clean music/coin files. The vertical push guide and its tuning constants are removed; the horizontal coral danger line remains. Physics, table/rails, silhouettes, target collection/handoff, launcher, danger, and result flow are unchanged. Exact source is `77daaa0c69de40140f546217f004d37abc556473`; source tag is `reference-target-reward-correction-v3-source`; delivery tag is `reference-target-reward-correction-v3`. APK: `build/android/reference-target-reward-correction-v3.apk` (102,848,585 bytes; SHA-256 `7BEDDD928F29CAD89E05CDB410EFF6203E8DC6612D265614E84D4FBD440A4B7D`). All six regression/profile suites and four reviewed 720 x 1600 Compatibility/ANGLE captures pass. ADB listed no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/REFERENCE_TARGET_REWARD_CORRECTION_V3_REPORT.md`.

**Current milestone:** Reference Audio + Reward Layering v2. Production now plays a seamless `1.80 s` loop derived from the continuous music in the supplied reference recording; the player starts once and is never triggered by movement/contact. The incorrectly event-mapped reference slices are inactive, while the earlier 15 cached gem/merge/target/result tones are restored behind typed thresholds, cooldowns, three-player reuse, and the session sound toggle; separate coin sounds remain disabled. Four reward coins are slightly larger (`14.5 px`) and, together with the collected target proxy, render in a dedicated HUD foreground above live gems and cards. The duplicate world target burst is removed. Completed L5/L7 targets now fade toward the top-left while L7/L8 fades in from the right, using two prebuilt foreground sprites; target state still advances only in the controller. The push guide shares the centralized coral danger-line color. Physics, silhouettes, L5→L7→L8 progression, rewards, launcher, danger, and results are unchanged. Exact source is `7a619981ff5bc8a572b11c62d19dd0362a00ec5f`; source tag is `reference-audio-layering-v2-source`; delivery tag is `reference-audio-layering-v2`. APK: `build/android/reference-audio-layering-v2.apk` (102,852,681 bytes; SHA-256 `2876EE74B74E2A011C8572A381F1BB45DABB58C92F0F98DE90D2F214CDE44DDC`). All five regression suites and the motion profile pass; four reviewed 720×1600 Compatibility/ANGLE renders are under `reports/reference-audio-layering-v2/final-screenshots/`. ADB listed no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/REFERENCE_AUDIO_LAYERING_V2_REPORT.md`.

**Current milestone:** Reference Feedback Match v1. The corrective reference pass removes all collision squash/stretch/kick and all anisotropic merge transforms; live gems keep a rigid silhouette and merge emphasis is one centered uniform pop. Every confirmed reward now uses exactly four simple gold tokens in one compact ordered arc, with a restrained counter pulse. Target collection ends in a longer gold-ring/green-check/spark confirmation drawn above the target card. The procedural crystal/mallet/shaker soundtrack is not instantiated: production preloads short launch, contact, merge-reward, and target-reward Ogg derivatives cut from the user-supplied reference recording, with no continuous ambience and no layered coin ticks. Level 1 remains exactly L5, L7, L8; launch speed, damping, restitution, merge momentum, table/rails, radii, contact rules, currency values, launcher, danger, and reset behavior are unchanged. Exact gameplay source is `1c1478e7ab07c86d6e2083e71bdaada0135818d2`; source tag is `reference-feedback-match-v1-source`; delivery tag is `reference-feedback-match-v1`. APK: `build/android/reference-feedback-match-v1.apk` (102,827,861 bytes; SHA-256 `16A44ECD5FA4F796E7DD0604DB25FD411F4CDE6D7951BC35B5C925D42C9B1995`). All five regression suites and the motion profile pass; four real 720 x 1600 Compatibility/ANGLE renders are under `reports/reference-feedback-match-v1/final-screenshots/`. ADB listed no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/REFERENCE_FEEDBACK_MATCH_V1_REPORT.md`.

**Current milestone:** Production Gameplay Parity Final v1. The user-video/reference comparison is resolved as one final Level 1 pass: objectives are L5, then L7, then L8; the legal edge aim guide stays inside the sloped table; controlled restitution and merge momentum create visible pile compression/rebound; confirmed contact uses directional squash; merge results lift, tilt, stretch, overshoot, and settle above the pile; the supplied glossy coin drives the HUD and bounded multi-lane reward flight; and the cached original mix now includes rhythmic crystal-island ambience with stronger event cues. Launch speed, table/rail geometry, radii, contact-only merge rules, unlimited launcher, danger handling, currency authority, and reset guarantees remain intact. Exact gameplay source is `2f2dbafa96bcb13e423bc8a49e2cbb0306beb2d3`; source tag is `production-gameplay-parity-final-v1-source`; delivery tag is `production-gameplay-parity-final-v1`. APK: `build/android/production-gameplay-parity-final-v1.apk` (102,674,715 bytes; SHA-256 `132FA633E3208C707D2BA8EF80D5F41A119A061F9608EC0A5C0BC68A06F36E78`). Five gameplay/UI suites and the motion profile pass; four real 720 x 1600 Compatibility/ANGLE captures are under `reports/production-gameplay-parity-final-v1/final-screenshots/`. ADB listed no connected device, so installation, phone feel, listening, and haptics are not claimed. See `reports/PRODUCTION_GAMEPLAY_PARITY_FINAL_V1_REPORT.md`.

**Current milestone:** Reference Gameplay + Coin Parity v1. The production game now uses an always-visible ready-state aim guide, slower reference-paced merge emergence, 10-coin normal / 14-coin major bursts, staggered curved flights into a pulsing COINS counter, original layered coin sounds, and short confirmed-contact squash/pop. The exact confirmed-event reward integers and chain multiplication are unchanged; `coins` is now the canonical run currency while `score` remains a compatibility alias. Simulation speed, damping, restitution, radii, rails, contact/merge rules, Level 1's L1-L4 mixed bag, unlimited launcher, and sequential L7 then L8 targets are unchanged. Exact gameplay source is `b9f15935174f8e52663fcf4c088cac92e0a35bc4`; delivery tag is `reference-gameplay-coin-parity-v1`. APK: `build/android/reference-gameplay-coin-parity-v1.apk` (100,806,453 bytes; SHA-256 `CED1D7496791BBDEE3E01C85EF1D2D397A98998785A438B1C3B1613E1CE29A94`). All six suites and four real ANGLE captures pass. ADB returned no connected device, so phone feel/listening/haptics remain unverified. See `reports/REFERENCE_GAMEPLAY_COIN_PARITY_V1_REPORT.md`.

**Current milestone:** Physics + Reward Feedback v1. Video-guided tuning now produces controlled separating redirects instead of sticky inward contacts, preserves more motion between impacts, awards L6/L7/L8 merges 350/800/1,800 points, gives L6+ a bounded major reward, and makes the procedural feedback mix clearly present with a cached original ambience bed. Level 1 progression remains exactly L7 then L8 with the unchanged L1-L4 mixed launch bag and unlimited launcher. Exact gameplay source is `4cde848`; delivery tag is `physics-reward-feedback-v1`. APK: `build/android/physics-reward-feedback-v1.apk` (100,793,853 bytes; SHA-256 `AE1189E5E8AC21EA95497182F90F05B4F81383573222A74886BAD13453861594`). All gameplay/UI/contact/catalog/profile suites pass; physical-device listening/haptics remain unverified because ADB is unavailable. See `reports/PHYSICS_REWARD_FEEDBACK_V1_REPORT.md`.

**Current milestone:** Production UI Polish v4. MERGE PATH owns the top row and shows all eight Level 1 gems at their original catalog silhouettes without circular UI frames; equal SCORE/NEXT cards sit immediately below it. Pause, Win, and Fail use simple responsive cream/gold cards. `GameConfig.configure_viewport()` supplies one shared horizontal table offset consumed by artwork, rails, launcher, live pieces, collection presentation, effects, and debug markers, so wide canvases center visual and physical gameplay together. Exact source is `8bbc4b2ae7f3259defd740e033e053d46dd8a9df`; delivery tag is `production-ui-polish-v4`. Fresh APK: `build/android/production-ui-finalization-v1.apk` (100,789,757 bytes; SHA-256 `B771310C4A1B829AD6AC740663353A61C3EF68AFAD34FDDDD70DD063C00E0266`). All six suites and 36 real ANGLE captures pass. See `reports/PRODUCTION_UI_POLISH_V4_REPORT.md`.

**Current milestone:** Production UI Simplification v3. SCORE, NEXT, TARGET, and LEVEL 1 now share one coral pill-label language over simple cream/gold panels. MERGE PATH shows all eight active gameplay gems in a larger readable strip. TARGET contains only the authoritative current gem and follows the portrait-bottom table, maintaining a 46 design-pixel gap above the playable top; target names, sequence fractions, progress text, and the progress bar are intentionally absent. Exact UI source is `126585365fd7a5c5b8bfc4f1590964ddc1b3aedd`; delivery tag is `production-ui-simplification-v3`. APK: `build/android/production-ui-simplification-v3.apk` (100,789,757 bytes; SHA-256 `EE39C5935AD6CF992C4BEFEA577B1F5095CD841CDA205B7A1BD4AB3EE2BC710E`). Six resolutions, simulated notch, 35 final captures, and all six regression/profile suites pass. See `reports/PRODUCTION_UI_SIMPLIFICATION_V3_REPORT.md`.

**Current milestone:** Production UI Corrective Pass v2. The reported 576 x 1312 composition has been corrected and reviewed from real ANGLE renders: SCORE/NEXT are balanced and contained; MERGE PATH has a readable framed surface; the target gem, name, labeled progress, and bar share one clipped responsive card; Level/Target/Settings align as one objective row; and the danger line has stronger visual contrast without any rule or coordinate change. Exact UI source is `baae6488874174811207437d2b84f5daa6b148fa`; delivery tag is `production-ui-finalization-v2`. APK: `build/android/production-ui-finalization-v2.apk` (100,793,853 bytes; SHA-256 `53CEF1A789A91956B80CF8EB627BCE066899C1445919104A366D162F23E61A38`). Six resolutions, simulated notch, 35 final captures, and every regression suite pass. See `reports/PRODUCTION_UI_CORRECTIVE_PASS_V2_REPORT.md`.

**Current milestone:** Production UI Finalization v1. Gameplay now uses reusable safe-area-aware `GameplayHud.tscn` and `ResultOverlay.tscn` layers backed by one cached design system. SCORE/NEXT are balanced; scores fit through `Qi`; the five-step merge path, level badge, and current L7/L8 target are readable; Settings is the only gameplay action; and Pause/Win/Fail share responsive production-quality composition and states. Exact UI source is `a861fecb8e7b344b4dabe63894e2ae10e2c2fc63`; delivery tag is `production-ui-finalization-v1`. APK: `build/android/production-ui-finalization-v1.apk` (100,789,757 bytes; SHA-256 `32737D83797840B2145913CADBD54EE1CC7A4004B3FD752BB3D16C88E3DC57E8`). All requested resolutions and a simulated notch pass. Gameplay, targets, table, rails, perspective, collisions, scoring, rewards, sound, and haptics are unchanged. See `reports/PRODUCTION_UI_FINALIZATION_V1_REPORT.md`.

**Current milestone:** Gameplay UI, Animation, Reward Feel, and Pause/Settings Finalization v1. Production now uses a responsive supplied-art `GameplayHudLayer`, a modal pause/settings popup with Resume and the correct supplied RESTART pill, child-only merge/spawn presentation, bounded spark/score effects, late-fade visual-only target collection, and an exactly ordered final-win sequence. The cyclic launcher contains no counter or finite limit; 80 post-restart production launch cycles pass. Level 1 remains L7 then L8 with the unchanged L1-L4 mixed bag, and the approved table, rails, perspective/collider mapping, motion, contacts, danger behavior, and scoring formula are unchanged. Exact APK source is `42c7b38085aa70bd422f35637b76758507acc7e9`; delivery tag is `gameplay-ui-feel-finalization-v1`. APK: `build/android/gameplay-ui-feel-finalization-v1.apk` (100,772,764 bytes; SHA-256 `420684CA1D975A434D421EF129FAB195E98FA511C6C2207CA71D64DD7A374090`). See `reports/GAMEPLAY_UI_FEEL_FINALIZATION_V1_REPORT.md`.

**Current milestone:** Video-Verified Unlimited Launcher + HUD v1. The 9:12 user video exposed a real permanent merge/lifecycle deadlock: an unrelated merge could strand a moving active marker in `SPAWNING_NEXT`. Launcher handoff is now bounded to 0.30 seconds and independent of settling; crowded motion and unrelated merges cannot exhaust launches. NEXT/GOAL containment, centered target art, supplied RESTART, and larger settings are verified in a local render. See `reports/VIDEO_VERIFIED_UNLIMITED_LAUNCHER_HUD_V1_REPORT.md`.

**Current milestone:** Unlimited Launcher Runtime Proof v1. The launcher now recovers if its active marker is unexpectedly absent, and the Level 1 test drives forty complete production frame-loop launch cycles to prove continued launcher creation. The L7/L8 GOAL preview uses a larger aspect-preserving contain area; no physics, table, or motion behavior changed. See `reports/UNLIMITED_LAUNCHER_RUNTIME_PROOF_V1_REPORT.md`.

**Current milestone:** Unlimited Launcher + HUD Final Repair v1. A moving non-active board gem can no longer block the next launcher; launches continue indefinitely until danger failure or final L8 completion. The HUD uses supplied REPLAY artwork for restart and a matching red-header/cream-body goal card with contained target artwork. See `reports/UNLIMITED_LAUNCHER_HUD_FINAL_REPAIR_V1_REPORT.md`.

**Current milestone:** Portrait Bottom Table + HUD Repair v1. On expanded portrait canvases, one runtime bottom offset moves the table art and every shared table-physics coordinate together; the HUD remains top-anchored. The active GOAL icon uses contain scaling within a larger supplied panel, settings is larger, and the supplied restart control resets to an unlimited ready launcher. See `reports/PORTRAIT_BOTTOM_TABLE_HUD_REPAIR_V1_REPORT.md`.

**Current milestone:** Reference-Accurate HUD + Unlimited Level 1 v1. SCORE, five-ring progression, NEXT, one active GOAL, and settings use direct approved sheet regions; gem previews use aspect-preserving contain scaling. Level 1 remains exactly L7 then L8 with the controlled L1-L4 mixed bag and unlimited launches before and after restart. Background cover fills 720x1600, 1080x1920, and 1080x2400 without moving table or physics coordinates. See `reports/REFERENCE_ACCURATE_HUD_UNLIMITED_LEVEL1_V1_REPORT.md`.

**Current milestone:** Reference HUD + Unlimited Launches v1. The visible HUD matches the supplied reference composition: SCORE left, gem ladder center, NEXT right; objective counters and Restart/S/V controls are not drawn there. Launches are unlimited—only danger overflow or completing the two sequential objectives ends a run. Expanded portrait aspect handling removes the prior black bars. Table, rails, perspective scaling, colliders, motion, and contact merging are unchanged. See `reports/REFERENCE_HUD_UNLIMITED_V1_REPORT.md`.

**Current delivery:** `restored-working-table-rails-v1.apk` restores the historically proven `new-table-shadow-contact-fix-v1` table-interpolated side containment and launcher clamp. Its source rail geometry is translated exactly `+116px` in Y to the retained bottom-aligned table. The later perpendicular slanted-line resolver and its competing launcher limit system are removed. See `reports/RESTORED_WORKING_TABLE_RAILS_V1_REPORT.md`.

**Current delivery:** `physical-rails-match-table-v1.apk` is the standalone rail-only build. The visible table and deterministic physical rails share exact design-space anchors: left `(171.4, 413.0) → (40.7, 1226.0)` and right `(547.8, 413.0) → (680.1, 1226.0)`. Slanted circle-to-line containment replaces the old vertical X clamp during normal motion. See `reports/PHYSICAL_RAILS_MATCH_TABLE_V1_REPORT.md`.

**Current delivery:** `table-perspective-matched-physics-v1.apk` is a fresh standalone export of the matched perspective/physics implementation. Gems use the same 0.85–1.00 table-depth scale for their rendered root, shadow, and deterministic simulation radius; rail containment uses the scaled live radius. Source behavior remains commit `25fac1f`; see `reports/TABLE_PERSPECTIVE_MATCHED_PHYSICS_V1_REPORT.md`.

**Current milestone:** Matched Perspective Physics Scale v1. Gems use one table-local-Y scale (`0.85` at the back to `1.00` at the front) for both their visual root and simulation radius. Rails, collision, contact-only merges, and shadows use that same live geometry. APK: `build/android/matched-perspective-physics-scale-v1.apk`. See `reports/MATCHED_PERSPECTIVE_PHYSICS_SCALE_V1_REPORT.md`.

**Current milestone:** Pre-Shared-Perspective Restored v1 at rollback commit `97b6bc355172c3f1df394a85b9bc63f6fb376290`. This normal revert removes only `2c7114c` (`shared-perspective-win-sequence-fix-v1`) and restores the exact code state of pre-task commit `70733c0`, with the working mechanics milestone at `3316d2d` / `visible-touch-table-alignment-fix-v1`. Fresh verification APK: `build/android/pre-shared-perspective-restored.apk`. See `reports/LAST_TASK_ROLLBACK_REPORT.md`.

**Current milestone:** Visible-Touch Table Alignment Fix v1 at commit `3316d2dcdebde9528885c882b2de385c26862c66`, tagged `visible-touch-table-alignment-fix-v1`. This is a narrow repair on top of `complete-perspective-view-variety-v1`: live gems no longer use dynamic Y perspective or uncalibrated tier scaling. Their fixed approved body textures, fixed colliders, sprite roots, shadows, and physics positions remain aligned in the same shared table-local coordinate system. The table artwork retains its bottom-anchored perspective and stable Y/ID draw ordering remains active. APK: `build/android/visible-touch-table-alignment-fix-v1.apk`. See `reports/VISIBLE_TOUCH_TABLE_ALIGNMENT_FIX_V1_REPORT.md`.

**Current milestone:** Level 1 Balance v1 builds from the approved `level-1-flow-v1` baseline. It preserves Level 1's L1-L8 range, L1/L1/L2 queue, empty start, no shot cap, overflow failure, motion, colliders, merge rules, table, and HUD. The sole target type is now two confirmed merge-created L4 Sapphires; the deterministic minimum is twelve Pearl-equivalent launches. See `reports/LEVEL_1_BALANCE_V1_REPORT.md`.

**Current milestone:** Level 1 Flow v1 is delivered at commit `4ad1d51e09e0efce75d6842b0310880095ad349c`, tagged `level-1-flow-v1`, from the clean `18-gem-progression-tested-v1` baseline. It adds only data-driven Level 1: L1-L8 normal-play exposure, deterministic low-tier L1/L2 queue, and one confirmed-merge-created L5 target. Motion, colliders, full catalog, table, HUD structure, feedback, queue lifecycle, danger failure, and win sequencing are preserved. APK: `build/android/level-1-flow-v1.apk` (99,200,243 bytes; SHA-256 `E7BDBBE6D1158F113F705980602A769DA64078194A61780E45D6AA4156616D9B`). No device was connected. See `reports/LEVEL_1_FLOW_V1_REPORT.md`.

**Current milestone:** 18-Gem Order v1. The final deterministic L1–L18 visual progression is recorded in `reports/18_GEM_ORDER_V1_REPORT.md`; `AssetCatalog.GEM_TIER_SOURCE_INDEX` is the only source of tier-to-asset truth. The approved size/collision calibration is preserved per asset after reordering. APK: `build/android/18-gem-order-v1.apk`; runtime source commit `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194`.

**Current milestone:** 18-Gem Size & Collision Fix v1 at `fc71e2dad781134948d1962dfe2a49ad0b6521fe`. All 18 gem runtime textures now use alpha-trimmed calibrated derivatives with a fixed visual-to-collider mapping and separate visual-only shadows. The approved `18-gem-motion-smoothness-fix-v1` movement profile, collision radii, merge rules, table, UI, target flow, score, launcher, outcomes, sound, and haptics are unchanged. See `reports/18_GEM_SIZE_COLLISION_FIX_V1_REPORT.md`.

**Phase:** 18-Gem Motion Smoothness Fix v1, tagged `18-gem-motion-smoothness-fix-v1`. The 18-tier chain remains intact, while the smooth `new-table-shadow-contact-fix-v1` motion profile is restored: textures are cached at initialization, runtime derivatives are capped at 256 px, sprite appearance work is not repeated each frame, and Pearl–Diamond collision bodies match the baseline exactly. See `reports/18_GEM_MOTION_SMOOTHNESS_FIX_V1_REPORT.md`. No level, multi-target, perspective, table, HUD, launcher, score, sound, haptics, win/fail, or gameplay-design change is present. Android export remains blocked by the documented Godot CLI filename bug; no APK is claimed.

**In progress:** Visual Sequencing + Perspective + Contact Calibration v2. The baseline is clean commit `8fdebd4` / tag `visual-physics-calibration-v1`. This milestone separates `win_qualified` from `win_presented`, moves result UI into `ResultOverlayLayer`, adjusts upper table anchors to `58..662`, and calibrates the visual gem body independently from stable simple colliders. It is awaiting its final APK export, manifest record, commit, and tag.

**Phase:** New Table + Shadow-Separation Contact Fix v1 delivered at commit `0b562d5b85b0b4d0330ecd10da3f832408949ad9`, tagged `new-table-shadow-contact-fix-v1`. It activates the latest supplied table, uses body-only gem textures with presentation-only separated shadows, and preserves all simulation/merge rules. The standalone APK is `build/android/new-table-shadow-contact-fix-v1.apk` (76,113,263 bytes, 2026-07-29 13:05:58 +05:00). Godot parse/import and `CLEAN_CONTACT_TESTS` passed; no device was connected for installation.

**Phase:** Visual-Physics Calibration v1 delivered at source commit `8fdebd405c791eddf9188bd32e9f0de3b83cbd42`, tagged `visual-physics-calibration-v1`. It uses calibrated runtime textures and per-level collision radii (Pearl 42, Ruby 42, Emerald 32, Sapphire 42, Diamond 33 design px), a 0.75 px contact epsilon, and a shallower derived coral-table texture whose physical rails are `x=90..630` at the top and `x=0..720` at the bottom. Collision sound telemetry now comes from confirmed physical contacts, with debug visualization available by F8 in desktop/editor builds and disabled by default. See `reports/VISUAL_PHYSICS_CALIBRATION_V1_REPORT.md`.

**Phase:** Asset Integration — Background, Table, and Gems v1 delivered at source commit `7ac26f197d7768f13f8ea87c17e29b9893db4300`, tagged `asset-integration-background-table-gems-v1`. It replaces procedural live gem/table/background rendering with the user-supplied tropical background, calibrated coral table, and Sprite2D runtime gem textures. Table visuals and physics now use one trapezoid layout model; all merge, chain, queue, score, win/fail, pause, sound, haptic, and restart rules remain unchanged. The standalone APK is `build/android/asset-integration-background-table-gems-v1.apk` (70,457,131 bytes, 2026-07-29 10:24:35 +05:00). No Android device was connected. See `reports/ASSET_INTEGRATION_BACKGROUND_TABLE_GEMS_V1_REPORT.md` and `ASSET_INVENTORY.md`.

**Phase:** Reference Table + Gem Audio v1 delivered at source commit `d2e99213f01005ba08ff1f9bd50a98ac11a967c7`, tagged `reference-table-gem-audio-v1`. The table is now a contained physical surface with visible procedural crystal scenery around it. Generic sine cues were replaced with original runtime crystal synthesis; gem and wall contacts are distinct, thresholded, and throttled. The standalone APK is `build/android/reference-table-gem-audio-v1.apk` (27,748,993 bytes, 2026-07-29 08:29:58 +05:00). Godot parse/import validation and the full headless suite passed. The ADB query did not complete in this session, so no device installation or launch was attempted. See `reports/REFERENCE_TABLE_GEM_AUDIO_V1_REPORT.md`.

**Phase:** Sound + Haptics v1 delivered at source commit `5245163722e2c34f86657aa25483f47d96e7fdfa`, tagged `sound-haptics-v1`. It adds procedural one-shot sound, mobile-safe haptic routing, and session-only `S`/`V` controls. All gameplay rules are preserved. The standalone APK is `build/android/sound-haptics-v1.apk` (27,744,897 bytes, 2026-07-29 07:59:11 +05:00); `adb devices -l` found no connected device. See `reports/SOUND_HAPTICS_V1_REPORT.md`.

**Phase:** Progression HUD v1 delivered at source commit `2dc007575457fec112acabc51b7d6dcfb9f06462`, tagged `progression-hud-v1`. It adds presentation-only current/next gem previews, a compact Diamond-target progression strip, and a simplified luxury HUD. It does not change physics, contact merge eligibility, chains, score rules, launcher lifecycle, danger handling, outcomes, or restart. The standalone APK is `build/android/progression-hud-v1.apk` (27,732,265 bytes, 2026-07-29 07:42:27 +05:00); no phone was connected for device testing.

**Phase:** Physics and pacing parity v1 delivered at source commit `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b`, tagged `physics-pacing-parity-v1`. It changes only documented centralized feel values plus bounded tangential contact resistance and merge momentum handoff. Merge eligibility, chains, launcher lifecycle, score, win/fail, restart, and gem mapping remain unchanged. The standalone APK is `build/android/physics-pacing-parity-v1.apk` (27,728,010 bytes, 2026-07-29 07:25:11 +05:00); no phone was connected for device testing.

**Prior verified baseline:** Gameplay balance v1 delivered at source commit `4bb5469456bf23480b569a15b9c44c7692e30257`, tagged `gameplay-balance-v1`. It centralizes delta-based launch, damping, settling, collision, border, presentation, chain-display, and next-launcher pacing values without changing gameplay rules. No phone was connected for device testing.

## Do Not Regress

- Visual layout constants and `GemVisuals` must remain presentation-only; never pass their values into simulation, collision, merge eligibility, launcher lifecycle, danger timers, scoring, chains, or outcomes.
- Preserve the fixed portrait gameplay coordinate system. Canvas-item stretching scales the visual design; it does not authorize changes to board bounds or input math.
- Preserve the balance profile in `GameConfig`: all mobile-feel numbers are centralized and documented with approved ranges. Do not alter contact eligibility, merge resolution, scoring, chain logic, danger semantics, or launcher state transitions during tuning.

**Phase:** Gemstone visual prototype delivered at source commit `561235ad45a6dbf50a3b8a018820656dae53cd53`, tagged `gem-visual-prototype-v1`; gameplay source remains the verified playable-loop behavior with presentation-only visual updates.

## Verified Working Now

- `build/android/gem-visual-prototype-v1.apk` is the standalone Android delivery (27,723,914 bytes, 2026-07-29 04:40:27 +05:00).
- `GemVisuals` owns procedural visuals only: Pearl, Ruby, Emerald, Sapphire, and Diamond match their intended level mapping without affecting circular collision truth.
- Merge physics review found no justified simulation retune. The only safe improvement was render ordering: ghosts draw before live pieces so upgraded gems do not appear beneath fading source visuals.
- Godot parse/import validation and the complete headless controller/simulation suite passed. No device installation was attempted in this session.

**Phase:** Complete playable level loop delivered at source commit `2d982a8af80e0477caf2c8641f8543c28587a178`, tagged `clean-contact-merge-v3-playable-loop`.

## Verified Working Now

- `build/android/clean-contact-merge-v3-playable-loop.apk` is the verified standalone Android APK (27,719,661 bytes, 2026-07-29 04:16:50 +05:00).
- The level awards score only from confirmed merges: Ruby 10, Emerald 25, Sapphire 60, Diamond 150; each confirmed event in one resolution sequence increments its score multiplier.
- Creating Diamond wins once and blocks further launcher input/spawns. A settled non-active gem below the visual-only danger line for 0.75 seconds fails once; moving and active launcher gems are exempt.
- Replay, Retry, and Restart share the complete reset path and restore an empty board with exactly one active launcher.
- Parse/import validation, the complete headless controller/simulation suite, and standalone Android export passed. `adb devices` found no connected phone, so no device test was performed.

## Do Not Regress

- Score and win must consume confirmed merge events only; never rescan the board or collisions for outcomes.
- Danger timers must remain keyed by non-active piece ID and be cleared for moving, active, removed, merged, or safe pieces.
- Win/fail overlays must block launches and new launcher spawns until a full reset.

**Phase:** Clean Gameplay Milestone 2 chain-merge polish delivered at commit `10f8d59408cccd6287d308f5fc0ab0046326ea3a`, tagged `clean-contact-merge-v2-chain-polish`.

**Governance follow-up:** Documentation-only handoff hardening is committed in Git as `docs: harden AI project knowledge and agent workflow`. It adds no gameplay or build change.

## Verified Working Now

- This task began from clean commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tag `clean-contact-merge-v1-spawn-fix`, and delivered the confirmed standalone APK `build/android/clean-contact-merge-v2-chain-polish.apk` (27,711,469 bytes, 2026-07-29 03:44:48 +05:00).
- Empty board, one active launcher, drag/release, borders, visual-only danger line, and settlement-gated one-time queue advance remain covered by the headless suite.
- v2 preserves contact-only same-level merging, adds capped local contact chains, and uses presentation-only effects.

## Do Not Regress

- Only `SPAWNING_NEXT` can create a launcher; idle settled frames must not spawn.
- Never merge distant or cross-level gems, reuse stale pairs, or perform board-wide chain scanning.
- Presentation must never alter collision, positions, IDs, or merge candidates.
- Do not spawn a launcher until pieces are settled and merge presentation is complete.

The verified milestone source is commit `ac795736bbecb4ee83c346a2717276d66a2b483c`, tagged `clean-contact-merge-v1`. Its standalone APK is `build/android/clean-contact-merge-v1.apk` (27,707,373 bytes, built 2026-07-29 03:12:46 +05:00). Godot parse/import validation, headless integration tests, and Android export passed. No phone was connected, so device testing has not occurred.

Implemented scope: empty-board launcher, horizontal drag, negative-Y shot, visual-only danger line, top/side containment, settlement-gated next launcher, and current-contact-only gem merges. Do not modify merge behavior without a specific task and targeted regression tests. Chains, scoring, loss/win, sounds, menus, persistence, ads, and final art remain out of scope.

The verified spawn-lifecycle source is commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tagged `clean-contact-merge-v1-spawn-fix`. Its standalone APK is `build/android/clean-contact-merge-v1-spawn-fix.apk` (27,707,373 bytes, built 2026-07-29 03:23:14 +05:00). The launcher now follows `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`; one active launcher exists at a time and the queue advances once per completed shot. Headless parse/import validation and integration tests passed. No Android device was connected, so the APK has not been installed or tested on-device.
# Current milestone: Perspective Table View v1

Delivered from build source commit `5125a4c238d1c9963cad8d185d68491910892623` and tagged `perspective-table-view-v1`. The standalone APK is `build/android/perspective-table-view-v1.apk`; see `reports/PERSPECTIVE_TABLE_VIEW_V1_REPORT.md`. It changes only shared lower table/view composition, bounded visual-only Y perspective, and stable front/back ordering. Level 1 targets/balance, launcher queue/weights, gem order, collision radii, merge rules, score, danger failure, sounds, haptics, and all tier intrinsic sizes remain unchanged.
# Current milestone: Complete Perspective View & Variety v1

The project now uses a fully bottom-anchored table transform with perspective-only gem depth, fixed tier presentation growth, stable Y/ID occlusion, varied Level 1 source silhouettes, and result-presented target counting. Simulation and calibrated colliders remain unchanged. See `reports/COMPLETE_PERSPECTIVE_VIEW_VARIETY_V1_REPORT.md`.

## HUD alignment correction - 2026-08-08
The light glass HUD now explicitly expands its horizontal container chain to the full 720 design width. Coins/Level are left aligned, Next/Settings are right aligned, and the merge progression + Target stack is centered over the table. Target-to-table visual clearance is 28 design pixels to account for the StyleBoxFancy glass shadow. Gameplay/table geometry remains unchanged.

### HUD alignment correction (2026-08-08)
The light glass gameplay HUD now forces both the utility header and gameplay objective anchor to the full 720px design width before applying safe-area margins. This fixes the observed runtime collapse where Next/Settings and the centered progression/Target stack were pulled toward the upper-left. Expected layout: Coins top-left, Next top-right, Level below Coins, Settings below Next, progression centered above Target, and Target centered immediately above the table.

## 2026-08-09 — Front-end flow and modal state

Crystal Magic now has a two-step Home-to-game flow. The Home `PLAY`/`CONTINUE` action no longer immediately unpauses gameplay; it opens a level-preview modal first. The preview reads the controller HUD snapshot and displays the current level plus target gem/objective, then emits the existing `play_requested` signal only from `START GAME`.

Home now exposes a Settings button and a settings-only modal. Its Music, Sound FX, and Vibration controls are wired to the same controller handlers and `GameSettingsService` persistence path used by the gameplay pause modal. The Home settings modal intentionally has no Resume, Restart, or Home actions; it closes with DONE/Back.

The pause modal keeps Resume, Restart, and Home, but its layout is normalized to a shared content width with full-width Resume and equal-width secondary actions. Setting controls are explicit ON/OFF toggle buttons rather than the prior cramped default CheckButton presentation.

## Latest polish
- Home-screen music now keeps playing while the home overlay is visible unless the Music setting is turned off.
- Launcher/system splash now use a borderless Crystal Magic icon that is separate from the main logo.
- Godot boot splash now uses the tropical beach background plus the generated Crystal Magic logo.

## v8.1 splash/icon refinement
- App icon now uses the generated Crystal Magic logo with explicit padding over a beachy background.
- Adaptive Android icon now uses a separate beach background and a padded transparent foreground logo.
- System splash icon and Godot boot splash were re-composed for a cleaner fit.

## v8.2 branding correction
- Home logo, boot splash logo, and icon branding now all resolve from the exact supplied Crystal Magic transparent logo.
- Boot splash no longer uses a background image; it displays the standalone logo on a blue theme background.
- App icon uses the same logo over a beach background with explicit padding.
- Settings cog icon is blue everywhere.
- Home logo slot was enlarged to prevent gem-edge clipping.

## Result modal unification — 2026-08-10
- Home always shows `PLAY`, including returning players; selecting it still opens the pre-level preview before entering gameplay.
- Win/Failed overlays share the production light-glass modal system used by Pause and Home Settings: `gameplay_modal_panel_style()`, 520×690 design minimum, 424px action width, blue typography, light-glass reward card, and matching button motion.
- Win and failure use the same shell; only title/subtitle, result art, transition copy, and primary action change by outcome.


- Branding hotfix: Home now uses `assets/runtime/gem-aim-logo.png`, Android/game icon now uses `assets/runtime/gem-aim-icon.png`, settings icon was switched to a crisp PNG derivative, and the home tagline size was increased for readability.
# Current State Addendum - AdMob Integration v1

The project now has one pause-safe `AdManager` autoload backed by Poing Studios Godot AdMob v5.0.0. It initializes once, preloads interstitial and rewarded ads, exposes readiness, prevents overlapping fullscreen sessions, retries load failures, destroys consumed ads, and reloads each format. Debug builds are hard-routed to Google's Android test units; release unit placeholders are centralized in `scripts/ad_config.gd`.

Only the natural completed-level exit may request an interstitial, at levels 2, 4, 6, and so on. The Level Complete modal keeps the existing reward/total display and now offers Collect plus Double Coins. The normal reward remains controller-authoritative; exactly one additional copy is persisted only from the confirmed rewarded callback. Early close/failure restores Collect without a bonus. Pause, Settings, active gameplay, Retry, failure, physics, targets, difficulty, and merge behavior are unchanged.

Godot 4.6.3 whole-project import/parse passes. The focused AdMob suite and existing branding/push-line suite reach PASS; the Windows headless test runner still exits with its known post-PASS teardown access violation. The fresh debug APK is `build/android/admob-integration-v1-debug.apk` (108,146,729 bytes, SHA-256 `6BFD90E81F509881C651162B1FA8602200690871F2A564E24B7A06B98C4D4005`). Package, AdMob manifest/plugin registration, packaged test IDs, arm64 runtime, and v2 signature checks pass. ADB returned no connected device, so physical Google test-ad verification is not claimed.
# Current State Addendum — Post-AdMob Reward Flow and Size Fix

Level Complete now remains visible until its base or doubled reward is resolved and the player explicitly presses `NEXT LEVEL`. Collect banks the existing authoritative level earnings once; only the rewarded earned callback adds one bonus copy. Failure/early close restores Collect without progression. Next Level is the natural every-two-level interstitial point and then opens the existing Level Intro modal; Play explicitly resumes the generated next level.

The Android application ID is `com.owais.majestygems`. The verified debug APK is `build/android/majestic-gems-post-admob-fix-debug.apk` at 53,363,440 bytes with SHA-256 `7EEF183F5F7CB068292BFB1B588CD8ED271B9873AC5466D3AD471FBBC3E7DBD4`. It contains only arm64, retains AdMob runtime dependencies/test configuration, and excludes editor/sample/C#/iOS/mock/ICU payloads. Automated parse/state/package/signature checks pass; no Android device was connected, so physical install/ad playback is not claimed. See `reports/POST_ADMOB_REWARD_FLOW_AND_SIZE_FIX.md`.
# Current State Addendum - Game Flow + Reward + Splash Polish

The active mobile flow is now `STARTUP -> HOME -> LEVEL_READY -> PLAYING -> LEVEL_COMPLETE -> REWARD_PROCESSING -> optional AD_SHOWING -> LEVEL_READY`. Home PLAY reveals the gameplay/table screen before Level Ready appears. START GAME is the only action that resumes simulation.

The post-reward `NEXT LEVEL` state no longer exists. Normal Collect and earned Double Coins keep the same Level Complete popup alive through their short presentation, animate the gameplay coin HUD from the pre-level bank to the final bank, then close automatically. Even-level interstitials run only after that animation; dismissal/unavailability routes to Level Ready, never directly to play.

Rewarded earnings remain exactly-once and controller-owned. The earned callback persists the bonus, while the x2/result/HUD animation waits for rewarded dismissal so it cannot complete behind the ad. Early close/failure restores Collect/Double on the same popup with no bonus or progression.

Android keeps the native Majestic-blue system splash and disables the extra Godot Android boot splash. A dedicated in-engine splash uses the existing contained Majestic Gems logo for a 1.05-second hold plus 0.20-second fade before Home. Application display name is now `Majestic Gems`; package remains `com.owais.majestygems`.

Verified debug APK: `build/android/majestic-gems-flow-reward-splash-polish-debug.apk`, 53,370,111 bytes, SHA-256 `06A5C78AF3DE4A63BBE2107A074E0B0C22D363A0B129D7F8DD20D5B58C999265`. Package, arm64-only payload, forbidden-file, and v2 signature audits pass. ADB returned no connected device, so physical startup, reward/ad playback, and lifecycle behavior are not claimed.

# Current State Addendum - Splash and Reward UI Correction

The extra `StartupSplashLayer` has been removed. Android enters the existing Home overlay directly; that same overlay briefly shows its exact full-bleed `level_bg_1.png` cover backdrop and contained Majestic Gems logo before revealing Home controls. There is no second custom CanvasLayer or intermediary scene.

Level Complete now separates the prominent earned amount from the bank total. Both values use the same `CoinIcon`/`AssetCatalog.COIN_REWARD` presentation path as the top-left gameplay HUD. Collect and rewarded x2 still lock immediately, animate the authoritative final total, and transition only after the popup and HUD animations finish.

Verified debug APK: `build/android/majestic-gems-splash-reward-ui-polish-debug.apk`, 53,369,788 bytes, SHA-256 `1A500655BBCF5BC8AAE68F36983B46951C5C1C1C6449DBB8D759A7A826055827`. Package, arm64-only payload, removed-splash payload, forbidden-file, and v2 signature audits pass. ADB did not return, so no physical cold-launch or ad verification is claimed.

# Current State Addendum - Single Android Splash

The timed logo-only state inside `HomeOverlayLayer` is removed. Mobile startup now shows only Android's platform-owned splash and then renders the complete Home menu immediately, including logo, level, coins, Play, and Settings. `StartupSplashLayer` remains deleted and the separate Godot Android boot splash remains disabled.

Android 12+ does not support a full-screen cover bitmap in its system splash; it requires an opaque background color and a constrained icon. The current single-splash configuration therefore keeps the mask-safe Majestic icon over its matched blue and does not add another in-app image phase.

Verified debug APK: `build/android/majestic-gems-single-splash-correction-debug.apk`, 53,368,728 bytes, SHA-256 `65575E1B14AF81E88608CB07BDFAB37604B2D5B1B014F340BFC5F6D467351840`. Export exited 0; package, arm64-only payload, removed-splash payload, forbidden-file, and v2 signature audits pass. ADB timed out, so physical cold-launch behavior is not claimed.
# Current State Addendum — Poing UMP `canRequestAds()` Patch v1

Poing AdMob v5.0.0 now carries a local one-method Android bridge patch exposing Google UMP `ConsentInformation.canRequestAds()` as GDScript `can_request_ads()`. Android startup updates consent information and uses that authoritative result before initializing/loading ads, including the documented update-failure case where a valid previous-session decision may remain usable. If ads are not allowed, Home and gameplay remain usable without an ad request.

Home and Pause Settings contain the published Privacy Policy link and conditionally expose Poing's official UMP Privacy Options form. Debug EEA/not-EEA forcing is centralized, disabled by default, and hard-disabled for release builds. Existing interstitial cadence, rewarded exact-once behavior, production/test IDs, rewards, gameplay, physics, package, and splash are unchanged.

Patched AARs and reapplication source are recorded in `reports/POING_UMP_CAN_REQUEST_ADS_PATCH.md`. Debug APK: `build/android/ump-can-request-ads-patch-v1-debug.apk`, 53,376,732 bytes, SHA-256 `DB2299C1E6F6C779D548A2CFC21833DF32B43353EFEF9324D1771288BF2686C6`. Native AAR build, parse, focused regression markers, APK DEX/package/ABI/configuration/signature audits pass. No Android device was connected, so live UMP/ad acceptance is not claimed.

# Current State Addendum — Google Play Closed Testing release

The Android export preset now targets a Gradle release App Bundle at `build/android/majestic-gems-closed-test.aab`. Non-debug builds select the Majestic Gems production interstitial and rewarded units; debug builds retain Google's test units. The user-provided upload keystore and Godot export credentials are local/ignored and are not part of source control.

The verified bundle uses package `com.owais.majestygems`, versionCode `1`, versionName `Majestic Gems`, min SDK 24, target/compile SDK 36, and arm64-v8a only. Its release manifest is not debuggable and contains the configured production AdMob App ID. Packaged release routing resolves both production units, forced UMP geography is disabled, the release test-device list is empty, and no consent reset or temporary device hash is packaged.

UMP remains the official production flow: update consent information, show Google's form only when required, use the locally patched authoritative `canRequestAds()`, and initialize/load ads only when allowed. Ad unavailability and consent/update failures remain fail-open for gameplay; ad success is never required to continue.
# Current State Addendum — Responsive reference UI + scale test v1

Gameplay now follows the supplied portrait reference hierarchy while retaining the existing Majestic Gems theme and artwork: Coins is left, Target is the centered dominant top card, Next and Settings share the right slot, and the redundant Level box is removed. The complete authoritative eight-gem progression path is centered in its own bottom-safe panel.

The table is centered and dominant across supported portrait shapes. `GameConfig` owns one responsive trapezoid transform shared by table artwork, rails, board bounds, launcher, drag clamp, danger line, containment, and perspective sampling. At the 720×1280 design size the table spans y=360..1145; over the tested 720×1600 canvas it spans y=488..1446. Backgrounds still cover/crop without distortion.

Active L1-L8 gem radii are `36/39/42/45/48/51/54/57 px`. The same radius remains authoritative for alpha-trimmed visual diameter and circle collision size; the ladder is monotonic and bounded at 1.583× from L1 to L8. Merge eligibility, target/scoring/progression logic, movement tuning, audio, ads/UMP, results, and animations are unchanged.

TEST APK: `build/android/majestic-gems-ui-scale-test.apk`, 85,220,655 bytes, SHA-256 `12F5BE9848C9982A92B40A1C2FE589BEB7094C5385DA254EF7606305A4578DFB`, from `60448dd` / `responsive-ui-scale-test-v1-source`. Package/ABI/v2-signature audits pass. ADB timed out, so installation and physical-device review are not claimed. Full evidence is in `reports/RESPONSIVE_UI_SCALE_TEST_REPORT.md`.
# Current State Addendum - Sound mapping correction v2

Only five user-selected supplied replacements remain active: gem contact uses `gems-colide.mp3` at `0.34`, rail contact uses `gems-rail-colide.mp3` at `0.39`, ordinary merges use `merge-target.mp3` at `0.70`, UI taps use `mixkit-on-or-off-light-switch-tap-2585.wav` at `0.32`, and final level success uses `merge-basic.mp3` at `0.84`. Target-producing merges, chain feedback, and target arrival use their original procedural identities; objective completion has no separate supplied cue. Existing launch/push and coin identities remain unchanged, and no lose/game-over audio is routed.

Background music remains `supplied_background_music_v5.ogg` and is raised from `0.035` to `0.06` linear (-24.44 dB), still below the earlier `0.10` gain. The 65/90 ms contact cooldowns, collision pitch variation, exact merge-contact suppression, five-voice priority pool, Music/SFX buses, and limiter remain intact. No gameplay, physics, animation, UI, privacy, ads, or assets were changed. TEST APK: `build/android/majestic-gems-sound-mapping-v2-test.apk` (81,304,475 bytes; SHA-256 `A3A075124A1DF0F421FF4D87A693D087D618F506420338495C9C47FCBA1FDAC8`). Package, signature, dual-ARM, payload, and exclusion audits pass; no AAB was generated and device installation was unavailable. See `reports/SOUND_MAPPING_CORRECTION_V2_REPORT.md`.
# Current State Addendum - Sound mapping correction v2

Only five user-selected supplied replacements remain active: gem contact uses `gems-colide.mp3` at `0.34`, rail contact uses `gems-rail-colide.mp3` at `0.39`, ordinary merges use `merge-target.mp3` at `0.70`, UI taps use `mixkit-on-or-off-light-switch-tap-2585.wav` at `0.32`, and final level success uses `merge-basic.mp3` at `0.84`. Target-producing merges, chain feedback, and target arrival use their original procedural identities; objective completion has no separate supplied cue. Existing launch/push and coin identities remain unchanged, and no lose/game-over audio is routed.

Background music remains `supplied_background_music_v5.ogg` and is raised from `0.035` to `0.06` linear (-24.44 dB), still below the earlier `0.10` gain. The 65/90 ms contact cooldowns, collision pitch variation, exact merge-contact suppression, five-voice priority pool, Music/SFX buses, and limiter remain intact. No gameplay, physics, animation, UI, privacy, ads, or assets were changed. No APK/AAB was generated for this source-only correction. See `reports/SOUND_MAPPING_CORRECTION_V2_REPORT.md`.
# Current State Addendum - Immediate merge-sound synchronization v3

The supplied `merge-target.mp3` used by the approved v2 ordinary-merge mapping contained `0.523125 s` of leading silence, which made its audible attack occur after the result gem appeared even though the controller requested it in the confirmed merge frame. The untouched source remains under `assets/sound/`; gameplay now loads `assets/runtime/audio/merge-target-immediate.ogg`, a non-destructive derivative trimmed by `0.515 s` with a measured `0.008042 s` remaining lead-in. The controller also routes the cue immediately after merge classification and before result-presentation setup in that same confirmed frame.

Physics, merge eligibility/resolution, result creation, animation duration, target logic, mappings, gains, music, other SFX, UI, ads, and Android configuration are unchanged. Focused timing/game-flow validation passes. TEST APK: `build/android/majestic-gems-merge-sound-sync-v3-test.apk` (81,319,143 bytes; SHA-256 `58648E9C5FF783AB1D79020E2368CB6FECA56E7A3AEC232BB683303EE2A9695F`). Package, signature, dual-ARM, immediate-audio payload, and exclusion audits pass; no AAB was generated and device installation was unavailable. See `reports/MERGE_SOUND_SYNC_FIX_V3_REPORT.md`.
# Current State Addendum - Immediate merge-sound synchronization v3

The supplied `merge-target.mp3` used by the approved v2 ordinary-merge mapping contained `0.523125 s` of leading silence, which made its audible attack occur after the result gem appeared even though the controller requested it in the confirmed merge frame. The untouched source remains under `assets/sound/`; gameplay now loads `assets/runtime/audio/merge-target-immediate.ogg`, a non-destructive derivative trimmed by `0.515 s` with a measured `0.008042 s` remaining lead-in. The controller also routes the cue immediately after merge classification and before result-presentation setup in that same confirmed frame.

Physics, merge eligibility/resolution, result creation, animation duration, target logic, mappings, gains, music, other SFX, UI, ads, and Android configuration are unchanged. Focused validation and a TEST APK are pending. No AAB will be generated. See `reports/MERGE_SOUND_SYNC_FIX_V3_REPORT.md`.
# Current State Addendum - Immediate merge-sound release AAB v3

The current immediate merge-sound implementation is exported as the signed release bundle `build/android/majestic-gems-merge-sound-sync-v3.aab` (69,163,559 bytes; SHA-256 `D08D5169C19AAA8E8F63FD9BFB3B6345CEE0C64B7C9C550D359B5BECC1346D30`). Bundletool, JAR signature, package/SDK, release-manifest, production AdMob App ID, dual-ARM, immediate-audio payload, and exclusion checks pass. The existing preset, package, versionCode 2/versionName 1.0.1, production signing, ads/UMP, and gameplay are unchanged; the previous closed-test v2 AAB was not overwritten. AAB installation/Play delivery is not claimed. If versionCode 2 is already uploaded in Play Console, a separately authorized version bump is required before uploading this bundle.
# Current State Addendum - Android release versionCode 3 correction

The Android export preset stored `version/code=3` for the corrected release bundle, superseding the rejected merge-sound AAB that used already-published versionCode 2. The corrected signed bundle is `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab` (69,163,616 bytes; SHA-256 `29E0476F88CEA5EC33AA579AC1E15CA432AA9E761C6A7DE6CDB7B9B61A2C5E3B`). Its embedded manifest proves versionCode 3/versionName 1.0.1, package `com.owais.majestygems`, min SDK 24, target/compile SDK 36, and the production AdMob App ID; Bundletool and upload-certificate verification pass. This historical state is superseded by the next-release preparation below. Signing, ads/UMP, gameplay, UI, physics, and audio are unchanged.

# Current State Addendum - Next Android release version preparation

The export preset is prepared for the next release with versionCode `4` and versionName `1.0.2`. No AAB was generated. From this point onward every new AAB must advance both the integer code and semantic visible name, commit both before export, include both in its filename, and pass a Bundletool embedded-manifest check before delivery. The prior `-vc3.aab` remains the recorded versionCode 3/versionName 1.0.1 artifact; this preparation does not modify it.
# Animation, collision feedback, and large-screen containment polish - 2026-08-18

- Confirmed merges now complete their presentation in 0.30 s with a 0.07 s source pull and a controlled 1.18x result overshoot. Resolution, target qualification, rewards, and launcher state remain authoritative and animation-independent.
- Meaningful non-merge gem/rail contacts receive an 0.11 s presentation-only compression capped at 5.5%, with a 0.10 s per-piece cooldown. The simulation root, collider, velocity, position, contact capture, and merge eligibility never read this transform.
- Android keeps the intentional portrait-phone setting. The existing `canvas_items` + `expand` viewport, centered authoritative table geometry, cover-scaled background, and `package/app_category=2` game declaration remain active; wide virtual canvases are now regression-covered without horizontal table stretch.
- Global Tweens remains restored as the existing autoload. Tween Composer remains excluded because current controller/native tweens already own these bounded effects and restoring its data would add duplicate runtime machinery.
- This milestone delivers an APK only. No AAB is created.

# Video comparison and animation-package audit - 2026-08-18

Both supplied root videos now have an end-to-end local decode, full-timeline contact-sheet review, focused launch/merge/target/reward sequences, waveform review, and loudness comparison recorded in `reports/ANIMATION_REWARD_AUDIO_LARGE_SCREEN_POLISH.md`. The comparison supports retaining the current target, reward, Next, music, and SFX systems; the delivered implementation gaps remain the corrected 0.30 s merge and new collision micro-feedback.

Correction: Tween Composer is a production Home runtime dependency, not unused source. The prior `tween_composer/*` Android exclusion was invalid and is now removed. Global Tweens remains the active autoload; Tween Composer remains limited to the Home logo loop.

Historical APK: `build/android/majestic-gems-animation-large-screen-polish-v2.apk`, 81,304,035 bytes, SHA-256 `9132197FB131F8367577573F9D01716AAB95875617975C707148E33174D4A1CA`. It contains no Tween Composer entries, which is now known to be a Home runtime packaging regression. Do not use it as a Home-flow baseline.
# Reference-driven game feel v2 - 2026-08-18

- Merge presentation is now an unmistakable 0.27 s contact/pull/pop/settle beat with a 1.26x result overshoot and 10 lightweight crystal rays (12 for L6+).
- Target collection completes in 0.32 s, uses arrival glow/rays instead of the removed checkmark, and begins the next-target transition after 0.12 s.
- Four target coins travel over 0.54-0.60 s with tighter stagger; HUD arrivals retain authoritative reconciliation and use a stronger 0.18 s pulse.
- Existing audio assets/music remain active. Normal gem/rail contacts are quieter at 0.28/0.32, ordinary merge is 0.78, target arrival is 0.90, and final success is 0.92.
- Simulation uses up to eight bounded displacement substeps. Merge candidates captured inside confirmed physical contact are no longer discarded after a later substep separates the pair; proximity merging remains forbidden.
# Reference-driven game feel v2 - 2026-08-18

- Merge presentation is now an unmistakable 0.27 s contact/pull/pop/settle beat with a 1.26x result overshoot and 10 lightweight crystal rays (12 for L6+).
- Target collection completes in 0.32 s, uses arrival glow/rays instead of the removed checkmark, and begins the next-target transition after 0.12 s.
- Four target coins travel over 0.54-0.60 s with tighter stagger; HUD arrivals retain authoritative reconciliation and use a stronger 0.18 s pulse.
- Existing audio assets/music remain active. Normal gem/rail contacts are quieter at 0.28/0.32, ordinary merge is 0.78, target arrival is 0.90, and final success is 0.92.
- Simulation uses up to eight bounded displacement substeps. Merge candidates captured inside confirmed physical contact are no longer discarded after a later substep separates the pair; proximity merging remains forbidden.
# Home startup and return-flow repair - 2026-08-18

- Production startup now always enters `HOME`; the former mobile-feature conditional that could fall through to `PLAYING` is removed.
- Pause HOME uses a dedicated controller transition that clears the Pause modal before presenting Home.
- Android Back from Level Ready returns to Home instead of being consumed with no navigation.
- Gameplay physics, game-feel tuning, targets, rewards, progression, ads, and saves are unchanged.
# Current State Addendum - Android Back, idle, settings, and splash repair

Android Back is now owned by the authoritative app-flow state: Home Settings closes first, bare Home performs an AdManager-safe application exit, Level Ready returns Home, Playing toggles Pause, and completed/reward/ad states cannot open the gameplay Pause layer. Home remains paused during idle time, and ad loader/retry callbacks are invalidated during exit.

Privacy Policy is explicitly centered across the full viewport at the safe-area-aware bottom edge. Unsupported Vibration switches are removed from Home and Pause Settings and haptics remain disabled. The blue Android system splash is retained but now uses the dedicated 1152x1152 `majestic_gems_system_splash_1152_v2.png` derivative instead of the 432x432 adaptive launcher foreground.

Coin rewards remain unchanged and explicit: target result tiers L2-L8 award `10/25/60/150/350/800/1800`; ordinary merges award zero. Level 1 base reward is 150, Level 2 is 500, and later deterministic totals depend on their seeded two- or three-target L5-L8 set. See `reports/ANDROID_BACK_IDLE_SETTINGS_SPLASH_REPAIR.md`.

Fresh TEST APK: `build/android/majestic-gems-back-idle-settings-splash-repair.apk` (82,149,382 bytes; SHA-256 `F60C5A6DBB9A17F37C3CC4C37E198DE23D33A338EA2B213FF10025297C79ED9B`). Package/SDK, v2 debug signature, dual ARM ABIs, and the new splash resource pass inspection. No device was connected.
# Current State Addendum - Last-AAB Home dependency and Back correction

The version-code-3 AAB baseline was compared directly with current source. Production Home has always used Tween Composer for its logo loop, but post-AAB commit `9f83eb7` incorrectly excluded `tween_composer/*` from Android. Android export now retains that required runtime dependency again. Home also hides the gameplay HUD explicitly and establishes its visible input surface before optional snapshot/motion work, so a presentation failure cannot masquerade as an already-started game.

Android window-Back and Escape-style Back representations share one 350 ms platform debounce before the state-aware policy. One physical press therefore cannot perform two state transitions. See `reports/LAST_AAB_HOME_BACK_REGRESSION_AUDIT.md`.

Corrected TEST APK: `build/android/majestic-gems-last-aab-home-back-repair.apk` (82,166,770 bytes; SHA-256 `B84DDD485475F5BA60ECB01ECE765E1AF39AEDB5A1691F0C0B499B8F9BFB4A8B`). Package inspection confirms all four Home Tween Composer runtime bytecode files, both ARM ABIs, and v2 signing. No device was connected.
# Current State Addendum - Firebase Analytics Android Integration v1.0.7

Firebase Analytics is configured in the tracked Godot Android custom template using Google Services plugin 4.5.0, Firebase BoM 34.18.0, and `firebase-analytics`; its supplied configuration matches the unchanged `com.owais.majestygems` package. The `Analytics` autoload and Android plugin observe only confirmed level, target, merge, and ad events, with no gameplay or reward authority. The requested Play sequence is restored to versionCode 9 / versionName 1.0.7 because the user confirmed Play's highest upload is 8 / 1.0.6. See `reports/FIREBASE_ANALYTICS_ANDROID_V1.0.7_REPORT.md`.
# Retention Sprint (unreleased)

The active controller now owns limited-shots attempts, out-of-shots rescue, one safe danger-line continuation, and local daily mission state. The UI remains a snapshot consumer; physics, strict contact merges, target authority, and launch generation are unchanged. Daily missions are local-date based and therefore susceptible to device-clock manipulation until a future server-time implementation.
