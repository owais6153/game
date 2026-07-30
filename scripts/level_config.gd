class_name LevelConfig
extends RefCounted

## Small data boundary for the first level. Targets are sequential: one card is
## active, then its collected result advances the queue after animation.
static func level_1() -> Dictionary:
	return {
		"id": "level_1",
		"name": "First Facets",
		"active_tier_min": 1,
		"active_tier_max": 8,
		"spawnable_tiers": [1, 2],
		"spawn_weights": {1: 2, 2: 1},
		# The deterministic 2:1 sequence is intentional for the introductory
		# level: it follows the declared weights without unlucky queue streaks.
		"launcher_sequence": [1, 1, 2],
		# Unlimited launches are still bounded by the existing danger-line fail.
		# This first sequence teaches L3, then asks the player to reach L4.
		"target_sequence": [{"tier": 3, "quantity": 1}, {"tier": 4, "quantity": 1}],
		"starting_board": [],
	}

static func initial_launcher_level(config: Dictionary) -> int:
	return int((config.get("launcher_sequence", [1]) as Array)[0])

static func launcher_level_at(config: Dictionary, sequence_index: int) -> int:
	var sequence: Array = config.get("launcher_sequence", [1])
	return int(sequence[posmod(sequence_index, sequence.size())])
