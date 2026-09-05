extends SceneTree

## Composites the adaptive icon layers and applies the three launcher mask
## shapes Android devices actually use, so the crop can be judged here rather
## than discovered on a handset. The icon is full-bleed artwork, so what this
## proves is that the wordmark clears the inscribed circle.
##
## Run: godot --headless --path . --script scripts/dev/preview_adaptive_icon_masks.gd
func _init():
	var bg := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/ui/majestic_gems_adaptive_background_v6.png"))
	var fg := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/ui/majestic_gems_adaptive_foreground_v6.png"))
	bg.convert(Image.FORMAT_RGBA8); fg.convert(Image.FORMAT_RGBA8)
	var flat := bg.duplicate() as Image
	flat.blend_rect(fg, Rect2i(Vector2i.ZERO, fg.get_size()), Vector2i.ZERO)
	var n := 432
	var sheet := Image.create_empty(n * 3 + 40, n, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.10, 0.12, 1.0))
	var shapes := ["circle", "squircle", "rounded"]
	for i in range(3):
		var m := flat.duplicate() as Image
		for y in range(n):
			for x in range(n):
				var p := Vector2(x - n / 2.0, y - n / 2.0)
				var keep := true
				match shapes[i]:
					"circle": keep = p.length() <= n * 0.5
					"squircle": keep = pow(absf(p.x) / (n * 0.5), 3.0) + pow(absf(p.y) / (n * 0.5), 3.0) <= 1.0
					"rounded": keep = absf(p.x) <= n * 0.46 and absf(p.y) <= n * 0.46
				if not keep:
					m.set_pixel(x, y, Color(0, 0, 0, 0))
		sheet.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), Vector2i(i * (n + 20), 0))
	sheet.save_png(ProjectSettings.globalize_path("res://reports/brand-refresh-v6/adaptive-masks.png"))
	print("MASK OK")
	quit(0)
