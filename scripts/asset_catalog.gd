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
const GEM_TIER_TEXTURES := {
	1: preload("res://assets/runtime/gems18/calibrated/tier_01.png"),
	2: preload("res://assets/runtime/gems18/calibrated/tier_02.png"),
	3: preload("res://assets/runtime/gems18/calibrated/tier_03.png"),
	4: preload("res://assets/runtime/gems18/calibrated/tier_04.png"),
	5: preload("res://assets/runtime/gems18/calibrated/tier_05.png"),
	6: preload("res://assets/runtime/gems18/calibrated/tier_06.png"),
	7: preload("res://assets/runtime/gems18/calibrated/tier_07.png"),
	8: preload("res://assets/runtime/gems18/calibrated/tier_08.png"),
	9: preload("res://assets/runtime/gems18/calibrated/tier_09.png"),
	10: preload("res://assets/runtime/gems18/calibrated/tier_10.png"),
	11: preload("res://assets/runtime/gems18/calibrated/tier_11.png"),
	12: preload("res://assets/runtime/gems18/calibrated/tier_12.png"),
	13: preload("res://assets/runtime/gems18/calibrated/tier_13.png"),
	14: preload("res://assets/runtime/gems18/calibrated/tier_14.png"),
	15: preload("res://assets/runtime/gems18/calibrated/tier_15.png"),
	16: preload("res://assets/runtime/gems18/calibrated/tier_16.png"),
	17: preload("res://assets/runtime/gems18/calibrated/tier_17.png"),
	18: preload("res://assets/runtime/gems18/calibrated/tier_18.png"),
}

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
