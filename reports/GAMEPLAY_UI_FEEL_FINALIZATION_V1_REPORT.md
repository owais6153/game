# Gameplay UI, Animation, Reward Feel, and Pause/Settings Finalization v1

## Baseline and inspected references

- Clean source baseline: commit `494a2b9e8c57b697d3493cc1cda926eadbfd8967`, tag `video-verified-unlimited-launcher-hud-v1`, on `main` with `origin/main` at the same commit before work began.
- Reference gameplay recording: `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4` — 18,527,126 bytes, 79.313 s, 1280×576, 23.993 fps, SHA-256 `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`.
- Current-game recording: `WhatsApp Video 2026-07-29 at 10.41.41 AM.mp4` — 5,014,064 bytes, 40.659 s, 576×1312, 24.004 fps, SHA-256 `C6D134678DF0D81C2A26AAAC415706DD4F82149DA24909BBF44A00DDD2EAB715`.
- UI composition reference: `assets/ui/Generated image 1 (3).png`.
- Approved runtime art was taken only from existing `assets/buttons/`, `assets/ui/`, and the existing calibrated runtime gem catalog. No protected branding, characters, logo, copy, or reference-game artwork was copied.

## Frame comparison and chosen presentation response

| Area | Current recording | Reference recording | Final response |
|---|---|---|---|
| Launch | Release is responsive but visually bare. | A launcher remains visibly available throughout sampled play and release has clearer feedback. | Preserve the verified unlimited lifecycle and physics; add a 120 ms visual-child release settle, a 160 ms spawn pop, and a short lightweight launch ring/trail. |
| Motion | Translation is direct and readable but lacks presentation easing. | Movement reads continuously and reward beats soften state changes. | Preserve simulation motion exactly; interpolate only spawn/release visual scale. |
| Merge | Sources converge near 4.5 s, result/score appear by 4.7 s, and the ring is gone near 4.9 s. There is no local score or clear sparkle beat. | Contact is near 46.5 s; reward particles begin around 47 s and continue while score visibly rises through about 50 s. | Use a deliberately shorter Android-safe 270 ms merge: 80 ms source pull/compression, 150 ms result pop, 120 ms settle overlap, eight bounded spark rays/ring, and a 620 ms local score rise/fade. |
| Score | HUD value jumps with little spatial connection to the merge. | Score reward is visibly staged. | Keep the exact confirmed-event score update and add a popup at the merge midpoint. Compact HUD formatting prevents overflow. A zero-value higher-tier merge does not show a misleading `+0`. |
| Target/win | The recorded final shot reaches the cluster around 33.9 s and the overlay is already fully visible around 34.0 s, obscuring the result. | The supplied reference clip does not contain a target collection or win sequence. | Use an explicit tested event order, 620 ms visual-only target flight, late fade after 68% travel, 220 ms target confirmation pulse, then a 320 ms post-collection hold before the result overlay. These timings are project-specific, not falsely attributed to the reference clip. |
| UI | Small fixed HUD elements compete for attention and earlier builds exposed Restart on gameplay. | SCORE, progression, and NEXT have strong hierarchy. | Replace immediate HUD drawing with responsive Controls, keep the approved top hierarchy, show one active target, and put supplied RESTART only inside Settings/Pause. |
| Crowded board | Launch continuity was the critical prior failure mode. | Launcher remains available in sampled crowded play. | Preserve the bounded 0.30 s handoff and no-counter lifecycle; add 80 post-restart production launch cycles and crowded-board profiling. |

Audio in both recordings is mono 48 kHz, but individual cue timing could not be classified reliably from the compressed clips. Haptics are not observable in video. Final sound/haptic timing therefore follows confirmed controller events and the visible impact/arrival beats.

## Final HUD hierarchy

`GameplayHudLayer` is a dedicated `CanvasLayer` at layer 40. It reads only `GameController.hud_snapshot()`.

```text
GameplayUIRoot (Control)
├── SafeHudMargin (MarginContainer)
│   └── HudRows (VBoxContainer)
│       ├── MainRow (HBoxContainer)
│       │   ├── ScorePanel (Control + supplied TextureRect + MarginContainer + Label)
│       │   ├── ProgressionCenter (CenterContainer + five contained slots)
│       │   └── NextPanel (Control + supplied TextureRect + Margin/Aspect/TextureRect)
│       └── ObjectiveRow (HBoxContainer)
│           ├── Level chip
│           ├── ActiveTargetPanel (supplied NinePatch skins + contained icon/details/progress)
│           └── SettingsButton
└── PauseInputBlocker (full-screen Control, hidden during play)
    ├── dimmer/input blocker
    └── centered supplied-art pause panel
        ├── Resume
        └── supplied RESTART
```

