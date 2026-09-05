# Analytics Event Catalog

**Schema version: 1.0.17 (generator_version 2).**

Production events use fixed Firebase-compatible names and flat primitive
parameters. `Analytics` is observational: delivery failure never changes
gameplay, currency, ads, or navigation. The established `merge` event is the
project's canonical gem-merge event; `rewarded_ad_completed` is the canonical
earned-reward event. Duplicate aliases are intentionally not emitted.

For *how to read this data* — which metric means "too hard", which means
"boring" — see `reports/DIFFICULTY_ANALYTICS_GUIDE.md`. This file is the schema.

## Three rules that govern every event here

1. **An event fires only after the action it names has actually succeeded.** A
   purchase reports success after the save commits, not when the button is
   tapped. A rewarded ad reports completion from the SDK earned-reward callback
   only. A mission reports a claim after the claim persists.
2. **One attempt produces exactly one outcome event.** `level_complete`,
   `level_fail`, and `level_abandon` share the `analytics_level_finished` latch,
   so a player who fails and then backs out to Home is counted once, not twice.
3. **GA4 accepts at most 25 parameters per event and silently drops the rest.**
   `AnalyticsService.MAX_EVENT_PARAMETERS` warns on overflow and
   `run_shop_input_analytics_v1_tests` asserts the budget for the widest events.
   Adding a parameter to a level event means removing one.

## Level context

Every level-lifecycle event carries this compact core, so any of them can be
sliced by composition without a join:

`level_number`, `attempt_number`, `level_type`, `level_template_id`,
`layout_id`, `difficulty_band`, `queue_band`, `target_structure`,
`generator_version`

`level_start` additionally carries the full composition, sent once per attempt:
`shot_limit`, `template_role`, `progression_band`, `level_seed`,
`starting_board_gem_count`, `coin_balance`, `active_pattern_family`,
`active_pattern_variant`, `pattern`, and `target_1..3_tier` / `target_1..3_amount`.

Join outcome events back to `level_start` on `level_number` +
`level_template_id`.

Two band fields, answering different questions. `difficulty_band` is how hard
*this composition* is; `progression_band` is how far up the curve the level
sits. A relief level deep in the game has a low `difficulty_band` and a high
`progression_band`, and that gap is deliberate.

## Attempt aggregates

`level_complete`, `level_fail`, and `level_abandon` each carry a per-attempt
aggregate block. This is why there is no per-shot or per-chain event: a merge
game fires far too many small events to send each one, and the quantities that
matter are ratios over an attempt.

`shots_used`, `shots_remaining`, `total_merges`, `total_chains`,
`max_chain_depth`, `combo_1_count`, `combo_2_count`, `combo_3_plus_count`,
`shot_merge_percent`, `shot_chain_percent`, `targets_completed`,
`powers_used_count`, `most_used_power`, `attempt_duration`

`shots_remaining` is `-1` on an unlimited level, so it is distinguishable from a
limited level that ran exactly out. `max_chain_depth` is the single "max combo"
measurement — there is deliberately no second field for it.

`coins_earned`, `continues_used`, and `extra_shots_used` are tracked on
`LevelAttemptAnalytics` but **not** in this block: each already has a dedicated
event, and repeating them here would double-count in any summed report.

## Level lifecycle

| Event | Authoritative trigger | Duplicate protection |
| --- | --- | --- |
| `level_start` | START GAME or a playable retry after reset | Per-attempt `analytics_level_started` guard |
| `level_complete` | Final target qualifies victory | Shared per-attempt end latch |
| `level_fail` | Danger-line or out-of-shots failure transition; carries `fail_reason` | Shared per-attempt end latch |
| `level_abandon` | Player leaves a live, unresolved attempt; carries `abandon_point`, `abandon_destination` | Shared per-attempt end latch; suppressed if won/failed |
| `level_retry` | Accepted Retry/Restart action | UI action lock plus synchronous reset |
| `level_skip` | Persisted skip transaction; carries `skip_reason`, `coin_cost` | Request lock plus save-before-commit |
| `limited_shots_level_start` | A limited level begins | Emitted with `level_start` |

