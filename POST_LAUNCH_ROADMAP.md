# Post-Launch Roadmap

This roadmap is intentionally outside the production-candidate scope. Items require production evidence before implementation.

## Delivered ahead of schedule

- **Skip Level coin sink** (200 coins, jumps to the next level with no reward). See `ECONOMY.md`.
- **Current Gem reroll** (100 coins) redesigned to reroll the aimable launcher gem itself, not the queued Next preview.

## Attempted and reverted

- A Google Play Games Services v2 integration (sign-in, achievements, daily streak, local reminder notification) was built, device-tested, and then fully removed at the user's request to be revisited later as its own deliberate pass. No trace of it remains in the Android manifest, Gradle dependencies, or GDScript autoloads.

## V1.1

- Analyze production analytics and the level/attempt/merge/target/ad/economy funnels.
- Improve weak retention points only where production data supports a change.
- Consider further coin utilities only if reroll/skip usage and balances justify it.
- Revisit Google Play Games Services (sign-in, achievements, streak) as a dedicated pass.

## V1.2

- Evaluate a limited-shot level variation.
- Add at most the first evidence-backed modifier, such as frozen gems or blockers.
- Improve level variety based on player behavior and completion data.

## Later

- Leaderboards and tournaments.
- Deeper progression and a larger economy.
- Cosmetics and a cosmetics store.
- Mystery, locked, or additional gameplay modifiers.
- Multiplayer or Sidekick-specific experiences.

Explicitly deferred from the launch candidate: timed levels, shot limits, frozen/locked gems, blockers, mystery gems, new level types, streaks, leaderboards, tournaments, events, extra boosters, large shops, cosmetics, major progression redesign, and multiplayer. The Skip Level sink was pulled forward and delivered — see above.
