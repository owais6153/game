class_name AssetCatalog
extends RefCounted

## Presentation-only texture catalog. Simulation must never read these resources.
const TROPICAL_BACKGROUND: Texture2D = preload("res://assets/runtime/backgrounds/tropical_beach.png")
const CORAL_TABLE: Texture2D = preload("res://assets/runtime/table/coral_table.png")
const PEARL: Texture2D = preload("res://assets/runtime/gems/pearl.png")
const RUBY: Texture2D = preload("res://assets/runtime/gems/ruby.png")
const EMERALD: Texture2D = preload("res://assets/runtime/gems/emerald.png")
const SAPPHIRE: Texture2D = preload("res://assets/runtime/gems/sapphire.png")
const DIAMOND_CLEAN: Texture2D = preload("res://assets/runtime/gems/diamond.png")

static func gem_texture(level: int) -> Texture2D:

	match level:
		1: return PEARL
		2: return RUBY
		3: return EMERALD
		4: return SAPPHIRE
		5: return DIAMOND_CLEAN
		_: return PEARL

static func gem_resource_path(level: int) -> String:
	return gem_texture(level).resource_path

static func visual_scale(level: int) -> float:
	# These values only normalize the supplied art's apparent size around the
	# unchanged circular gameplay radius. They are never collision dimensions.
	match level:
		1: return 0.90
		2: return 0.96
		3: return 0.94
		4: return 0.96
		5: return 0.98
		_: return 0.90
