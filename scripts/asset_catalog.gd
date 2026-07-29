class_name AssetCatalog
extends RefCounted

## Presentation-only texture catalog. Simulation must never read these resources.
const TROPICAL_BACKGROUND: Texture2D = preload("res://assets/runtime/backgrounds/tropical_beach.png")
const CORAL_TABLE: Texture2D = preload("res://assets/runtime/table/coral_table_calibrated.png")
const PEARL: Texture2D = preload("res://assets/runtime/gems_calibrated/pearl.png")
const RUBY: Texture2D = preload("res://assets/runtime/gems_calibrated/ruby.png")
const EMERALD: Texture2D = preload("res://assets/runtime/gems_calibrated/emerald.png")
const SAPPHIRE: Texture2D = preload("res://assets/runtime/gems_calibrated/sapphire.png")
const DIAMOND_CLEAN: Texture2D = preload("res://assets/runtime/gems_calibrated/diamond.png")

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

static func visual_scale(_level: int) -> float:
	# Alpha-trimmed derivatives map their long visual axis directly to the
	# calibrated collision diameter; decorative transparent padding is excluded.
	return 1.0