Normal gameplay exposes exactly one `BaseButton`: Settings. Restart is not a descendant of the gameplay HUD margin and is invisible until Pause opens. There is no shot counter, target fraction, S/V text button, developer rectangle, Home button, or direct gameplay Restart control.

## Supplied assets and measured layout

The following original regions are used directly; they were not redrawn:

- SCORE: `assets/buttons/Generated image 10.png`, region `(632,358,360,232)`.
- NEXT: the same sheet, region `(632,610,360,400)`.
- Stretchable cream body: the same sheet, region `(38,620,550,190)`.
- Coral decorative/button header: the same sheet, region `(46,428,530,142)`.
- Settings cog: the same sheet, region `(276,832,180,180)`.
- Pause-only RESTART: `assets/ui/Generated image 3.png`, region `(321,1128,300,100)`. An asset audit confirmed this is the literal supplied RESTART pill; the available arrows are BACK controls and are intentionally not used.
- Gem identity/texture: `AssetCatalog.GEM_TIER_TEXTURES`, including active L7 Ruby and L8 Sapphire.

At the 720 px design width, safe margins begin at 24 px and expand for the platform safe area. Component minima are SCORE `188×121`, progression `5×48` px rings with 12 px connectors, NEXT `178×198`, active target `288×104`, and Settings `88×88`. The top rows occupy 336 design px, leaving the approved table unobstructed. The supplied reference's prior measured 720-space composition was SCORE about `(38,48,174,136)`, progression rings on 56 px centers, and NEXT about `(510,48,178,158)`. The final layout keeps comparable hierarchy while preserving each supplied panel's real aspect ratio rather than stretching its border art.

The 720×1061 desktop render (desktop display height capped the requested window) measured visually clean spacing with the table still flush to the bottom. Exact 720×1600, 1080×1920, and 1080×2400 bounds were validated in isolated Godot viewports.

## Font and score strategy

- Dynamic text uses one cached `FontVariation` over `ThemeDB.fallback_font` with a modest embolden value (`0.72` for UI, `0.75` for score effects), matching the supplied rounded/bold direction without adding an unlicensed font.
- SCORE uses 44 px for short values, 39 px through six display characters, then 34 px. It remains centered inside the supplied cream panel.
- `ScoreFormatter` preserves the exact integer in the controller and changes only display text: `0`, `999`, `1,000`, `9,999`, `10K`, `125.5K`, `1M`, and `9.9B` are covered.
- The HUD and merge popup receive the same exactly-once confirmed merge event. Duplicate `result_id` input cannot duplicate score, target progress, sound, haptic, or visuals.

## Preview contain scaling

- NEXT uses a `78×74` logical interior margin area and a `74×74` `AspectRatioContainer`; its `TextureRect` uses `STRETCH_KEEP_ASPECT_CENTERED`.
- Each progression icon is contained inside a 38×38 interior ring.
- The target uses a centered 52×52 aspect container inside a 70×54 slot, fully inside the supplied target body.
- Result-overlay artwork uses the same aspect-preserving `TextureRect` behavior.
- No gem preview uses circular clipping, a shader mask, independent X/Y stretching, alpha scanning, runtime image analysis, or per-frame texture loading. Wide, tall, oval, square, diamond, and irregular source textures remain fully visible at original aspect ratio.

## Pause/settings and restart flow

Settings cancels any drag, shows a full-screen input blocker/dimmer, and pauses the scene tree. The pause layer processes while paused so Resume and Restart remain functional. Resume closes the popup and unpauses. Restart closes/unpauses first, then calls the one existing `GameController.restart()` path. That path clears score, board, queue index, sequential target state, danger timers, merge candidates/presentations, exactly-once IDs, event trace, collection proxy, transient effects, overlay, and stale visual scales, then creates exactly one ready unlimited launcher. Signal-count tests prove one connection per action.

