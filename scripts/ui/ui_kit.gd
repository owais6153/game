class_name UiKit
extends RefCounted

## Supplied-art UI kit. Every texture here is a trimmed runtime derivative of
## the artwork sheets in `assets/ui_kit_source/`; the originals are never loaded
## at runtime. This module owns only presentation resources — it must never be
## consulted by simulation, merge, launcher, or collision code.
##
## `NINE` records the nine-patch margins for the assets that are allowed to
## stretch. Assets absent from that table are fixed-composition art (a coin sits
## inside the plate, gems run along the bar) and must be drawn at their natural
## aspect ratio instead of being sliced.

const KIT := "res://assets/runtime/ui/kit/%s.png"

# Buttons
const BTN_HERO_BRIGHT := preload("res://assets/runtime/ui/kit/btn_hero_bright.png")
const BTN_HERO_DEEP := preload("res://assets/runtime/ui/kit/btn_hero_deep.png")
const BTN_PILL_PLAIN := preload("res://assets/runtime/ui/kit/btn_pill_plain.png")
const BTN_GREEN := preload("res://assets/runtime/ui/kit/btn_green.png")
const BTN_SQUARE_SMALL := preload("res://assets/runtime/ui/kit/btn_square_small.png")
const BTN_SQUARE_SWAP := preload("res://assets/runtime/ui/kit/btn_square_swap.png")
const BTN_PILL_GEM := preload("res://assets/runtime/ui/kit/btn_pill_gem.png")
const BTN_PILL_GEM_GLOW := preload("res://assets/runtime/ui/kit/btn_pill_gem_glow.png")
const BTN_PILL_SILVER := preload("res://assets/runtime/ui/kit/btn_pill_silver.png")

# Panels and frames
const BAR_GOLD_FRAME := preload("res://assets/runtime/ui/kit/bar_gold_frame.png")
const BANNER_LEAF := preload("res://assets/runtime/ui/kit/banner_leaf.png")
const CARD_LEAF_CTA := preload("res://assets/runtime/ui/kit/card_leaf_cta.png")
const PANEL_BANNER_SLOTS := preload("res://assets/runtime/ui/kit/panel_banner_slots.png")
const BAR_GEM_WIDE := preload("res://assets/runtime/ui/kit/bar_gem_wide.png")
const BAR_GEM_ROW := preload("res://assets/runtime/ui/kit/bar_gem_row.png")
const BAR_COIN_PROGRESS := preload("res://assets/runtime/ui/kit/bar_coin_progress.png")
const CHIP_COIN := preload("res://assets/runtime/ui/kit/chip_coin.png")
const TILE_COIN := preload("res://assets/runtime/ui/kit/tile_coin.png")

# Icons
const ICON_GEAR := preload("res://assets/runtime/ui/kit/icon_gear.png")
const ICON_GEAR_TILE := preload("res://assets/runtime/ui/kit/icon_gear_tile.png")
const ICON_PLUS := preload("res://assets/runtime/ui/kit/icon_plus.png")
const ICON_COIN := preload("res://assets/runtime/ui/kit/icon_coin.png")
const ICON_SWAP := preload("res://assets/runtime/ui/kit/icon_swap.png")
const ICON_CHECK := preload("res://assets/runtime/ui/kit/icon_check.png")
const ICON_STAR_COIN := preload("res://assets/runtime/ui/kit/icon_star_coin.png")
const ICON_SHIELD_STAR := preload("res://assets/runtime/ui/kit/icon_shield_star.png")
const ICON_SPARKLE := preload("res://assets/runtime/ui/kit/icon_sparkle.png")
const ICON_GEM_COUNT := preload("res://assets/runtime/ui/kit/icon_gem_count.png")

# Mission / reward badges
const BADGE_GEMS := preload("res://assets/runtime/ui/kit/badge_gems.png")
const BADGE_CROWN := preload("res://assets/runtime/ui/kit/badge_crown.png")
const BADGE_COINBAG := preload("res://assets/runtime/ui/kit/badge_coinbag.png")
const BADGE_CALENDAR := preload("res://assets/runtime/ui/kit/badge_calendar.png")
const BADGE_FLAME := preload("res://assets/runtime/ui/kit/badge_flame.png")
const BADGE_CHEST := preload("res://assets/runtime/ui/kit/badge_chest.png")
const BADGE_TIMER := preload("res://assets/runtime/ui/kit/badge_timer.png")
const BADGE_MEDAL := preload("res://assets/runtime/ui/kit/badge_medal.png")
const BADGE_CHECK_LAUREL := preload("res://assets/runtime/ui/kit/badge_check_laurel.png")


