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

static func gem_texture(level: int) -> Texture2D:
	if level >= 1 and level <= GameConfig.MAX_GEM_LEVEL:
		var texture := load("res://assets/runtime/gems18/tier_%02d.png" % level) as Texture2D
		if texture != null:
			return texture
	# The fallback preserves the restored baseline if a developer opens the
	# project before Godot has imported a newly added runtime derivative.
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
