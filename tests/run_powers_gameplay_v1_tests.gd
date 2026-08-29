extends SceneTree

## Gameplay coverage for the four powers: the targeting handshake, each power's
## board effect, the rollback-safe spend, and the guarantee that an empty power
## offers a rewarded ad instead of a dead button.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_targeting_handshake()
	await _test_bomb_clears_a_bounded_cluster()
	await _test_hammer_destroys_one_chosen_gem()
	await _test_magnet_pulls_matching_gems()
	await _test_switch_changes_the_current_gem_without_coins()
	await _test_empty_power_offers_an_ad_and_never_disables()
	await _test_failed_spend_leaves_the_board_untouched()
	if failures.is_empty():
		print("POWERS_GAMEPLAY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POWERS_GAMEPLAY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## Bomb and hammer must arm, wait for a board tap, and be cancellable. A tap
## that hits nothing must leave the power armed and unspent.
func _test_targeting_handshake() -> void:
	var controller = await _start({"bomb": 2, "hammer": 2, "magnet": 0, "switch": 0})
	_populate(controller)

	_assert(controller.pending_power_target.is_empty(), "no power may be armed before one is requested")
	controller._on_power_requested(PowerInventoryServiceType.BOMB)
	_assert(controller.pending_power_target == PowerInventoryServiceType.BOMB,
		"requesting bomb must arm targeting rather than firing immediately")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 2,
		"arming a targeted power must not spend it yet")

	# Tapping the armed power again cancels, so the player is never trapped.
	controller._on_power_requested(PowerInventoryServiceType.BOMB)
	_assert(controller.pending_power_target.is_empty(), "re-tapping an armed power must cancel targeting")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 2,
		"cancelling targeting must not spend the power")

	controller._on_power_requested(PowerInventoryServiceType.BOMB)
	# The armed tile must be visually distinct from every other tile, or the
	# player has no way to tell their next tap will spend a power.
	var armed_tile: Dictionary = controller.gameplay_ui.power_tiles.get(PowerInventoryServiceType.BOMB, {})
	var armed_button := armed_tile.get("column") as Control
	_assert(armed_button != null and is_equal_approx(armed_button.scale.x, GameplayHudType.POWER_TILE_ARMED_SCALE),
		"the armed tile must be scaled up")
	_assert(armed_button != null and armed_button.modulate == GameplayHudType.POWER_TILE_ARMED_MODULATE,
		"the armed tile must brighten so it reads as selected")
	for other in PowerInventoryServiceType.ALL:
		if other == PowerInventoryServiceType.BOMB:
			continue
		var other_button := (controller.gameplay_ui.power_tiles.get(other, {}) as Dictionary).get("column") as Control
		_assert(other_button != null and other_button.modulate != GameplayHudType.POWER_TILE_ARMED_MODULATE,
			"only the armed tile may use the armed highlight (%s did too)" % other)

	var far_away := Vector2(GameConfig.BOARD_LEFT + 12.0, GameConfig.board_top() + 12.0)
	var consumed = controller._resolve_power_target(far_away)
	_assert(consumed, "an armed power must consume the board tap so it cannot also aim the launcher")
	_assert(controller.pending_power_target == PowerInventoryServiceType.BOMB,
		"a tap that hits nothing must leave the power armed")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 2,
		"a misfire must never cost the player the power")
	_free(controller)


