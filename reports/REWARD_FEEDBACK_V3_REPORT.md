# Reward Feedback V3 — Merge Juice, Combo Hierarchy, Final-Target Hero Moment

Task: make successful actions feel much more rewarding through precise animation
timing, hierarchy, and feedback — without redesigning the game.

Nothing in this pass changes gem progression rules, merge eligibility, contact
capture, physics constants, board geometry, HUD layout, target rules, level
rules, theme, or art direction. Every new visual is a cosmetic-only record and
the authoritative reward/target state is still produced by gameplay logic.

## 1. Reward hierarchy

The single enforced escalation is:

```
normal collision < normal merge < combo merge < final target achievement < level complete
```

It is expressed as data in `GameConfig.merge_timeline(depth, final_target)`, which
returns one timeline dictionary per reward tier. `run_reward_feedback_v3_tests.gd`
asserts the ring strength, SFX pitch, mini-gem count, and hit-stop length all
increase monotonically across the ladder.

| Tier | Hit-stop | Result scale curve | Ring | Mini gems | SFX pitch | Camera |
|---|---|---|---|---|---|---|
| Collision | — | contact squash only (unchanged) | — | — | — | none |
| Normal merge | 40 ms | 0.65 → 1.18 → 0.96 → 1.02 → 1.0 | ×1.00 | 3 | ×1.00 | none |
| COMBO 1 | 40 ms | 0.65 → 1.18 → 0.96 → 1.02 → 1.0 | ×1.14 | 3 | ×1.06 | none |
| COMBO 2 | 40 ms | 0.60 → 1.23 → 0.94 → 1.0 | ×1.22 | 5 | ×1.12 | none |
| COMBO 3+ | 45 ms | 0.55 → 1.30 → 0.93 → 1.04 → 1.0 | ×1.34 | 5 | ×1.18 | none |
| Final target | 50 ms | 0.65 → 1.25, then the hero sequence | ×1.30 | 3 | ×1.00 | none |

No lightning, no screen flashes, no full-screen shaders, and no camera shake were
added. The project has no camera-shake infrastructure, so the optional COMBO 3+
camera impulse was deliberately skipped rather than introducing a new camera
system into a working gameplay scene.

## 2. Normal merge — 420 ms

Measured from the confirmed contact merge:

| Window | Behaviour |
|---|---|
| 0–40 ms | Hit-stop. Only the confirmed result gem is frozen; the rest of the board keeps stepping. Its merge momentum is stored and restored exactly. |
| 40–110 ms | Source pair pulls toward the merge centre and scales 1.0 → 0.82. |
| 110 ms | Source pair hidden, upgraded gem revealed at 0.65, merge chime plays. |
| 110–190 ms | 0.65 → 1.18 with an ease-out/back overshoot. |
| 150 ms | One subtle circular shockwave ring. |
| 140–430 ms | 3 cosmetic mini gems shoot from behind the new gem, peak at 0.38 scale, then drift/shrink/fade. |
| 190–300 ms | 1.18 → 0.96. |
| 300–390 ms | 0.96 → 1.02 → 1.0 secondary settle. |
| 390–420 ms | Animation finishes; normal gameplay/physics state resumes. |

Feedback per merge: short chime, existing haptic routing, one ring, three mini
gems. No camera shake, no lightning.

## 3. Combo system

`depth` from `ContactMergeService.resolve_with_chains` is already exactly
"a merge caused by a gem that a previous merge in this same resolution produced".
The combo level reads that value directly, so it counts chain merges from one
shot and resets automatically when the shot's resolution chain finishes. Normal
successful shots across separate launches never accumulate a combo.

Labels: `COMBO 1`, `COMBO 2`, `COMBO 3!`, and the rare `COMBO 4 — AMAZING!` /
`COMBO n — PERFECT!`. The escalated wording is gated to depth ≥ 4 so shallow
chains can never borrow it. Label motion is 0.5 → 1.2 (60 ms) → 1.0 (100 ms),
then a 20 px rise and fade over a ~480 ms lifetime, lifted clear of the result
gem's own overshoot.

**Deliberately not implemented:** the optional `+20 / +40 / +80` combo reward
text. The existing economy awards coins only on target completion, so printing a
coin value the player does not actually receive would misrepresent the balance.
The spec marks this item optional; the combo now reads through scale, ring,
mini gems, pitch, and label instead.

## 4. Final target — hero moment

`T` = the moment the valid final-target merge completes. Times are from `T`, and
the values in the right column are the measured values from the instrumented run.

