# Level Design — Template System

**Generator version 2, introduced in 1.0.17.**

Source: `scripts/core/level_template.gd` (compositions and pacing),
`scripts/core/level_config.gd` (generation), `scripts/core/level_solver.gd`
(feasibility).

## Why this exists

Before 1.0.17 a level was assembled from three independent ladders, each keyed to
the level number alone: a launcher queue cycle, a target-quantity curve, and a
limited-shots modulo. Each ladder capped out — the queue by level 13, target
quantities by level 26, board rows by level 8 — and once all three had capped,
every subsequent level was one of exactly two shapes:

- normal: L6×3 → L7×2 → L8×1, four rows, scarce queue
- limited: L6×1 → L7×1, four rows, scarce queue

Backgrounds and gem sets kept changing, so the game still *looked* varied. But
from roughly level 14 onward the decisions the player made stopped changing, and
that is what the audit picked up as the progression plateau.

## The model

A **template** names one complete composition rather than a point on three
separate curves:

| Field | Drives |
| --- | --- |
| `band` | Intrinsic difficulty of this composition |
| `queue` | Launcher generosity (5 bands, `intro` → `scarce`) |
| `layout` | Opening board archetype (11 shapes) |
| `rows`, `gaps` | Opening board density |
| `targets` | Target structure (10 ladders) |
| `limited`, `shot_margin` | Limited-shot behaviour and its margin |
| `power_hint` | Which power the composition rewards (metadata only) |

Difficulty becomes a property of the *combination*. Two levels in the same band
can play very differently: a lean queue against a short target ladder, or a
generous queue against a long one. That is the variation the three-ladder system
could not express, because there the queue and the targets both hardened
together as the level number rose.

**No new mechanics.** Every field drives a system that already shipped.

## Difficulty bands and pacing

Bands: `TUTORIAL` → `EASY` → `NORMAL` → `CHALLENGING` → `HARD` → `EXPERT`, with
onsets at levels 1, 4, 8, 15, 26, 40.

Levels 1-5 are scripted, because the opening has to teach in a fixed order.
From level 6, each level is assigned a **role** from an 8-long cycle:

```
challenge, challenge, relief, challenge, spike, relief, challenge, spike
```

Each role draws from a per-band pool. Relief levels deliberately drop to an
easier template than the level before them: a run of ever-harder levels flattens
into "hard" and the spikes stop registering. The curve trends upward without
being monotonic — asserted by `run_level_template_v1_tests`, which requires both
an upward trend across the run and at least ten genuine dips.

Two selection details that matter:

- Pool entries are indexed by a **multiplicative hash of the level number**, not
  by `level % pool.size()`. The role cycle has an even length, so a modulo walk
  handed a two-entry pool the same index every time that role came round — which
  put levels 50, 60 and 100 all on one template in the first audit run.
- If two adjacent levels still resolve to the same template, the second steps to
  the next pool entry. Back-to-back identical compositions are exactly the
  repetition this system removes, and the test suite treats them as a failure.

## Limited-shot cadence

Previously every third level, forever — legible enough that players could count
it. Now seven in every twenty-three, with gaps of 2, 5, 3, 2, 4, 3, 4.

Any deterministic schedule repeats; the only question is whether the period is
long enough that nobody counts it. **Check the emitted gap sequence, not the
pattern array** — two attempts here looked irregular written down and were not:

- a 13-length pattern produced gaps cycling `2 5 2 4`, so every *other* limited
  level sat exactly two apart — learnable in one sitting;
- a mis-transcribed 23-length pattern yielded only three distinct gap lengths in
  a `5 3 5 3 5 2` loop.

23 is prime and so shares no factor with the 8-long role cycle, giving a
combined period of 184 levels before cadence and pacing role pair up the same
way again. `scripts/dev/verify_level_systems.gd` prints the gap histogram.

Density is held near the old one-in-three, but note that per-level coin income
still fell 12.3% against 1.0.16 — not from the cadence but because the target
ladders themselves are shorter. Levels also demand 12.6% less material, so the
earn rate per unit of merge work is unchanged (+0.3%) and coins per minute is
flat. **Read ECONOMY.md before changing any target quantity to "fix" the
per-level figure; doing so would inflate the economy.**

Limited levels are never back to back.

## Target progression — and one behaviour to understand

Ten structures, all using only tiers 6-8:

| Key | Ladder |
| --- | --- |
| `pair_low` | L6×1 → L7×1 |
| `base_pair` | L6×2 → L7×1 |
| `top_pair` | L7×1 → L8×1 |
| `climb_single` | L6×1 → L7×1 → L8×1 |
| `climb_base` | L6×2 → L7×1 → L8×1 |
| `climb_middle` | L6×1 → L7×2 → L8×1 |
| `climb_heavy` | L6×2 → L7×2 → L8×1 |
| `climb_wide` | L6×3 → L7×2 → L8×1 |
| `base_heavy` | L6×3 → L7×1 |
| `low_build` | L6×2 → L7×2 |

