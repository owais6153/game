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
		"spawnable_tiers": [1, 2, 3, 4],
		"spawn_weights": {1: 4, 2: 3, 3: 2, 4: 1},
		# A controlled mixed bag retains learnable difficulty while preventing the
		# former repeated same-line L1/L1 pattern from auto-solving the targets.
		"launcher_sequence": [1, 2, 1, 3, 2, 1, 4, 2, 3, 1],
		# Unlimited launches are still bounded by the existing danger-line fail.
		# The first objective teaches the target loop early. L7 and L8 then retain
		# the longer placement challenge without changing the unlimited launcher.
		"target_sequence": [{"tier": 5, "quantity": 1}, {"tier": 7, "quantity": 1}, {"tier": 8, "quantity": 1}],
		"starting_board": [],
	}

static func initial_launcher_level(config: Dictionary) -> int:
	return int((config.get("launcher_sequence", [1]) as Array)[0])

static func launcher_level_at(config: Dictionary, sequence_index: int) -> int:
	var sequence: Array = config.get("launcher_sequence", [1])
	return int(sequence[posmod(sequence_index, sequence.size())])
