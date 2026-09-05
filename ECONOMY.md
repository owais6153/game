# Economy

**Accurate as of versionName 1.0.17 / versionCode 19.** Every number below was
read from the shipping source, not from an earlier plan. Where this document
previously disagreed with the code, the code was right and the document has been
corrected — see *Corrections* at the end for what changed and why, so an earlier
revision of this file is not mistaken for a spec the code has drifted from.

## Sources — how coins are earned

Coins come only from confirmed target results, daily missions, and the
exactly-once rewarded Double Coins callback. **Ordinary merges award nothing.**
Only a merge whose result tier equals the *active* target card pays out.

Target rewards, from `GameConfig.TARGET_COIN_REWARD_BY_RESULT_LEVEL`:

| Result tier | L2 | L3 | L4 | L5 | L6 | L7 | L8 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Coins | 2 | 6 | 14 | 30 | 55 | 120 | 260 |

The confirmed chain multiplier applies on top.

Because a level's targets are set by its template, income per level varies by
composition rather than by level number alone. Measured across levels 1-100 with
`scripts/dev/print_level_template_audit.gd`:

| Levels | 1-20 | 21-40 | 41-60 | 61-80 | 81-100 |
| --- | --- | --- | --- | --- | --- |
| Average coins per level (1.0.17) | 310 | 412 | 470 | 480 | 452 |
| Average coins per level (1.0.16) | 425 | 493 | 518 | 493 | 493 |

**Per-level income is 12.3% lower than 1.0.16, and this is not a nerf.** Levels
also demand 12.6% less material, because many templates use shorter target
ladders than the old universal `L6x3 -> L7x2 -> L8x1`. Normalised against the
work a level actually asks for, the earn rate is unchanged:

| | Per level | Coins per material unit |
| --- | --- | --- |
| 1.0.16 | 484 coins / 257 units | 1.884 |
| 1.0.17 | 425 coins / 225 units | 1.890 (+0.3%) |

So coins per *minute* of play is flat and the sink prices below stay correctly
calibrated; only coins per *level* moved, because levels are shorter. A player
reaches the same balance after slightly more, slightly quicker levels.

Two consequences worth holding in mind before changing anything here:

- **Do not "fix" the per-level figure by raising target quantities.** That would
  raise the earn rate above 1.0.16 and inflate the economy.
- Income no longer rises strictly monotonically by bucket (81-100 sits just
  under 61-80) because which levels land as limited shifts with the cadence
  pattern. The trend across the run is what matters and is strongly upward;
  `run_coin_economy_v1_tests` asserts that trend over a window, not per bucket.

Re-measure both tables with `scripts/dev/print_level_template_audit.gd` after any
template or target-structure edit.

### Daily missions

Three missions per day, one from each difficulty tier:

- Easy: `45`-`55` coins (Merge 15 Gems, Merge 25 Gems, Complete 3 Targets)
- Medium: `85`-`95` coins (Complete 3 Levels, Earn 500 Coins, Make 8 Combos, Use 3 Powers)
- Challenging: `130`-`150` coins (Create 1 High-Tier Gem, Finish Without Powers,
  Beat a Limited-Shots Level — the last only once the player has reached the
  first limited level)

### Daily chest

`DailyMissionService.CHEST_REWARD` is **`0` coins**. The chest pays in powers
only: `{switch: 2, magnet: 1, hammer: 1}`. It is not a coin source.

### Milestone chest (added 2026-09-05)

One chest per twenty levels, on the level-select path, unlocked by clearing
levels 20, 40, 60 and so on. `LevelMilestone.COIN_REWARD` is **`800` coins**,
paid alongside the same power grant the daily chest gives.

It pays coins where the daily chest does not, because the two answer different
questions. The daily chest recurs once a day against a coin flow that already
arrives from every level, so adding coins there would only inflate it. A
milestone is earned once per twenty levels and has to land as an event.

`800` is chosen against two figures the player already knows: roughly two
levels' income at the measured 310-480 coins per level, and exactly the price of
one Skip Level. Sizing it that way keeps the reward legible without introducing
a new number to the economy.

**Effect on the earn rate:** 800 coins per 20 levels is 40 coins per level, or
about +9% on the 425-coin average - a bonus that is felt at the moment it lands
but does not move the sink calibration. Raising it much past this starts to make
Skip Level (800) and Continue (500) cheap enough to blunt the failure loop.

### Rewarded ads

