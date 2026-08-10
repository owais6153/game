class_name AssetCatalog
extends RefCounted

## Presentation-only texture catalog. Simulation must never read these resources.
const LEVEL_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/runtime/backgrounds/level_bg_1.png"),
	preload("res://assets/runtime/backgrounds/level_bg_2.png"),
	preload("res://assets/runtime/backgrounds/level_bg_3.png"),
	preload("res://assets/runtime/backgrounds/level_bg_4.png"),
	preload("res://assets/runtime/backgrounds/level_bg_5.png"),
]
const NEW_TABLE: Texture2D = preload("res://assets/runtime/table/new_table_v1.png")
const GEM_SOFT_SHADOW: Texture2D = preload("res://assets/runtime/effects/gem_soft_shadow.png")
## Cropped mobile derivative of the supplied glossy coin artwork. The original
## remains untouched under assets/buttons and this texture is presentation-only.
const COIN_REWARD: Texture2D = preload("res://assets/runtime/effects/coin_reward_reference_v2.png")
const BRAND_LOGO: Texture2D = preload("res://assets/runtime/ui/majestic_gems_logo_v1.png")
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

## All gameplay textures are preloaded once. `gem_texture()` is called from the
## per-frame sprite synchronization path, so it must be a dictionary lookup,
## never a `load()` call. The source PNGs remain under assets/gems; these are
## the mobile-sized runtime derivatives.
## Final deterministic visual progression. Values are immutable source-asset
## indices, not gameplay levels: all calibrated per-asset body/shadow settings
## remain attached to the same artwork after the catalog reorder.
const GEM_TIER_SOURCE_INDEX := {
	# Authoritative user-approved L1-L18 order. These source indices and the
	# matching runtime textures must move together; labels never infer identity
	# from the tier alone.
	1: 16, 2: 4, 3: 5, 4: 8, 5: 2, 6: 7, 7: 1, 8: 3, 9: 11,
	10: 9, 11: 6, 12: 10, 13: 14, 14: 15, 15: 18, 16: 12, 17: 13, 18: 17,
}

const GEM_TIER_TEXTURES := {
	1: preload("res://assets/runtime/gems18/calibrated/tier_16.png"),
	2: preload("res://assets/runtime/gems18/calibrated/tier_04.png"),
	3: preload("res://assets/runtime/gems18/calibrated/tier_05.png"),
	4: preload("res://assets/runtime/gems18/calibrated/tier_08.png"),
	5: preload("res://assets/runtime/gems18/calibrated/tier_02.png"),
	6: preload("res://assets/runtime/gems18/calibrated/tier_07.png"),
	7: preload("res://assets/runtime/gems18/calibrated/tier_01.png"),
	8: preload("res://assets/runtime/gems18/calibrated/tier_03.png"),
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
static var active_gem_identity_by_tier: Dictionary = {}

static func set_active_level_mapping(mapping: Dictionary) -> void:
	active_gem_identity_by_tier = mapping.duplicate(true)

static func reset_active_level_mapping() -> void:
	active_gem_identity_by_tier.clear()

static func identity_for_local_tier(level: int) -> int:
	return int(active_gem_identity_by_tier.get(level, level))

static func background_texture(index: int) -> Texture2D:
	return LEVEL_BACKGROUNDS[posmod(index, LEVEL_BACKGROUNDS.size())]

static func gem_entry(level: int) -> Dictionary:
	var identity := identity_for_local_tier(level)
	return {"tier": level, "identity": identity, "id": String(GEM_IDS.get(identity, "unknown")), "name": String(GEM_DISPLAY_NAMES.get(identity, "Unknown")), "texture": gem_texture(level), "texture_path": gem_resource_path(level), "collision_radius": GameConfig.gem_collision_radius(level), "visual_scale": visual_scale(level)}

static func gem_name(level: int) -> String:
	return String(GEM_DISPLAY_NAMES.get(identity_for_local_tier(level), "Unknown"))

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
