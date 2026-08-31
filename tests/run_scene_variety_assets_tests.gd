extends SceneTree

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_runtime_assets()
	_test_seeded_level_selection()
	if failures.is_empty():
		print("SCENE_VARIETY_ASSETS_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SCENE_VARIETY_ASSETS_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_runtime_assets() -> void:
	_assert(AssetCatalogType.LEVEL_BACKGROUNDS.size() == AssetCatalogType.BACKGROUND_COUNT, "Background catalog count must match its public bound")
	_assert(AssetCatalogType.LEVEL_TABLES.size() == AssetCatalogType.TABLE_COUNT, "Table catalog count must match its public bound")
	for index in range(AssetCatalogType.BACKGROUND_COUNT):
		var texture := AssetCatalogType.background_texture(index)
		_assert(texture != null, "Background %d must load" % index)
		if texture != null:
			_assert(texture.get_size() == Vector2(720.0, 1280.0), "Background %d must use the optimized 720x1280 runtime canvas" % index)
	for index in range(AssetCatalogType.TABLE_COUNT):
		var texture := AssetCatalogType.table_texture(index)
		_assert(texture != null, "Table %d must load" % index)
		if texture != null:
			_assert(texture.get_size() == Vector2(720.0, 1280.0), "Table %d must use the optimized full-composition 720x1280 runtime canvas" % index)
			# Scene art ships VRAM-compressed (ETC2/ASTC) so the ten tables and
			# ten backgrounds cost a few MB of texture memory instead of 70 MB.
			# A compressed Image cannot be sampled directly, so decompress the
			# CPU-side copy before reading the corner. This checks the shipped
			# texture, which is the one that matters.
			var table_image := texture.get_image()
			if table_image != null and table_image.is_compressed():
				_assert(table_image.decompress() == OK, "Table %d runtime texture must be decompressible for inspection" % index)
			_assert(table_image != null and table_image.get_pixel(0, 0).a <= 0.02, "Table %d must retain transparent outer corners" % index)
	_assert(AssetCatalogType.GEM_TIER_TEXTURES.size() == AssetCatalogType.GEM_IDENTITY_COUNT, "Every supplied gem identity must have one runtime derivative")
	AssetCatalogType.reset_active_level_mapping()
	for identity in range(1, AssetCatalogType.GEM_IDENTITY_COUNT + 1):
		var gem_texture := AssetCatalogType.GEM_TIER_TEXTURES.get(identity) as Texture2D
		_assert(gem_texture != null, "Gem %d must load" % identity)
		if gem_texture != null:
			var gem_image := gem_texture.get_image()
			var used_rect := gem_image.get_used_rect()
			_assert(gem_image.get_width() <= 256 and gem_image.get_height() <= 256, "Gem %d must use a bounded mobile runtime size" % identity)
			_assert(used_rect == Rect2i(Vector2i.ZERO, gem_image.get_size()), "Gem %d must be alpha-tight with no transparent border" % identity)
		_assert(AssetCatalogType.gem_name(identity).is_empty(), "Gem %d must not expose a player-facing name" % identity)
		_assert(String(AssetCatalogType.gem_entry(identity).get("name", "")).is_empty(), "Gem %d catalog entry must keep its display name empty" % identity)
	_assert(AssetCatalogType.background_texture(-1) == AssetCatalogType.background_texture(AssetCatalogType.BACKGROUND_COUNT - 1), "Background lookup must wrap safely")
	_assert(AssetCatalogType.table_texture(-1) == AssetCatalogType.table_texture(AssetCatalogType.TABLE_COUNT - 1), "Table lookup must wrap safely")


func _test_seeded_level_selection() -> void:
	var seen_backgrounds := {}
	var seen_tables := {}
	var seen_gem_identities := {}
	for level_number in range(1, 501):
		var seed_value := LevelConfigType.seed_for_level(level_number)
		var first := LevelConfigType.generated(level_number, seed_value)
		var retry := LevelConfigType.generated(level_number, seed_value)
		var background_index := int(first.get("background_index", -1))
		var table_index := int(first.get("table_index", -1))
		_assert(background_index >= 0 and background_index < AssetCatalogType.BACKGROUND_COUNT, "Level %d background must stay in catalog bounds" % level_number)
		_assert(table_index >= 0 and table_index < AssetCatalogType.TABLE_COUNT, "Level %d table must stay in catalog bounds" % level_number)
		_assert(background_index == int(retry.get("background_index", -2)), "Level %d retry must preserve its background" % level_number)
		_assert(table_index == int(retry.get("table_index", -2)), "Level %d retry must preserve its table" % level_number)
		seen_backgrounds[background_index] = true
		seen_tables[table_index] = true
		for identity in (first.get("gem_identity_by_tier", {}) as Dictionary).values():
			seen_gem_identities[int(identity)] = true
	_assert(seen_backgrounds.size() == AssetCatalogType.BACKGROUND_COUNT, "Generated levels must exercise every supplied background")
	_assert(seen_tables.size() == AssetCatalogType.TABLE_COUNT, "Generated levels must exercise every supplied table")
	_assert(seen_gem_identities.size() == AssetCatalogType.GEM_IDENTITY_COUNT, "Generated levels must exercise every supplied gem identity")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
