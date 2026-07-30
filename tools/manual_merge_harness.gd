## Development-only command-line merge harness. It is not referenced by scenes,
## export presets, or runtime input. Example:
## Godot --headless --path D:\Owais\game --script res://tools/manual_merge_harness.gd -- --level=14 --chain=4
extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const MergeType = preload("res://scripts/merge_service.gd")

func _init() -> void:
	var level := 1
	var chain_depth := 1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			level = clampi(argument.trim_prefix("--level=").to_int(), 1, GameConfig.MAX_GEM_LEVEL)
		elif argument.begins_with("--chain="):
			chain_depth = clampi(argument.trim_prefix("--chain=").to_int(), 1, 4)
	if level >= GameConfig.MAX_GEM_LEVEL:
		print("MANUAL_MERGE_HARNESS: L18 is terminal; no merge created")
		quit(0)
		return
	var radius := GameConfig.gem_collision_radius(level)
	var first := GemPieceType.new(1, level, Vector2(300, 500), radius)
	var second := GemPieceType.new(2, level, Vector2(300 + radius * 2.0, 500), radius)
	var merger := MergeType.new()
	merger.capture_contact(first, second)
	var result: Dictionary = merger.resolve([first, second], 100)
	var first_result: GemPiece = result.get("pieces")[0]
	var current_level: int = first_result.level
	for depth in range(1, chain_depth):
		if current_level >= GameConfig.MAX_GEM_LEVEL:
			break
		var current: GemPiece = result.get("pieces")[0]
		var partner := GemPieceType.new(100 + depth, current_level, current.position + Vector2(current.radius + GameConfig.gem_collision_radius(current_level), 0), GameConfig.gem_collision_radius(current_level))
		merger.capture_contact(current, partner)
		result = merger.resolve([current, partner], result.next_id)
		var upgraded: GemPiece = result.get("pieces")[0]
		current_level = upgraded.level
	print("MANUAL_MERGE_HARNESS: L%d chain=%d result=L%d events=%d" % [level, chain_depth, current_level, (result.get("presentation_events") as Array).size()])
	quit(0)
