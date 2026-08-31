extends SceneTree

## Covers two reported production bugs.
##
## 1. The out-of-shots rescue softlock. Tapping the buy button disables every
##    button on the rescue popup so a double tap cannot buy twice — including
##    GIVE UP. When the controller declined the request without dismissing the
##    popup (the player could not afford it, or the save failed) nothing ever
##    re-enabled them, so the player was stuck: they could not buy, could not
##    give up, and could not reach Home. The level was unrecoverable.
##
## 2. The bomb destroying objective gems. The blast cleared anything in radius,
##    including the L6-L8 gems the level exists to build, so using the power
##    could delete the player's own progress.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const GemPieceType = preload("res://scripts/core/gem_piece.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	_test_rescue_popup_recovers_when_purchase_is_declined()
	await _test_rescue_popup_is_escapable_after_a_failed_purchase()
	_test_blast_spares_objective_tiers()
	if failures.is_empty():
		print("RESCUE_SOFTLOCK_BLAST_SAFETY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("RESCUE_SOFTLOCK_BLAST_SAFETY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The overlay in isolation: once a tap has armed the pending state, only an
## explicit clear may re-enable the buttons.
func _test_rescue_popup_recovers_when_purchase_is_declined() -> void:
	var overlay := ResultOverlayType.new()
	root.add_child(overlay)
	overlay.present_out_of_shots(0, 5, 300)
	_assert(overlay.visible_result, "The rescue popup must present when shots run out")
	_assert(not overlay.home_button.disabled, "GIVE UP must start enabled")
	overlay._on_action_pressed()
	_assert(overlay.retry_button.disabled, "Tapping buy must lock the buy button against a double purchase")
	_assert(overlay.home_button.disabled, "Tapping buy locks GIVE UP too, which is why it must be released again")
	overlay.clear_pending_actions()
	_assert(not overlay.retry_button.disabled, "A declined purchase must re-enable the buy button")
	_assert(not overlay.home_button.disabled, "A declined purchase must re-enable GIVE UP so the player can leave")
	overlay.queue_free()


## The controller path the player actually hit: out of shots, no coins left.
func _test_rescue_popup_is_escapable_after_a_failed_purchase() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller.out_of_shots_pending = true
	controller.out_of_shots_presented = true
	controller.coins = 0
	controller.result_overlay.present_out_of_shots(0, GameConfig.EXTRA_SHOTS_AMOUNT, GameConfig.EXTRA_SHOTS_COST)
	# The real tap. extra_shots_requested is wired straight to the controller, so
	# this one call runs the whole chain: the overlay arms its pending state and
	# the controller declines because the balance cannot cover the cost. What
	# matters is the state the player is left in afterwards.
	controller.result_overlay._on_action_pressed()
	_assert(not controller.result_overlay.home_button.disabled, "A player with no coins must still be able to GIVE UP after tapping buy")
	_assert(not controller.result_overlay.retry_button.disabled, "The buy button must not be left permanently dead")
	_assert(not controller.failed, "Declining a purchase must not fail the level on its own")
	# Android Back must also answer the rescue popup. It is deliberately swallowed
	# on win/fail result screens, and swallowing it here too is what left the
	# player with no exit at all once the buttons had locked.
	_assert(controller.result_overlay.is_rescue_mode(), "The popup must still be the rescue offer at this point")
	# The declined purchase opened the watch-a-video offer on top, so the first
	# Back closes that, exactly as a player would expect.
	_assert(controller._handle_back_request() == "power_overlay", "Back must first close the video offer stacked above the rescue popup")
	_assert(controller._handle_back_request() == "rescue_declined", "Back must then decline the rescue offer rather than being swallowed")
	_assert(controller.failed, "Declining via Back must end the attempt so the player can return Home")
	controller.queue_free()
	await process_frame


## Objective gems sit inside the blast and must survive it; commons in the same
## radius must still be cleared, or the power would do nothing.
func _test_blast_spares_objective_tiers() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	var origin := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 200.0)
	controller.pieces = [] as Array[GemPiece]
	var common_ids: Array[int] = []
	var objective_ids: Array[int] = []
	var next_id := 900
	for tier in range(1, 9):
		var piece := GemPieceType.new(next_id, tier, origin + Vector2(float(tier - 4) * 6.0, 0.0), GameConfig.gem_collision_radius(tier))
		controller.pieces.append(piece)
		if tier > GameConfig.POWER_BOMB_MAX_CLEARED_TIER:
			objective_ids.append(next_id)
		else:
			common_ids.append(next_id)
		next_id += 1
	var cleared_ids: Array = []
	for piece in controller.pieces:
		if piece.level <= GameConfig.POWER_BOMB_MAX_CLEARED_TIER and piece.position.distance_to(origin) <= GameConfig.POWER_BOMB_RADIUS:
			cleared_ids.append(piece.id)
	controller._apply_bomb_effect(origin, cleared_ids)
	var surviving: Array[int] = []
	for piece in controller.pieces:
		surviving.append(piece.id)
	for id_value in objective_ids:
		_assert(surviving.has(id_value), "Objective-tier gem %d must survive a blast centred on it" % id_value)
	for id_value in common_ids:
		_assert(not surviving.has(id_value), "Common gem %d inside the blast must still be cleared" % id_value)
	_assert(GameConfig.POWER_BOMB_MAX_CLEARED_TIER < 5, "Only Common tiers may be blast-clearable")
	controller.queue_free()
