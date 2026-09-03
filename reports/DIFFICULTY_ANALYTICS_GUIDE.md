# Reading Real-User Difficulty — Analyst Guide

**For: whoever balances Majestic Gems levels after the 1.0.17 release.**

The point of the 1.0.17 instrumentation is that level balancing stops being a
matter of opinion. Every level now reports which *composition* was played and
how the attempt actually went, so "level 34 is too hard" becomes a number you
can check.

This guide says which events to look at, which parameters matter, and — the part
that is easy to get wrong — what the numbers actually mean. `ANALYTICS_EVENT_CATALOG.md`
is the schema; this is how to use it.

Everything here is Firebase/GA4. No backend was built and none is needed.

---

## 1. The unit of analysis is the template, not the level

The single most important habit: **group by `level_template_id`, not by
`level_number`.**

A level number tells you where a player was. A template tells you what they were
asked to do, and it is the thing you can actually change. Eighteen templates
cover a hundred levels, so a template has roughly six times the sample size of
any one level and reaches significance six times sooner.

Use `level_number` when you are investigating a specific reported level, and
`layout_id`, `queue_band`, or `target_structure` when you want to know *which
part* of a composition is causing the problem — those three are the levers you
would pull.

`generator_version` is on every level event. Filter on it. When the generator
changes, old rows describe levels that no longer exist, and mixing them is the
easiest way to draw a confident wrong conclusion.

---

## 2. The core metrics and how to compute them

All of these come from four events: `level_start`, `level_complete`,
`level_fail`, `level_abandon`. Every one carries `level_template_id`,
`layout_id`, `difficulty_band`, `queue_band`, `target_structure`.

| Metric | How to compute it |
| --- | --- |
| Starts | `count(level_start)` |
| Completion rate | `count(level_complete) / count(level_start)` |
| Failure rate | `count(level_fail) / count(level_start)` |
| Abandonment rate | `count(level_abandon) / count(level_start)` |
| Retry rate | `count(level_retry) / count(level_fail)` |
| Skip rate | `count(level_skip) / count(level_start)` |
| Average attempts to win | `avg(attempt_number)` on `level_complete` |
| Average shots used | `avg(shots_used)` on the outcome event |
| Average time to win | `avg(attempt_duration)` on `level_complete` |
| Average time before failure | `avg(attempt_duration)` on `level_fail` |
| Average powers used | `avg(powers_used_count)` on the outcome event |
| Most-used power | mode of `most_used_power` |
| Chain frequency | `avg(shot_chain_percent)` |
| Merge frequency | `avg(shot_merge_percent)` |
| Max combo | `avg(max_chain_depth)` and its distribution |
| Coin spend | sum `amount` on `coin_spent`, split by `coin_sink` |
| Continue usage | `count(continue_used) / count(level_fail)` |
| Extra-shot usage | `count(extra_shots_used) / count(out_of_shots)` |

The three outcome events are mutually exclusive — they share one latch — so
completion + failure + abandonment should account for very nearly every start.
**If they do not sum to ~100%, stop and investigate the instrumentation before
trusting anything else.** The usual innocent cause is an app kill mid-attempt,
which produces a start with no outcome; a large gap means something is wrong.

---

## 3. What the numbers mean

This is the part that matters. A completion rate on its own does not tell you
whether a level is bad — you need the shape of the failure.

### Too easy

- Completion rate **> 90%** on first attempt (`attempt_number = 1`)
- `avg(attempt_number)` on completion **≈ 1.0**
- On limited levels, `shots_remaining` at completion is consistently **high** —
  the shot limit is not doing anything
- `powers_used_count` **≈ 0** — no one needed help
- Short `attempt_duration` with a high completion rate

A level being easy is not automatically a problem: relief levels are *supposed*
to look like this. Check `template_role` on `level_start` first. A `relief`
template reading easy is working; a `spike` template reading easy is broken.

### Too hard

- Completion rate **< 35%**
- `avg(attempt_number)` **> 3** before a win
- High `count(level_skip)` — players are paying 800 coins to escape
- High `continue_used` and `extra_shots_used` rates
- `targets_completed` on `level_fail` clustered at **0 or 1** — they never got
  going, as opposed to failing at the last card

The distinction that matters: failing *near the end* is good difficulty; failing
*at the start* is a level that does not give the player a way in. Compare
`targets_completed` on `level_fail` against the level's card count. Lots of
`final_target_complete` events without matching `level_complete` events means
players are reaching the last card and dying there — usually a shot limit or
board-pressure problem, not a target problem.

### Boring

This is the one the old analytics could not see at all, and it is the reason
`shot_merge_percent` and `shot_chain_percent` exist.

- `shot_chain_percent` **< 10%** — chains are the game's satisfaction, and they
  are not happening
- `avg(max_chain_depth)` **≤ 1** — no cascades, just one-off merges
- `combo_3_plus_count` **≈ 0** across the whole template
- High completion rate **combined with** high `attempt_duration` — long, easy,
  and uneventful, which is the worst combination in the set
- Abandonment concentrated at `abandon_point = mid_targets` while the completion
  rate is *high* — they could have won and stopped caring