`abandon_point` is a stable categorical, not a raw shot count:
`before_first_shot`, `before_first_target`, `mid_targets`, `on_final_target`.

`level_skip` carries the compact context but **not** the aggregate block: Skip
is offered on the failure screen, so a skip can legitimately follow a
`level_fail` for the same attempt.

## Gameplay

| Event | Authoritative trigger | Notes |
| --- | --- | --- |
| `merge` | Controller accepts a unique confirmed merge result ID | Guarded by `processed_merge_result_ids`; carries `chain_depth` |
| `target_progress` | Confirmed result advances a multi-quantity target without completing it | Only emitted for cards needing more than one gem |
| `target_complete` | Confirmed result completes the active target | Confirmed result-ID and target-state authority |
| `final_target_complete` | The last card of the level completes | Makes "reached the final card but did not finish" measurable |
| `power_used` | After the spend is persisted and the power consumed | `power_type`, `power_inventory_before`/`after` |

**Target counting semantics, which the templates are built around:** a merge
counts toward a target only if its result tier equals the *active* card at the
moment it resolves. A gem merged above the active tier is not banked for a later
card. Target sequences are therefore always ascending — `LevelTemplate.validate()`
enforces it.

## Powers and shop

`power_shop_open`, `power_shop_close`, `power_purchase_attempt`,
`power_purchase_success`, `power_purchase_failed`, `power_granted`,
`power_tutorial_shown`, `power_tutorial_completed`, `power_ad_declined`

`power_purchase_attempt` fires on every Buy tap, so the denominator of the
purchase funnel is everyone who reached for it. `power_purchase_failed` carries
`failure_reason` (`insufficient_coins`, `save_failed`, `unknown_power`,
`rejected`). Success fires only after the save commits. Parameters:
`power_type`, `power_price`, `coin_balance_before`, `coin_balance_after`,
`power_inventory_after`.

## Daily missions

`daily_missions_open`, `daily_mission_generated`, `daily_mission_progress`,
`daily_mission_earned`, `daily_mission_complete`, `daily_mission_claim`,
`daily_all_missions_complete`, `daily_chest_claim`

`daily_mission_claim` fires after the claim persists, never on the tap.
Completion and claiming are separate events on purpose: the gap between them is
the interesting number.

## Level select and milestone chests

`level_selected`, `milestone_chest_unlocked`, `milestone_chest_claim`,
`milestone_chest_claim_failed`

`level_selected` fires when a level is picked off the map. Parameters:
`level_number`, `highest_level`, `is_replay`. `is_replay` is the one that
matters - it separates forward progress from a player going back to re-play
something, which every per-level completion and difficulty metric otherwise
mixes together.

`milestone_chest_unlocked` fires on the win that clears a multiple of 20, and
`milestone_chest_claim` when the chest is actually opened on the map. As with
the daily chest these are deliberately separate: the gap between them is how
many players earned a reward and never went back for it.
`milestone_chest_claim` carries `chest_index`, `level_number`, `amount`,
`powers` and `resulting_balance`, and is paired with a `coin_earned` carrying
`coin_source` `milestone_chest`. `milestone_chest_claim_failed` carries a
`failure_reason` of `not_unlocked`, `save_failed`, or `power_save_failed`.

Like every other grant here, the claim event fires only after both saves commit.

## Recovery funnels

`skip_level_attempt`, `skip_level_success`, `skip_level_failed`,
`continue_offer_shown`, `continue_accept`, `continue_used`,
`extra_shots_offer_shown`, `extra_shots_accept`, `extra_shots_used`,
`extra_shots_decline`, `out_of_shots`, `coin_action_granted`,
`coin_action_ad_declined`

