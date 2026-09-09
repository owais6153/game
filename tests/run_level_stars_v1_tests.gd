extends SceneTree

## Level stars: what the three objectives ask for, whether they can actually be
## earned, and the per-level snapshot that keeps a replayed level the one the
## player remembers.
##
## The achievability cases are the reason this suite exists. The shot ladder
## that preceded the solver was authored by hand and made every limited level
## unwinnable, and nothing noticed until a feasibility pass was written months
## later. A star is the same shape of mistake waiting to happen: it is a promise
## made on the level-start screen, and a threshold nobody can reach breaks it
## silently. Every numeric star is therefore checked against the level's own
## play-out for levels 1 to 120, not spot-checked.

const LevelStarsType = preload("res://scripts/core/level_stars.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")
const LevelTemplateType = preload("res://scripts/core/level_template.gd")
const LevelRecordServiceType = preload("res://scripts/services/level_record_service.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const LevelSelectType = preload("res://scripts/ui/level_select_overlay_layer.gd")
const LevelMapViewType = preload("res://scripts/ui/level_map_view.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")

## How far up the curve the achievability sweep runs. Far enough to cover every
## band and both limited and unlimited compositions many times over.
const SWEEP := 120

var failures: Array[String] = []

## A GDScript runtime error aborts the case it happens in without failing the
## process, so each case signs the register on its way out.
const REQUIRED_CASES := [
	"records_pin_a_level_once_it_has_been_played",
	"controller_awards_and_banks_stars",
	"result_popup_awards_stars_before_unlocking_collect",
	"level_ready_shows_the_objectives_it_will_be_judged_on",
	"map_and_header_render_the_stored_stars",
]

var completed: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_every_level_has_three_stable_objectives()
	_test_shot_star_is_reachable_and_meaningful()
	_test_bonus_star_is_reachable_and_varied()
	_test_evaluation_rules()
	_test_star_totals_and_clamping()
	await _test_records_pin_a_level_once_it_has_been_played()
	await _test_controller_awards_and_banks_stars()
	await _test_result_popup_awards_stars_before_unlocking_collect()
	await _test_level_ready_shows_the_objectives_it_will_be_judged_on()
	await _test_map_and_header_render_the_stored_stars()
	for name in REQUIRED_CASES:
		if not completed.has(name):
			failures.append("Case '%s' did not run to completion - look for a SCRIPT ERROR above" % name)
	if failures.is_empty():
		print("LEVEL_STARS_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEVEL_STARS_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _config(level: int) -> Dictionary:
	return LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))


func _test_every_level_has_three_stable_objectives() -> void:
	for level in [1, 2, 7, 20, 63, 119]:
		var config := _config(level)
		var objectives := LevelStarsType.objectives_for(config)
		_assert(objectives.size() == LevelStarsType.MAX_STARS,
			"Level %d must have exactly %d objectives, got %d" % [level, LevelStarsType.MAX_STARS, objectives.size()])
		_assert(String((objectives[0] as Dictionary).get("kind", "")) == LevelStarsType.STAR_COMPLETE,
			"The first star must always be completing the level")
		for index in range(objectives.size()):
			var text := String((objectives[index] as Dictionary).get("text", ""))
			_assert(not text.is_empty(),
				"Level %d objective %d must carry the wording both screens render" % [level, index])
		# Pure, so the level-start screen and the result popup cannot be shown
		# different objectives for the same level.
		var again := LevelStarsType.objectives_for(_config(level))
		_assert(str(objectives) == str(again),
			"Level %d objectives must be stable across calls" % level)


## The efficiency star has to be beatable and has to be worth something. A
## threshold at or below a perfect play-out is impossible; one at or above a
## limited level's own budget is handed out with the win.
func _test_shot_star_is_reachable_and_meaningful() -> void:
	var tightest := 999.0
	var tightest_level := 0
	for level in range(1, SWEEP + 1):
		var config := _config(level)
		var minimum := LevelSolverType.minimum_shots(config)
		if minimum <= 0:
			failures.append("Level %d has no play-out at all, so no star can be sized against it" % level)
			continue
		var target := LevelStarsType.shot_target(config)
		_assert(target > minimum,
			"Level %d shot star (%d) must leave room over a perfect play-out (%d)" % [level, target, minimum])
		var slack := float(target) / float(minimum) - 1.0
		if slack < tightest:
			tightest = slack
			tightest_level = level
		var limit := int(config.get("shot_limit", 0))
		if limit > 0:
			_assert(target < limit,
				"Level %d shot star (%d) must sit inside its own %d-shot budget" % [level, target, limit])
	_assert(tightest >= 0.20,
		"The tightest shot star must leave at least 20%% over a perfect play-out; level %d leaves %.1f%%"
			% [tightest_level, tightest * 100.0])


