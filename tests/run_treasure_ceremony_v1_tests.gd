extends SceneTree

## The treasure ceremony: the drop rules, the tap-driven sequence, and the
## controller path that grants a post-win treasure before the win popup.
##
## Three things here are worth more than the rest.
##
## The drop must be a pure function of the level number, for the same reason
## level seeds are: a replay of level 20 has to behave like level 20. A drop
## that consulted the clock or a live RNG would make replays quietly different
## from first plays and nothing else in the suite would notice.
##
## The reward must already be persisted before the ceremony starts. The
## presentation is a report, not a grant, and a player who force-closes the app
## mid-animation must keep everything.
##
## And the level's own coin reward must survive the treasure. A milestone chest
## pays 800 coins into the same balance the win popup reads, so without the
## captured baseline the popup would claim the level paid 900 and Double Coins
## would offer to match it.

const TreasureDropType = preload("res://scripts/core/treasure_drop.gd")
const TreasureOverlayType = preload("res://scripts/ui/treasure_overlay_layer.gd")
const DailyOverlayType = preload("res://scripts/ui/daily_missions_overlay_layer.gd")
const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const LevelMilestoneType = preload("res://scripts/core/level_milestone.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const MascotViewType = preload("res://scripts/ui/mascot_view.gd")

var failures: Array[String] = []

## A GDScript runtime error inside a case aborts that case but does not stop the
## runner or fail the process, so each case signs the register on its way out
## and a missing signature fails the run.
const REQUIRED_CASES := [
	"overlay_opens_on_tap_and_claims_one_reward_at_a_time",
	"overlay_declines_an_empty_treasure",
	"daily_chest_art_is_its_own_tap_target",
	"controller_grants_a_post_win_treasure_before_the_popup",
	"controller_clears_drop_state_on_restart",
	"win_popup_mascot_still_reacts_after_a_treasure",
]

var completed: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_milestone_drop_rules()
	_test_bonus_drop_is_pure_and_bounded()
	await _test_overlay_opens_on_tap_and_claims_one_reward_at_a_time()
	await _test_overlay_declines_an_empty_treasure()
	await _test_daily_chest_art_is_its_own_tap_target()
	await _test_controller_grants_a_post_win_treasure_before_the_popup()
	await _test_controller_clears_drop_state_on_restart()
	await _test_win_popup_mascot_still_reacts_after_a_treasure()
	for name in REQUIRED_CASES:
		if not completed.has(name):
			failures.append("Case '%s' did not run to completion - look for a SCRIPT ERROR above" % name)
	if failures.is_empty():
		print("TREASURE_CEREMONY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("TREASURE_CEREMONY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The twenty-level chest is now handed over by the win rather than waited for
## on the map, and it is still earned exactly once.
func _test_milestone_drop_rules() -> void:
	var none: Array[int] = []
	var first: Array[int] = [1]

	var drop := TreasureDropType.for_level_win(20, none)
	_assert(String(drop.get("kind", "")) == TreasureDropType.KIND_MILESTONE,
		"Clearing level 20 must drop the milestone treasure")
	_assert(int(drop.get("chest_index", 0)) == 1,
		"The level 20 drop must be chest 1, the same chest the map draws")
	_assert(int(drop.get("coins", 0)) == LevelMilestoneType.COIN_REWARD,
		"The milestone drop must pay the milestone coin reward, not a new number")
	_assert(not (drop.get("powers", {}) as Dictionary).is_empty(),
		"The milestone drop must carry powers as well as coins")

	_assert(String(TreasureDropType.for_level_win(40, none).get("kind", "")) == TreasureDropType.KIND_MILESTONE,
		"Clearing level 40 must drop the second milestone treasure")
	_assert(int(TreasureDropType.for_level_win(40, none).get("chest_index", 0)) == 2,
		"The level 40 drop must be chest 2")

	# The whole point of consulting the claimed list: replaying a milestone must
	# not re-pay it. What is left is an ordinary level win, which may still roll
	# the bonus, so the assertion is that it is not the milestone.
	var replay := TreasureDropType.for_level_win(20, first)
	_assert(String(replay.get("kind", "")) != TreasureDropType.KIND_MILESTONE,
		"Replaying level 20 must not re-pay a chest that is already claimed")

	_assert(TreasureDropType.for_level_win(0, none).is_empty(),
		"Level 0 is not a level and must drop nothing")


## The bonus roll must be reproducible and must stay a garnish. A drop rate that
## crept toward every level would make the ceremony part of the completion flow
## instead of an event, and would quietly inflate the economy by a power a level.
func _test_bonus_drop_is_pure_and_bounded() -> void:
	for level in [1, 3, 7, 19, 21, 63, 250, 1004]:
		_assert(TreasureDropType.rolls_bonus(level) == TreasureDropType.rolls_bonus(level),
			"rolls_bonus(%d) must be stable across calls" % level)
		_assert(TreasureDropType.bonus_power(level) == TreasureDropType.bonus_power(level),
			"bonus_power(%d) must be stable across calls" % level)
		_assert(PowerInventoryServiceType.is_power(TreasureDropType.bonus_power(level)),
			"bonus_power(%d) must name a real power" % level)

	var bonus_levels := 0
	var powers_seen := {}
	for level in range(1, 501):
		if not TreasureDropType.rolls_bonus(level):
			continue
		bonus_levels += 1
		powers_seen[TreasureDropType.bonus_power(level)] = true
	var rate := float(bonus_levels) / 500.0
	_assert(rate > 0.04 and rate < 0.30,
		"The bonus drop must stay occasional; measured %.3f over 500 levels" % rate)
	_assert(powers_seen.size() >= 3,
		"The bonus must not always pay the same power; saw %d distinct" % powers_seen.size())

	# A milestone level whose chest is unclaimed must never come back as a bonus:
	# the bigger reward has to win, or clearing level 20 could pay 120 coins.
	var none: Array[int] = []
	for level in [20, 40, 60, 200]:
		_assert(String(TreasureDropType.for_level_win(level, none).get("kind", "")) == TreasureDropType.KIND_MILESTONE,
			"Level %d must drop its milestone, never a bonus" % level)


## The sequence the whole feature exists for: one tap opens the chest, and then
## each reward waits for a tap of its own. An auto-advancing reveal was the
## obvious design and is the one this asserts against.
func _test_overlay_opens_on_tap_and_claims_one_reward_at_a_time() -> void:
	var overlay = TreasureOverlayType.new()
	root.add_child(overlay)
	await process_frame

	var finished := [0]
	overlay.treasure_finished.connect(func() -> void: finished[0] += 1)

	_assert(overlay.present(800, {"switch": 2, "magnet": 1}, "MILESTONE TREASURE"),
		"A treasure with contents must open")
	_assert(overlay.is_open(), "The overlay must be visible once presented")
	_assert(overlay.handle_back_request(),
		"Back must be swallowed while a granted reward is still on screen")
	# Coins first, then powers in display order.
	_assert(overlay._queue.size() == 3,
		"Coins and each granted power must each be their own claim, got %d" % overlay._queue.size())

	await _settle(overlay, TreasureOverlayType.Phase.READY, 2.0)
	_assert(overlay._phase == TreasureOverlayType.Phase.READY,
		"The chest must come to rest waiting to be tapped")
	_assert(overlay.prompt_label.text == "TAP TO OPEN",
		"The waiting chest must say what to do with it")
	_assert(overlay.chest_icon.texture == UiKit.BADGE_CHEST,
		"The chest must still be shut before it is tapped")

	overlay.handle_tap()
	_assert(overlay._phase == TreasureOverlayType.Phase.OPENING,
		"Tapping the closed chest must start the opening, not a claim")
	# A second tap mid-open must not skip the burst it is there to show.
	overlay.handle_tap()
	_assert(overlay._phase == TreasureOverlayType.Phase.OPENING,
		"Taps during the opening must be ignored")

	await _settle(overlay, TreasureOverlayType.Phase.REWARD, 4.0)
	_assert(overlay._phase == TreasureOverlayType.Phase.REWARD,
		"The opening must hand over to the first reward")
	_assert(overlay.chest_icon.texture == UiKit.BADGE_CHEST_OPEN,
		"The chest must be open once its rewards are coming out")
	_assert(overlay.prompt_label.text == "TAP TO CLAIM",
		"A reward on screen must say it needs a tap")
	_assert(_tree_contains_text(overlay.reward_host, "+800")
		and _tree_contains_text(overlay.reward_host, "COINS"),
		"The first reward must name and count the coins that were granted")

	# Nothing may advance on its own: hold for longer than a full reward cycle
	# and the same card must still be waiting.
	await create_timer(1.2, true, false, true).timeout
	_assert(overlay._phase == TreasureOverlayType.Phase.REWARD
		and _tree_contains_text(overlay.reward_host, "+800"),
		"A reward must wait for the player, never time out into the next one")

	# Powers follow in PowerInventoryService.ALL order - the same order the shop,
	# the HUD and the daily reveal use - so the same treasure always plays back
	# the same way.
	overlay.handle_tap()
	await _settle(overlay, TreasureOverlayType.Phase.REWARD, 4.0)
	_assert(_tree_contains_text(overlay.reward_host, "MAGNET")
		and _tree_contains_text(overlay.reward_host, "×1"),
		"Claiming the coins must bring the next reward, counted")

	overlay.handle_tap()
	await _settle(overlay, TreasureOverlayType.Phase.REWARD, 4.0)
	_assert(_tree_contains_text(overlay.reward_host, "SWITCH")
		and _tree_contains_text(overlay.reward_host, "×2"),
		"The third reward must follow the second, with its own count")

	overlay.handle_tap()
	await _settle(overlay, TreasureOverlayType.Phase.CLOSED, 4.0)
	_assert(not overlay.is_open(), "The ceremony must close after the last claim")
	_assert(finished[0] == 1,
		"treasure_finished must fire exactly once, got %d" % finished[0])
	_assert(not overlay.handle_back_request(),
		"A closed treasure must stop swallowing Back")

	completed.append("overlay_opens_on_tap_and_claims_one_reward_at_a_time")
	overlay.queue_free()
	await process_frame


## An empty treasure must decline rather than open an empty ceremony, because
## the post-win caller waits on `treasure_finished` before showing the win
## popup - and a ceremony with nothing in it would never emit one.
func _test_overlay_declines_an_empty_treasure() -> void:
	var overlay = TreasureOverlayType.new()
	root.add_child(overlay)
	await process_frame
	_assert(not overlay.present(0, {}), "A treasure with no contents must not open")
	_assert(not overlay.present(0, {"switch": 0}), "A zero count is not a reward")
	_assert(not overlay.is_open(), "A declined treasure must leave nothing on screen")
	completed.append("overlay_declines_an_empty_treasure")
	overlay.queue_free()
	await process_frame


## Reaching past a picture of a chest to press a button labelled CLAIM is the
## least direct way to open one.
func _test_daily_chest_art_is_its_own_tap_target() -> void:
	var overlay = DailyOverlayType.new()
	root.add_child(overlay)
	await process_frame

	var claims := [0]
	overlay.chest_claim_requested.connect(func() -> void: claims[0] += 1)

	overlay.present({"missions": [], "chest_claimed": false}, 0)
	_assert(overlay.chest_tap_target != null, "The chest art must carry a tap target")
	_assert(overlay.chest_tap_target.disabled,
		"An unearned chest must not be openable by tapping it")

	overlay.present({"missions": [], "chest_claimed": false, "chest_ready": true}, 0)
	# chest_ready is derived by the service from the missions, so drive it the
	# way the popup itself is driven rather than asserting a private field.
	overlay.chest_button.disabled = false
	overlay.chest_tap_target.disabled = false
	overlay.chest_tap_target.emit_signal("pressed")
	_assert(claims[0] == 1,
		"Tapping the chest art must request the claim, got %d" % claims[0])

	completed.append("daily_chest_art_is_its_own_tap_target")
	overlay.queue_free()
	await process_frame


## The controller path. The grant is asserted through the save file rather than
## through in-memory state, because "persisted before presented" is the property
## that matters and in-memory fields would pass either way.
func _test_controller_grants_a_post_win_treasure_before_the_popup() -> void:
	ProgressionSaveServiceType.clear_progress()
	var controller = GameControllerType.new()
	root.add_child(controller)
	await process_frame
	# Nothing in this case may advance the real game loop; every transition is
	# driven by hand so the assertions describe the flow rather than a race.
	controller.set_process(false)

	_assert(controller.treasure_overlay != null, "The controller must own a treasure layer")

	controller.level_number = 20
	controller.claimed_chests = [] as Array[int]
	controller.coins = 500
	controller.level_start_coins = 400
	var powers_before := PowerInventoryServiceType.count(controller.power_state, "switch")

	var blocked: bool = controller._try_present_post_win_treasure()
	_assert(blocked, "A milestone win must hold the win popup for its treasure")
	_assert(controller.treasure_overlay.is_open(), "The treasure must be on screen")
	_assert(controller.coins == 500 + LevelMilestoneType.COIN_REWARD,
		"The milestone coins must be banked before the ceremony, got %d" % controller.coins)
	_assert(controller.level_start_coins == 400 + LevelMilestoneType.COIN_REWARD,
		"The baseline must move with the treasure so the level's own reward survives")
	_assert(maxi(0, controller.coins - controller.level_start_coins) == 100,
		"The level's own reward must still read as 100, got %d"
			% maxi(0, controller.coins - controller.level_start_coins))
	_assert(PowerInventoryServiceType.count(controller.power_state, "switch") > powers_before,
		"The chest powers must be granted before the ceremony")
	_assert(controller.claimed_chests.has(1),
		"The milestone must be recorded as claimed so the map shows it opened")

	var saved := ProgressionSaveServiceType.load_progress()
	_assert(int(saved.get("total_coins", 0)) == controller.coins,
		"The treasure coins must be on disk before the animation runs")
	_assert((saved.get("claimed_chests", []) as Array).has(1),
		"The opened chest must be on disk before the animation runs")

	# Blocked for as long as the ceremony is up, and released once by its close.
	_assert(controller._try_present_post_win_treasure(),
		"The win popup must stay blocked while the treasure is open")
	controller.treasure_overlay._close()
	_assert(controller.post_win_treasure_done, "Closing the treasure must release the win popup")
	_assert(not controller._try_present_post_win_treasure(),
		"A finished treasure must let the win popup through")
	_assert(not controller._try_present_post_win_treasure(),
		"The drop must resolve once per win, not once per frame")

	completed.append("controller_grants_a_post_win_treasure_before_the_popup")
	controller.queue_free()
	await process_frame
	ProgressionSaveServiceType.clear_progress()


## Restart is the reset that matters: a retry after a milestone win must be able
## to drop its own treasure, and must not replay the last one.
func _test_controller_clears_drop_state_on_restart() -> void:
	ProgressionSaveServiceType.clear_progress()
	var controller = GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)

	controller.post_win_treasure_resolved = true
	controller.post_win_treasure_done = true
	controller.win_reward_captured = true
	controller.restart()
	_assert(not controller.post_win_treasure_resolved
		and not controller.post_win_treasure_done
		and not controller.win_reward_captured,
		"Restart must clear every post-win treasure flag")

	# A level with no milestone and no bonus roll must not hold the popup at all.
	var quiet := 0
	for level in range(1, 200):
		if LevelMilestoneType.chest_for_level(level) == 0 and not TreasureDropType.rolls_bonus(level):
			quiet = level
			break
	_assert(quiet > 0, "The bonus roll must leave some levels without a drop")
	controller.level_number = quiet
	controller.claimed_chests = [] as Array[int]
	_assert(not controller._try_present_post_win_treasure(),
		"A level that drops nothing must not delay the win popup")
	_assert(not controller.treasure_overlay.is_open(),
		"A level that drops nothing must not open an empty ceremony")

	completed.append("controller_clears_drop_state_on_restart")
	controller.queue_free()
	await process_frame
	ProgressionSaveServiceType.clear_progress()


## The treasure now runs immediately before the win popup, so the popup's own
## entrance - and the mascot reaction it holds back until that entrance lands -
## has to survive a ceremony finishing in front of it. The mascot frames are a
## static cache shared by every instance, and the ceremony has its own tweens
## and its own always-processing layer, so this is asserted rather than assumed.
func _test_win_popup_mascot_still_reacts_after_a_treasure() -> void:
	var treasure = TreasureOverlayType.new()
	root.add_child(treasure)
	var result = ResultOverlayType.new()
	root.add_child(result)
	await process_frame

	# Run a whole ceremony first, exactly as a milestone win would.
	treasure.present(800, {"magnet": 1}, "MILESTONE TREASURE")
	await _settle(treasure, TreasureOverlayType.Phase.READY, 2.0)
	treasure.handle_tap()
	await _settle(treasure, TreasureOverlayType.Phase.REWARD, 4.0)
	# Coins, then the one power: two claims, so two taps.
	treasure.handle_tap()
	await _settle(treasure, TreasureOverlayType.Phase.REWARD, 4.0)
	treasure.handle_tap()
	await _settle(treasure, TreasureOverlayType.Phase.CLOSED, 4.0)
	_assert(not treasure.is_open(), "The ceremony must be finished before the popup opens")

	_assert(result.present(true, 1200, 20, 8, 100, false), "The win popup must open after the treasure")
	_assert(result.mascot != null, "The win popup must carry the mascot")
	_assert(result.mascot.current_frame() <= 0.01,
		"The mascot must start neutral and react once the popup has landed")

	# Long enough for the popup entrance plus the mascot's own glide.
	await create_timer(1.6, true, false, true).timeout
	_assert(result.mascot.current_mood() == MascotViewType.MOOD_HAPPY,
		"A win must leave the mascot on the happy track, got '%s'" % result.mascot.current_mood())
	_assert(result.mascot.current_frame() > 1.0,
		"The mascot must actually travel its track after a treasure, reached frame %.2f"
			% result.mascot.current_frame())

	completed.append("win_popup_mascot_still_reacts_after_a_treasure")
	treasure.queue_free()
	result.queue_free()
	await process_frame


## Waits for the overlay to reach `phase`, bounded so a broken sequence fails the
## assertion that follows rather than hanging the runner.
func _settle(overlay, phase: int, timeout: float) -> void:
	var waited := 0.0
	while overlay._phase != phase and waited < timeout:
		await create_timer(0.05, true, false, true).timeout
		waited += 0.05


func _tree_contains_text(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text.findn(text) >= 0:
		return true
	for child in node.get_children():
		if _tree_contains_text(child, text):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
