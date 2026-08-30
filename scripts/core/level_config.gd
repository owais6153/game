class_name LevelConfig
extends RefCounted

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")
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
		"level_type": "normal",
		"shot_limit": 0,
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
	var limited_shots := is_limited_shots_level(level_number)
	var targets: Array[Dictionary] = []
	# Limited-shot rounds are accuracy challenges, not endurance checks. Two
	# single-count lower targets give the player room to recover from imperfect
	# placement instead of asking for the same L8 climb with fewer launches.
	var target_ranks := [6, 7] if limited_shots else [6, 7, 8]
	for rank in target_ranks:
		targets.append({"tier": rank, "quantity": 1 if limited_shots else target_quantity(level_number, rank)})
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
	var config := {
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
		"starting_board": starting_board_for_level(level_number, seed_value, mapping),
		"level_type": "limited_shots" if limited_shots else "normal",
		"shot_limit": 0,
	}
	if limited_shots:
		config["shot_limit"] = shot_limit_for_config(config, level_number)
	return config

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


## Limited-shots schedule. The first one lands immediately after the three
## unlimited introduction levels, so the mechanic is taught while the board is
## still simple, then recurs on a widening-then-tightening rhythm so it reads as
## a recurring variant rather than a phase the player passes through.
##
## Levels 1-3 are never limited: they are where the merge loop itself is taught.
const FIRST_LIMITED_SHOTS_LEVEL := 4
const LIMITED_SHOTS_CYCLE := 3

static func is_limited_shots_level(level_number: int) -> bool:
	if level_number < FIRST_LIMITED_SHOTS_LEVEL:
		return false
	return (level_number - FIRST_LIMITED_SHOTS_LEVEL) % LIMITED_SHOTS_CYCLE == 0


## Shots tighten with level and then hold at a floor. The floor is deliberately
## well above the launcher cycle length: every L6-L8 objective must stay
## constructible from the sequence alone, so powers can be strongly encouraged
## but are never required.


## Seeded opening layout. Levels used to start on an empty table, which is why
## they could be cleared by pushing gems up the same line: with nothing to aim
## around, horizontal position never mattered. A pre-placed cluster forces real
## aiming, and the rows are staggered so the centre lane is never open.
##
## Constraints that keep every level solvable without powers:
## - Only spawnable tiers appear, so every placed gem can still be merged into.
## - The board stops well above the danger line, so it never starts near a loss.
## - Row count grows with level but is capped, so the table never starts crowded
##   enough to deny the launcher a landing spot.
const STARTING_BOARD_FIRST_LEVEL := 2
const STARTING_BOARD_MAX_ROWS := 4
const STARTING_BOARD_COLUMNS := 5
const STARTING_BOARD_ROW_SPACING := 78.0
## Distance above the danger line where the lowest seeded row sits. Generous, so
## an opening board is never itself close to failing the level.
const STARTING_BOARD_DANGER_MARGIN := 250.0
## From here on, opening rows leave a single gap instead of two.
const STARTING_BOARD_DENSE_LEVEL := 2
## Minimum normalised horizontal separation between one row's gap and the next's.
## Below roughly a fifth of the row width the two openings overlap enough to
## leave a gem-width channel straight through the board.
const STARTING_BOARD_GAP_SEPARATION := 0.30

static func starting_board_rows(level_number: int) -> int:
	if level_number < STARTING_BOARD_FIRST_LEVEL:
		return 0
	# Two rows minimum. A single-row board cannot block a straight lane - its gap
	# is open top to bottom by definition - so the very first seeded levels were
	# still one-lineable however the gaps were chosen.
	return mini(STARTING_BOARD_MAX_ROWS, 2 + (level_number - STARTING_BOARD_FIRST_LEVEL) / 3)