No sound/vibration controls were added to the gameplay HUD or popup; they were optional and the milestone keeps the popup focused.

## Merge and reward implementation

- The merge service and simulation still commit immediately. Source bodies are consumed before presentation.
- Source ghost textures are cached into the presentation record at confirmation and pull inward/fade over 80 ms.
- The authoritative gem visual root continues to carry the approved perspective/physics scale. Only its child `Visual` container receives the temporary `0.82 → 1.13 → 1.0` merge presentation scale; collider/radius/body scale never reads it.
- A bounded `GameplayEffectsLayer` draws a result-aware ring plus eight spark rays and at most 12 merge impacts / 12 score popups. Effects own no physics body and expire deterministically.
- Score popup rises 36 px over 620 ms and fades after 45% of its lifetime.
- Spawn/release feedback also scales only the visual child.
- Original procedural crystal cues are generated once into 15 cached `AudioStreamWAV` resources during service initialization. Playback performs no sample/resource generation. L6, L7, and L8 now have their own merge tones; the collection cue/haptic aligns with HUD arrival.

## Target collection, cleanup, and event sequence

After the target merge presentation completes, the confirmed result is marked consumed and erased from `pieces`; its danger timer is removed and merge candidates are cleared. Only then is an independent `Sprite2D` proxy created under the effects layer. The proxy uses a uniform texture scale, a quadratic path to the current target icon, a brief `1.16` pop, and a mostly opaque first 68% of travel. Fade is concentrated in the last 32%, ending at 0.15 immediately before removal. Arrival triggers a 220 ms panel pulse/ring/spark and the collection sound/haptic.

The exact trace for final L8 is:

```text
merge_confirmed
→ result_created
→ result_first_frame_visible
→ merge_presentation_completed
→ target_completed
→ physics_body_removed
→ collection_animation_started
→ collection_animation_completed
→ final_target_confirmed
→ win_overlay_started
```

The first L7 trace stops after `collection_animation_completed`, then the sole visible target changes to L8. Final L8 qualifies victory only after collection; the overlay begins once after the 320 ms hold. Pause freezes this sequence. Restart and danger failure atomically cancel proxies/effects and cannot leave ghost collision, occupancy, input-disable, or duplicate-win state.

## Unlimited launcher and unchanged Level 1 balance

- There is no production `shot_limit`, `shots_left`, `shot_count`, maximum-launch, or decrementing launch state anywhere under `scripts/` or `scenes/`.
- Launcher availability is the cyclic `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM` state machine. Its existing bounded 0.30 s handoff prevents moving/crowded pieces from owning the launcher indefinitely.
- The focused Level 1 regression performs 80 additional production launches after pause-popup Restart and receives a new ready launcher every cycle. Existing crowded/unrelated-merge and collection-during-shot coverage also passes.
- Level 1 remains exactly sequential L7 Ruby ×1, then L8 Sapphire ×1. Only the current target is shown.
- The unchanged deterministic mixed bag is `[1,2,1,3,2,1,4,2,3,1]`, repeating indefinitely. Its documented nominal weights remain L1:4, L2:3, L3:2, L4:1. L7/L8 are never directly launched.
- Only existing danger-line overflow fails the run; only completing both sequential targets succeeds.

## Responsive layout and background/table behavior

The project retains `canvas_items` plus `stretch/aspect="expand"`. The supplied tropical background uses uniform cover scale so expanded portrait space is filled without letterboxing or distortion. `GameConfig.configure_portrait_bottom()` remains the single baseline-owned table offset used by table art, rails, launcher, danger line, drag clamp, and perspective interpolation. The new HUD stays top-anchored and reads none of those simulation coordinates.

Focused viewport results passed at 720×1280, 720×1600, 1080×1920, and 1080×2400: SCORE/NEXT and target/Settings do not overlap, all key panels remain inside the viewport, Settings stays at least 88×88, the pause card stays centered, large score text fits, and contained NEXT/target rectangles remain inside their supplied panels.

## Performance observations

Final headless CPU profile (Godot dummy renderer, development host):