## The rotating star has to be reachable too, and it has to actually rotate -
## the whole reason it exists is that two levels in the same band should not
## read identically.
func _test_bonus_star_is_reachable_and_varied() -> void:
	var seen := {}
	for level in range(1, SWEEP + 1):
		var config := _config(level)
		var objective: Dictionary = LevelStarsType.objectives_for(config)[2]
		var kind := String(objective.get("kind", ""))
		seen[kind] = int(seen.get(kind, 0)) + 1
		match kind:
			LevelStarsType.KIND_MERGES:
				var unlimited := config.duplicate(true)
				unlimited["shot_limit"] = 0
				var perfect := int(LevelSolverType.simulate(unlimited).get("merges", 0))
				var target := int(objective.get("target", 0))
				_assert(target > 0 and target <= perfect,
					"Level %d asks for %d merges but a perfect play-out only makes %d"
						% [level, target, perfect])
			LevelStarsType.KIND_COMBO:
				var combo := int(objective.get("target", 0))
				_assert(combo >= 2 and combo <= 3,
					"Level %d combo star of %d is outside the plannable 2-3 range" % [level, combo])
			LevelStarsType.KIND_NO_POWER:
				_assert(int(objective.get("target", 0)) == 0,
					"The no-power star is not a numeric objective")
			_:
				failures.append("Level %d carries unknown third-star kind '%s'" % [level, kind])
	for kind in LevelStarsType.BONUS_KINDS:
		_assert(int(seen.get(kind, 0)) > 0,
			"Third star '%s' never appears in %d levels, so the rotation is broken" % [kind, SWEEP])
	# Not a metronome: the kind must not simply cycle with the level number.
	var consecutive_repeats := 0
	for level in range(1, SWEEP):
		if LevelStarsType.bonus_kind(level) == LevelStarsType.bonus_kind(level + 1):
			consecutive_repeats += 1
	_assert(consecutive_repeats > 0 and consecutive_repeats < SWEEP - 1,
		"The third star must neither cycle rigidly nor stay fixed; %d of %d adjacent pairs repeat"
			% [consecutive_repeats, SWEEP - 1])


func _test_evaluation_rules() -> void:
	var config := _config(5)
	var objectives := LevelStarsType.objectives_for(config)
	var shots := int((objectives[1] as Dictionary).get("target", 0))

	# A loss earns nothing at all. The other two objectives describe how a level
	# was beaten, so crediting them for an attempt that was not beaten would let
	# a player bank two stars by giving up efficiently.
	var lost := LevelStarsType.evaluate(objectives, {
		"won": false, "shots_used": 1, "merges": 99999, "best_combo": 9, "used_power": false,
	})
	_assert(not lost[0] and not lost[1] and not lost[2], "A failed attempt must earn no stars")
	_assert(LevelStarsType.awarded(objectives, {"won": false}) == 0, "A failed attempt must award zero")

	# Winning always earns the first star, and the second only inside the budget.
	var thrifty := LevelStarsType.evaluate(objectives, {
		"won": true, "shots_used": shots, "merges": 0, "best_combo": 0, "used_power": true,
	})
	_assert(thrifty[0], "Winning must always earn the completion star")
	_assert(thrifty[1], "Finishing exactly on the shot target must earn the shot star")
	var wasteful := LevelStarsType.evaluate(objectives, {
		"won": true, "shots_used": shots + 1, "merges": 0, "best_combo": 0, "used_power": true,
	})
	_assert(not wasteful[1], "One shot over the target must miss the shot star")

	# Each third-star kind, driven through a level that actually carries it.
	for level in range(1, SWEEP + 1):
		var level_config := _config(level)
		var level_objectives := LevelStarsType.objectives_for(level_config)
		var bonus: Dictionary = level_objectives[2]
		var target := int(bonus.get("target", 0))
		var base := {"won": true, "shots_used": 999999, "merges": 0, "best_combo": 0, "used_power": true}
		var met := base.duplicate()
		match String(bonus.get("kind", "")):
			LevelStarsType.KIND_MERGES:
				met["merges"] = target
				base["merges"] = target - 1
			LevelStarsType.KIND_COMBO:
				met["best_combo"] = target
				base["best_combo"] = target - 1
			LevelStarsType.KIND_NO_POWER:
				met["used_power"] = false
		_assert(LevelStarsType.evaluate(level_objectives, met)[2],
			"Level %d must award its third star when the objective is met" % level)
		_assert(not LevelStarsType.evaluate(level_objectives, base)[2],
			"Level %d must withhold its third star when the objective is missed" % level)


