class_name AssetCatalog
extends RefCounted

## Presentation-only texture catalog. Simulation must never read these resources.
const LEVEL_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/runtime/backgrounds/scene_bg_01.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_02.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_03.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_04.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_05.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_06.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_07.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_08.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_09.webp"),
	preload("res://assets/runtime/backgrounds/scene_bg_10.webp"),
]
const LEVEL_TABLES: Array[Texture2D] = [
	preload("res://assets/runtime/tables/table_01.webp"),
	preload("res://assets/runtime/tables/table_02.webp"),
	preload("res://assets/runtime/tables/table_03.webp"),
	preload("res://assets/runtime/tables/table_04.webp"),
	preload("res://assets/runtime/tables/table_05.webp"),
	preload("res://assets/runtime/tables/table_06.webp"),
	preload("res://assets/runtime/tables/table_07.webp"),
	preload("res://assets/runtime/tables/table_08.webp"),
	preload("res://assets/runtime/tables/table_09.webp"),
	preload("res://assets/runtime/tables/table_10.webp"),
]
const BACKGROUND_COUNT := 10
const TABLE_COUNT := 10
const GEM_IDENTITY_COUNT := 34
const GEM_SOFT_SHADOW: Texture2D = preload("res://assets/runtime/effects/gem_soft_shadow.png")
## Cropped mobile derivative of the supplied glossy coin artwork. The original
## remains untouched under assets/buttons and this texture is presentation-only.
const COIN_REWARD: Texture2D = preload("res://assets/runtime/effects/coin_reward_reference_v2.png")
const BRAND_LOGO: Texture2D = preload("res://assets/runtime/ui/majestic_gems_logo_v4.png")
const HUD_SCORE_PANEL_REGION := Rect2(632.0, 358.0, 360.0, 232.0)
const HUD_NEXT_PANEL_REGION := Rect2(632.0, 610.0, 360.0, 400.0)
const HUD_WHITE_PANEL_REGION := Rect2(38.0, 620.0, 550.0, 190.0)
const HUD_GOAL_HEADER_REGION := Rect2(46.0, 428.0, 530.0, 142.0)
const HUD_GOAL_BODY_REGION := Rect2(646.0, 448.0, 340.0, 136.0)
## The teal cog is the only gameplay-HUD control. Its source remains the
## supplied button sheet; no procedural control artwork is introduced.
const HUD_SETTINGS_BUTTON_REGION := Rect2(276.0, 832.0, 180.0, 180.0)
## Literal supplied RESTART control from the pause artwork. The source contains
## no circular restart/refresh icon; arrow regions are BACK and must not be used.
const HUD_RESTART_BUTTON_REGION := Rect2(321.0, 1128.0, 300.0, 100.0)

## All gameplay textures are preloaded once. The supplied originals remain in
## assets/gems; runtime files are alpha-tight, mobile-sized derivatives.
const GEM_TIER_TEXTURES := {
	1: preload("res://assets/runtime/gems/gem_01.png"),
	2: preload("res://assets/runtime/gems/gem_02.png"),
	3: preload("res://assets/runtime/gems/gem_03.png"),
	4: preload("res://assets/runtime/gems/gem_04.png"),
	5: preload("res://assets/runtime/gems/gem_05.png"),
	6: preload("res://assets/runtime/gems/gem_06.png"),
	7: preload("res://assets/runtime/gems/gem_07.png"),
	8: preload("res://assets/runtime/gems/gem_08.png"),
	9: preload("res://assets/runtime/gems/gem_09.png"),
	10: preload("res://assets/runtime/gems/gem_10.png"),
	11: preload("res://assets/runtime/gems/gem_11.png"),
	12: preload("res://assets/runtime/gems/gem_12.png"),
	13: preload("res://assets/runtime/gems/gem_13.png"),
	14: preload("res://assets/runtime/gems/gem_14.png"),
	15: preload("res://assets/runtime/gems/gem_15.png"),
	16: preload("res://assets/runtime/gems/gem_16.png"),
	17: preload("res://assets/runtime/gems/gem_17.png"),
	18: preload("res://assets/runtime/gems/gem_18.png"),
	19: preload("res://assets/runtime/gems/gem_19.png"),
	20: preload("res://assets/runtime/gems/gem_20.png"),
	21: preload("res://assets/runtime/gems/gem_21.png"),
	22: preload("res://assets/runtime/gems/gem_22.png"),
	23: preload("res://assets/runtime/gems/gem_23.png"),
	24: preload("res://assets/runtime/gems/gem_24.png"),
	25: preload("res://assets/runtime/gems/gem_25.png"),
	26: preload("res://assets/runtime/gems/gem_26.png"),
	27: preload("res://assets/runtime/gems/gem_27.png"),
	28: preload("res://assets/runtime/gems/gem_28.png"),
	29: preload("res://assets/runtime/gems/gem_29.png"),
	30: preload("res://assets/runtime/gems/gem_30.png"),
	31: preload("res://assets/runtime/gems/gem_31.png"),
	32: preload("res://assets/runtime/gems/gem_32.png"),
	33: preload("res://assets/runtime/gems/gem_33.png"),
	34: preload("res://assets/runtime/gems/gem_34.png"),
}

