extends SceneTree

## Coverage for the level-template system: selection, determinism, target
## validity, layout safety, difficulty banding, and the limited-shot solvability
## guard.
##
## The generator is a pure function of the level number, so almost everything
## here can be asserted over a wide range of levels rather than on hand-picked
## examples. Where a bug would only show at scale - a template that never gets
## picked, a layout that opens a straight lane on one level in forty - the range
## is what catches it.

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelTemplateType = preload("res://scripts/core/level_template.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")
const GameConfigType = preload("res://scripts/core/game_config.gd")

const LAST_LEVEL := 120

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_every_template_is_structurally_valid()
	_test_selection_is_deterministic()
	_test_generation_is_deterministic()
	_test_no_immediate_template_repeats()
	_test_every_template_is_reachable()
	_test_targets_are_valid_everywhere()
	_test_layouts_are_safe()
	_test_layouts_never_leave_a_straight_lane()
	_test_limited_levels_stay_solvable()
	_test_limited_cadence_is_regular_but_not_metronomic()
	_test_difficulty_trends_upward_with_relief()
	_test_stable_identifiers_are_present()
	if failures.is_empty():
		print("LEVEL_TEMPLATE_V1_TESTS: PASS")
	else:
		for failure in failures:
			push_error(failure)
		print("LEVEL_TEMPLATE_V1_TESTS: FAIL (%d)" % failures.size())
	quit()


func _test_every_template_is_structurally_valid() -> void:
	for id in LevelTemplateType.TEMPLATES.keys():
		var template: Dictionary = (LevelTemplateType.TEMPLATES[id] as Dictionary).duplicate(true)
		template["id"] = id
		var problems := LevelTemplateType.validate(template)
		_assert(problems.is_empty(), "template %s is invalid: %s" % [id, ", ".join(problems)])


## A retry, a reinstall, and a save reload must all rebuild the same level.
func _test_selection_is_deterministic() -> void:
	for level in range(1, LAST_LEVEL + 1):
		var first := LevelTemplateType.id_for_level(level)
		var second := LevelTemplateType.id_for_level(level)
		_assert(first == second, "template selection for level %d is not stable" % level)
		_assert(LevelTemplateType.TEMPLATES.has(first),
			"level %d selected unknown template %s" % [level, first])


func _test_generation_is_deterministic() -> void:
	for level in [1, 4, 9, 17, 26, 41, 63, 88, 100]:
		var seed_value := LevelConfigType.seed_for_level(level)
		var first := LevelConfigType.generated(level, seed_value)
		var second := LevelConfigType.generated(level, seed_value)
		_assert(JSON.stringify(first.get("starting_board", [])) == JSON.stringify(second.get("starting_board", [])),
			"level %d opening board is not deterministic" % level)
		_assert(JSON.stringify(first.get("target_sequence", [])) == JSON.stringify(second.get("target_sequence", [])),
			"level %d targets are not deterministic" % level)
		_assert(int(first.get("shot_limit", 0)) == int(second.get("shot_limit", 0)),
			"level %d shot limit is not deterministic" % level)


## Back-to-back identical compositions are the repetition this system exists to
## remove, so they are a hard failure rather than a tuning preference.
func _test_no_immediate_template_repeats() -> void:
	for level in range(2, LAST_LEVEL + 1):
		var previous := LevelTemplateType.id_for_level(level - 1)
		var current := LevelTemplateType.id_for_level(level)
		_assert(previous != current,
			"levels %d and %d both use template %s" % [level - 1, level, current])


## A template nothing selects is dead configuration that will drift out of sync
## with the code around it.
func _test_every_template_is_reachable() -> void:
	var seen := {}
	for level in range(1, LAST_LEVEL + 1):
		seen[LevelTemplateType.id_for_level(level)] = true
	for id in LevelTemplateType.TEMPLATES.keys():
		_assert(seen.has(id), "template %s is never selected in levels 1-%d" % [id, LAST_LEVEL])


func _test_targets_are_valid_everywhere() -> void:
	for level in range(1, LAST_LEVEL + 1):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var targets: Array = config.get("target_sequence", []) as Array
		_assert(not targets.is_empty(), "level %d has no targets" % level)
		var previous_tier := 5
		for entry in targets:
			var target: Dictionary = entry as Dictionary
			var tier := int(target.get("tier", 0))
			var quantity := int(target.get("quantity", 0))
			_assert(tier >= 6 and tier <= 8,
				"level %d asks for tier %d, outside the objective range" % [level, tier])
			# Targets are counted against the active card at merge time, so a
			# descending sequence would strand work the player must do anyway.
			_assert(tier > previous_tier,
				"level %d target tiers must ascend (%d after %d)" % [level, tier, previous_tier])
			previous_tier = tier
			_assert(quantity >= 1, "level %d has a non-positive target quantity" % level)
			_assert(not (tier == 8 and quantity > 1),
				"level %d repeats the apex tier" % level)


