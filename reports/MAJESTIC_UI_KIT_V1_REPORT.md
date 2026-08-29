# Majestic UI Kit V1 — supplied-art UI pass and retention V1 defect fixes

Scope: adopt the supplied Candy-Crush-style art kit and typefaces across every
screen and popup, and repair the defects in the previous retention / coin /
daily-missions implementation.

## 1. Defects found in the retention V1 implementation

All four were reproduced before being fixed, and each has a regression test in
`tests/run_retention_daily_missions_v2_tests.gd` that fails against the previous
code (verified by temporarily restoring the old behaviour).

| # | Defect | Player-visible effect | Fix |
| --- | --- | --- | --- |
| 1 | `DailyMissionService` mutated the caller's `Dictionary` in place and returned that same object. `_record_daily_progress` compared `daily_state != previous` to decide whether to save — always false, since both names referred to one object. | Daily mission progress was **never persisted and never reported**. Every app restart reset the day's progress to zero. | Service is now pure: `ensure_current_day()` deep-duplicates, `record()` returns `{state, changed}`, and the controller saves on the explicit `changed` flag. |
| 2 | `claim_mission()` / `claim_chest()` marked the mission claimed on the caller's own state *before* `save_progress()` was checked. On a save failure the controller returned early without granting coins. | A failed save **consumed the mission and paid nothing**. The reward was permanently lost. | The pure service leaves `daily_state` untouched until the controller assigns the returned state, which it does only after the save succeeds. |
| 3 | `DailyMissionsOverlayLayer` used `layer = 55`; `HomeOverlayLayer` uses `layer = 60`. Home is the popup's only entry point. | Tapping Daily Missions on Home appeared to **do nothing** — the popup opened behind the opaque Home screen. | Popup moved to `layer = 65`, above Home, with the constraint recorded in code. |
| 4 | `present_out_of_shots()` set `home_button.text = "GIVE UP"`, but `"HOME"` was only ever assigned in `_build_ui()`. | After one out-of-shots screen, every later win/fail screen showed **"GIVE UP" instead of "HOME"** for the rest of the session. | `present()` restores the label. |

Also repaired: `tests/run_firebase_analytics_pipeline_tests.gd` had been left red
by the earlier change of `SKIP_LEVEL_COST` from 200 to 800 (seven failing
assertions hardcoded the old cost). The suite now derives its expectations from
`GameConfig`, so future retuning cannot silently break it.

## 2. Typography

The supplied families are installed and now carry all UI text.

| Role | Face | Notes |
| --- | --- | --- |
| UI copy, buttons, captions | Nunito Sans, weight 800 | `UiDesignSystem.font()` |
| Counters, scores, button captions | Nunito Sans, weight 1000 | `UiDesignSystem.heavy_font()` |
| Brand tagline, display | Cinzel Black | `UiDesignSystem.display_font()` |

`NunitoSans-Variable.ttf` defaults its `wght` axis to **200 (ExtraLight)**.
Loading it without setting the axis renders spindly text, so every variation
sets `wght` explicitly through `FontVariation.variation_opentype`.

The type scale was raised substantially — body copy went from 18 to 25 canvas
units at the 720x1280 design viewport (roughly 9dp to 12.5dp on a 360dp phone),
which was the main reason UI text previously looked undersized against the
artwork. Labels also carry a dark outline theme-wide so copy survives the busy
jewel backgrounds.

## 3. Art kit

The six supplied sheets were sliced into 37 runtime assets. Slicing was done
with a Godot tool script (connected-component labelling with glow-gap bridging
for the irregular button/panel sheets; fixed 3x3 grid slicing for the badge
sheet, whose rows touch). Originals are preserved and never loaded at runtime.

- Sources: `assets/ui_kit_source/` (6 sheets + the home-screen mockup)
- Runtime: `assets/runtime/ui/kit/` (9 buttons, 9 panels/bars, 10 icons, 9 badges)
- Module: `scripts/ui/ui_kit.gd`

`UiKit.NINE` holds nine-patch margins only for assets that may stretch.
Fixed-composition art (a coin seated inside a plate, gems running along a bar)
has no correct slicing and is rejected by `assert` rather than smeared.

**Nine-patch margins must stay below half the shortest height an asset is drawn
at.** A first pass used the art's natural rim thickness (e.g. 48px vertical on a
68px-tall button); when top+bottom margins exceed the drawn height the
unstretched caps overlap and the plate visibly crushes. Vertical margins are now
26–34.

## 4. Screens

Button families are registered as theme type variations, so the art and
typography reach every screen and popup through the shared theme rather than
per-screen edits:

| Variation | Art | Used for |
| --- | --- | --- |
| `Button` (primary) | gem-capped pill | default actions, paid rescues |
| `SecondaryButton` | plain gold pill | navigation (Home, Skip, Close) |
| `HeroButton` | ornate gold plate | Home's PLAY only |
| `GreenButton` | green plate | affirmative rewards (Collect, Claim, Retry) |
| `IconButton` | square plate | settings gear |

