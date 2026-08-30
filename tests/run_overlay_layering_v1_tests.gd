extends SceneTree

## Locks the stacking rules behind three shipped defects:
##
## - Tapping GET in the power shop looked like it did nothing, and the reward
##   popup after a completed video was never visible, because the power overlay
##   sat on a lower CanvasLayer than the shop and Home that open it.
## - The daily-mission status badges drew straight through the Settings modal,
##   because they raise their own z_index and z_index sorts across the whole
##   canvas layer regardless of tree order.

const PowerOverlayType = preload("res://scripts/ui/power_overlay_layer.gd")
const PowerShopType = preload("res://scripts/ui/power_shop_overlay_layer.gd")
const DailyMissionsType = preload("res://scripts/ui/daily_missions_overlay_layer.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")
const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")
const LevelBriefingType = preload("res://scripts/ui/level_briefing_overlay_layer.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_power_overlay_outranks_every_opener()
	await _test_home_modals_outrank_content_z_index()
	await _test_gameplay_modal_outranks_the_banner()
	if failures.is_empty():
		print("OVERLAY_LAYERING_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("OVERLAY_LAYERING_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The ad offer and the reward result can be opened from the HUD, Home, the
## daily-missions popup, and the shop. It must render above all of them.
func _test_power_overlay_outranks_every_opener() -> void:
	var openers := {
		"gameplay HUD": 40,
		"Home": 60,
		"daily missions": DailyMissionsType.OVERLAY_LAYER,
		"power shop": PowerShopType.OVERLAY_LAYER,
		"level briefing": LevelBriefingType.OVERLAY_LAYER,
	}
	for opener in openers:
		_assert(PowerOverlayType.OVERLAY_LAYER > int(openers[opener]),
			"the power overlay (layer %d) must render above %s (layer %d)"
				% [PowerOverlayType.OVERLAY_LAYER, opener, int(openers[opener])])


## Every Home modal must outrank any content that raises its own z_index.
func _test_home_modals_outrank_content_z_index() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	# A day with one mission already complete, so the status badges are built.
	var state := DailyMissionServiceType.record(
		DailyMissionServiceType.ensure_current_day({}), "merge", 999
	).get("state", {}) as Dictionary
	home.present(4, 1200, state)
	await process_frame

	# Derived rather than hardcoded, so a modal added later is covered by this
	# test automatically instead of silently escaping it.
	var blockers: Array[String] = []
	for node in home.root_control.find_children("*Blocker", "Control", true, false):
		blockers.append(String(node.name))
		_assert((node as Control).z_index >= HomeOverlayType.MODAL_Z_INDEX,
			"%s must outrank content z_index (has %d)" % [node.name, (node as Control).z_index])
	_assert(not blockers.is_empty(), "Home must build at least one modal blocker to check")

	# Nothing outside a modal may reach the modal's z_index.
	var deepest := 0
	for node in home.root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or _is_inside_blocker(control, blockers):
			continue
		deepest = maxi(deepest, control.z_index)
	_assert(deepest < HomeOverlayType.MODAL_Z_INDEX,
		"no Home content may reach the modal z_index (highest was %d)" % deepest)
	home.queue_free()
	await process_frame


## The mission banner raises its z_index to sit over the HUD, so the pause
## modal has to outrank it or the banner draws through a paused game.
func _test_gameplay_modal_outranks_the_banner() -> void:
	var hud := GameplayHudType.new()
	root.add_child(hud)
	await process_frame
	_assert(hud.pause_blocker != null and hud.pause_blocker.z_index >= GameplayHudType.MODAL_Z_INDEX,
		"the pause modal must outrank every HUD content z_index")
	_assert(hud.mission_toast != null and hud.mission_toast.z_index < hud.pause_blocker.z_index,
		"the mission banner must not draw through the pause modal")
	hud.queue_free()
	await process_frame


func _is_inside_blocker(control: Control, blockers: Array) -> bool:
	var cursor: Node = control
	while cursor != null:
		if blockers.has(cursor.name):
			return true
		cursor = cursor.get_parent()
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
