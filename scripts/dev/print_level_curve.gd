extends SceneTree

## Prints the generated difficulty curve so balance changes can be reviewed as
## data rather than guessed at. Developer aid only; nothing loads it at runtime.

const L = preload("res://scripts/core/level_config.gd")

func _init() -> void:
	print("lvl | type    | shots | gems | targets  | total | shots/gem")
	for n in range(1, 31):
		var c := L.generated(n, L.seed_for_level(n))
		var board: Array = c.get("starting_board", []) as Array
		var quantities := PackedStringArray()
		for entry in (c.get("target_sequence", []) as Array):
			quantities.append(str(int((entry as Dictionary).get("quantity", 1))))
		var total := L.total_target_quantity(n)
		var limit := int(c.get("shot_limit", 0))
		var ratio := "-" if limit <= 0 else "%.1f" % (float(limit) / float(maxi(1, total)))
		print("%3d | %-7s | %5s | %4d | %-8s | %5d | %s" % [
			n,
			"LIMITED" if L.is_limited_shots_level(n) else "normal",
			str(limit) if limit > 0 else "-",
			board.size(),
			"/".join(quantities),
			total,
			ratio,
		])
	quit(0)
