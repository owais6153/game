class_name AssetCatalog
extends RefCounted

## Presentation-only texture catalog. Simulation must never read these resources.
const TROPICAL_BACKGROUND: Texture2D = preload("res://assets/runtime/backgrounds/tropical_beach.png")
const NEW_TABLE: Texture2D = preload("res://assets/runtime/table/new_table_v1.png")
const PEARL: Texture2D = preload("res://assets/runtime/gems_body_v2/pearl.png")
const RUBY: Texture2D = preload("res://assets/runtime/gems_body_v2/ruby.png")
const EMERALD: Texture2D = preload("res://assets/runtime/gems_body_v2/emerald.png")
const SAPPHIRE: Texture2D = preload("res://assets/runtime/gems_body_v2/sapphire.png")
const DIAMOND_CLEAN: Texture2D = preload("res://assets/runtime/gems_body_v2/diamond.png")
const GEM_SOFT_SHADOW: Texture2D = preload("res://assets/runtime/effects/gem_soft_shadow.png")

## All gameplay textures are preloaded once. `gem_texture()` is called from the
## per-frame sprite synchronization path, so it must be a dictionary lookup,
## never a `load()` call. The source PNGs remain under assets/gems; these are
## the mobile-sized runtime derivatives.
## Final deterministic visual progression. Values are immutable source-asset
## indices, not gameplay levels: all calibrated per-asset body/shadow settings
## remain attached to the same artwork after the catalog reorder.
const GEM_TIER_SOURCE_INDEX := {
	# L1-L8 deliberately alternate oval, horizontal, cushion, pear, round,
	# square, slender, and diamond-like supplied silhouettes.
	1: 2, 2: 7, 3: 4, 4: 8, 5: 1, 6: 3, 7: 5, 8: 16, 9: 11,
	10: 9, 11: 6, 12: 10, 13: 14, 14: 15, 15: 18, 16: 12, 17: 13, 18: 17,
}

const GEM_TIER_TEXTURES := {
	1: preload("res://assets/runtime/gems18/calibrated/tier_02.png"),
	2: preload("res://assets/runtime/gems18/calibrated/tier_07.png"),
	3: preload("res://assets/runtime/gems18/calibrated/tier_04.png"),
	4: preload("res://assets/runtime/gems18/calibrated/tier_08.png"),
	5: preload("res://assets/runtime/gems18/calibrated/tier_01.png"),
	6: preload("res://assets/runtime/gems18/calibrated/tier_03.png"),
	7: preload("res://assets/runtime/gems18/calibrated/tier_05.png"),
	8: preload("res://assets/runtime/gems18/calibrated/tier_16.png"),
	9: preload("res://assets/runtime/gems18/calibrated/tier_11.png"),
	10: preload("res://assets/runtime/gems18/calibrated/tier_09.png"),
	11: preload("res://assets/runtime/gems18/calibrated/tier_06.png"),
	12: preload("res://assets/runtime/gems18/calibrated/tier_10.png"),
	13: preload("res://assets/runtime/gems18/calibrated/tier_14.png"),
	14: preload("res://assets/runtime/gems18/calibrated/tier_15.png"),
	15: preload("res://assets/runtime/gems18/calibrated/tier_18.png"),
	16: preload("res://assets/runtime/gems18/calibrated/tier_12.png"),
	17: preload("res://assets/runtime/gems18/calibrated/tier_13.png"),
	18: preload("res://assets/runtime/gems18/calibrated/tier_17.png"),
}

## The one presentation identity mapping for all gameplay tiers. UI labels,
## icons, launcher gems, targets, and merge results must resolve through it.
const GEM_IDS := {1: "pearl", 2: "obsidian", 3: "jade", 4: "aquamarine", 5: "peridot", 6: "pink_tourmaline", 7: "ruby", 8: "sapphire", 9: "emerald", 10: "watermelon_tourmaline", 11: "morganite", 12: "garnet", 13: "amethyst", 14: "citrine", 15: "orange_sapphire", 16: "royal_sapphire", 17: "diamond", 18: "blue_diamond"}
const GEM_DISPLAY_NAMES := {1: "Pearl", 2: "Obsidian", 3: "Jade", 4: "Aquamarine", 5: "Peridot", 6: "Pink Tourmaline", 7: "Ruby", 8: "Sapphire", 9: "Emerald", 10: "Watermelon Tourmaline", 11: "Morganite", 12: "Garnet", 13: "Amethyst", 14: "Citrine", 15: "Orange Sapphire", 16: "Royal Sapphire", 17: "Diamond", 18: "Blue Diamond"}

static func gem_entry(level: int) -> Dictionary:
	return {"tier": level, "id": String(GEM_IDS.get(level, "unknown")), "name": String(GEM_DISPLAY_NAMES.get(level, "Unknown")), "texture": gem_texture(level), "texture_path": gem_resource_path(level), "collision_radius": GameConfig.gem_collision_radius(level), "visual_scale": visual_scale(level)}

static func gem_name(level: int) -> String:
	return String(GEM_DISPLAY_NAMES.get(level, "Unknown"))

static func gem_texture(level: int) -> Texture2D:
	var cached := GEM_TIER_TEXTURES.get(level) as Texture2D
	if cached != null:
		return cached
	match level:
		1: return PEARL
		2: return RUBY
		3: return EMERALD
		4: return SAPPHIRE
		5: return DIAMOND_CLEAN
		_: return PEARL

static func gem_resource_path(level: int) -> String:
	return gem_texture(level).resource_path

static func shadow_resource_path() -> String:
	return GEM_SOFT_SHADOW.resource_path

static func visual_scale(_level: int) -> float:
	# Alpha-trimmed derivatives map their long visual axis directly to the
	# calibrated collision diameter; decorative transparent padding is excluded.
	return 1.0
