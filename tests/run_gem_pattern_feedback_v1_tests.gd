extends SceneTree

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_registry_and_runtime_crops()
	_test_pattern_blocks_and_target_safety()
	_test_feedback_tuning()
	_test_hud_styles_have_no_box_shadows()
	if failures.is_empty():
		print("GEM_PATTERN_FEEDBACK_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("GEM_PATTERN_FEEDBACK_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_registry_and_runtime_crops() -> void:
	_assert(AssetCatalogType.GEM_IDENTITY_COUNT == 34, "All 34 supplied gems must be registered")
	var common_count := 0
	var unique_count := 0
	for identity in range(1, AssetCatalogType.GEM_IDENTITY_COUNT + 1):
		var definition := AssetCatalogType.gem_definition(identity)
		_assert(["circle", "rounded_square"].has(String(definition.get("shape", ""))), "Gem %d must use one audited shape" % identity)
		_assert(["solid", "gradient"].has(String(definition.get("color_style", ""))), "Gem %d must use one audited color style" % identity)
		_assert(not String(definition.get("color_family", "")).is_empty(), "Gem %d must have a color family" % identity)
		var rarity := String(definition.get("rarity", ""))
		_assert(["common", "unique"].has(rarity), "Gem %d must use one supported rarity" % identity)
		common_count += 1 if rarity == "common" else 0
		unique_count += 1 if rarity == "unique" else 0
		var texture: Texture2D = AssetCatalogType.GEM_TIER_TEXTURES.get(identity)
		_assert(texture != null, "Gem %d runtime texture must preload" % identity)
		if texture == null:
			continue
		var image := texture.get_image()
		_assert(image != null and not image.is_empty(), "Gem %d runtime image must decode" % identity)
		if image == null or image.is_empty():
			continue
		var used := image.get_used_rect()
		_assert(used.position == Vector2i.ZERO and used.size == image.get_size(), "Gem %d runtime PNG must be alpha-tight" % identity)
		_assert(maxi(image.get_width(), image.get_height()) == 256, "Gem %d longest runtime edge must be normalized to 256 px" % identity)
	_assert(common_count == 22 and unique_count == 12, "The audited pool must remain 22 Common / 12 Unique")
	_assert(unique_count < common_count, "Unique gems must remain a limited minority")
	for identity in range(21, 35):
		_assert(AssetCatalogType.GEM_TIER_TEXTURES.has(identity), "New gem %d must participate in runtime selection" % identity)
	_assert(AssetCatalogType.gem_name(1).is_empty() and String(AssetCatalogType.gem_entry(1).get("name", "x")).is_empty(), "Player-facing gem names must remain absent")


func _test_pattern_blocks_and_target_safety() -> void:
	var saw_shape_circle := false
	var saw_shape_square := false
	var saw_cool_color := false
	var saw_warm_color := false
	var previous_block := {}
	for level_number in range(1, 81):
		var pattern := LevelConfigType.pattern_for_level(level_number)
		var block_start := int(pattern.block_start)
		var block_size := int(pattern.block_size)
		_assert(block_size == 3 or block_size == 4, "Level %d pattern block must last 3 or 4 levels" % level_number)
		_assert(level_number >= block_start and level_number < block_start + block_size, "Level %d must lie inside its declared pattern block" % level_number)
		var first := LevelConfigType.generated(level_number, LevelConfigType.seed_for_level(level_number))
		var retry := LevelConfigType.generated(level_number, LevelConfigType.seed_for_level(level_number))
		_assert(first == retry, "Level %d generation must be deterministic" % level_number)
		var mapping: Dictionary = first.gem_identity_by_tier
		_assert(mapping.size() == 8, "Level %d must map exactly eight local tiers" % level_number)
		var seen := {}
		for tier in range(1, 9):
			var identity := int(mapping.get(tier, -1))
			_assert(identity >= 1 and identity <= 34 and not seen.has(identity), "Level %d tier %d must map one distinct valid identity" % [level_number, tier])
			seen[identity] = true
			var rarity := String(AssetCatalogType.gem_definition(identity).get("rarity", ""))
			_assert(rarity == ("common" if tier <= 4 else "unique"), "Level %d tier %d must respect the Common/Unique progression split" % [level_number, tier])
		var targets: Array = first.target_sequence
		# Limited-shot levels are accuracy challenges and deliberately ask for the
		# two lower objectives instead of the full L6-L8 climb (see
		# LevelConfig.generated). This assertion predates that rule and was
		# failing on every third level; it now checks the rule that exists.
		# Target structure is a template property from 1.0.17: a level asks for two
		# or three cards depending on its composition, and a short ladder may
		# start above L6 (see LevelTemplate.TARGET_STRUCTURES). The invariant that
		# still holds - and the one the merge economy actually depends on - is
		# that the tiers ascend and stay inside the L6-L8 objective range.
		_assert(targets.size() >= 2 and targets.size() <= 3,
			"Level %d must ask for two or three targets (found %d)" % [level_number, targets.size()])
		var previous_target_tier := 5
		for target_index in range(targets.size()):
			var target_tier := int(targets[target_index].tier)
			_assert(target_tier >= 6 and target_tier <= 8,
				"Level %d target %d tier %d is outside the L6-L8 objective range" % [level_number, target_index + 1, target_tier])
			_assert(target_tier > previous_target_tier,
				"Level %d targets must remain a reachable ascending path (%d after %d)" % [level_number, target_tier, previous_target_tier])
			previous_target_tier = target_tier
			var target_identity := int(mapping[target_tier])
			_assert(String(AssetCatalogType.gem_definition(target_identity).rarity) == "unique", "Level %d target %d must come from Unique" % [level_number, target_index + 1])
		if String(pattern.family) == "same_shape":
			var dominant_shape := String(pattern.dominant)
			var opposite_shape := "rounded_square" if dominant_shape == "circle" else "circle"
			for tier in range(1, 6):
				_assert(String(AssetCatalogType.gem_definition(int(mapping[tier])).shape) == dominant_shape, "Level %d normal tier %d must follow dominant shape" % [level_number, tier])
			for tier in range(6, 9):
				_assert(String(AssetCatalogType.gem_definition(int(mapping[tier])).shape) == opposite_shape, "Level %d target tier %d must use the opposite shape" % [level_number, tier])
			saw_shape_circle = saw_shape_circle or dominant_shape == "circle"
			saw_shape_square = saw_shape_square or dominant_shape == "rounded_square"
		else:
			var dominant_color := String(pattern.dominant)
			var matching_common := 0
			for tier in range(1, 5):
				matching_common += 1 if String(AssetCatalogType.gem_definition(int(mapping[tier])).color_family) == dominant_color else 0
			_assert(matching_common >= 3, "Level %d must keep most Common gems in the dominant color" % level_number)
			_assert(String(AssetCatalogType.gem_definition(int(mapping[5])).color_family) == dominant_color, "Level %d non-target Unique must support the dominant color" % level_number)
			for tier in range(6, 9):
				_assert(String(AssetCatalogType.gem_definition(int(mapping[tier])).color_family) != dominant_color, "Level %d target tier %d must contrast the dominant color" % [level_number, tier])
			saw_cool_color = saw_cool_color or ["blue", "purple"].has(dominant_color)
			saw_warm_color = saw_warm_color or ["pink", "red", "orange"].has(dominant_color)
		if not previous_block.is_empty() and int(previous_block.block_index) != int(pattern.block_index):
			_assert(String(previous_block.family) != String(pattern.family) or String(previous_block.dominant) != String(pattern.dominant), "Adjacent blocks must not repeat the exact configuration")
		previous_block = pattern
	_assert(saw_shape_circle and saw_shape_square, "Pattern history must exercise both dominant shapes")
	_assert(saw_cool_color and saw_warm_color, "Pattern history must exercise cool and warm color families")


func _test_feedback_tuning() -> void:
	_assert(GameConfig.TARGET_VISUAL_SCALE >= 1.16 and GameConfig.TARGET_VISUAL_SCALE <= 1.20, "Target collection scale must use the enlarged approved range")
	_assert(is_equal_approx(GameConfig.TARGET_COLLECTION_OVERLAP_START - float(GameConfig.MERGE_TIMELINE_TARGET.duration), 0.12), "Every target must hold at its merge position for 120 ms after merge feedback")
	_assert(GameConfig.MERGE_TIMELINE_TARGET.ring_layers == 5 and GameConfig.MERGE_TIMELINE_FINAL_TARGET.ring_layers == 5, "Target merges must use five dense layered rings")
	_assert(GameConfig.MERGE_TIMELINE_TARGET.ring_segments >= 48 and GameConfig.MERGE_TIMELINE_FINAL_TARGET.ring_segments >= 48, "Target rings must use dense circular tessellation")
	_assert(float(GameConfig.MERGE_TIMELINE_TARGET.ring_scale) > float(GameConfig.MERGE_TIMELINE_NORMAL.ring_scale), "Target wave must exceed the normal merge wave")
	_assert(GameConfig.LEVEL_REWARD_COIN_COUNT == GameConfig.COIN_BURST_COUNT, "Last-target visible coin quantity must match earlier target completions")
	_assert(GameConfig.TARGET_COIN_TABLE_HOLD >= 1.0 and GameConfig.LEVEL_REWARD_COIN_TABLE_HOLD >= 1.0, "All target coin groups must retain a readable table hold")
	_assert(GameConfig.TARGET_COIN_SHADOW_OPACITY <= 0.25 and GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY <= 0.25, "Table coins must use only light contact shadows")


func _test_hud_styles_have_no_box_shadows() -> void:
	var styles: Array[StyleBox] = [
		UiDesignSystemType.panel_style(), UiDesignSystemType.hud_content_style(), UiDesignSystemType.simple_hud_panel_style(),
		UiDesignSystemType.secondary_hud_panel_style(), UiDesignSystemType.hud_shell_style(), UiDesignSystemType.progression_inset_style(),
		UiDesignSystemType.card_header_style(), UiDesignSystemType.target_panel_style(), UiDesignSystemType.target_badge_style(),
		UiDesignSystemType.utility_frame_style(), UiDesignSystemType.setting_row_style(), UiDesignSystemType.progression_panel_style(),
	]
	for style in styles:
		if style is StyleBoxFancy:
			_assert(not style.shadow_enabled and style.shadow_color.a == 0.0 and style.shadow_blur == 0, "Fancy HUD styles must not draw box shadows")
		elif style is StyleBoxFlat:
			_assert(style.shadow_size == 0 and style.shadow_color.a == 0.0 and style.shadow_offset == Vector2.ZERO, "Flat HUD styles must not draw box shadows")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