### The audit: future target gems do not count

**Behaviour, confirmed in `GameController` (the `result_level ==
active_target_tier()` check at merge resolution):** a merge counts toward a
target only if its result tier equals the *currently active* card at the moment
it resolves. Counting is driven by the merge event, not by a board scan, so a
tier-8 gem built while the tier-6 card is active is never banked for the tier-8
card later. It stays on the board as a settled gem — wasted material *and*
permanent clutter.

**This is preserved.** It is what makes the target sequence a sequence rather
than a checklist, and changing it would alter the core loop for every live
player.

**How the templates account for it:**

1. **Target tiers always ascend.** `LevelTemplate.validate()` enforces it and the
   test suite asserts it over 120 levels. A descending ladder would strand work
   the player has to do anyway.
2. **The apex tier is asked for at most once.** L8 is the longest chain in the
   level; repeating it multiplies the hardest work rather than deepening the
   objective.
3. **Quantity caps:** L6 ≤ 3, L7 ≤ 2, L8 = 1.

**Consequence for anyone reading analytics:** a high `total_merges` on a failed
attempt can mean the player was building ahead and wasting material, not that
they were close to winning. See `reports/DIFFICULTY_ANALYTICS_GUIDE.md` §6.

**Consequence for the solver:** `LevelSolver.simulate()` keeps a tier histogram
and *does* collect pre-built gems once their card becomes active. It is therefore
optimistic relative to the real game, and every figure derived from it —
`shot_limit`, `spare_shots`, the difficulty classification — is an upper bound on
real play. This is safe in the direction that matters (shot limits come out
slightly generous rather than impossible) but it means solver output must never
be read as a difficulty prediction.

## Layout archetypes

Twelve shapes: `empty`, `staggered_gaps`, `left_heavy`, `right_heavy`,
`center_heavy`, `split_clusters`, `alternating_gaps`, `wide_center_gap`,
`two_pocket`, `chain_opportunity`, `sparse_top`, `dense_top`.

An archetype decides **only** which columns are left open and how tiers are
distributed. Row heights, column positions, spacing, gem radii, collision
geometry, and the danger-line margin are untouched and still come from
`GameConfig` and the `STARTING_BOARD_*` constants, so no archetype can place a
gem inside a rail or start a level near failure.

### The no-straight-lane guarantee

The seeded board exists to stop a level being cleared by pushing gems up a single
line. A column left open in *every* row is exactly that lane.

Archetypes express a **preference** over gap positions; the selector only ever
picks from columns that already satisfy the separation rule against the previous
row. So `left_heavy` leans left without ever stacking its openings into a
full-height channel.

Where the separation rule starves the candidate pool, the generator serves
**fewer gaps** rather than abandoning the rule. The original fallback — take any
column — opened real lanes on four levels during development, caught by
`run_level_template_v1_tests`, which samples 60 horizontal positions per level
across 120 levels and every archetype.

`chain_opportunity` additionally assigns tiers in adjacent pairs, so the board
opens with matching gems already touching and one good shot can start a cascade.
That is the existing merge rule being set up, not a new mechanic.

Note that `chain_opportunity` is the one archetype whose effect is **invisible in
a gap diagram** — its gap placement is deliberately unconstrained, so it looks
like `staggered_gaps` when drawn. Its difference is in tier placement, measured
rather than assumed: across 40 seeded boards it produces adjacent same-tier pairs
in **71%** of neighbouring slots, against **23.8%** for `staggered_gaps` (which
is about the 25% expected by chance across four spawnable tiers).
`scripts/dev/verify_level_systems.gd` renders every archetype.

## Validation

- `scripts/dev/print_level_template_audit.gd` — generates levels 1-100 and prints
  composition, solver verdict, template/band/layout distribution, coin income by
  band, and any immediate repeats. Run it after any change here.
- `tests/run_level_template_v1_tests.gd` — selection determinism, target
  validity, layout safety, straight-lane check, limited solvability, cadence
  irregularity, difficulty trend, and analytics identifier presence over 120
  levels.
- `tests/run_level_difficulty_v1_tests.gd` — the pre-existing difficulty
  invariants, updated for template-driven density and margins.

## Changing the system safely

1. Edit `TEMPLATES`, `TARGET_STRUCTURES`, `QUEUE_BANDS`, or the pools.
2. Run `print_level_template_audit.gd`. Check: no problems reported, no
   consecutive repeats, all templates reachable, coin income still rising by band.
3. Run the full suite.
4. **Bump `GENERATOR_VERSION`** so analytics can separate before and after.

Every template must be reachable — the test suite fails on one that is never
selected, because dead configuration drifts out of sync with the code around it.
