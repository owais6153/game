extends SceneTree

## Prints coin flow as data so the economy can be balanced against measured
## numbers rather than intuition. Developer aid only.

const L = preload("res://scripts/core/level_config.gd")
const P = preload("res://scripts/services/power_inventory_service.gd")
const D = preload("res://scripts/services/daily_mission_service.gd")

func _init() -> void:
	print("=== SINKS ===")
	for power in P.ALL:
		print("  buy %-7s %5d" % [power, P.purchase_cost(power)])
	print("  extra shots %5d" % GameConfig.EXTRA_SHOTS_COST)
	print("  continue    %5d" % GameConfig.CONTINUE_COST)
	print("  skip level  %5d" % GameConfig.SKIP_LEVEL_COST)

	print("\n=== EARN PER LEVEL (target rewards only) ===")
	for n in [1, 4, 10, 20, 40]:
		var c := L.generated(n, L.seed_for_level(n))
		var total := 0
		for e in (c.get("target_sequence", []) as Array):
			var t: Dictionary = e as Dictionary
			total += GameConfig.target_coin_reward_for_result_level(int(t.get("tier", 6))) * maxi(1, int(t.get("quantity", 1)))
		print("  level %2d  targets=%d  coins=%d" % [n, (c.get("target_sequence", []) as Array).size(), total])

	print("\n=== DAILY CEILING ===")
	var mission_total := 0
	for e in (D.ensure_current_day({}, "2026-09-04", 99).get("missions", []) as Array):
		mission_total += int((e as Dictionary).get("reward", 0))
	print("  missions/day %d   chest %s" % [mission_total, D.CHEST_POWER_REWARD])
	quit(0)
