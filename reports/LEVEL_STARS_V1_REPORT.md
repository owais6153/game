# Level Stars and Pinned Level Records V1 — 1.0.19 (vc21) — 2026-09-09

Scope: three star objectives per level, shown before play and awarded one at a
time after it; star totals on the level screen and per-level rows on the map;
and a per-level snapshot so a replayed level is the one the player remembers.

---

## The star model

### Three stars, three different kinds of demand

| Star | Asks for | Source |
| --- | --- | --- |
| 1 | Complete the level | always |
| 2 | Finish in N shots or fewer | `LevelSolver.minimum_shots()` × 1.25 |
| 3 | One of: merge N gems / reach combo N / win without a power | rotated per level |

Stars 2 and 3 pull in opposite directions on purpose. One rewards taking fewer
shots; the other rewards the volume or depth of what those shots produce. Three
stars is therefore a decision about *how* to play, not the same play done
better. `no_power` is orthogonal to both.

### No threshold is authored

This is the part that matters. The shot ladder that preceded `LevelSolver`
counted down 40 → 30 with no reference to what a level contained, and **every
limited level in the game was unwinnable** because of it — for months, unnoticed,
until a feasibility pass was written. A star is the same failure waiting to
happen: it is a number promised on the level-start screen.

So `LevelSolver.simulate()` now reports the merges it performs alongside the
shots, and both numeric stars are sized against a play-out of that exact level.
No literal threshold exists in `LevelStars`. If a template is retuned, the stars
move with it.

`scripts/dev/print_level_star_audit.gd` prints the whole table so the numbers can
be read rather than assumed — which is how the first draft of the merge star was
caught (see below).

### Measured results, levels 1–120

```
level  band          limited  minShots  starShots  slack%  perfMerges  objective
    1  TUTORIAL      no             45         57   26.7         109  Merge 95 gems
    4  NORMAL        yes            19         24   26.3          52  Reach a combo of 2
   13  CHALLENGING   yes            11         15   36.4          45  Reach a combo of 3
   22  CHALLENGING   yes             9         13   44.4          39  Reach a combo of 3
   26  EXPERT        no             65         82   26.2         205  Win without using a power
   37  EXPERT        no             76         95   25.0         201  Merge 222 -> 180 gems

Third-star distribution over 120 levels: {merges: 34, no_power: 43, combo: 43}
Tightest shot star: level 3 at +25.0% over a perfect play-out
```

Two bounds are asserted for **all 120 levels**, not spot-checked:

- The shot star leaves at least 20% over a perfect play-out (measured minimum:
  25.0%), and on a limited level sits strictly inside that level's own budget —
  otherwise winning would award it for free.
- The merge star sits at or below the merge count a perfect play-out performs.

### The merge star was tuned the wrong way first, and the audit caught it

The first draft set the merge bar at **110% of a perfect play-out**, reasoning
that a real player takes 30–70% more shots and therefore produces more material
and more merges. The audit printed `Merge 120 gems`, `Merge 152 gems`,
`Merge 222 gems` — and the reasoning was only half right.

A real player does take more shots, but also strands gems the play-out pairs
perfectly, and **no player can beat the play-out's merges per unit of material**.
The net of those two effects is not knowable from the config.

The failure modes are not symmetrical. A star that is slightly too easy is a mild
waste. A star nobody can reach is a promise the level-start screen made and
broke. So the bar was moved to **90% of the demonstrated count**, and the merge
star is now openly the most forgiving of the three. It is also rounded down to a
multiple of five, because `Merge 98 gems` reads as a number that fell out of a
formula and `Merge 95 gems` reads as an objective.

### Rotation

`bonus_kind()` hashes the level number rather than using `level % 3`, so the
third star is not a visible metronome. Over 120 levels: 34 merge, 43 combo, 43
no-power, with adjacent repeats present but not universal (both asserted).

---

## The flow

**Level Ready** shows the three objectives with empty stars, and lights the ones
already held so a replay shows at a glance which is still missing. The wording is
the exact `text` field from `LevelStars`, carried through the controller snapshot
— presentation composes nothing, so the screen cannot promise a different
objective from the one that is scored.

