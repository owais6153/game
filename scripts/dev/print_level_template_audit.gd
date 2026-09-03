extends SceneTree

## Developer audit: generates every level in a range and prints the composition
## and solver verdict for each. Used to validate the level-template system over
## levels 1-100 and to spot-check the levels named in the balancing brief.
##
## Run: godot --headless --script scripts/dev/print_level_template_audit.gd

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelTemplateType = preload("res://scripts/core/level_template.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")
const GameConfigType = preload("res://scripts/core/game_config.gd")

const LAST_LEVEL := 100
const SPOTLIGHT := [1, 2, 4, 5, 7, 8, 10, 13, 14, 20, 25, 34, 40, 50, 60, 80, 100]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var problems: Array[String] = []
	var template_counts := {}
	var band_counts := {}
	var layout_counts := {}
	var limited_total := 0
	var rows := []

	for level in range(1, LAST_LEVEL + 1):
		var config: Dictionary = LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var template := LevelTemplateType.for_level(level)
		problems.append_array(LevelTemplateType.validate(template))

		var template_id := String(config.get("template_id", ""))
		var band := String(config.get("difficulty_band", ""))
		var layout := String(config.get("layout_id", ""))
		template_counts[template_id] = int(template_counts.get(template_id, 0)) + 1
		band_counts[band] = int(band_counts.get(band, 0)) + 1
		layout_counts[layout] = int(layout_counts.get(layout, 0)) + 1

		var limited := String(config.get("level_type", "")) == "limited_shots"
		if limited:
			limited_total += 1

		var analysis := LevelSolverType.analyse(config)
		var targets_text := _targets_text(config)
		var board: Array = config.get("starting_board", []) as Array

		# Structural guards that apply to every generated level.
		if board.size() > 20:
			problems.append("L%d: opening board of %d gems is beyond the safe cap" % [level, board.size()])
		for entry in board:
			var record: Dictionary = entry as Dictionary
			var tier := int(record.get("tier", 0))
			if tier < 1 or tier > 4:
				problems.append("L%d: opening gem tier %d is not spawnable" % [level, tier])
			var row_index := int(record.get("row", 0))
			if row_index < 0 or row_index >= LevelConfigType.STARTING_BOARD_MAX_ROWS:
				problems.append("L%d: opening row %d out of range" % [level, row_index])
		if (config.get("launcher_sequence", []) as Array).is_empty():
			problems.append("L%d: empty launcher sequence" % level)
		if limited and int(config.get("shot_limit", 0)) <= 0:
			problems.append("L%d: limited level has no shot limit" % level)
		if limited and not bool(analysis.completed):
			problems.append("L%d: limited level is not completable by the solver" % level)
		if limited and String(analysis.classification) == "AVOID":
			problems.append("L%d: limited level leaves too little margin (%s)" % [level, analysis.classification])

		rows.append({
			"level": level,
			"template": template_id,
			"band": band,
			"layout": layout,
			"gems": board.size(),
			"queue": String(config.get("queue_band", "")),
			"targets": targets_text,
			"limited": limited,
			"shot_limit": int(config.get("shot_limit", 0)),
			"solver": String(analysis.classification),
			"shots_used": int(analysis.shots_used),
			"spare": int(analysis.spare_shots),
		})

	print("=== SPOTLIGHT LEVELS ===")
	print("lvl | template          | band        | layout            | gems | queue    | targets              | ltd | limit | solver   | perfect")
	for row in rows:
		if not SPOTLIGHT.has(int((row as Dictionary).level)):
			continue
		_print_row(row as Dictionary)

	print("")
	print("=== FULL RANGE 1-%d ===" % LAST_LEVEL)
	for row in rows:
		_print_row(row as Dictionary)

	print("")
	print("=== DISTRIBUTION ===")
	print("limited-shot levels: %d of %d" % [limited_total, LAST_LEVEL])
	print("templates used: %d of %d" % [template_counts.size(), LevelTemplateType.TEMPLATES.size()])
	_print_counts("template", template_counts)
	_print_counts("band", band_counts)
	_print_counts("layout", layout_counts)

	print("")
	print("=== COIN INCOME (target rewards per level) ===")
	var income_by_band := {}
	var income_total := 0
	for level in range(1, LAST_LEVEL + 1):
		var config: Dictionary = LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var income := 0
		for entry in (config.get("target_sequence", []) as Array):
			var target: Dictionary = entry as Dictionary
			income += GameConfigType.target_coin_reward_for_result_level(int(target.get("tier", 6))) \
				* maxi(1, int(target.get("quantity", 1)))
		income_total += income
		var bucket := "%02d-%02d" % [((level - 1) / 20) * 20 + 1, ((level - 1) / 20) * 20 + 20]
		income_by_band[bucket] = int(income_by_band.get(bucket, 0)) + income
	var buckets: Array = income_by_band.keys()
	buckets.sort()
	for bucket in buckets:
		print("  levels %s average %d coins" % [String(bucket), int(income_by_band[bucket]) / 20])
	print("  overall average %d coins per level" % (income_total / LAST_LEVEL))

	print("")
	print("=== IMMEDIATE REPEATS ===")
	var repeat_runs := 0
	for index in range(1, rows.size()):
		if String((rows[index] as Dictionary).template) == String((rows[index - 1] as Dictionary).template):
			repeat_runs += 1
			print("L%d repeats %s" % [int((rows[index] as Dictionary).level), String((rows[index] as Dictionary).template)])
	print("consecutive identical templates: %d" % repeat_runs)

	print("")
	if problems.is_empty():
		print("LEVEL_TEMPLATE_AUDIT: PASS (no invalid configurations in 1-%d)" % LAST_LEVEL)
	else:
		print("LEVEL_TEMPLATE_AUDIT: %d PROBLEM(S)" % problems.size())
		for problem in problems:
			print("  - %s" % problem)
	quit()


func _print_row(row: Dictionary) -> void:
	print("%3d | %-17s | %-11s | %-17s | %4d | %-8s | %-20s | %-3s | %5d | %-8s | %d" % [
		int(row.level), String(row.template), String(row.band), String(row.layout),
		int(row.gems), String(row.queue), String(row.targets),
		"yes" if bool(row.limited) else "no", int(row.shot_limit),
		String(row.solver), int(row.shots_used),
	])


func _targets_text(config: Dictionary) -> String:
	var parts: Array[String] = []
	for entry in (config.get("target_sequence", []) as Array):
		var target: Dictionary = entry as Dictionary
		parts.append("L%dx%d" % [int(target.get("tier", 0)), int(target.get("quantity", 1))])
	return " ".join(parts)


func _print_counts(label: String, counts: Dictionary) -> void:
	var keys: Array = counts.keys()
	keys.sort()
	for key in keys:
		print("  %s %-18s %d" % [label, String(key), int(counts[key])])
