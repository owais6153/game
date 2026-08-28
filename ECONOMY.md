# V1 Economy

Coins are earned only from confirmed target results and the exactly-once rewarded Double Coins callback. Ordinary merges award no coins. The authoritative target rewards remain L2-L8: `10, 25, 60, 150, 350, 800, 1800`, with the existing confirmed chain multiplier.

## Current Gem reroll

- Cost: `GameConfig.NEXT_GEM_REROLL_COST` (`100` coins for the production candidate).
- Scope: replaces the tier of the currently aimable launcher gem in place (its physical/visual identity, not the queued Next preview). It does not modify later deterministic queue entries, target generation, physics rules, or merge rules. `GemSpriteLayer` re-syncs texture, collision radius, and shadow from the piece's model automatically.
- Eligibility: active gameplay, the current gem is still aimable (not yet launched or mid-resolution), no terminal state, sufficient banked coins, and at least one different tier in the current level's existing weighted launcher sequence.
- Selection: deterministic from the level seed, queue index, and reroll count, sampled from the existing weighted launcher sequence after excluding the displayed tier. It cannot create L5-L8 or any unavailable tier.
- Transaction safety: the banked balance is saved before the in-memory gem/balance commit. A save failure cancels the reroll. A 350 ms request lock prevents rapid duplicate spending.
- Retry safety: unresolved target earnings keep the existing rollback contract. Rerolls spend banked coins and reduce the attempt baseline by the same amount, so Retry cannot refund the cost and force-close cannot duplicate unresolved rewards.
- Analytics: one `coin_spent` event with amount, reason, level, resulting balance, and resulting local tier.
- UI: live gameplay shows one large circular `SWITCH GEM` button below the table. Its cost appears as a transient popup at spending time, styled after the gameplay combo labels.

## Skip Level

- Cost: `GameConfig.SKIP_LEVEL_COST` (`200` coins).
- Scope: jumps straight to the next level. There is no win screen, no reward-processing state, no interstitial, and no level-complete coin reward — it is purely a paid escape hatch, not an alternate way to earn coins. The active launcher sequence, physics, merge rules, and target rules for the *next* level are generated exactly as they would be by a normal completion.
- Eligibility: Level Ready or active gameplay (including Pause and the Failed result), never a completed/win-qualified level, no in-flight skip request, and at least 200 banked coins from the level-start baseline.
- Selection: the next level and its seed use the same deterministic `LevelConfig.seed_for_level()` sequence a normal completion would produce.
- Transaction safety: the banked balance and the advanced `level_number`/seed are persisted in one atomic save before any in-memory state changes. A failed save cancels the skip and leaves balance and level unchanged, matching the reroll sink's contract. A request lock prevents double-spend from a rapid double-tap.
- Analytics: one `coin_spent` event (`reason: "skip_level"`) plus a distinct `level_skipped` event, so skip usage never shows up in `level_complete`/`level_failed` funnels.
- UI: Skip is absent from the live board and successful Level Complete. It appears only in Level Ready, Pause, and Failed overlays with its explicit 200-coin price and the curated @icons fast-forward glyph.

No shop, IAP, coin pack, or booster catalog is part of V1. V1 now ships two coin sinks: Next Gem Reroll and Skip Level.