Composition changes:

- **Home** — Cinzel tagline, a daily-missions card showing today's three badges
  and progress, brass-rimmed level/coin cards, and the hero PLAY plate.
- **Daily missions** — rebuilt: gold ribbon header, three mission cards with
  badge, objective, green progress bar, coin reward, and claim action, plus a
  chest row.
- **Result (win / fail / out-of-shots)** — actions stacked vertically. Two
  captioned buttons sharing a row overflowed the panel on 720px-wide screens,
  because the kit plates carry wide ornamental caps.
- **Settings** — ON now reads green and OFF neutral; two violet states were hard
  to tell apart.

Disabled controls keep their plate silhouette and desaturate, except disabled
green actions, which swap to the neutral plate outright — a tint cannot
desaturate green, so a dimmed CLAIM still read as available.

The shared border token moved from violet to brass, which is what every framed
surface in the supplied art uses. `run_ui_scale_layout_tests.gd` asserted the old
violet direction (`b > g`); that assertion now guards the brass direction
(`r > g > b`) so it still catches an accidental palette reset.

## 5. Validation

All thirteen Godot regression suites pass:

- `run_ui_scale_layout_tests` (updated palette assertion)
- `run_firebase_analytics_pipeline_tests` (made cost-agnostic)
- `run_retention_daily_missions_v2_tests` (**new**, 6 cases)
- `run_game_flow_reward_splash_tests`, `run_animation_audio_back_privacy_polish_tests`,
  `run_sound_privacy_link_tests`, `run_reward_feedback_v3_tests`,
  `run_gem_pattern_feedback_v1_tests`, `run_rail_target_blast_gem_expansion_v1_tests`,
  `run_reference_game_feel_v2_tests`, `run_scene_variety_assets_tests`,
  `run_branding_push_line_tests`, `run_admob_integration_tests`

Visual proof: `tests/capture_majestic_ui_kit_v1.gd` renders Home, daily missions,
gameplay HUD, win, fail, out-of-shots, and settings at 720x1280 and 720x1600 into
`reports/majestic-ui-kit-v1/screenshots/`.

## 6. Status and residual risk

- **No Android artifact was produced in this task** and no device was available,
  so no AAB/APK is recorded in `BUILD_MANIFEST.md` for this pass. The UI change
  is broad and should get a device pass before a release candidate is cut.
- Limited-shots levels, extra-shots purchase, and the coin continue were reviewed
  and left behaviourally unchanged apart from defect 4; their balance values
  (`EXTRA_SHOTS_COST` 300, `CONTINUE_COST` 500, `SKIP_LEVEL_COST` 800, shot
  limits 34/36) are unverified against real play data and remain open tuning
  questions.
- Daily missions still use device local time by design; server time is out of
  scope for V1.

---

## 7. Interaction polish pass (follow-up)

The first kit pass got the art and typography in place but shipped a broken
interaction layer. Findings and fixes:

| Defect | Cause | Fix |
| --- | --- | --- |
| Hover "looked terrible" | States pointed at different textures, so Godot's stylebox swap morphed the plate mid-interaction. The secondary pill grew gem caps; the settings gear became swap arrows (`btn_square_swap` has its glyph painted in). | One silhouette per family; states differ by tint only. |
| Screen read as four competing buttons | Secondary plates rendered brighter than the primary action. | Secondary starts recessed; green = affirmative, gem plate = primary/paid. |
| Disabled buttons drew nothing | `btn_green_off` / `btn_pill_gem_off` were generated but never imported; `load()` returns null silently. | Imported, plus a test asserting every referenced plate is importable. |
| Proof sheet showed every mission DONE | The harness mutated the *saved* daily state, so claims leaked between capture runs. | Harness builds a fresh roll. |
| Harness reported PASS over blank screenshots | A failed script load leaves a bare `Node2D`; nothing checked. | Harness verifies the controller instantiated and fails loudly. |
| Stray hairline + placeholder "!" box | Leftover `HSeparator` and an unfinished fail badge. | Removed; real kit art for the badge. |
| Reward copy still small | Hardcoded 13-16px sizes bypassed the type scale. | Routed through the scale. |

Added for "boring": `ScreenTransitionLayer` for Home ↔ gameplay, a real
entrance/exit on the daily-missions popup, and claim feedback (card kick plus a
floating coin value, fired only after the reward is persisted).

**One design constraint worth keeping:** the transition applies its state swap
synchronously and animates only the reveal. A first version deferred the swap to
the covered midpoint of a fade-out/fade-in, which made every navigation call
asynchronous and broke three suites, because callers could no longer read
`app_flow_state` after asking to navigate.

New coverage: `tests/run_ui_kit_polish_v1_tests.gd` (6 cases), verified to fail
against the previous behaviour. All fourteen suites pass.