| Phase | Spec | Measured |
|---|---|---|
| A — hit-stop, source pull, reveal, 0.65 → 1.25, success ding | 0–180 ms | as specified |
| B — travel to the visual centre of the playable board, 1.25 → 1.15, ease-out cubic | 180–430 ms | hero hold starts 433 ms |
| C — hero hold: 1.15 → 1.38 (120 ms) → 1.27, then a 1.27–1.31 breathing pulse, one soft expanding radial glow, `TARGET COMPLETE!` caption | 430–930 ms | caption at ~530 ms |
| D — curved flight to the target HUD panel, 1.27 → 0.35, 0° → 10° → 0° tilt; panel anticipates to 0.95; arrival then 0.95 → 1.12 (90 ms) → 1.0 (130 ms) | 930–1280 ms | count updates at 1267 ms |
| E — completed panel state (`TARGET 3/3`, `COMPLETE · 1/1`), completion chime, 6 sparkles bounded to the panel | 1280–1550 ms | as specified |

The target count is updated only inside Phase D's arrival. It cannot complete
early: the HUD-facing `presented_target_*` state was already separate from the
authoritative `target_*` state, and this pass only retimed when the presented
state advances.

## 5–8. Coins and Level Complete

| Stage | Spec | Measured |
|---|---|---|
| Coin spawn begins, 20 coins in 4 waves of 5 | ~1500 ms | 1517 ms |
| All 20 coins visible on the table | — | 1633 ms |
| Deliberate table hold | 350–400 ms | 380 ms (first landing 1737 ms → collection 2117 ms) |
| Staggered collection begins, waves of 3 every 45 ms, 300 ms curved flight each | ~2100 ms | 2117 ms |
| Last coin reaches the HUD | ~2650 ms | 2700 ms |
| Background dim begins | ~2780 ms | 2797 ms |
| Level Complete panel animates in, 0.86 → 1.04 → 1.0 | ~2850 ms | 2867 ms |
| Fully settled | 3.2–3.5 s | ~3.35 s |

Coins scatter across a controlled central band of the board (62 % of the playable
half-width, ±134 px vertically) using deterministic best-candidate sampling, so
the pile is even, never overlaps into clumps, never reaches the rails, and is
identical between runs. They land with a small settle bounce and idle-wobble
during the hold.

The HUD balance interpolates upward as coins arrive rather than jumping, and the
coin container is punched once per wave (1.0 → 1.06 → 1.0) rather than once per
coin. Arrival ticks reuse the existing `coin_tick` cooldown so twenty coins never
produce twenty full-volume identical sounds.

The Level Complete modal is unchanged in art, layout, copy, and actions. Only its
entrance was retimed: the dim leads the panel by 70 ms, the panel overshoots once,
and the content is revealed in order — title, completed target gem, then the
reward card and buttons.

**This regression is fixed. See "Addendum — HUD coin-counter continuity fix"
below for the root cause, the fix, and its verification.**

## 10. Engineering rules

- One new explicit state, `final_celebration_active`, gates the whole sequence.
  While it or `win_qualified` is set, pointer input is rejected, dragging is
  cleared, the launcher lifecycle is not advanced, and `_update_win_presentation`
  refuses to present. Verified by test: no shooter gem spawns and no drag starts
  during the celebration.
- The exactly-once guards were reused, not replaced: `processed_merge_result_ids`,
  `counted_target_result_ids`, and `pending_target_presentations` are unchanged.
  A repeated confirmed result still awards coins once and counts the target once.
- `_advance_target_state_authoritative` now runs *before* the reward presentation
  in `_apply_confirmed_merge_events`, so the presentation can branch on the
  confirmed final-target result instead of inferring it. The authoritative
  ordering and values are identical.
- The final target skips the compact per-target coin group so the reward is never
  animated twice.
- If an earlier queued target delays the hero sequence, the coin pile waits for
  the hero gem to arrive. A 2 s safety bound prevents the celebration state — and
  therefore Level Complete — from ever being stuck.
- Hit-stop stores and restores the exact merge momentum, so the simulation
  resumes with the value `ContactMergeService` produced.
- `restart()` and `_trigger_failure()` clear every new record: mini gems, combo
  labels, sparkles, hero effect, reward coins, hit-stops, and celebration state.
  Nothing persists across levels or scene changes.
- Mini gems, rings, combo labels, sparkles, the hero glow, and reward coins are
  drawn records inside `GameplayEffectsLayer`. They allocate no nodes, add no
  simulation bodies, and are invisible to contact capture and merge eligibility.

## 11. Performance

No shaders, no `GPUParticles`, no full-screen effects. All new visuals are
immediate-mode draw calls on the existing effects canvas: at most one ring, five
mini gems, one label per merge, and twenty coins during the level celebration.
All arrays are capped (`_cap_effects`) and filtered by lifetime each frame. The
one-time coin scatter sampling runs once per level completion.

## 12. Validation

Godot 4.6.3. Whole-project import/parse: PASS, no errors.

All nine repository suites PASS:

