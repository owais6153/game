class_name HudRenderer
extends RefCounted

## Retired compatibility type. The production controller has no reference to
## this immediate-mode renderer; `GameplayHudLayer` owns the responsive Control
## tree, supplied skins, contain-scaled gems, settings input, and pause popup.
static func draw(_controller: CanvasItem, _snapshot: Dictionary, _font: Font) -> void:
	pass