`*_accept` is the tap; `*_used` is the committed transaction. A tap that could
not be paid for produces an accept without a use, which is the measurement that
matters.

## Economy

`coin_earned`, `coin_spent` — each carrying `amount`, `balance_before`,
`balance_after`, and a stable categorical `coin_source` / `coin_sink`.

Sources: `target_reward`, `daily_mission`, `rewarded_ad`.
Sinks: `power_purchase`, `skip_level`, `extra_shots`, `continue`.

The legacy `reason` parameter is retained alongside `coin_source`/`coin_sink`
because existing saved reports group on it. Do not sum both a dedicated action
event and its coin event for the same transaction.

## Ads

| Event | Authoritative trigger |
| --- | --- |
| `rewarded_ad_requested` | Player accepts a rewarded offer |
| `rewarded_ad_shown` | SDK `on_ad_showed_full_screen_content` — never before |
| `rewarded_ad_completed` | SDK earned-reward callback only |
| `rewarded_ad_failed` | Unavailable manager/inventory, SDK show failure, or callback timeout |
| `interstitial_requested` | Approved post-completion cadence |
| `interstitial_shown` | SDK `on_ad_showed_full_screen_content` — never before |
| `interstitial_failed` | Unavailable manager/inventory, SDK show failure, or timeout |

Load retries are deliberately not events: a 15-second retry loop would create
noisy, high-frequency telemetry. Native diagnostics remain in Godot output and
logcat. Firebase DebugView receipt requires a connected authorized Android
device in debug mode.

## Requested events deliberately not emitted

Five events from the 1.0.17 brief are intentionally absent. Recorded here so
their absence reads as a decision rather than an oversight.

| Event | Why not, and where the data lives instead |
| --- | --- |
| `shots_fired` | One event per shot would be by far the highest-volume event in the game — tens per attempt, per player. `shots_used` on every attempt-ending event carries the same information at 1/40th the volume. |
| `shot_result` | Same volume problem. The useful form is a rate, not a stream: `shot_merge_percent` and `shot_chain_percent`. |
| `chain_reaction` | Chains are frequent and bursty; a per-chain event would spike hardest exactly when the game is working well. `total_chains` and `max_chain_depth` per attempt answer the same questions. |
| `combo_reached` | Covered by `combo_1_count`, `combo_2_count`, `combo_3_plus_count` per attempt, which is the requested breakdown without the per-occurrence cost. |
| `continue_decline` | **No trigger exists.** Unlike the out-of-shots rescue, which has an explicit GIVE UP button (`extra_shots_decline`), the continue offer has no decline action — the player simply takes another action on the fail screen. Emitting one would mean inventing a UI semantic that does not exist. Declined continues are derivable as `continue_offer_shown` minus `continue_accept`. |

The first four follow the brief's own instruction not to emit thousands of
redundant events where an attempt-level summary will do. If per-shot telemetry
is ever genuinely needed, sample it — do not send it for every shot.

## Renames in 1.0.17

Renamed to a single consistent vocabulary. Each kept its previous parameters, so
existing saved reports resolve after the name is updated. Historical rows under
the old names are not rewritten — reports spanning the 1.0.16/1.0.17 boundary
must union both.

| Old | New |
| --- | --- |
| `retry` | `level_retry` |
| `level_skipped` | `level_skip` |
| `shop_opened` | `power_shop_open` |
| `continue_purchased` | `continue_used` |
| `continue_offered` | `continue_offer_shown` |
| `extra_shots_purchased` | `extra_shots_used` |
| `extra_shots_offered` | `extra_shots_offer_shown` |
| `extra_shots_declined` | `extra_shots_decline` |
| `daily_mission_completed` | `daily_mission_complete` |
| `daily_mission_reward_claimed` | `daily_mission_claim` |
| `daily_all_missions_completed` | `daily_all_missions_complete` |
| `daily_chest_claimed` | `daily_chest_claim` |

`power_used` renamed its `power` parameter to `power_type` for consistency with
the shop events.
