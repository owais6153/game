class_name ContactPair
extends RefCounted

var first_id: int
var second_id: int

func _init(a_id: int, b_id: int) -> void:
	first_id = min(a_id, b_id)
	second_id = max(a_id, b_id)

func key() -> String:
	return "%d:%d" % [first_id, second_id]