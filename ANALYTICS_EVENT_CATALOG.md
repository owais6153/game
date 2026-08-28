# Analytics Event Catalog

Production events use fixed Firebase-compatible names and flat primitive parameters. `Analytics` is observational: delivery failure never changes gameplay, currency, ads, or navigation. The established `merge` event is the project's canonical gem-merge event (the semantic equivalent of `gem_merge`); `rewarded_ad_completed` is the canonical earned-reward event. Duplicate aliases are intentionally not emitted.

| Event | Authoritative trigger | Main parameters | Duplicate protection | Purpose |
| --- | --- | --- | --- | --- |
| `level_start` | START GAME or a playable retry after reset | `level_number`, `attempt_number`, `coin_balance`, `pattern` | Per-attempt `analytics_level_started` guard | Attempt funnel and level entry |
| `retry` | Accepted Retry/Restart action | `level_number`, next `attempt_number`, `shots`, `reason` | UI action lock plus synchronous reset | Retry rate and failure recovery |
| `merge` | Controller accepts a unique confirmed merge result ID | level, attempt, shots, mapped gem ID/type, target involvement, chain depth | `processed_merge_result_ids` | Gem progression and merge balance |
| `target_progress` | Confirmed result advances a multi-quantity target without completing it | level, target index/progress/quantity | Confirmed result-ID authority | Partial objective progress; current quantity-1 levels do not emit it |
| `target_complete` | Confirmed result completes the active target | level, attempt, shots, target index and mapped ID/type | Confirmed result-ID and target-state authority | Sequential objective completion |
| `level_complete` | Final target qualifies victory | level, attempt, shots, earned coins, balance | Per-attempt end guard | Win funnel and economy outcome |
| `level_fail` | Danger-line failure transition | level, attempt, shots, balance, `fail_reason` | Per-attempt end guard | Fail funnel and reason analysis |
| `coin_earned` | Confirmed target reward or official rewarded bonus callback | amount, reason, level, resulting balance | Merge-result guard or rewarded-session guard | Economy inflow |
| `coin_spent` | Persisted Next Gem reroll transaction | amount, `reason=next_gem_reroll`, level, resulting balance, result tier | Immediate request lock plus save-before-commit | Economy outflow and sink use |
| `rewarded_ad_requested` | Player accepts Double Coins | placement, level, reward amount, balance | Result action lock | Rewarded demand/fill analysis |
| `rewarded_ad_shown` | SDK `on_ad_showed_full_screen_content` | request context | Per-fullscreen-session shown guard | Real rewarded impressions |
| `rewarded_ad_completed` | SDK earned-reward callback | request context | SDK session ID plus earned guard | Earned rewards only |
| `rewarded_ad_failed` | Unavailable manager/inventory, SDK show failure, or callback timeout | request context, failure reason/code when known | One active fullscreen/request path | Monetization failure diagnosis |
| `interstitial_requested` | Approved post-completion cadence | placement and completed level | Completion-transition guard | Interstitial demand/cadence |
| `interstitial_shown` | SDK `on_ad_showed_full_screen_content` | request context | Per-fullscreen-session shown guard | Real interstitial impressions |
| `interstitial_failed` | Unavailable manager/inventory, SDK show failure, or callback timeout | request context, failure reason/code when known | One completion transition | Fail-open diagnosis |

Load retries are deliberately not analytics events because a 15-second retry loop would create noisy, high-frequency telemetry. Native request/forward/rejection diagnostics remain available in Godot output and Android logcat. Firebase DebugView receipt still requires a connected authorized Android device and Firebase debug mode.