| Scenario | Average process | Worst sampled process | Bodies |
|---|---:|---:|---:|
| Empty-board launch | 0.100 ms | 0.526 ms | 1 |
| Repeated launch | 0.172 ms | 1.653 ms | 2 |
| 10 active gems | 0.876 ms | 5.478 ms | 11 |
| 20 active gems | 3.780 ms | 25.232 ms | 21 |
| Crowded board | 1.855 ms | 9.822 ms | 21 |
| Six-step reward chain | 0.231 ms | 0.541 ms | 1 |
| Target collection | 0.203 ms | 2.810 ms | 1 |
| Pause popup | 0.001 ms | 0.004 ms | modal |
| Final win sequence | 0.119 ms | 1.306 ms | 1 |
| Restart | 0.078 ms | 0.205 ms | 1 |

The profile reports zero per-gem process callbacks, zero gameplay resource loads after initialization, 15 cached audio streams, zero active effects after expiry, and `node_delta=0`. A Windows/headless ObjectDB cleanup warning remains after the successful harness exit, but the measured runtime node delta is zero; it is not treated as an on-device result.

## Validation results

- Godot 4.6.3 editor parse/import: passed. The environment still logs its known Windows root-certificate/editor-settings warnings after successful completion.
- `GAMEPLAY_UI_FEEL_TESTS: PASS`.
- `CLEAN_CONTACT_TESTS: PASS`.
- `LEVEL_1_FLOW_TESTS: PASS` (includes 80 post-restart unlimited launches).
- `GEM18_CHAIN_TESTS: PASS`.
- `MOTION_PROFILE: PASS`.
- Real ANGLE renderer evidence capture: `GAMEPLAY_UI_EVIDENCE_CAPTURE: PASS`.
- APK export: passed; Godot aligned, debug-signed, and verified it.
- APK ZIP structure: 349 entries; `AndroidManifest.xml`, `classes.dex`, `resources.arsc`, and `lib/arm64-v8a/libgodot_android.so` present; no `reports/` or `tools/` development artifact entries.
- `apksigner 36.0.0`: verifies; v2 and v3 signatures valid; one RSA-2048 signer.
- `adb devices -l` did not return within the validation window. No device install, launch, audio listening, haptic check, or phone frame-rate claim is made.

## APK metadata

- File: `D:\Owais\game\build\android\gameplay-ui-feel-finalization-v1.apk`
- Size: `100,772,764 bytes`
- Modified: `2026-07-31 13:42:12 +05:00` (`2026-07-31T08:42:12Z`)
- SHA-256: `420684CA1D975A434D421EF129FAB195E98FA511C6C2207CA71D64DD7A374090`
- Exact APK gameplay source commit: `42c7b38085aa70bd422f35637b76758507acc7e9` (`feat: finalize gameplay UI and reward feel`).
- Delivery tag: `gameplay-ui-feel-finalization-v1`

## Development evidence

Evidence is under `reports/gameplay-ui-feel-finalization-v1/`:

- `final-hud.png`
- `large-score.png`
- `settings-popup.png`
- `merge-impact.png`
- `target-collection-mid-flight.png`
- `target-collection-late-fade.png`
- `final-target-before-win.png`
- `win-overlay.png`
- `crowded-board.png`

These are development artifacts and are excluded from the APK by `reports/.gdignore`; test/capture scripts are excluded by the Android export filter.

## Files and architecture changed

- Added `GameplayHudLayer`, `GameplayEffectsLayer`, and `ScoreFormatter`.
- Reworked `ResultOverlayLayer` into a dedicated responsive CanvasLayer.
- Updated `GameController` only for UI routing, exactly-once/event sequencing, visual-only reward timing, atomic target proxy cleanup, and pause flow.
- Updated `GemSpriteLayer` with child-only presentation scale.
- Cached procedural audio streams and added L6–L8/target-arrival feedback mappings.
- Retired `HudRenderer` to a compatibility no-op; production does not instantiate it.
- Added focused evidence capture/tests and expanded clean, Level 1, and motion regressions.
- Added build-time exclusion for test tools and report artifacts.

`scripts/board_simulation.gd`, `scripts/merge_service.gd`, `scripts/gem_piece.gd`, and `scripts/level_config.gd` were not changed. Table position/model, rails, bottom-following behavior, perspective formula, live collider scaling, collision radii, contact-only merge rules, gravity/motion constants, danger-line behavior, scoring table/formula, Level 1 targets/bag/difficulty, and unlimited launcher behavior are unchanged. The focused test snapshots the table/rail/motion/contact/perspective constants and proves the signature remains identical through the presentation suite.
