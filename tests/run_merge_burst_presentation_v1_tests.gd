extends SceneTree

## Guards the merge burst's readability contract.
##
## The burst is the feedback for the action the player performs most, on a board
## crowded with sharp, high-contrast gem art. Three things it must keep:
##
## 1. It must last long enough to be looked at. The previous 0.18s window was
##    over before the eye settled on it.
## 2. Its escalation must survive the pipeline. Objective and combo merges are
##    tuned brighter than an ordinary one, and an intensity clamp at 1.0 silently
##    flattened every tier above ordinary back down to it.
## 3. Colour families must actually differ, or the "different animations per gem"
##    intent degrades into one effect recoloured.

const GemSpriteLayerType = preload("res://scripts/presentation/gem_sprite_layer.gd")
const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")

var failures: Array[String] = []


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	_test_burst_is_actually_visible()
	_test_burst_window_matches_its_sound()
	_test_tier_escalation_survives_the_clamp()
	_test_colour_families_differ()
	_test_shred_sparks_are_gone()
	if failures.is_empty():
		print("MERGE_BURST_PRESENTATION_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("MERGE_BURST_PRESENTATION_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The burst spent its whole life invisible.
##
## Its sprites carried z_index -4096, and a child's z_index is relative to its
## parent, so inside a gem layer at z 10 they resolved below the table sprite and
## were drawn behind opaque table art. No amount of tuning brightness or duration
## could have shown up on screen.
##
## The burst now draws over the gems: underneath them it read as something
## happening behind the board rather than to the gem that just merged, and the
## gem art occluded most of it. The material is additive, so drawing on top
## lights the gem rather than hiding it.
func _test_burst_is_actually_visible() -> void:
	var layer := GemSpriteLayerType.new()
	layer.z_index = GameConfig.GEM_LAYER_Z_INDEX
	root.add_child(layer)
	layer._build_radial_pool()
	_assert(not layer._radial_pool.is_empty(), "The burst pool must be built")
	# The highest z any gem in this layer can take.
	var highest_gem := GameConfig.gem_visual_z_index(GameConfig.GEM_VISUAL_Z_TIE_STRIDE - 1, GameConfig.board_bottom())
	for sprite in layer._radial_pool:
		var effective: int = layer.z_index + sprite.z_index
		_assert(sprite.z_as_relative, "Burst z_index is treated as relative to the layer; the ordering below assumes it")
		_assert(effective > GameConfig.TABLE_Z_INDEX,
			"The merge burst must draw above the table (effective z %d vs table %d) or it is invisible" % [effective, GameConfig.TABLE_Z_INDEX])
		_assert(sprite.z_index > highest_gem,
			"The merge burst must draw above every gem (z %d vs highest gem %d)" % [sprite.z_index, highest_gem])
		# Godot clamps z_index to 4096; exceeding it would silently reorder.
		_assert(effective <= 4096,
			"Layer z plus burst z (%d) must stay inside the engine's z ceiling" % effective)
	layer.queue_free()


## The burst has to agree with its own sound.
##
## `merge-target-immediate.ogg` peaks at 0.10-0.15s and is ~20 dB down by 0.30s.
## A 0.78s burst was tried and read as wrong for exactly that reason: it was
## still turning on screen long after the merge had stopped being audible. The
## bound below keeps the visual inside the cue's envelope.
func _test_burst_window_matches_its_sound() -> void:
	_assert(GameConfig.MERGE_RADIAL_DURATION <= 0.40,
		"The merge burst must clear within the merge cue's envelope (got %.2fs)" % GameConfig.MERGE_RADIAL_DURATION)
	# Short, but not so short it cannot be seen at all on a 60 Hz screen.
	_assert(GameConfig.MERGE_RADIAL_DURATION >= 0.18,
		"The merge burst must last long enough to register (got %.2fs)" % GameConfig.MERGE_RADIAL_DURATION)
	# It still has to grow, or there is no burst — but only just past the gem.
	# Large bursts covered the result and its neighbours.
	_assert(GameConfig.MERGE_RADIAL_END_SCALE > GameConfig.MERGE_RADIAL_START_SCALE * 2.0,
		"The burst must expand enough to register as an event")
	_assert(GameConfig.MERGE_RADIAL_END_SCALE <= 1.4,
		"The burst must stay close to the gem's own footprint so it never hides the result")


func _test_tier_escalation_survives_the_clamp() -> void:
	var ladder := [
		GameConfig.MERGE_RADIAL_INTENSITY_NORMAL,
		GameConfig.MERGE_RADIAL_INTENSITY_COMBO_1,
		GameConfig.MERGE_RADIAL_INTENSITY_COMBO_2,
		GameConfig.MERGE_RADIAL_INTENSITY_COMBO_3,
		GameConfig.MERGE_RADIAL_INTENSITY_COMBO_4,
	]
	for index in range(1, ladder.size()):
		_assert(float(ladder[index]) > float(ladder[index - 1]),
			"Combo intensity must keep escalating at step %d" % index)
	_assert(GameConfig.MERGE_RADIAL_INTENSITY_FINAL_TARGET > GameConfig.MERGE_RADIAL_INTENSITY_TARGET,
		"The final objective must out-punch an ordinary objective")
	_assert(GameConfig.MERGE_RADIAL_INTENSITY_TARGET > GameConfig.MERGE_RADIAL_INTENSITY_NORMAL,
		"An objective merge must out-punch an ordinary merge")
	# The clamp in begin_merge_radial must not flatten the top of that ladder.
	var highest: float = GameConfig.MERGE_RADIAL_INTENSITY_FINAL_TARGET
	_assert(GameConfig.MERGE_RADIAL_INTENSITY_CEILING >= highest,
		"The intensity ceiling (%.2f) clamps away the top of the tier ladder (%.2f)" % [GameConfig.MERGE_RADIAL_INTENSITY_CEILING, highest])
	# And prove it end to end rather than trusting the constants: a final-target
	# burst must actually reach the stored intensity a normal one does not.
	var layer := GemSpriteLayerType.new()
	root.add_child(layer)
	layer.begin_merge_radial(Vector2(100.0, 100.0), 2, GameConfig.MERGE_RADIAL_INTENSITY_NORMAL)
	layer.begin_merge_radial(Vector2(200.0, 200.0), 8, GameConfig.MERGE_RADIAL_INTENSITY_FINAL_TARGET)
	_assert(layer._radial_bursts.size() == 2, "Both bursts must be registered")
	if layer._radial_bursts.size() == 2:
		var ordinary := float(layer._radial_bursts[0].intensity)
		var final_target := float(layer._radial_bursts[1].intensity)
		_assert(final_target > ordinary,
			"A final-objective burst must survive the clamp brighter than an ordinary one (%.2f vs %.2f)" % [final_target, ordinary])
	layer.queue_free()


func _test_colour_families_differ() -> void:
	var layer := GemSpriteLayerType.new()
	root.add_child(layer)
	AssetCatalogType.reset_active_level_mapping()
	var shapes: Dictionary = {}
	for family in GameConfig.MERGE_BURST_FAMILY_STYLE:
		var style: Dictionary = GameConfig.MERGE_BURST_FAMILY_STYLE[family]
		var key := "%s|%s" % [style.get("arms", 0.0), style.get("spin", 0.0)]
		_assert(not shapes.has(key), "Family %s must not duplicate %s's burst shape" % [family, shapes.get(key, "")])
		shapes[key] = family
		# Few, broad arms read as a spinning fan blade rather than as light
		# travelling around a shockwave. Keep the lobes numerous and narrow.
		_assert(float(style.get("arms", 0.0)) >= 6.0, "Family %s needs enough arms to read as a travelling wave rather than a fan" % family)
		_assert(absf(float(style.get("spin", 0.0))) > 0.0, "Family %s must actually rotate" % family)
	# Both rotation directions must be in use, or every burst turns the same way.
	var clockwise := false
	var anticlockwise := false
	for family in GameConfig.MERGE_BURST_FAMILY_STYLE:
		var spin := float((GameConfig.MERGE_BURST_FAMILY_STYLE[family] as Dictionary).get("spin", 0.0))
		clockwise = clockwise or spin > 0.0
		anticlockwise = anticlockwise or spin < 0.0
	_assert(clockwise and anticlockwise, "Burst rotation must vary in direction across families")
	# Objective tiers must resolve to the brighter accent, commons to the plain one.
	var common_style: Dictionary = layer._burst_style(1)
	var target_style: Dictionary = layer._burst_style(8)
	_assert(common_style.accent == GameConfig.MERGE_BURST_ACCENT_COMMON, "A common merge must use the common accent")
	_assert(target_style.accent == GameConfig.MERGE_BURST_ACCENT_TARGET, "An objective merge must use the objective accent")
	_assert(float(target_style.sparkle) > float(common_style.sparkle), "An objective merge must sparkle harder than a common one")
	layer.queue_free()


## The radial spark crown was removed: it read as shredded debris rather than as
## one deliberate effect, and cost a primitive per ray.
func _test_shred_sparks_are_gone() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/presentation/gameplay_effects_layer.gd")
	_assert(not source.is_empty(), "Effects layer source must be readable")
	_assert(not source.contains("for index in range(spark_count)"),
		"The merge spark crown must stay removed from the effects layer draw path")
