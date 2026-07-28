class_name ContactMergeService
extends RefCounted

var _candidates: Array[ContactPair] = []

func capture_contact(first: GemPiece, second: GemPiece) -> void:
	# Captured in the current simulation step before overlap separation.
	if first.id != second.id:
		_candidates.append(ContactPair.new(first.id, second.id))

func resolve(pieces: Array[GemPiece], next_id: int) -> Dictionary:
	return resolve_with_chains(pieces, next_id)

func resolve_with_chains(pieces: Array[GemPiece], next_id: int) -> Dictionary:
	var by_id: Dictionary = {}
	for piece in pieces:
		by_id[piece.id] = piece
	var working: Array[GemPiece] = pieces.duplicate()
	var id_cursor := next_id
	var presentation_events: Array[Dictionary] = []
	var candidates := _candidates.duplicate()
	_candidates.clear()
	var merge_count := 0
	var chain_depth := 0
	while not candidates.is_empty() and chain_depth < GameConfig.MERGE_CHAIN_DEPTH_CAP:
		var cycle := _resolve_cycle(working, candidates, id_cursor, chain_depth)
		working = cycle.pieces
		id_cursor = cycle.next_id
		merge_count += cycle.merge_count
		presentation_events.append_array(cycle.presentation_events)
		candidates = cycle.chain_contacts
		chain_depth += 1
	return {"pieces": working, "next_id": id_cursor, "merge_count": merge_count, "presentation_events": presentation_events, "chain_depth": max(0, chain_depth - 1)}

func _resolve_cycle(pieces: Array[GemPiece], candidates: Array[ContactPair], next_id: int, depth: int) -> Dictionary:
	var by_id: Dictionary = {}
	for piece in pieces:
		by_id[piece.id] = piece
	var consumed: Dictionary = {}
	var remove_ids: Dictionary = {}
	var spawned: Array[GemPiece] = []
	var events: Array[Dictionary] = []
	var seen_pairs: Dictionary = {}
	var id_cursor := next_id
	for candidate in candidates:
		if seen_pairs.has(candidate.key()): continue
		seen_pairs[candidate.key()] = true
		var first: GemPiece = by_id.get(candidate.first_id)
		var second: GemPiece = by_id.get(candidate.second_id)
		if first == null or second == null or consumed.has(first.id) or consumed.has(second.id): continue
		if first.level != second.level or first.level >= 5: continue
		if first.position.distance_to(second.position) > first.radius + second.radius + GameConfig.CONTACT_EPSILON: continue
		consumed[first.id] = true; consumed[second.id] = true
		remove_ids[first.id] = true; remove_ids[second.id] = true
		first.consumed = true; second.consumed = true
		var midpoint := (first.position + second.position) * 0.5
		var upgraded := GemPiece.new(id_cursor, first.level + 1, midpoint, first.radius)
		id_cursor += 1
		spawned.append(upgraded)
		events.append({"first_position": first.position, "second_position": second.position, "midpoint": midpoint, "level": upgraded.level, "depth": depth})
	var remaining: Array[GemPiece] = []
	for piece in pieces:
		if not remove_ids.has(piece.id): remaining.append(piece)
	remaining.append_array(spawned)
	# Chain candidates are local: only a just-created gem may contact an existing equal-level gem.
	var chain_contacts: Array[ContactPair] = []
	for upgraded in spawned:
		for other in remaining:
			if other.id == upgraded.id or other.level != upgraded.level: continue
			if upgraded.position.distance_to(other.position) <= upgraded.radius + other.radius + GameConfig.CONTACT_EPSILON:
				chain_contacts.append(ContactPair.new(upgraded.id, other.id))
	return {"pieces": remaining, "next_id": id_cursor, "merge_count": spawned.size(), "presentation_events": events, "chain_contacts": chain_contacts}

func clear() -> void:
	_candidates.clear()

func has_pending_candidates() -> bool:
	return not _candidates.is_empty()