**Level Complete** awards the earned stars one at a time (0.44 s each, 0.30 s
apart), naming each objective under the row as it lands, then reports the tally.
`COLLECT`, `DOUBLE COINS` and `HOME` are disabled until the last star has landed:
without the gate a tap on the popup's first frame dismissed an award the player
never saw. A failed result shows no star row and gates nothing.

**The level screen** totals the stars beside the chest line in the header, and
every cleared node on the map carries its own three-star row.

Order with the treasure ceremony: board settles → post-win treasure (if any) →
stars banked → Level Complete opens → mascot reacts → stars land → actions
unlock.

---

## Two boundaries this keeps

**Stars are banked before they are shown.** `_award_level_stars()` evaluates,
persists and logs at win time; the popup animates a record of something already
saved and grants nothing. Same rule the treasure ceremony follows. The test
asserts this through the save file, not through memory.

**Evaluation reads the aggregates that already existed.** `shots_used`,
`merges`, `best_combo` come from `LevelAttemptAnalytics` and `used_power` from
the existing flag. No counter was added, so a star and the `level_complete`
event describing the same attempt cannot disagree — which a parallel counter set
would make possible the first time one was reset in the wrong place.

Storage is monotonic *inside* `ProgressionSaveService`, so every caller gets the
guarantee: replaying an old level to chase a missed star can never cost the ones
already held.

---

## Level records

### Why, when generation is already deterministic

`LevelConfig.generated(n, seed_for_level(n))` is pure, so replaying level 9
already rebuilt exactly the level that was played — same gems, same board, same
queue, same background. That is asserted directly in
`run_level_select_map_v1_tests` and was never in doubt.

What it is pure **with respect to** is our generator. Retuning a template, adding
a gem to the catalog, changing a layout archetype or bumping
`GENERATOR_VERSION` silently rewrites every level the player has already played.
The purity guarantee holds across devices and reinstalls; it does not hold across
updates. Once a level has been played it is a place the player remembers, and the
level map's promise — that going back to level 9 means going back to *that* level
9 — has to survive the next content patch.

So the snapshot is not a substitute for determinism. It is the record that pins a
level once the player has actually met it.

### What is stored

Only the fields that decide what a level *is*: `seed`, `gem_identity_by_tier`,
`launcher_sequence`, `starting_board`, `target_sequence`, `shot_limit`,
`level_type`, `background_index`, `table_index`. Everything else in a config is
derived metadata — analytics ids, pattern bookkeeping, band names — and is left
to regenerate, so a future field is not frozen at whatever value it happened to
have.

Records live in `user://level_records.cfg`, not in the progression save. The
progress file is read on every launch and written on every coin transaction; a
player at level 300 would otherwise parse and rewrite three hundred board layouts
to bank one merge.

### Two rules that carry the feature

- **`store()` is write-once.** A level already on file is left exactly as it is.
  An unconditional write would re-pin the level to whatever the current generator
  produces on every visit — the exact opposite of the point.
- **`matches()` compares structurally.** This was found by the test: a ConfigFile
  round trip does not preserve Dictionary key order, so `str()` comparison of two
  byte-identical opening boards reported a mismatch on every level and the drift
  detector would have cried wolf permanently. It now walks the structure and
  reconciles int against float.

---

## Tests

New: `tests/run_level_stars_v1_tests.gd` — five registered UI/controller cases
plus five pure-function cases.