## Horizontal margins come from the silhouette: they end where the ornamental
## cap stops changing the plate's outline, because a cap must never stretch
## while the gloss gradient between them stretches cleanly.
##
## Vertical margins are ~half the plate height by design. These plates are a
## continuous bevel whose safely-stretchable band measured only 2-5px tall, so
## any vertical stretch smears the rim and specular highlight. Each plate is
## therefore authored at the exact height it is drawn at (see
## UiDesignSystem.BUTTON_HEIGHT and friends) and the vertical scale is 1.0.
## A control shorter than its plate will crush the caps — DRAWN_HEIGHT below is
## the contract, and run_ui_kit_polish_v1_tests enforces it.
const NINE := {
	"btn_hero_bright": [72, 56, 72, 56],
	"btn_hero_deep": [80, 56, 80, 56],
	"btn_pill_plain": [32, 46, 31, 46],
	"btn_green": [40, 46, 40, 46],
	"btn_green_off": [40, 46, 40, 46],
	"btn_square_small": [20, 36, 20, 36],
	"btn_square_swap": [72, 70, 72, 70],
	"btn_pill_gem": [54, 46, 48, 46],
	"btn_pill_gem_off": [54, 46, 48, 46],
	"btn_pill_gem_glow": [80, 34, 80, 34],
	"btn_pill_silver": [52, 46, 51, 46],
	"bar_gold_frame": [63, 44, 63, 44],
	"banner_leaf": [84, 44, 85, 44],
	"card_leaf_cta": [110, 100, 110, 100],
}

## Minimum height each plate may be drawn at, i.e. the sum of its vertical
## margins. Drawing shorter than this overlaps the caps and visibly crushes the
## plate; this is the exact defect that made buttons look stretched.
const DRAWN_HEIGHT := {
	"btn_hero_bright": 116, "btn_hero_deep": 116,
	"btn_pill_plain": 96, "btn_green": 96, "btn_green_off": 96,
	"btn_pill_gem": 96, "btn_pill_gem_off": 96, "btn_pill_silver": 96,
	"btn_square_small": 76, "bar_gold_frame": 92, "banner_leaf": 92,
}



static func badge(name: String) -> Texture2D:
	match name:
		"gems": return BADGE_GEMS
		"crown": return BADGE_CROWN
		"coinbag": return BADGE_COINBAG
		"calendar": return BADGE_CALENDAR
		"flame": return BADGE_FLAME
		"chest": return BADGE_CHEST
		"timer": return BADGE_TIMER
		"medal": return BADGE_MEDAL
		"check": return BADGE_CHECK_LAUREL
		_: return BADGE_GEMS


## Builds a stretchable StyleBoxTexture for one kit asset. `key` must be present
## in NINE; fixed-composition art has no correct slicing and is rejected loudly
## rather than silently smearing its artwork.
static func nine_patch_style(key: String, content: Vector4 = Vector4.ZERO, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var margins: Array = NINE.get(key, [])
	assert(not margins.is_empty(), "UiKit.nine_patch_style: '%s' has no nine-patch margins" % key)
	var style := StyleBoxTexture.new()
	style.texture = load(KIT % key)
	style.modulate_color = modulate
	style.set_texture_margin(SIDE_LEFT, float(margins[0]))
	style.set_texture_margin(SIDE_TOP, float(margins[1]))
	style.set_texture_margin(SIDE_RIGHT, float(margins[2]))
	style.set_texture_margin(SIDE_BOTTOM, float(margins[3]))
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	if content != Vector4.ZERO:
		style.content_margin_left = content.x
		style.content_margin_top = content.y
		style.content_margin_right = content.z
		style.content_margin_bottom = content.w
	return style


## Convenience for decorative art that must keep its own aspect ratio.
static func texture_rect(texture: Texture2D, height: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var aspect := float(texture.get_width()) / float(maxf(1.0, texture.get_height()))
	rect.custom_minimum_size = Vector2(height * aspect, height)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