A boring level and an easy level are different failures with different fixes. An
easy level needs more pressure; a boring one needs a `chain_opportunity` layout
or a denser opening board so the cascades have material to work with.

### Good challenge — what you are aiming for

- Completion rate **55-75%**
- `avg(attempt_number)` between **1.4 and 2.5** — most players lose once
- `shot_chain_percent` **> 20%**, `avg(max_chain_depth)` **≥ 2**
- `powers_used_count` **> 0 but < 2** — powers help and are not mandatory
- Retry rate **high** (> 70% of failures retry) and skip rate **low** (< 5%)

That last pair is the strongest single signal in the whole dataset. **A player
who fails and retries found the level fair. A player who fails and skips or
abandons found it unfair.** When you have time to look at exactly one number per
template, look at retry-versus-skip after failure.

---

## 4. Diagnosing *which lever* to pull

Once a template is flagged, these comparisons isolate the cause. All three
dimensions are on every level event.

**Group by `queue_band`** (`intro` / `generous` / `balanced` / `lean` /
`scarce`). If failure concentrates in `lean` and `scarce`, the player is not
being given enough material and the fix is the queue, not the targets. Expect
`shot_merge_percent` to fall as the band tightens; a sharp cliff between two
bands means one is mistuned.

**Group by `layout_id`** (11 archetypes). Layouts are directly comparable —
otherwise-identical templates differ only in opening shape. A layout with a
notably worse completion rate is placing gems where they block rather than help.
Watch `two_pocket` and `wide_center_gap`, the two most constrained.

**Group by `target_structure`** (10 structures). This isolates objective length
from board pressure. `climb_wide` (L6×3 → L7×2 → L8×1) is the longest ladder in
the game; if it underperforms everywhere it is too long, not badly placed.

**Check `starting_board_gem_count`** from `level_start` against failure rate. A
correlation means opening density is the dominant difficulty term and the
template's `rows`/`gaps` need adjusting rather than its queue.

---

## 5. Limited-shot levels

Limited levels need their own pass, because a shot limit fails differently.

Filter `level_type = "limited_shots"` and compare `shots_remaining` at
completion against `shot_limit` from `level_start`:

- Consistently **> 40%** of the limit left over: the margin is too generous and
  the limit is decorative
- Consistently **< 10%** left: near-flawless play is required, which the design
  rule forbids
- Healthy is roughly **15-30%** spare

`out_of_shots` firing far more often than `level_fail` with
`fail_reason = "out_of_shots"` means players are rescuing themselves with
`extra_shots_used` — the level is over-tight and the economy is absorbing it,
which will show up as coin drain rather than as a failure rate.

Shot limits are computed by `LevelSolver` from a perfect play-out times the
template's `shot_margin`. **Note the solver is optimistic**: it banks gems built
before their card is active, and the real game does not (see §6). So the real
margin is always somewhat tighter than the configured one. If limited levels
read uniformly hard, this asymmetry is the first place to look.

---

## 6. Two known asymmetries — read before concluding anything

**Targets are counted at merge time against the active card.** A gem merged
above the active tier is *not* banked for a later card; it stays on the board as
clutter. So a player who builds ahead is punished, and `total_merges` can be high
on a failed attempt precisely because the merges went to waste. Do not read high
merges on a failure as "they were doing well".

**`LevelSolver` does not model that.** Its `simulate()` keeps a tier histogram
and collects pre-built gems once their card becomes active, so every solver
figure — `shot_limit`, `spare_shots`, the `EASY`/`MEDIUM`/`HARD` classification —
is an upper bound on what a real player achieves. Treat solver output as a
feasibility floor, never as a difficulty prediction. Real-user data is the
authority, which is the whole reason this instrumentation exists.

---

## 7. Session and retention

Firebase's automatic `session_start` and `user_engagement` are not replaced and
should not be. Derive session-level figures from the level events within a
session:

- Levels attempted per session: `count(level_start)` per session
- Levels completed per session: `count(level_complete)` per session
- Highest level reached: `max(level_number)` per user
- Time spent per level: `attempt_duration`, summed across attempts
- Where players stop: last `level_start` before a session ends, plus
  `abandon_point` on `level_abandon`

For the "where do players quit the game entirely" question, look at the last
`level_number` seen per user against `difficulty_band` and `template_role`. A
band boundary — 8, 15, 26, 40 — showing a drop-off means that step up is too
steep.

---

## 8. A first-week checklist

1. Confirm outcome events sum to ~100% of starts. Fix instrumentation first if
   not.
2. Rank templates by completion rate. Look at the extremes, not the middle.
3. For every template below 35%, check retry-versus-skip after failure to decide
   whether it is *hard* or *unfair*.
4. For every template above 90%, check `template_role` — relief is fine, spike is
   not.
5. Rank by `shot_chain_percent` ascending. The bottom of that list is where the
   game is boring, whatever its completion rate says.
6. Check limited levels' `shots_remaining` distribution against §5.
7. Check `power_purchase_failed` with `failure_reason = "insufficient_coins"`. A
   high rate means the economy, not the levels, is the constraint.

Change **one lever at a time** and bump `LevelTemplate.GENERATOR_VERSION` when
you do, so the before-and-after populations stay separable.