```
REWARD_FEEDBACK_V3_TESTS                    PASS   (new)
REFERENCE_GAME_FEEL_V2_TESTS                PASS
ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS   PASS
UI_SCALE_LAYOUT_TESTS                       PASS
GAME_FLOW_REWARD_SPLASH_TESTS               PASS
SOUND_PRIVACY_LINK_TESTS                    PASS
BRANDING_PUSH_LINE_TESTS                    PASS
SCENE_VARIETY_ASSETS_TESTS                  PASS
ADMOB_INTEGRATION_TESTS                     PASS
```

The merge/contact-only gameplay suite is unchanged in substance:
`REFERENCE_GAME_FEEL_V2_TESTS` still proves visible separation does not merge,
exact contact merges once, the visible-touch band merges once, slight overlap
merges once, different tiers collide without merging, fast shots are substepped,
and chains require each contact.

Three previously-frozen timing assertions were updated to the new approved v3
contract, because this task explicitly supersedes them:

- `MERGE_PRESENTATION_DURATION` 0.27 → 0.42, `MERGE_SOURCE_PULL_DURATION` 0.06 → 0.07
- `MERGE_REVEAL_START` / `MERGE_REVEAL_SOUND_AT` 0.0 → 0.11
- `MERGE_RESULT_POP_SCALE` 1.26 → 1.18
- `WIN_PRESENTATION_HOLD` 0.42 → 0.18 (it is now the beat after the last coin,
  not the whole pre-modal wait)
- The old 1.66 s final bound is replaced by `GameConfig.final_celebration_duration()`

`tests/run_reward_feedback_v3_tests.gd` adds coverage for: the reward hierarchy
ladder, the exact normal-merge and Phase A scale keyframes, hit-stop lock and
exact momentum restore, cosmetic effects adding no simulation bodies, combo
labels appearing only for chained merges, restart clearing every temporary
record, non-final targets keeping the existing compact collection, and the full
final-target celebration driven frame by frame through the production controller.

### In-game verification

`tests/capture_reward_feedback_v3.gd` drives real confirmed merges through the
production controller in a 720×1280 viewport and photographs every stage.
Screenshots are in `reports/reward-feedback-v3/screenshots/`.

Confirmed visually: normal merge pop with three mini gems and its ring; COMBO 1/2/3
escalation with clear labels; the hero gem held enlarged at the centre of the
playable board with its glow and `TARGET COMPLETE!` caption while the panel still
reads `0 / 1`; the gem arriving at the correct HUD panel with the count flipping
to `COMPLETE · 1/1` and its sparkles; twenty coins resting evenly on the table
during the hold; staggered curved collection into the top-left counter; and the
Level Complete modal appearing only afterwards with its layout intact.

Two defects were found by the captures and fixed before completion: the
`TARGET COMPLETE!` caption fired ~200 ms late, and the Level Complete gem and
reward card were still invisible at 3.2 s because the staged reveal ran too long.

### Not verified

No Android device was connected, so no on-device testing is claimed at the time
of the initial pass (a debug APK was produced in the follow-up fix below).

## Addendum — HUD coin-counter continuity fix

After the initial pass, in-game observation surfaced a regression: once the
final-target reward coins land in the top-left HUD counter, the counter visibly
**drops back to the pre-level balance** the instant Level Complete opens, then
climbs back up again when `COLLECT` is pressed. Example: starting balance
7,850, target reward 4,550 — the HUD correctly climbed to 12,400 as coins
landed, then dropped to 7,850 when the modal appeared.

### Root cause

The bug was pre-existing, not introduced by the initial reward-feedback-v3 pass.
Individual target coin rewards had always been animated live into the top-left
HUD counter as they land (`GameplayEffectsLayer` → `_on_coin_arrived` /
`_on_level_reward_coin_arrived` → `GameplayHudLayer.collect_coin_chunk`), and by
the time `_update_win_presentation` is ready to present, that live delivery has
already finished — `_displayed_coins` is already correct. It was only ever
*visually* jarring for the final target, because the new celebration makes the
climb prominent (20 coins, a 380 ms hold) instead of a quick 4-coin flight.

The actual defect was in `GameplayHudLayer.prepare_completion_reward_display`,
called once as Level Complete is about to present:

```gdscript
func prepare_completion_reward_display(previous_total: int, final_total: int) -> void:
	_displayed_coins = maxi(0, previous_total)   # forced back to the PRE-LEVEL total
	...
```

This unconditionally overwrote the already-correct `_displayed_coins` with
`previous_total` (the pre-level balance), so the counter reset itself right as
the modal opened. `animate_completion_reward`, called from `_on_collect_requested`,
then re-climbed from that artificially-reset value back up to the real total —
a redundant second animation of a reward that was granted once, at merge time.