## Internal IDs are intentionally generic. Player-facing gem names are not part
## of the product UI; artwork alone communicates identity.
const GEM_IDS := {
	1: "gem_01", 2: "gem_02", 3: "gem_03", 4: "gem_04", 5: "gem_05",
	6: "gem_06", 7: "gem_07", 8: "gem_08", 9: "gem_09", 10: "gem_10",
	11: "gem_11", 12: "gem_12", 13: "gem_13", 14: "gem_14", 15: "gem_15",
	16: "gem_16", 17: "gem_17", 18: "gem_18", 19: "gem_19", 20: "gem_20",
	21: "gem_21", 22: "gem_22", 23: "gem_23", 24: "gem_24", 25: "gem_25",
	26: "gem_26", 27: "gem_27", 28: "gem_28", 29: "gem_29", 30: "gem_30",
	31: "gem_31", 32: "gem_32", 33: "gem_33", 34: "gem_34",
}

## One audited metadata registry for every supplied gem. Categories describe
## only visible properties present in the artwork: circle/rounded_square shape,
## a practical color family, solid/gradient color treatment, and common/unique
## gameplay rarity. Display names intentionally do not exist.
const GEM_DEFINITIONS := {
	1: {"shape": "circle", "color_family": "pink", "color_style": "solid", "rarity": "common"},
	2: {"shape": "circle", "color_family": "blue", "color_style": "solid", "rarity": "common"},
	3: {"shape": "circle", "color_family": "pink", "color_style": "solid", "rarity": "common"},
	4: {"shape": "circle", "color_family": "red", "color_style": "solid", "rarity": "common"},
	5: {"shape": "circle", "color_family": "green", "color_style": "solid", "rarity": "common"},
	6: {"shape": "rounded_square", "color_family": "yellow", "color_style": "solid", "rarity": "common"},
	7: {"shape": "rounded_square", "color_family": "purple", "color_style": "solid", "rarity": "common"},
	8: {"shape": "circle", "color_family": "blue", "color_style": "solid", "rarity": "common"},
	9: {"shape": "rounded_square", "color_family": "pink", "color_style": "solid", "rarity": "common"},
	10: {"shape": "rounded_square", "color_family": "blue", "color_style": "solid", "rarity": "common"},
	11: {"shape": "circle", "color_family": "orange", "color_style": "solid", "rarity": "common"},
	12: {"shape": "circle", "color_family": "blue", "color_style": "solid", "rarity": "common"},
	13: {"shape": "circle", "color_family": "yellow", "color_style": "solid", "rarity": "common"},
	14: {"shape": "circle", "color_family": "purple", "color_style": "solid", "rarity": "common"},
	15: {"shape": "circle", "color_family": "red", "color_style": "solid", "rarity": "common"},
	16: {"shape": "rounded_square", "color_family": "green", "color_style": "solid", "rarity": "common"},
	17: {"shape": "rounded_square", "color_family": "orange", "color_style": "solid", "rarity": "common"},
	18: {"shape": "rounded_square", "color_family": "blue", "color_style": "solid", "rarity": "common"},
	19: {"shape": "rounded_square", "color_family": "pink", "color_style": "solid", "rarity": "common"},
	20: {"shape": "rounded_square", "color_family": "purple", "color_style": "solid", "rarity": "common"},
	21: {"shape": "circle", "color_family": "blue", "color_style": "gradient", "rarity": "unique"},
	22: {"shape": "circle", "color_family": "pink", "color_style": "gradient", "rarity": "unique"},
	23: {"shape": "circle", "color_family": "green", "color_style": "gradient", "rarity": "unique"},
	24: {"shape": "rounded_square", "color_family": "blue", "color_style": "gradient", "rarity": "unique"},
	25: {"shape": "rounded_square", "color_family": "blue", "color_style": "gradient", "rarity": "unique"},
	26: {"shape": "rounded_square", "color_family": "red", "color_style": "solid", "rarity": "common"},
	27: {"shape": "circle", "color_family": "orange", "color_style": "gradient", "rarity": "unique"},
	28: {"shape": "circle", "color_family": "purple", "color_style": "gradient", "rarity": "unique"},
	29: {"shape": "circle", "color_family": "orange", "color_style": "gradient", "rarity": "common"},
	30: {"shape": "rounded_square", "color_family": "blue", "color_style": "gradient", "rarity": "unique"},
	31: {"shape": "rounded_square", "color_family": "pink", "color_style": "gradient", "rarity": "unique"},
	32: {"shape": "rounded_square", "color_family": "green", "color_style": "gradient", "rarity": "unique"},
	33: {"shape": "circle", "color_family": "pink", "color_style": "gradient", "rarity": "unique"},
	34: {"shape": "rounded_square", "color_family": "pink", "color_style": "gradient", "rarity": "unique"},
}
static var active_gem_identity_by_tier: Dictionary = {}