Rewarded video substitutes for a coin cost rather than paying coins, except for
Double Coins on level completion. Every grant runs from the earned-reward
callback only, so a cancelled or failed video grants nothing. Power grants are
capped per day by `PowerInventoryService`: `MAX_AD_GRANTS_PER_POWER_PER_DAY = 3`
and `MAX_AD_GRANTS_PER_DAY = 6`.

## Sinks — how coins are spent

| Sink | Cost | Constant |
| --- | --- | --- |
| Extra Shots (+5) | `300` | `GameConfig.EXTRA_SHOTS_COST` |
| Continue after failure | `500` | `GameConfig.CONTINUE_COST` |
| Skip Level | `800` | `GameConfig.SKIP_LEVEL_COST` |
| Power: Switch | `120` | `PowerInventoryService.PURCHASE_COST` |
| Power: Magnet | `200` | `PowerInventoryService.PURCHASE_COST` |
| Power: Hammer | `260` | `PowerInventoryService.PURCHASE_COST` |
| Power: Bomb | `350` | `PowerInventoryService.PURCHASE_COST` |

Continue is capped at `MAX_COIN_CONTINUES_PER_ATTEMPT = 1` per attempt.

### The power shop

There **is** a shop: `PowerShopOverlayLayer`, opened from Home. It sells the four
powers above, one at a time, at the fixed prices listed. A power the player
cannot afford is never presented as a dead button — the row swaps its coin price
for a `+` and the tap routes to the rewarded-ad offer instead. There is still no
IAP, no coin pack, and no purchasable bundle.

## The authoritative balance

This is the part most likely to be got wrong, and it caused a production bug in
1.0.16.

There are two coin variables in `GameController`:

- **`level_start_coins` — the banked balance. This is the authority.** Every
  sink spends it, and every affordability check must read it, through
  `GameController.spendable_coins()`.
- `coins` — a *display* value. It is the banked balance plus the current
  attempt's unresolved target earnings, and `restart()` rolls it back to
  `level_start_coins`.

Coins earned mid-attempt are provisional until the level resolves. Coins granted
by a daily reward are banked immediately, and must be credited through
`_credit_banked_coins()` so both variables move together — crediting `coins`
alone is precisely the defect that made the shop display a balance it would not
spend.

**Rule: never read `coins` to decide whether the player can afford something.**
Read `spendable_coins()`.

Transaction contract for every sink: persist first, adopt the result only on a
successful save, and hold a request lock across the transaction so a double tap
cannot spend twice. A failed save cancels the spend and leaves balance,
inventory, and level unchanged.

## Switch inventory behaviour

Switching the queued gem is a **power spent from inventory**, not a coin
purchase. The player buys Switch powers in the shop (or earns them from the
chest or a rewarded video) and spends one to reroll the current launcher gem.

The reroll itself is deterministic from the level seed, the queue index, and the
reroll count, sampled from the level's existing weighted launcher sequence after
excluding the displayed tier. It cannot produce L5-L8 or any tier the level does
not use, and it does not alter later queue entries, targets, physics, or merge
rules.

## Analytics

Economy events are `coin_earned` and `coin_spent`, each carrying `amount`,
`balance_before`, `balance_after`, and a stable categorical `coin_source` or
`coin_sink`. Dedicated events (`power_purchase_success`, `level_skip`,
`continue_used`, `extra_shots_used`, `daily_mission_claim`) describe the action;
the coin event describes the money. Do not sum both for the same transaction.
See `ANALYTICS_EVENT_CATALOG.md` and `reports/DIFFICULTY_ANALYTICS_GUIDE.md`.

## Corrections made in 1.0.17

The previous revision of this file had drifted from the code in ways that would
mislead anyone planning a balance change. Recorded rather than deleted:

- **Target rewards** were documented as `10, 25, 60, 150, 350, 800, 1800`. The
  shipping table is `2, 6, 14, 30, 55, 120, 260` — roughly seven times smaller.
  Any plan sized against the old figures was wrong by that factor.
- **"Current Gem reroll — cost `GameConfig.NEXT_GEM_REROLL_COST` (100 coins)"**
  described a coin sink that no shipped path ever charged. `NEXT_GEM_REROLL_COST`
  was read by nothing and has been removed; the constant's removal note lives at
  the top of `GameConfig`. Switching is a power, as described above.
- **Skip Level** was documented as `200` coins in one section and `800` in
  another. It is `800`.
- **"No shop … is part of V1"** was false. The power shop ships.
- **"V1 now ships two coin sinks"** was false. There are seven, listed above.
- **Daily chest** was described as a `180`-coin reward. `CHEST_REWARD` is `0`;
  the chest pays powers only.
- Analytics event names were pre-rename (`level_skipped`).