## Returns placement records rather than pieces, so the data boundary stays
## free of simulation types. The controller turns these into gems.
static func starting_board_for_level(level_number: int, seed_value: int, mapping: Dictionary) -> Array:
	var rows := starting_board_rows(level_number)
	if rows <= 0:
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = int((seed_value ^ 0x5F3759DF) & 0x7fffffff)
	var board: Array = []
	var previous_gap_positions: Array[float] = []
	for row in range(rows):
		# Alternate rows are offset by half a column, so no straight vertical
		# lane runs the height of the opening board.
		var stagger := 0.5 if row % 2 == 1 else 0.0
		var columns := STARTING_BOARD_COLUMNS - (1 if row % 2 == 1 else 0)
		# One seeded gap per row keeps the layout from reading as a solid wall and
		# guarantees a route through for a player who aims well. Rolled once per
		# row: rolling inside the column loop left some rows sealed and others
		# missing several gems.
		# Early boards leave two gaps per row and later boards only one, so density
		# keeps rising after the row count has capped out. Without this the board
		# stopped changing at all around level 8 and levels blurred together.
		var gaps := 2 if level_number < STARTING_BOARD_DENSE_LEVEL else 1
		# Gaps must not line up between rows. Rolled independently they often did,
		# leaving a column empty in every row - a straight lane the player could
		# shoot up all level without ever aiming, which is exactly the "push gems
		# through one line" complaint. Excluding the previous row's gaps means no
		# column is ever open in two consecutive rows, so no full-height lane can
		# exist on any board with more than one row.
		var gap_columns: Array[int] = []
		# Excluded by normalised position, not by column index. Rows alternate five
		# and four columns, so the same index sits at a different x in adjacent
		# rows - and two different indices can line up almost exactly. Comparing
		# where the gap actually falls across the row is what stops the openings
		# stacking into a lane.
		var available: Array[int] = []
		for column in range(columns):
			var t := float(column) / float(maxi(1, columns - 1))
			var clear := true
			for previous_t in previous_gap_positions:
				if absf(t - float(previous_t)) < STARTING_BOARD_GAP_SEPARATION:
					clear = false
					break
			if clear:
				available.append(column)
		# Guard: with enough gaps per row the exclusion could starve the pool, so
		# fall back to every column rather than emit a sealed row.
		if available.size() < mini(gaps, columns - 1):
			available.clear()
			for column in range(columns):
				available.append(column)
		while gap_columns.size() < mini(gaps, columns - 1) and not available.is_empty():
			var picked := rng.randi_range(0, available.size() - 1)
			gap_columns.append(available[picked])
			available.remove_at(picked)
		previous_gap_positions.clear()
		for column in gap_columns:
			previous_gap_positions.append(float(column) / float(maxi(1, columns - 1)))
		for column in range(columns):
			if gap_columns.has(column):
				continue
			var tier := 1 + rng.randi_range(0, 3)
			if not mapping.is_empty() and not mapping.has(tier):
				tier = 1
			board.append({
				"tier": tier,
				"row": row,
				"column": float(column) + stagger,
				"columns": STARTING_BOARD_COLUMNS,
			})
	return board


## How many of a target tier a level asks for. Board density caps out around
## level 11, so without this the objective stopped changing and later levels
## became indistinguishable from one another.
##
## Only the two lower target tiers ever ask for more than one. The top tier is
## the longest merge chain in the level, so repeating it would multiply the
## hardest work rather than deepen the objective, and the totals stay inside the
## margin the shot floor is sized against.
const TARGET_QUANTITY_CAP := {6: 3, 7: 2, 8: 1}
const TARGET_QUANTITY_STEP := {6: 7, 7: 13, 8: 0}

static func target_quantity(level_number: int, tier: int) -> int:
	var step := int(TARGET_QUANTITY_STEP.get(tier, 0))
	var cap := int(TARGET_QUANTITY_CAP.get(tier, 1))
	if step <= 0:
		return 1
	return clampi(1 + level_number / step, 1, cap)


## Total gems a level asks the player to collect, summed across its three
## target cards. The shot floor is sized against this, and
## run_level_difficulty_v1_tests asserts the two stay in proportion so a
## limited level can never ask for more than its shots can build.
static func total_target_quantity(level_number: int) -> int:
	if is_limited_shots_level(level_number):
		return 2
	var total := 0
	for tier in [6, 7, 8]:
		total += target_quantity(level_number, tier)
	return total


## Shots granted to a limited level, derived from what the level actually needs
## rather than from a fixed ladder.
##
## The previous ladder counted down 40 -> 30 with no reference to the targets,
## and every limited level was unwinnable because of it: a perfect play-out of
## level 4 needs 46 shots against the 40 it granted, and level 25 needed 79
## against 30. LevelSolver.minimum_shots() plays the level out greedily with the
## real merge and bonus-gem rules, so the limit is anchored to a solution that
## demonstrably exists.
##
## The margin above that floor is the room a real player has for imperfect
## placement. It starts generous while the mechanic is new and tightens with
## level, but never falls to zero - a shipped level must never require flawless
## play.
const SHOT_MARGIN_INTRO := 1.70
const SHOT_MARGIN_FLOOR := 1.30
const SHOT_MARGIN_DECAY_LEVELS := 30.0
const LIMITED_SHOTS_MINIMUM := 24

static func shot_margin_for_level(level_number: int) -> float:
	var progress := clampf(float(level_number - FIRST_LIMITED_SHOTS_LEVEL) / SHOT_MARGIN_DECAY_LEVELS, 0.0, 1.0)
	return lerpf(SHOT_MARGIN_INTRO, SHOT_MARGIN_FLOOR, progress)


static func shot_limit_for_config(config: Dictionary, level_number: int) -> int:
	var floor_shots: int = LevelSolverType.minimum_shots(config)
	if floor_shots <= 0:
		# The solver could not find any play-out. Fall back to unlimited rather
		# than shipping a level nobody can finish.
		return 0
	return maxi(LIMITED_SHOTS_MINIMUM,
		int(ceil(float(floor_shots) * shot_margin_for_level(level_number))))


## Retained for callers that only have a level number.
static func shot_limit_for_level(level_number: int) -> int:
	if not is_limited_shots_level(level_number):
		return 0
	return int(generated(level_number, seed_for_level(level_number)).get("shot_limit", 0))
