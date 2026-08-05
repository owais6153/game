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
		"spawn_weights": {1: 2, 2: 2, 3: 3, 4: 3},
		# A controlled mixed bag retains learnable difficulty while preventing the
		# former repeated same-line L1/L1 pattern from auto-solving the targets.
		"launcher_sequence": [4, 4, 3, 3, 2, 2, 1, 1, 3, 2],
		# Unlimited launches are still bounded by the existing danger-line fail.
		# One L5 objective teaches the complete loop without an endurance spike.
		"target_sequence": [{"tier": 5, "quantity": 1}],
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
	var target_ranks: Array[int] = []
	if level_number == 1:
		# One reachable objective teaches launch, merge, target and reward without
		# front-loading a full multi-target endurance run.
		target_ranks.assign([5])
	elif level_number == 2:
		# The second level introduces sequential targets with adjacent ranks.
		target_ranks.assign([5, 6])
	else:
		# Mature levels normally use three upward targets; seeded one-in-four
		# variants use two to create recovery/breather levels without backtracking.
		var target_count := 2 if posmod(level_number, 4) == 0 else 3
		for index in range(target_count):
			target_ranks.append(target_candidates[index])
	target_ranks.sort()
	var targets: Array[Dictionary] = []
	for rank in target_ranks:
		targets.append({"tier": rank, "quantity": 1})
	var launcher_sequence: Array[int] = []
	var cycle_template: Array[int]
	var difficulty_band: String
	if level_number == 1:
		difficulty_band = "INTRO"
		cycle_template = [4, 4, 3, 3, 2, 2, 1, 1, 3, 2]
	elif level_number == 2:
		difficulty_band = "EASY"
		cycle_template = [4, 3, 3, 2, 2, 2, 1, 1, 1, 4]
	elif level_number <= 5:
		difficulty_band = "NORMAL"
		cycle_template = [1, 1, 1, 2, 2, 2, 3, 3, 4, 4]
	elif level_number <= 12:
		difficulty_band = "CHALLENGE"
		cycle_template = [1, 1, 1, 1, 2, 2, 2, 3, 3, 4]
	else:
		difficulty_band = "EXPERT"
		# Difficulty is capped here. L3/L4 remain in every ten-launch cycle and
		# launches remain unlimited, so every L5-L8 target stays constructible.
		cycle_template = [1, 1, 1, 1, 1, 2, 2, 2, 3, 4]
	for _cycle in range(2):
		var cycle: Array[int] = cycle_template.duplicate()
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
		"difficulty_band": difficulty_band,
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