func _test_star_totals_and_clamping() -> void:
	_assert(LevelStarsType.total({1: 3, 2: 2, 3: 1}) == 6, "Totals must sum the per-level counts")
	# A hand-edited save must not be able to inflate the header.
	_assert(LevelStarsType.total({1: 99}) == LevelStarsType.MAX_STARS,
		"A per-level count above the maximum must be clamped in the total")
	_assert(LevelStarsType.stars_for_level({7: 2}, 7) == 2, "Stored stars must read back")
	_assert(LevelStarsType.stars_for_level({}, 7) == 0, "An unplayed level has no stars")
	_assert(LevelStarsType.glyphs(2) == "★★☆", "Two of three must render as ★★☆")
	_assert(LevelStarsType.glyphs(0) == "☆☆☆", "No stars must render as three empty")


## The record is what keeps a replayed level the one the player remembers, and
## it must be written once and never overwritten - an unconditional write would
## re-pin the level to whatever the current generator produces on every visit,
## which is the exact opposite of the point.
func _test_records_pin_a_level_once_it_has_been_played() -> void:
	LevelRecordServiceType.clear_records()
	var original := _config(9)

	_assert(not LevelRecordServiceType.has_record(9), "An unplayed level must have no record")
	_assert(LevelRecordServiceType.apply(original.duplicate(true), {}).get("restored_from_record") == null,
		"Applying an empty record must leave the generated config untouched")

	_assert(LevelRecordServiceType.store(9, original) == OK, "Storing a level record must succeed")
	var record := LevelRecordServiceType.record_for(9)
	_assert(not record.is_empty(), "A stored record must read back")
	for field in LevelRecordServiceType.RECORDED_FIELDS:
		_assert(record.has(field), "A record must pin '%s'" % field)

	# Generation is pure, so a regenerated config must still match. This is the
	# drift detector: if a future generator change breaks it, this fails rather
	# than the player quietly getting a different level 9.
	_assert(LevelRecordServiceType.matches(_config(9), record),
		"A regenerated level 9 must still match its record - the generator has drifted")

	# A second store must not overwrite the first.
	var drifted := original.duplicate(true)
	drifted["shot_limit"] = 12345
	drifted["background_index"] = 7
	LevelRecordServiceType.store(9, drifted)
	_assert(int(LevelRecordServiceType.record_for(9).get("shot_limit", -1)) == int(original.get("shot_limit", 0)),
		"A level already on file must never be re-pinned")

	# And the record must win over a generator that has changed underneath it.
	var restored := LevelRecordServiceType.apply(drifted, record)
	_assert(int(restored.get("shot_limit", -1)) == int(original.get("shot_limit", 0))
		and int(restored.get("background_index", -1)) == int(original.get("background_index", 0)),
		"A restored level must use the recorded values, not the regenerated ones")
	_assert(bool(restored.get("restored_from_record", false)),
		"A restored level must be marked, so an audit can tell it from a regenerated one")
	_assert(str(restored.get("gem_identity_by_tier")) == str(original.get("gem_identity_by_tier")),
		"A replayed level must show the same gems it showed the first time")

	# Fields the record does not pin still regenerate, so a future config field
	# is not frozen at whatever value it happened to have.
	_assert(restored.has("difficulty_band") and restored.has("template_id"),
		"Derived metadata must still be present on a restored config")

	LevelRecordServiceType.clear_records()
	completed.append("records_pin_a_level_once_it_has_been_played")
	await process_frame