**Where the reward becomes authoritative:** `coins += awarded_coins` inside
`_apply_confirmed_merge_events`, at the confirmed merge event — never at
`COLLECT`. This was already true before this task and is unchanged.

**What `COLLECT` actually does:** persists the current `coins` value via
`ProgressionSaveServiceType.save_progress` and unblocks the level transition. It
has never granted or changed the reward amount; it only used to (incorrectly)
re-animate the HUD display of an amount already granted.

**What the HUD reads from:** `GameplayHudLayer` already had the intended
"authoritative + displayed" structure (`_authoritative_coins`, `_displayed_coins`,
`_queued_coin_rewards`), reused as-is. The only defect was one call path that
moved `_displayed_coins` backward instead of only ever forward.

### Fix

`prepare_completion_reward_display` no longer forces the display down. It
clamps the existing value between `previous_total` and `final_total` — a no-op
in the normal case where the live celebration already delivered every coin, and
a forward-only correction in any path that skipped it:

```gdscript
_displayed_coins = clampi(_displayed_coins, previous_total, final_total)
```

`animate_completion_reward` (used by both `COLLECT` and the rewarded
"double coins" bonus) now skips the tween entirely when the display has already
reached `final_total`, so `COLLECT` can never re-animate or imply a reward was
granted twice. It still animates forward for the one case where `final_total`
is genuinely higher than what has landed — the double-coins bonus, which really
does add more coins after `COLLECT`-adjacent interaction.

No authoritative state changed: `coins`, the exactly-once merge-result guards,
and `ProgressionSaveServiceType` are untouched. This was purely a display-layer
fix — one balance, one forward-only displayed projection of it.

### Verification

Added `_test_hud_coin_counter_continuity` to
`tests/run_reward_feedback_v3_tests.gd`, which drives the real COLLECT →
transition → scene-reload flow through the production controller and asserts,
for a real final-target completion:

- `balance_before + target_reward == final_authoritative_balance`
- the HUD already reads the final balance the instant the last reward coin arrives
- the HUD does not drop when Level Complete opens
- the HUD is still at the final balance once Level Complete has settled
- `COLLECT` does not grant the reward again, and persists the exact final balance
- the level transition afterward changes neither the balance nor the HUD value
- a freshly reloaded controller (simulating leaving/re-entering the scene) loads
  the same exact balance from disk, with the HUD showing it correctly from the
  first frame

To confirm the test would actually have caught the original bug, the fix was
temporarily reverted and the suite re-run: it failed with exactly the three
assertions describing the reported symptom (drop on Level Complete open, wrong
value once settled, wrong value after COLLECT). The fix was then restored and
the suite re-verified as passing. The test backs up and restores the developer's
real on-disk save (`user://infinite_progression.cfg`) around the run, since this
is the first test in the suite to exercise the actual `COLLECT`/save/reload path.

All nine repository suites pass after the fix, including the new assertions:

```
REWARD_FEEDBACK_V3_TESTS                    PASS
REFERENCE_GAME_FEEL_V2_TESTS                PASS
ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS   PASS
UI_SCALE_LAYOUT_TESTS                       PASS
GAME_FLOW_REWARD_SPLASH_TESTS               PASS
SOUND_PRIVACY_LINK_TESTS                    PASS
BRANDING_PUSH_LINE_TESTS                    PASS
SCENE_VARIETY_ASSETS_TESTS                  PASS
ADMOB_INTEGRATION_TESTS                     PASS
```

In-game screenshots were re-captured (`reports/reward-feedback-v3/screenshots/`,
regenerated in place): the top-left `COINS` panel now reads the same post-reward
value (e.g. `14.7K`) continuously from the moment coins finish arriving, through
Level Complete opening, through settling — no drop is visible at any point.

### Scope note — the modal's own reward-card total

The Level Complete panel has a second, separate coin display inside its reward
card (`ResultOverlayLayer`'s "TOTAL" row), which still shows the pre-level total
until `COLLECT` is pressed, then animates up as its own deliberate "count up your
reward" flourish. This is a distinct UI element from the top-left HUD counter
described in this fix, was not part of the reported symptom or the stated
invariants (all of which reference "the HUD"), and was left unchanged to keep
this fix minimal and scoped. It does not read from or affect `coins`, so it
carries no economy risk; it is only a separate, arguably still-inconsistent
cosmetic detail worth a follow-up task if wanted.

### APK

A debug verification APK was exported to confirm this fix packages correctly:
`build/android/majestic-gems-reward-feedback-v3-hud-coin-fix.apk`. It reuses the
committed versionCode 6 / versionName 1.0.4 identity unchanged (no AAB was
generated, so no version bump was required per the release rule). See
`BUILD_MANIFEST.md` for size, hash, validation, and test evidence. No Android
device was connected, so on-device installation/launch is not claimed. This
build is uncommitted working-tree state on top of `db11dae` and is not tagged.
