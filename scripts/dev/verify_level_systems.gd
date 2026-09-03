extends SceneTree

## Demonstration harness for the four level systems, written to be *read* rather
## than to pass or fail. Each section prints the real generated output so the
## behaviour can be inspected directly instead of taken on trust.
##
## Run: godot --headless --script scripts/dev/verify_level_systems.gd

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelTemplateType = preload("res://scripts/core/level_template.gd")
const GameConfigType = preload("res://scripts/core/game_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_section_2_templates()
	_section_3_targets()
	_section_4_layouts()
	_section_5_difficulty()
	quit()


# --- 2. Template system -----------------------------------------------------

func _section_2_templates() -> void:
	print("================ 2. LEVEL-TEMPLATE SYSTEM ================")
	print("Each template is a whole composition. The point is that the levers")
	print("move INDEPENDENTLY - a hard queue can pair with short targets, and a")
	print("kind queue with a long climb. If they all moved together this would")
	print("just be the old single difficulty ladder wearing 18 names.")
	print("")
	print("%-18s %-11s %-9s %-18s %-5s %-14s %s" % ["template", "band", "queue", "layout", "rows", "targets", "limited"])
	var ids: Array = LevelTemplateType.TEMPLATES.keys()
	ids.sort()
	for id in ids:
		var t: Dictionary = LevelTemplateType.TEMPLATES[id]
		print("%-18s %-11s %-9s %-18s %-5d %-14s %s" % [
			id, String(t.band), String(t.queue), String(t.layout),
			int(t.rows), String(t.targets),
			("yes m=%.2f" % float(t.shot_margin)) if bool(t.limited) else "no",
		])

	# The independence claim, checked rather than asserted: for the same queue
	# band, do target structures actually differ?
	print("")
	print("Independence check - same queue band, different target structures:")
	var by_queue := {}
	for id in ids:
		var t: Dictionary = LevelTemplateType.TEMPLATES[id]
		var q := String(t.queue)
		if not by_queue.has(q):
			by_queue[q] = {}
		(by_queue[q] as Dictionary)[String(t.targets)] = true
	for q in by_queue.keys():
		var structures: Array = (by_queue[q] as Dictionary).keys()
		structures.sort()
		print("  queue %-9s -> %d distinct target structures: %s" % [
			String(q), structures.size(), ", ".join(structures)])
	print("")


# --- 3. Target progression --------------------------------------------------

func _section_3_targets() -> void:
	print("================ 3. TARGET PROGRESSION ================")
	print("Old behaviour: every late normal level was L6x3 -> L7x2 -> L8x1 and")
	print("every limited level was L6x1 -> L7x1. Below is what levels 30-55")
	print("actually ask for now.")
	print("")
	var counts := {}
	for level in range(30, 56):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var text := _targets_text(config)
		counts[text] = int(counts.get(text, 0)) + 1
		print("  L%-3d %-9s %-18s %s" % [
			level,
			"limited" if String(config.get("level_type", "")) == "limited_shots" else "normal",
			String(config.get("template_id", "")),
			text,
		])
	print("")
	print("Distinct target ladders in that 26-level window: %d" % counts.size())
	var keys: Array = counts.keys()
	keys.sort()
	for key in keys:
		print("  %-22s x%d" % [String(key), int(counts[key])])

	# The rule that keeps every ladder buildable.
	print("")
	print("Ascending-tier rule across levels 1-120 (a gem merged above the")
	print("active card is never banked for a later one, so a descending ladder")
	print("would strand work the player must do anyway):")
	var violations := 0
	for level in range(1, 121):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var previous := 0
		for entry in (config.get("target_sequence", []) as Array):
			var tier := int((entry as Dictionary).get("tier", 0))
			if tier <= previous:
				violations += 1
			previous = tier
	print("  violations: %d" % violations)
	print("")


# --- 4. Layout variation ----------------------------------------------------

func _section_4_layouts() -> void:
	print("================ 4. LAYOUT VARIATION ================")
	print("Every archetype rendered from its real generated placements. '#' is a")
	print("seeded gem, '.' an opening. Row 0 is the LOWEST row (nearest the")
	print("danger line); higher rows sit further above it.")
	print("")
	var mapping := {}
	for tier in range(1, 9):
		mapping[tier] = tier
	for layout in LevelTemplateType.LAYOUTS:
		if String(layout) == LevelTemplateType.LAYOUT_EMPTY:
			continue
		# A synthetic template so each archetype is shown at the same density,
		# isolating shape from row count.
		var template := {
			"layout": String(layout), "rows": 4, "gaps": 1,
			"id": "demo", "band": "NORMAL", "queue": "balanced", "targets": "climb_single",
		}
		var board := LevelConfigType.starting_board_for_template(template, 20260903, mapping)
		print("  %s (%d gems)" % [String(layout), board.size()])
		_print_board(board)
		print("")

	print("Straight-lane safety across all archetypes, levels 1-120:")
	print("(a column open in EVERY row is a lane the player can shoot up all")
	print("level without ever aiming - the defect the seeded board prevents)")
	var lanes := 0
	for level in range(1, 121):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		if _has_straight_lane(config.get("starting_board", []) as Array):
			lanes += 1
			print("  LANE at level %d (%s)" % [level, String(config.get("layout_id", ""))])
	print("  levels with a straight lane: %d" % lanes)
	print("")


func _print_board(board: Array) -> void:
	var rows := {}
	var max_row := 0
	for entry in board:
		var record: Dictionary = entry as Dictionary
		var row := int(record.get("row", 0))
		max_row = maxi(max_row, row)
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(float(record.get("column", 0.0)))
	# Printed top row first, matching how the board is seen on screen.
	for row in range(max_row, -1, -1):
		var cells := ""
		var occupied: Array = rows.get(row, []) as Array
		# Half-column resolution, because odd rows are staggered by 0.5.
		for half in range(0, 9):
			var x := float(half) * 0.5
			var filled := false
			for column in occupied:
				if absf(float(column) - x) < 0.25:
					filled = true
					break
			cells += "#" if filled else "."
		print("    row %d  %s" % [row, cells])


func _has_straight_lane(board: Array) -> bool:
	if board.is_empty():
		return false
	var rows := {}
	for entry in board:
		var record: Dictionary = entry as Dictionary
		var row := int(record.get("row", 0))
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(float(record.get("column", 0.0)))
	if rows.size() < 2:
		return false
	for sample in range(0, 61):
		var x := float(sample) / 60.0 * float(LevelConfigType.STARTING_BOARD_COLUMNS - 1)
		var blocked := false
		for row in rows.keys():
			var clear := true
			for column in (rows[row] as Array):
				if absf(float(column) - x) < 0.9:
					clear = false
					break
			if not clear:
				blocked = true
				break
		if not blocked:
			return true
	return false


# --- 5. Difficulty progression ---------------------------------------------

func _section_5_difficulty() -> void:
	print("================ 5. DIFFICULTY PROGRESSION ================")
	print("The curve must trend upward without being monotonic: a run of")
	print("ever-harder levels flattens into 'hard' and the spikes stop being")
	print("felt. '^' is a step up from the previous level, 'v' a relief dip.")
	print("")
	print("lvl  band         role       template            rank  move")
	var previous_rank := -1
	var dips := 0
	var rises := 0
	for level in range(1, 61):
		var template := LevelTemplateType.for_level(level)
		var rank := int(LevelTemplateType.BAND_RANK[String(template.band)])
		var move := "  "
		if previous_rank >= 0:
			if rank > previous_rank:
				move = " ^"
				rises += 1
			elif rank < previous_rank:
				move = " v"
				dips += 1
		previous_rank = rank
		print("%3d  %-12s %-10s %-19s %d   %s" % [
			level, String(template.band), String(template.role),
			String(template.id), rank, move])
	print("")
	print("steps up: %d   relief dips: %d   (both non-zero = a real rhythm)" % [rises, dips])

	# Trend, measured rather than eyeballed.
	var early := 0.0
	var late := 0.0
	for level in range(1, 41):
		early += float(LevelTemplateType.BAND_RANK[String(LevelTemplateType.for_level(level).band)])
	for level in range(61, 101):
		late += float(LevelTemplateType.BAND_RANK[String(LevelTemplateType.for_level(level).band)])
	print("mean band rank, levels 1-40: %.2f   levels 61-100: %.2f" % [early / 40.0, late / 40.0])

	print("")
	print("Limited-shot cadence (gaps between consecutive limited levels).")
	print("A single repeated gap would be the old metronome:")
	var limited: Array[int] = []
	for level in range(1, 121):
		if LevelConfigType.is_limited_shots_level(level):
			limited.append(level)
	var gap_counts := {}
	var gap_text := ""
	for index in range(1, limited.size()):
		var gap := limited[index] - limited[index - 1]
		gap_counts[gap] = int(gap_counts.get(gap, 0)) + 1
		gap_text += "%d " % gap
	print("  limited levels: %s" % str(limited).replace("[", "").replace("]", ""))
	print("  gaps: %s" % gap_text)
	var gap_keys: Array = gap_counts.keys()
	gap_keys.sort()
	for key in gap_keys:
		print("    gap of %d: x%d" % [int(key), int(gap_counts[key])])
	print("  distinct gap lengths: %d" % gap_counts.size())
	print("")


func _targets_text(config: Dictionary) -> String:
	var parts: Array[String] = []
	for entry in (config.get("target_sequence", []) as Array):
		var target: Dictionary = entry as Dictionary
		parts.append("L%dx%d" % [int(target.get("tier", 0)), int(target.get("quantity", 1))])
	return " -> ".join(parts)
