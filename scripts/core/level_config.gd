class_name LevelConfig
extends RefCounted

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const PATTERN_BLOCK_SEED := 2026082417
const PATTERN_FAMILIES := ["same_shape", "same_color"]
const PATTERN_SHAPES := ["circle", "rounded_square"]
## These families each have at least three Common pieces plus a same-family
## Unique anchor, so "most" remains truthful without duplicating identities.
const PATTERN_COLORS := ["blue", "pink", "orange", "purple"]

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
		"target_sequence": [{"tier": 6, "quantity": 1}, {"tier": 7, "quantity": 1}, {"tier": 8, "quantity": 1}],
		"starting_board": [],
	}

## Generates one deterministic infinite-play level. Simulation continues to use
## local ranks L1-L8; `gem_identity_by_tier` selects which eight of the full
## catalog those ranks display for this level.
static func generated(level_number: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pattern := pattern_for_level(level_number)
	var common_identities: Array[int] = []
	var support_unique: Array[int] = []
	var target_identities: Array[int] = []
	if String(pattern.family) == "same_shape":
		var dominant_shape := String(pattern.dominant)
		var opposite_shape := "rounded_square" if dominant_shape == "circle" else "circle"
		common_identities = _take_random(AssetCatalogType.get_common_gems(dominant_shape), 4, rng)
		support_unique = _take_random(AssetCatalogType.get_unique_gems(dominant_shape), 1, rng)
		target_identities = _take_random(AssetCatalogType.get_unique_gems(opposite_shape), 3, rng)
	else:
		var dominant_color := String(pattern.dominant)
		common_identities = _take_random(AssetCatalogType.get_common_gems("", dominant_color), 3, rng)
		var common_fillers := AssetCatalogType.get_common_gems()
		_remove_all(common_fillers, common_identities)
		common_identities.append_array(_take_random(common_fillers, 1, rng))
		support_unique = _take_random(AssetCatalogType.get_unique_gems("", dominant_color), 1, rng)
		target_identities = _take_random(AssetCatalogType.get_unique_gems("", "", dominant_color), 3, rng)
	# Registry constraints guarantee these counts. Keep a deterministic fallback
	# so a future metadata edit can never produce a null or impossible target.
	if common_identities.size() < 4:
		var common_fallback := AssetCatalogType.get_common_gems()
		_remove_all(common_fallback, common_identities)
		common_identities.append_array(_take_random(common_fallback, 4 - common_identities.size(), rng))
	if support_unique.is_empty():
		var support_fallback := AssetCatalogType.get_unique_gems()
		_remove_all(support_fallback, target_identities)
		support_unique = _take_random(support_fallback, 1, rng)
	if target_identities.size() < 3:
		var target_fallback := AssetCatalogType.get_unique_gems()
		_remove_all(target_fallback, support_unique)
		_remove_all(target_fallback, target_identities)
		target_identities.append_array(_take_random(target_fallback, 3 - target_identities.size(), rng))
	_fisher_yates(common_identities, rng)
	_fisher_yates(target_identities, rng)
	var mapping := {}
	for index in range(4):
		mapping[index + 1] = common_identities[index]
	mapping[5] = support_unique[0]
	for index in range(3):
		mapping[index + 6] = target_identities[index]
	var targets: Array[Dictionary] = []
	for rank in [6, 7, 8]:
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
		"pattern_family": String(pattern.family),
		"pattern_dominant": String(pattern.dominant),
		"pattern_block_index": int(pattern.block_index),
		"pattern_block_start": int(pattern.block_start),
		"pattern_block_size": int(pattern.block_size),
		"background_index": rng.randi_range(0, AssetCatalogType.BACKGROUND_COUNT - 1),
		"table_index": rng.randi_range(0, AssetCatalogType.TABLE_COUNT - 1),
		"starting_board": [],
	}

## Pure, seeded block lookup: retries and save reloads reconstruct the same
## 3-4-level family without mutable global history, while adjacent blocks never
## repeat the exact family/dominant configuration.
static func pattern_for_level(level_number: int) -> Dictionary:
	var cursor := 1
	var block_index := 0
	var previous_by_family := {"same_shape": "", "same_color": ""}
	while true:
		var block_rng := RandomNumberGenerator.new()
		block_rng.seed = PATTERN_BLOCK_SEED + block_index * 7919
		var block_size := 3 + block_rng.randi_range(0, 1)
		var family := String(PATTERN_FAMILIES[block_index % PATTERN_FAMILIES.size()])
		var options: Array = PATTERN_SHAPES if family == "same_shape" else PATTERN_COLORS
		var candidates: Array[String] = []
		for option in options:
			if String(option) != String(previous_by_family.get(family, "")):
				candidates.append(String(option))
		var dominant := candidates[block_rng.randi_range(0, candidates.size() - 1)]
		previous_by_family[family] = dominant
		if level_number < cursor + block_size:
			return {"family": family, "dominant": dominant, "block_index": block_index, "block_start": cursor, "block_size": block_size}
		cursor += block_size
		block_index += 1
	return {}

static func _take_random(pool: Array[int], count: int, rng: RandomNumberGenerator) -> Array[int]:
	var candidates: Array[int] = pool.duplicate()
	_fisher_yates(candidates, rng)
	var selected: Array[int] = []
	for index in range(mini(count, candidates.size())):
		selected.append(candidates[index])
	return selected

static func _remove_all(pool: Array[int], values: Array[int]) -> void:
	for value in values:
		pool.erase(value)

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