func _test_bomb_clears_a_bounded_cluster() -> void:
	var controller = await _start({"bomb": 1, "hammer": 0, "magnet": 0, "switch": 0})
	_populate(controller)
	var before = controller.pieces.size()
	var origin: Vector2 = controller.pieces[8].position

	var expected_in_radius := 0
	for piece in controller.pieces:
		if not piece.is_active_launcher and piece.position.distance_to(origin) <= GameConfig.POWER_BOMB_RADIUS:
			expected_in_radius += 1
	var expected_cleared := mini(expected_in_radius, GameConfig.POWER_BOMB_MAX_CLEARED)
	_assert(expected_cleared > 0, "the seeded board must place gems inside the bomb radius")

	controller._on_power_requested(PowerInventoryServiceType.BOMB)
	controller._resolve_power_target(origin)
	_assert(controller.pieces.size() == before - expected_cleared,
		"bomb must clear exactly the capped set inside its radius (expected %d, removed %d)" % [expected_cleared, before - controller.pieces.size()])
	_assert(controller.pieces.size() > 0, "bomb must never clear the whole table")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 0,
		"firing bomb must spend exactly one")
	for piece in controller.pieces:
		_assert(not controller.danger_timers.has(piece.id) or not piece.consumed,
			"a surviving gem must not be left marked consumed")
	_free(controller)


## The cap must hold even where gems are packed tighter than the seeded board.
func _test_hammer_destroys_one_chosen_gem() -> void:
	var controller = await _start({"bomb": 0, "hammer": 1, "magnet": 0, "switch": 0})
	_populate(controller)
	var before = controller.pieces.size()
	var victim = controller.pieces[5]
	var victim_id: int = victim.id
	var victim_position: Vector2 = victim.position

	controller._on_power_requested(PowerInventoryServiceType.HAMMER)
	controller._resolve_power_target(victim_position)
	_assert(controller.pieces.size() == before - 1, "hammer must destroy exactly one gem")
	for piece in controller.pieces:
		_assert(piece.id != victim_id, "hammer must destroy the gem that was tapped")
	_assert(not controller.danger_timers.has(victim_id), "a destroyed gem must not leave a danger timer behind")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.HAMMER) == 0,
		"firing hammer must spend exactly one")
	_free(controller)


func _test_magnet_pulls_matching_gems() -> void:
	var controller = await _start({"bomb": 0, "hammer": 0, "magnet": 1, "switch": 0})
	_populate(controller)
	var active = controller.get_active_piece()
	_assert(active != null, "a READY_TO_AIM board must have an active launcher gem")
	if active == null:
		_free(controller)
		return
	# Seed a matching gem inside the radius so the pull has something to act on.
	var matching := GemPiece.new(9500, active.level, active.position - Vector2(0.0, 150.0), GameConfig.gem_collision_radius(active.level))
	controller.pieces.append(matching)
	var before = controller.pieces.size()

	controller._on_power_requested(PowerInventoryServiceType.MAGNET)
	_assert(controller.pending_power_target.is_empty(), "magnet must fire immediately rather than arming targeting")
	_assert(controller.pieces.size() == before, "magnet must not remove any gem")
	_assert(matching.velocity.length() > 0.0, "magnet must give the matching gem velocity toward the current gem")
	_assert(matching.velocity.dot(active.position - matching.position) > 0.0,
		"magnet must pull the matching gem toward the current gem, not away from it")
	_assert(matching.velocity.length() <= GameConfig.MAX_PIECE_SPEED,
		"magnet must respect the containment speed cap so pulled gems still settle")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.MAGNET) == 0,
		"firing magnet must spend exactly one")
	_free(controller)


func _test_switch_changes_the_current_gem_without_coins() -> void:
	var controller = await _start({"bomb": 0, "hammer": 0, "magnet": 0, "switch": 1})
	controller.coins = 900
	controller.level_start_coins = 900
	var active = controller.get_active_piece()
	var before_level: int = active.level
	var before_id: int = active.id

	controller._on_power_requested(PowerInventoryServiceType.SWITCH)
	var after = controller.get_active_piece()
	_assert(after != null and after.id == before_id, "switch must change the gem in place, not replace it")
	_assert(after.level != before_level, "switch must change the current gem's tier")
	_assert(controller.coins == 900 and controller.level_start_coins == 900,
		"switch must no longer charge coins now that it is a power")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.SWITCH) == 0,
		"firing switch must spend exactly one")
	_free(controller)