func _test_layouts_are_safe() -> void:
	for level in range(1, LAST_LEVEL + 1):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var spawnable: Array = config.get("spawnable_tiers", []) as Array
		var board: Array = config.get("starting_board", []) as Array
		var occupied := {}
		for entry in board:
			var record: Dictionary = entry as Dictionary
			var tier := int(record.get("tier", 0))
			# A seeded gem of an unspawnable tier could never be merged into.
			_assert(spawnable.has(tier),
				"level %d seeded tier %d, which can never be merged into" % [level, tier])
			var row := int(record.get("row", -1))
			_assert(row >= 0 and row < LevelConfigType.STARTING_BOARD_MAX_ROWS,
				"level %d seeded row %d outside the safe range" % [level, row])
			var column := float(record.get("column", -1.0))
			_assert(column >= 0.0 and column <= float(LevelConfigType.STARTING_BOARD_COLUMNS),
				"level %d seeded column %f outside the row" % [level, column])
			# Two gems in one slot would overlap on spawn.
			var slot := "%d:%f" % [row, column]
			_assert(not occupied.has(slot),
				"level %d seeded two gems into slot %s" % [level, slot])
			occupied[slot] = true


## The opening board exists to stop a level being cleared by pushing gems up one
## line. A column left open in every row is exactly that lane, so every layout
## archetype has to be checked, not just the default one.
func _test_layouts_never_leave_a_straight_lane() -> void:
	for level in range(1, LAST_LEVEL + 1):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var board: Array = config.get("starting_board", []) as Array
		if board.is_empty():
			continue
		var rows := {}
		for entry in board:
			var record: Dictionary = entry as Dictionary
			var row := int(record.get("row", 0))
			if not rows.has(row):
				rows[row] = []
			(rows[row] as Array).append(float(record.get("column", 0.0)))
		if rows.size() < 2:
			continue
		# A gem is roughly one column wide, so a lane needs an opening of about a
		# full column at the same x in every row.
		var lane_width := 0.9
		var samples := 60
		for sample in range(samples + 1):
			var x := float(sample) / float(samples) * float(LevelConfigType.STARTING_BOARD_COLUMNS - 1)
			var blocked_somewhere := false
			for row in rows.keys():
				var clear_here := true
				for column in (rows[row] as Array):
					if absf(float(column) - x) < lane_width:
						clear_here = false
						break
				if not clear_here:
					blocked_somewhere = true
					break
			_assert(blocked_somewhere,
				"level %d (%s) leaves a straight lane at column %.2f" % [
					level, String(config.get("layout_id", "")), x])


## A limited level must be winnable by someone playing well, with room left over
## for imperfect placement. Powers may be strongly encouraged, never required.
func _test_limited_levels_stay_solvable() -> void:
	var checked := 0
	for level in range(1, LAST_LEVEL + 1):
		if not LevelConfigType.is_limited_shots_level(level):
			continue
		checked += 1
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var limit := int(config.get("shot_limit", 0))
		_assert(limit > 0, "limited level %d has no shot limit" % level)
		var run := LevelSolverType.simulate(config)
		_assert(bool(run.completed),
			"limited level %d cannot be completed even with perfect play" % level)
		_assert(int(run.spare_shots) > 0,
			"limited level %d leaves no spare shots after a perfect play-out" % level)
		_assert(LevelSolverType.classify(config) != "AVOID",
			"limited level %d is classified AVOID" % level)
	_assert(checked > 0, "the range must contain limited levels")


func _test_limited_cadence_is_regular_but_not_metronomic() -> void:
	var limited: Array[int] = []
	for level in range(1, LAST_LEVEL + 1):
		if LevelConfigType.is_limited_shots_level(level):
			limited.append(level)
	_assert(limited.size() >= LAST_LEVEL / 6,
		"limited levels must recur often enough to read as a variant (found %d)" % limited.size())
	var gaps := {}
	for index in range(1, limited.size()):
		var gap := limited[index] - limited[index - 1]
		# Back-to-back limited levels read as a difficulty wall, not a change of
		# pace.
		_assert(gap >= 2,
			"limited levels %d and %d run back to back" % [limited[index - 1], limited[index]])
		gaps[gap] = true
	# The whole point of moving off "every third level": if every gap is the same
	# number the cadence is a metronome the player can count.
	_assert(gaps.size() >= 2,
		"limited-shot cadence is perfectly regular and reads as a metronome")


func _test_difficulty_trends_upward_with_relief() -> void:
	var early := 0.0
	var late := 0.0
	var relief_seen := 0
	for level in range(1, 41):
		early += float(LevelTemplateType.BAND_RANK[LevelTemplateType.for_level(level).band])
	for level in range(61, 101):
		late += float(LevelTemplateType.BAND_RANK[LevelTemplateType.for_level(level).band])
	_assert(late > early,
		"difficulty must trend upward (early %.1f, late %.1f)" % [early, late])
	# But not monotonically: a run of ever-harder levels flattens into "hard" and
	# the spikes stop being felt.
	for level in range(2, LAST_LEVEL + 1):
		var previous := int(LevelTemplateType.BAND_RANK[LevelTemplateType.for_level(level - 1).band])
		var current := int(LevelTemplateType.BAND_RANK[LevelTemplateType.for_level(level).band])
		if current < previous:
			relief_seen += 1
	_assert(relief_seen >= 10,
		"the curve must include real breathing levels (found %d dips)" % relief_seen)


## Analytics compares real-user difficulty per composition, which only works if
## every generated level actually carries its identifiers.
func _test_stable_identifiers_are_present() -> void:
	for level in range(1, LAST_LEVEL + 1):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		for key in ["template_id", "layout_id", "difficulty_band", "queue_band", "target_structure"]:
			_assert(not String(config.get(key, "")).is_empty(),
				"level %d is missing analytics identifier %s" % [level, key])
		_assert(int(config.get("generator_version", 0)) == LevelTemplateType.GENERATOR_VERSION,
			"level %d reports the wrong generator version" % level)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
