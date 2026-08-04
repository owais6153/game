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

## Generates one deterministic infinite-play level. Simulation continues to use
## local ranks L1-L8; `gem_identity_by_tier` selects which eight of the full
## catalog those ranks display for this level.
static func generated(level_number: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var identities: Array[int] = []
	for identity in range(1, 19):
		identities.append(identity)
	_fisher_yates(identities, rng)
	var selected: Array[int] = []
	for index in range(8):
		selected.append(identities[index])
	_fisher_yates(selected, rng)
	var mapping := {}
	for index in range(8):
		mapping[index + 1] = selected[index]
	var target_candidates: Array[int] = [5, 6, 7, 8]
	_fisher_yates(target_candidates, rng)
	# Preserve the already-verified introductory target pacing while every later
	# level receives a seeded subset. Gem identities at these local ranks are
	# still randomized even on Level 1.
	var target_ranks: Array[int] = []
	if level_number == 1:
		target_ranks.assign([5, 7, 8])
	else:
		for index in range(3):
			target_ranks.append(target_candidates[index])
	target_ranks.sort()
	var targets: Array[Dictionary] = []
	for rank in target_ranks:
		targets.append({"tier": rank, "quantity": 1})
	var launcher_sequence: Array[int] = [1, 2, 3, 4]
	for _cycle in range(2):
		var cycle: Array[int] = [1, 1, 1, 1, 2, 2, 2, 3, 3, 4]
		_fisher_yates(cycle, rng)
		launcher_sequence.append_array(cycle)
	return {
		"id": "level_%d" % level_number,
		"name": "Level %d" % level_number,
		"level_number": level_number,
		"seed": seed_value,
		"active_tier_min": 1,
		"active_tier_max": 8,
		"spawnable_tiers": [1, 2, 3, 4],
		"launcher_sequence": launcher_sequence,
		"target_sequence": targets,
		"gem_identity_by_tier": mapping,
		"background_index": rng.randi_range(0, 4),
		"starting_board": [],
	}

static func seed_for_level(level_number: int) -> int:
	# Stable across platforms and retries, while producing a new layout forever.
	return int((level_number * 1103515245 + 12345) & 0x7fffffff)

static func _fisher_yates(values: Array[int], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary

static func initial_launcher_level(config: Dictionary) -> int:
	return int((config.get("launcher_sequence", [1]) as Array)[0])

static func launcher_level_at(config: Dictionary, sequence_index: int) -> int:
	var sequence: Array = config.get("launcher_sequence", [1])
	return int(sequence[posmod(sequence_index, sequence.size())])
