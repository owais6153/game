class_name ContactMergeService
extends RefCounted

var _candidates: Array[ContactPair] = []

func capture_contact(first: GemPiece, second: GemPiece) -> void:
	# Captured in the current simulation step before overlap separation.
	if first.id != second.id:
		_candidates.append(ContactPair.new(first.id, second.id))

func resolve(pieces: Array[GemPiece], next_id: int) -> Dictionary:
	var by_id: Dictionary = {}
	for piece in pieces:
		by_id[piece.id] = piece
	var consumed: Dictionary = {}
	var remove_ids: Dictionary = {}
	var spawned: Array[GemPiece] = []
	var seen_pairs: Dictionary = {}
	var id_cursor := next_id
	for candidate in _candidates:
		if seen_pairs.has(candidate.key()):
			continue
		seen_pairs[candidate.key()] = true
		var first: GemPiece = by_id.get(candidate.first_id)
		var second: GemPiece = by_id.get(candidate.second_id)
		if first == null or second == null or first.id == second.id:
			continue
		if consumed.has(first.id) or consumed.has(second.id) or first.level != second.level or first.level >= 5:
			continue
		if first.position.distance_to(second.position) > first.radius + second.radius + GameConfig.CONTACT_EPSILON:
			continue
		# Mark before spawning: one source may merge only once this cycle.
		consumed[first.id] = true
		consumed[second.id] = true
		remove_ids[first.id] = true
		remove_ids[second.id] = true
		first.consumed = true
		second.consumed = true
		var upgraded := GemPiece.new(id_cursor, first.level + 1, (first.position + second.position) * 0.5, first.radius)
		id_cursor += 1
		spawned.append(upgraded)
	_candidates.clear()
	var remaining: Array[GemPiece] = []
	for piece in pieces:
		if not remove_ids.has(piece.id):
			remaining.append(piece)
	remaining.append_array(spawned)
	return {"pieces": remaining, "next_id": id_cursor, "merge_count": spawned.size()}

func clear() -> void:
	_candidates.clear()