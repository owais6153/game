# V1 Economy

Coins are earned only from confirmed target results and the exactly-once rewarded Double Coins callback. Ordinary merges award no coins. The authoritative target rewards remain L2-L8: `10, 25, 60, 150, 350, 800, 1800`, with the existing confirmed chain multiplier.

## Next Gem reroll

- Cost: `GameConfig.NEXT_GEM_REROLL_COST` (`100` coins for the production candidate).
- Scope: replaces only the currently displayed queued Next Gem. It does not modify the active launcher, later deterministic queue entries, target generation, physics, or merge rules.
- Eligibility: active gameplay, no terminal state, sufficient banked coins, and at least one different tier in the current level's existing weighted launcher sequence.
- Selection: deterministic from the level seed, queue index, and reroll count, sampled from the existing weighted launcher sequence after excluding the displayed tier. It cannot create L5-L8 or any unavailable tier.
- Transaction safety: the banked balance is saved before the in-memory gem/balance commit. A save failure cancels the reroll. A 350 ms request lock prevents rapid duplicate spending.
- Retry safety: unresolved target earnings keep the existing rollback contract. Rerolls spend banked coins and reduce the attempt baseline by the same amount, so Retry cannot refund the cost and force-close cannot duplicate unresolved rewards.
- Analytics: one `coin_spent` event with amount, reason, level, resulting balance, and resulting local tier.

No shop, IAP, coin pack, booster catalog, or additional sink is part of V1.
