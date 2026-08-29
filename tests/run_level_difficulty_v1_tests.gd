extends SceneTree

## Coverage for the level-difficulty pass: the limited-shots schedule, the
## seeded opening boards that stop a level being cleared up a single line, and
## the guarantees that keep every level solvable without spending a power.

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const GameScene = preload("res://scenes/Game.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_first_limited_shots_level_follows_the_intro()
	_test_limited_shots_recur_and_tighten()
	_test_shot_limits_never_make_a_level_impossible()
	_test_opening_board_grows_and_is_bounded()
	_test_opening_board_is_deterministic()
	_test_opening_board_leaves_a_route_through()
	await _test_controller_places_the_opening_board()
	if failures.is_empty():
		print("LEVEL_DIFFICULTY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEVEL_DIFFICULTY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The mechanic has to be taught while the board is still simple, and the three
## introduction levels are where the merge loop itself is taught.
func _test_first_limited_shots_level_follows_the_intro() -> void:
	for level in [1, 2, 3]:
		_assert(not LevelConfigType.is_limited_shots_level(level),
			"level %d must stay unlimited while the merge loop is being taught" % level)
		_assert(LevelConfigType.shot_limit_for_level(level) == 0,
			"level %d must carry no shot limit" % level)
	_assert(LevelConfigType.is_limited_shots_level(4),
		"the first limited-shots level must land immediately after level 3")
	_assert(LevelConfigType.shot_limit_for_level(4) == LevelConfigType.SHOT_LIMIT_INTRO,
		"the first limited-shots level must use the most generous limit")
	var config := LevelConfigType.generated(4, LevelConfigType.seed_for_level(4))
	_assert(String(config.get("level_type", "")) == "limited_shots",
		"the generated level 4 must be typed as limited_shots")
	_assert(int(config.get("shot_limit", 0)) == LevelConfigType.SHOT_LIMIT_INTRO,
		"the generated level 4 must carry the intro shot limit")


## Limited shots should read as a recurring variant, not a phase that ends.
func _test_limited_shots_recur_and_tighten() -> void:
	var limited: Array[int] = []
	for level in range(1, 41):
		if LevelConfigType.is_limited_shots_level(level):
			limited.append(level)
	_assert(limited.size() >= 10,
		"limited-shots levels must keep recurring across the first forty levels (found %d)" % limited.size())
	# Never two in a row: back-to-back limited levels read as a difficulty wall
	# rather than a change of pace.
	for index in range(1, limited.size()):
		_assert(limited[index] - limited[index - 1] >= 2,
			"limited-shots levels must not run back to back (%d then %d)" % [limited[index - 1], limited[index]])
	var previous := LevelConfigType.shot_limit_for_level(limited[0])
	for index in range(1, limited.size()):
		var current := LevelConfigType.shot_limit_for_level(limited[index])
		_assert(current <= previous,
			"shot limits must never loosen as levels advance (%d then %d)" % [previous, current])
		previous = current
	_assert(previous == LevelConfigType.SHOT_LIMIT_FLOOR,
		"shot limits must settle at the documented floor rather than shrinking forever")


## Hard levels may strongly encourage powers, but a level must never be
## mathematically unwinnable without them.
func _test_shot_limits_never_make_a_level_impossible() -> void:
	for level in range(4, 61):
		if not LevelConfigType.is_limited_shots_level(level):
			continue
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var limit := int(config.get("shot_limit", 0))
		var sequence: Array = config.get("launcher_sequence", []) as Array
		_assert(limit >= LevelConfigType.SHOT_LIMIT_FLOOR,
			"level %d must respect the shot floor" % level)
		# The floor has to clear the deterministic launcher cycle, or the player
		# could run out before the sequence has offered the tiers a target needs.
		_assert(limit >= sequence.size(),
			"level %d must allow at least one full launcher cycle (%d shots for %d)" % [level, limit, sequence.size()])
		var targets: Array = config.get("target_sequence", []) as Array
		var required := 0
		for entry in targets:
			required += maxi(1, int((entry as Dictionary).get("quantity", 1)))
		_assert(limit > required * 4,
			"level %d must leave real room to build each target" % level)


func _test_opening_board_grows_and_is_bounded() -> void:
	_assert(LevelConfigType.starting_board_rows(1) == 0,
		"level 1 must open on a clear table while the basic loop is taught")
	_assert(LevelConfigType.generated(1, LevelConfigType.seed_for_level(1)).get("starting_board", []).is_empty(),
		"the generated level 1 must carry no opening board")
	_assert(LevelConfigType.starting_board_rows(LevelConfigType.STARTING_BOARD_FIRST_LEVEL) > 0,
		"the opening board must begin once the loop is taught")
	var previous := 0
	for level in range(1, 61):
		var rows := LevelConfigType.starting_board_rows(level)
		_assert(rows >= previous, "opening board rows must never shrink as levels advance")
		_assert(rows <= LevelConfigType.STARTING_BOARD_MAX_ROWS,
			"opening board rows must stay capped so the launcher always has a landing spot")
		previous = rows

	# Only spawnable tiers may be pre-placed, or a seeded gem could never be
	# merged into and the level would be unwinnable.
	for level in range(2, 41):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var spawnable: Array = config.get("spawnable_tiers", []) as Array
		for entry in (config.get("starting_board", []) as Array):
			var tier := int((entry as Dictionary).get("tier", 0))
			_assert(spawnable.has(tier),
				"level %d seeded a tier %d gem that can never be merged into" % [level, tier])


## A retry has to present the same puzzle, or a failed level becomes a reroll.
func _test_opening_board_is_deterministic() -> void:
	for level in [2, 5, 9, 17]:
		var seed_value := LevelConfigType.seed_for_level(level)
		var first: Array = LevelConfigType.generated(level, seed_value).get("starting_board", []) as Array
		var second: Array = LevelConfigType.generated(level, seed_value).get("starting_board", []) as Array
		_assert(first.size() == second.size() and JSON.stringify(first) == JSON.stringify(second),
			"level %d must rebuild an identical opening board from the same seed" % level)


## The point of the opening board is that horizontal position starts mattering,
## but it must never seal the table off.
func _test_opening_board_leaves_a_route_through() -> void:
	for level in range(2, 41):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var board: Array = config.get("starting_board", []) as Array
		if board.is_empty():
			continue
		var rows := {}
		for entry_value in board:
			var entry: Dictionary = entry_value as Dictionary
			var row := int(entry.get("row", 0))
			rows[row] = int(rows.get(row, 0)) + 1
		for row in rows.keys():
			var expected := LevelConfigType.STARTING_BOARD_COLUMNS - (1 if int(row) % 2 == 1 else 0)
			_assert(int(rows[row]) < expected,
				"level %d row %d must leave a gap rather than seal the table" % [level, row])
			_assert(int(rows[row]) > 0,
				"level %d row %d must place at least one gem" % [level, row])


func _test_controller_places_the_opening_board() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.disable_3d = true
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 6
	controller.level_seed = LevelConfigType.seed_for_level(6)
	controller.restart()
	controller.set_process(false)

	var expected: Array = controller.level_config.get("starting_board", []) as Array
	_assert(not expected.is_empty(), "level 6 must define an opening board")
	var placed = controller._targetable_pieces()
	_assert(placed.size() == expected.size(),
		"the controller must place every seeded gem (expected %d, placed %d)" % [expected.size(), placed.size()])

	var danger := GameConfig.danger_line_y()
	for piece in placed:
		# An opening board must never start the player near a loss.
		_assert(piece.position.y < danger - 100.0,
			"a seeded gem must sit well clear of the danger line")
		_assert(piece.position.y > GameConfig.board_top(),
			"a seeded gem must sit inside the table")
		var left := GameConfig.table_left_at(piece.position.y)
		var right := GameConfig.table_right_at(piece.position.y)
		_assert(piece.position.x >= left - 1.0 and piece.position.x <= right + 1.0,
			"a seeded gem must sit inside the rails at its own row")
		_assert(is_equal_approx(piece.radius, GameConfig.gem_collision_radius(piece.level) * piece.perspective_scale),
			"a seeded gem must use the same radius the simulation gives a launched gem")

	# Seeded gems must not overlap, or the simulation would resolve them apart
	# on the first frame and the layout the player sees would not be the one
	# that was designed.
	for first in range(placed.size()):
		for second in range(first + 1, placed.size()):
			var gap = placed[first].position.distance_to(placed[second].position)
			var touching = placed[first].radius + placed[second].radius
			_assert(gap >= touching - 1.0,
				"seeded gems must not start overlapping (gap %.1f, needs %.1f)" % [gap, touching])
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