| Case | What it protects |
| --- | --- |
| `every_level_has_three_stable_objectives` | Three objectives, first is always completion, wording present, pure across calls |
| `shot_star_is_reachable_and_meaningful` | **All 120 levels**: above a perfect play-out by ≥20%, and below a limited level's own budget |
| `bonus_star_is_reachable_and_varied` | **All 120 levels**: merge bar ≤ perfect merges, combo in 2–3, all three kinds appear, rotation is neither rigid nor fixed |
| `evaluation_rules` | A loss earns nothing; exact-budget wins; one shot over misses; each third-star kind driven through a level that actually carries it |
| `star_totals_and_clamping` | Totals, hand-edited-save clamping, `★★☆` glyphs |
| `records_pin_a_level_once_it_has_been_played` | Write-once, drift detection, record beats a changed generator, derived metadata still regenerates |
| `controller_awards_and_banks_stars` | Stars **on disk** before the popup; monotonic replay; snapshot carries objectives |
| `result_popup_awards_stars_before_unlocking_collect` | COLLECT locked during the sequence, only earned stars awarded in order, unlock after the last, loss gates nothing |
| `level_ready_shows_the_objectives_it_will_be_judged_on` | Verbatim wording, held stars lit, block hidden when there is nothing to show |
| `map_and_header_render_the_stored_stars` | Header total follows an update; the map draws only what it is handed and invents nothing |

`run_reward_feedback_v3_tests`, `run_level_select_map_v1_tests`,
`run_ui_kit_polish_v1_tests` and the rest are unchanged and green.

**All 40 suites pass, over two consecutive full passes.**

---

## Files

| File | Change |
| --- | --- |
| `scripts/core/level_stars.gd` | New. Objectives, derived thresholds, evaluation, totals. |
| `scripts/core/level_solver.gd` | `simulate()` also reports `merges`. Additive. |
| `scripts/services/level_record_service.gd` | New. Per-level snapshot: store once, apply on replay, structural drift check. |
| `scripts/presentation/star_row.gd` | New. Drawn star row with per-star fill/pop/burst. |
| `scripts/services/progression_save_service.gd` | `level_stars` load + monotonic `save_level_stars()`. |
| `scripts/gameplay/game_controller.gd` | Record apply/store, objectives on configure, `_award_level_stars()`, snapshot fields, star award into the popup. |
| `scripts/ui/home_overlay_layer.gd` | Level Ready objectives block. |
| `scripts/ui/result_overlay_layer.gd` | Star row, award sequence, action gate. |
| `scripts/ui/level_select_overlay_layer.gd` | Header star total. |
| `scripts/ui/level_map_view.gd` | Per-node star rows. |
| `scripts/dev/print_level_star_audit.gd` | New. Development-only threshold audit. |
| `tests/run_level_stars_v1_tests.gd` | New suite. |

Simulation, merge, launcher, collision, table geometry, `GameConfig` and level
generation itself are untouched.

---

## Version note

Shipped as **versionName 1.0.19 / versionCode 21**, on product-owner
instruction.

`BUILD_MANIFEST.md` records codes 21–27 and names 1.0.19–1.0.22 against local
test iterations built on 2026-09-05. **None of those were ever uploaded**, and
the product owner retired them on 2026-09-05 when the canonical release identity
was corrected back to 1.0.18 / vc20 — which is the version actually delivered to
Play. vc21 is therefore strictly above the highest *uploaded* code, which is the
constraint Play enforces.

This is a deliberate departure from the standing "strictly greater than every
code in the manifest" rule, following the same precedent already recorded in the
manifest for the vc20 correction. It is flagged here so a future pass does not
read the vc24 entry and conclude the line had regressed.

---

## Residual risk

- **Star thresholds are proven reachable, not proven well-tuned.** The bounds
  come from a solver that assumes perfect placement; how often real players
  actually take each star is unmeasured. `level_stars_awarded` carries the raw
  `shots_used` / `merges` / `best_combo` alongside the verdict specifically so
  the first week of data can answer it, and every threshold is a single constant.
- **Levels already cleared before this update have no stars**, and are not
  retroactively credited — the game has no record of how they were cleared, and
  awarding three would make the first star meaningless everywhere behind the
  player. A returning player sees their existing progress with empty star rows.
- **Records only pin levels entered from this version onward.** A player at
  level 300 has no snapshots for levels 1–299; those still rely on generator
  purity, which is intact today. The protection begins at the next visit to each
  level.
- **The three-star popup is longer than it was** — roughly 2.9 s from the popup
  opening to COLLECT unlocking on a full-marks win. Tuned on desktop at 60 fps;
  device feel is covered by the install below rather than by measurement.