func _test_controller_awards_and_banks_stars() -> void:
	ProgressionSaveServiceType.clear_progress()
	LevelRecordServiceType.clear_records()
	var controller = GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)

	_assert(controller.level_star_objectives.size() == LevelStarsType.MAX_STARS,
		"Configuring a level must resolve its objectives")
	# The level the controller loaded must have been pinned by loading it.
	_assert(LevelRecordServiceType.has_record(controller.level_number),
		"Entering a level must pin it")

	# A full-marks attempt: inside the shot budget, and whichever third star this
	# level carries is satisfied outright.
	var objectives: Array = controller.level_star_objectives
	var bonus: Dictionary = objectives[2]
	controller.attempt_analytics.shots_fired = int((objectives[1] as Dictionary).get("target", 1))
	controller.attempt_analytics.total_merges = 999999
	controller.attempt_analytics.max_chain_depth = 9
	controller.level_used_power = false

	var award := controller._award_level_stars()
	_assert(int(award.get("earned", 0)) == LevelStarsType.MAX_STARS,
		"A perfect attempt must earn every star, got %d" % int(award.get("earned", 0)))
	_assert(int(award.get("previous", -1)) == 0, "A first clear must report no prior stars")
	_assert((award.get("results", []) as Array).size() == LevelStarsType.MAX_STARS,
		"The award must carry a result per star for the popup to animate")
	_assert(int(award.get("total", 0)) == LevelStarsType.MAX_STARS,
		"The running total must include the stars just earned")

	# Banked before the popup opens, asserted through the save rather than
	# through memory: "persisted before presented" is the property that matters.
	var saved := ProgressionSaveServiceType.load_progress()
	var stored: Dictionary = saved.get("level_stars", {}) as Dictionary
	_assert(int(stored.get(controller.level_number, 0)) == LevelStarsType.MAX_STARS,
		"Stars must be on disk before the result popup animates them")

	# Monotonic: a worse replay must not take stars back.
	controller.attempt_analytics.shots_fired = 999999
	controller.attempt_analytics.total_merges = 0
	controller.attempt_analytics.max_chain_depth = 0
	controller.level_used_power = true
	var replay := controller._award_level_stars()
	_assert(int(replay.get("earned", 0)) == 1,
		"A sloppy replay must still earn the completion star, got %d" % int(replay.get("earned", 0)))
	_assert(LevelStarsType.stars_for_level(controller.level_stars, controller.level_number) == LevelStarsType.MAX_STARS,
		"A worse replay must never take back stars the player already holds")

	# The snapshot the level-start screen reads must carry the same objectives.
	var snapshot := controller.hud_snapshot()
	_assert((snapshot.get("star_objectives", []) as Array).size() == LevelStarsType.MAX_STARS,
		"The HUD snapshot must carry the three objectives")
	_assert(int(snapshot.get("star_earned", -1)) == LevelStarsType.MAX_STARS,
		"The HUD snapshot must carry the stars already held for this level")

	completed.append("controller_awards_and_banks_stars")
	controller.queue_free()
	await process_frame
	ProgressionSaveServiceType.clear_progress()
	LevelRecordServiceType.clear_records()


## COLLECT is the end of the level. Offering it before the player has been shown
## what they earned is how a fast tap skips the award entirely.
func _test_result_popup_awards_stars_before_unlocking_collect() -> void:
	var overlay = ResultOverlayType.new()
	root.add_child(overlay)
	await process_frame

	var awarded: Array[int] = []
	var finished := [0]
	overlay.star_awarded.connect(func(index: int) -> void: awarded.append(index))
	overlay.stars_finished.connect(func() -> void: finished[0] += 1)

	var objectives := LevelStarsType.objectives_for(_config(5))
	_assert(overlay.present(true, 1200, 5, 8, 100, false, false, 0, false, 0, 0, "danger_line", {
		"objectives": objectives,
		"results": [true, false, true],
		"earned": 2,
		"previous": 0,
		"total": 2,
	}), "The win popup must open")

	_assert(overlay.star_row.visible, "A win must show the star row")
	_assert(overlay.star_row.filled == 0, "The row must start at the stars the player came in with")
	_assert(overlay.retry_button.disabled,
		"COLLECT must be locked while the stars are still arriving")

	await create_timer(3.4, true, false, true).timeout
	_assert(finished[0] == 1, "The star sequence must finish exactly once, got %d" % finished[0])
	_assert(awarded.size() == 2 and awarded[0] == 0 and awarded[1] == 2,
		"Only the earned stars must be awarded, in order; got %s" % str(awarded))
	_assert(overlay.star_row.filled == 3,
		"The row must end lit through the last earned star, got %d" % overlay.star_row.filled)
	_assert(not overlay.retry_button.disabled,
		"COLLECT must unlock once the last star has landed")
	_assert(overlay.star_caption.text.findn("2 of 3") >= 0,
		"The caption must report the tally, got '%s'" % overlay.star_caption.text)

	# A loss has no stars to wait for, so its actions stay live from the first
	# frame exactly as before.
	overlay.dismiss()
	await process_frame
	_assert(overlay.present(false, 300, 5), "The fail popup must open")
	_assert(not overlay.star_row.visible, "A loss must not show a star row")
	_assert(not overlay.retry_button.disabled, "RETRY must never wait on a star sequence")

	completed.append("result_popup_awards_stars_before_unlocking_collect")
	overlay.queue_free()
	await process_frame