## The whole point of the coin-sink change: a power at zero must stay pressable
## and route to a rewarded ad rather than presenting a disabled control.
func _test_empty_power_offers_an_ad_and_never_disables() -> void:
	var controller = await _start({"bomb": 0, "hammer": 0, "magnet": 0, "switch": 0})
	_populate(controller)
	controller._refresh_hud()

	for power in PowerInventoryServiceType.ALL:
		var tile: Dictionary = controller.gameplay_ui.power_tiles.get(power, {})
		var button := tile.get("button") as Button
		_assert(button != null and not button.disabled, "%s tile must never be disabled at zero owned" % power)
		var plus_icon := tile.get("plus_icon") as TextureRect
		var count_plate := tile.get("count_plate") as Control
		_assert(plus_icon != null and plus_icon.visible, "%s tile must show the + affordance at zero owned" % power)
		_assert(count_plate != null and not count_plate.visible, "%s tile must hide the count disc at zero owned" % power)

	# Requesting an unowned power must not fire it or arm targeting.
	controller._on_power_requested(PowerInventoryServiceType.BOMB)
	_assert(controller.pending_power_target.is_empty(), "an unowned power must not arm targeting")

	# With no ad loaded the offer must decline quietly and grant nothing.
	controller._offer_power_ad(PowerInventoryServiceType.BOMB)
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 0,
		"an unavailable rewarded ad must grant nothing")

	# A completed reward is the only path that grants, and it must persist.
	_assert(controller._grant_power_from_ad(PowerInventoryServiceType.BOMB),
		"a completed rewarded ad must grant one power")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.BOMB) == 1,
		"a granted power must appear in the inventory")
	var persisted := PowerInventoryServiceType.ensure_state(
		ProgressionSaveServiceType.load_progress().get("power_state", {}) as Dictionary
	)
	_assert(PowerInventoryServiceType.count(persisted, PowerInventoryServiceType.BOMB) >= 1,
		"a granted power must be persisted immediately")
	controller._refresh_hud()
	var bomb_tile: Dictionary = controller.gameplay_ui.power_tiles.get(PowerInventoryServiceType.BOMB, {})
	_assert((bomb_tile.get("count_plate") as Control).visible,
		"the tile must swap from + back to a count once a power is owned")
	_free(controller)


## A power whose effect finds nothing to act on must not be spent.
func _test_failed_spend_leaves_the_board_untouched() -> void:
	var controller = await _start({"bomb": 1, "hammer": 1, "magnet": 1, "switch": 0})
	_populate(controller)
	var before = controller.pieces.size()

	# A hammer tap far from every gem selects nothing.
	controller._on_power_requested(PowerInventoryServiceType.HAMMER)
	controller._resolve_power_target(Vector2(GameConfig.BOARD_LEFT + 8.0, GameConfig.board_top() + 8.0))
	_assert(controller.pieces.size() == before, "a hammer tap that selects nothing must destroy nothing")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.HAMMER) == 1,
		"a hammer tap that selects nothing must not be spent")
	_free(controller)


func _start(counts: Dictionary):
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.disable_3d = true
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 4
	controller.level_seed = LevelConfigType.seed_for_level(4)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": counts,
		"granted_starter": true,
	})
	return controller


func _free(controller) -> void:
	var viewport = controller.get_parent()
	if viewport != null:
		viewport.queue_free()


## A deterministic settled cluster, matching the review captures.
func _populate(controller) -> void:
	var piece_id := 9000
	for row in range(4):
		var y_position := GameConfig.danger_line_y() - 40.0 - float(row) * 78.0
		for column in range(5):
			var level := 1 + ((row * 5 + column) % 4)
			var radius := GameConfig.gem_collision_radius(level)
			var left := GameConfig.table_left_at(y_position) + radius
			var right := GameConfig.table_right_at(y_position) - radius
			var x_position := lerpf(left, right, float(column) / 4.0)
			controller.pieces.append(GemPiece.new(piece_id, level, Vector2(x_position, y_position), radius))
			piece_id += 1


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