static func set_active_level_mapping(mapping: Dictionary) -> void:
	active_gem_identity_by_tier = mapping.duplicate(true)

static func reset_active_level_mapping() -> void:
	active_gem_identity_by_tier.clear()

static func identity_for_local_tier(level: int) -> int:
	return int(active_gem_identity_by_tier.get(level, level))

static func background_texture(index: int) -> Texture2D:
	return LEVEL_BACKGROUNDS[posmod(index, LEVEL_BACKGROUNDS.size())]

static func table_texture(index: int) -> Texture2D:
	return LEVEL_TABLES[posmod(index, LEVEL_TABLES.size())]

static func gem_entry(level: int) -> Dictionary:
	var identity := identity_for_local_tier(level)
	var definition := gem_definition(identity)
	return {"tier": level, "identity": identity, "id": String(GEM_IDS.get(identity, "gem_unknown")), "name": "", "texture": gem_texture(level), "texture_path": gem_resource_path(level), "shape": String(definition.get("shape", "circle")), "color_family": String(definition.get("color_family", "blue")), "color_style": String(definition.get("color_style", "solid")), "rarity": String(definition.get("rarity", "common")), "collision_profile": "stable_local_tier", "collision_radius": GameConfig.gem_collision_radius(level), "visual_scale": visual_scale(level)}

static func gem_definition(identity: int) -> Dictionary:
	var definition: Dictionary = GEM_DEFINITIONS.get(identity, {})
	return definition.duplicate(true)

static func get_gems(shape: String = "", color_family: String = "", color_style: String = "", rarity: String = "", excluding_color: String = "") -> Array[int]:
	var matches: Array[int] = []
	for identity in range(1, GEM_IDENTITY_COUNT + 1):
		var definition: Dictionary = GEM_DEFINITIONS.get(identity, {})
		if not shape.is_empty() and String(definition.get("shape", "")) != shape:
			continue
		if not color_family.is_empty() and String(definition.get("color_family", "")) != color_family:
			continue
		if not color_style.is_empty() and String(definition.get("color_style", "")) != color_style:
			continue
		if not rarity.is_empty() and String(definition.get("rarity", "")) != rarity:
			continue
		if not excluding_color.is_empty() and String(definition.get("color_family", "")) == excluding_color:
			continue
		matches.append(identity)
	return matches

static func get_common_gems(shape: String = "", color_family: String = "") -> Array[int]:
	return get_gems(shape, color_family, "", "common")

static func get_unique_gems(shape: String = "", color_family: String = "", excluding_color: String = "") -> Array[int]:
	return get_gems(shape, color_family, "", "unique", excluding_color)

static func gem_name(_level: int) -> String:
	return ""

static func gem_texture(level: int) -> Texture2D:
	var identity := identity_for_local_tier(level)
	var cached := GEM_TIER_TEXTURES.get(identity) as Texture2D
	if cached != null:
		return cached
	return GEM_TIER_TEXTURES[1]

static func gem_resource_path(level: int) -> String:
	return gem_texture(level).resource_path

static func shadow_resource_path() -> String:
	return GEM_SOFT_SHADOW.resource_path

static func visual_scale(_level: int) -> float:
	# Alpha-trimmed derivatives map their long visual axis directly to the
	# calibrated collision diameter; decorative transparent padding is excluded.
	return 1.0