func _test_level_ready_shows_the_objectives_it_will_be_judged_on() -> void:
	var overlay = HomeOverlayType.new()
	root.add_child(overlay)
	await process_frame

	var objectives := LevelStarsType.objectives_for(_config(5))
	overlay.present_level_intro(5, 1000, {
		"star_objectives": objectives,
		"star_earned": 1,
	})
	await process_frame

	_assert(overlay.intro_objectives_panel != null and overlay.intro_objectives_panel.visible,
		"Level Ready must show the star objectives")
	_assert(overlay.intro_objectives_column.get_child_count() == LevelStarsType.MAX_STARS,
		"Level Ready must show one row per star, got %d" % overlay.intro_objectives_column.get_child_count())
	# Word for word, so the screen cannot promise a different objective from the
	# one the result popup judges.
	for objective in objectives:
		_assert(_tree_contains_text(overlay.intro_objectives_column, String((objective as Dictionary).get("text", ""))),
			"Level Ready must render the objective wording verbatim: '%s'" % String((objective as Dictionary).get("text", "")))
	# Stars already held are lit, so a replay shows which one is still missing.
	var first_star: StarRow = overlay.intro_objectives_column.get_child(0).get_child(0)
	var second_star: StarRow = overlay.intro_objectives_column.get_child(1).get_child(0)
	_assert(first_star.filled == 1, "A star already held must be shown lit")
	_assert(second_star.filled == 0, "A star not yet earned must be shown empty")

	# A level with no objectives must hide the block rather than draw an empty
	# card - the rescue and briefing paths can both present without them.
	overlay.update_snapshot({})
	_assert(not overlay.intro_objectives_panel.visible,
		"Level Ready must hide the objectives block when there is nothing to show")

	completed.append("level_ready_shows_the_objectives_it_will_be_judged_on")
	overlay.queue_free()
	await process_frame


func _test_map_and_header_render_the_stored_stars() -> void:
	var overlay = LevelSelectType.new()
	root.add_child(overlay)
	await process_frame

	var stars := {1: 3, 2: 2, 3: 1}
	overlay.present(4, 500, [] as Array[int], stars)
	await process_frame

	_assert(overlay.total_stars_label != null and overlay.total_stars_label.text == "6",
		"The header must total the stored stars, got '%s'" % (overlay.total_stars_label.text if overlay.total_stars_label != null else "<none>"))
	_assert(overlay.map_view.stars_by_level.size() == 3,
		"The map must be handed the per-level stars it draws")
	_assert(LevelStarsType.stars_for_level(overlay.map_view.stars_by_level, 2) == 2,
		"The map must read back the stars for a level")

	# The header follows a later award without the screen being re-presented.
	overlay.update_state(5, 500, [] as Array[int], {1: 3, 2: 2, 3: 1, 4: 3})
	_assert(overlay.total_stars_label.text == "9",
		"The header total must follow an update, got '%s'" % overlay.total_stars_label.text)

	# The map owns no rule: handed nothing, it draws nothing rather than guessing
	# from how far the player has come.
	overlay.update_state(50, 500, [] as Array[int], {})
	_assert(overlay.map_view.stars_by_level.is_empty(),
		"The map must not invent stars for levels it was told nothing about")
	_assert(overlay.total_stars_label.text == "0", "An empty star map must total zero")

	completed.append("map_and_header_render_the_stored_stars")
	overlay.queue_free()
	await process_frame


func _tree_contains_text(node: Node, text: String) -> bool:
	if text.is_empty():
		return false
	if node is Label and (node as Label).text.findn(text) >= 0:
		return true
	for child in node.get_children():
		if _tree_contains_text(child, text):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
