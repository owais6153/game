class_name LevelRecordService
extends RefCounted

## Per-level snapshots, written the first time a level is entered and applied
## every time it is entered again.
##
## ## Why this exists when generation is already deterministic
##
## `LevelConfig.generated(n, seed_for_level(n))` is a pure function, so replaying
## level 9 today rebuilds exactly the level that was played - same gems, same
## opening board, same queue, same background. That is asserted directly in
## `run_level_select_map_v1_tests` and is not in doubt.
##
## What it is pure *with respect to* is the generator, and the generator is
## ours. Retuning a template, adding a gem to the catalog, changing a layout
## archetype or bumping `GENERATOR_VERSION` all silently rewrite every level the
## player has already played. The purity guarantee holds across devices and
## reinstalls; it does not hold across updates. Once a level has been played it
## is a place the player remembers, and the promise the level map makes - that
## going back to level 9 means going back to *that* level 9 - has to survive the
## next content patch.
##
## So the snapshot is not a substitute for determinism. It is the record that
## pins a level once the player has actually met it.
##
## ## What is stored, and what is not
##
## Only the fields that decide what the level *is*: the seed it came from, the
## gem identities behind local tiers 1-8, the opening board, the launcher queue,
## the target cards, the shot limit, and the background and table it is drawn
## on. Everything else in a config is metadata derived from those - analytics
## ids, pattern bookkeeping, band names - and is left to regenerate, so a
## future field is not frozen at whatever value it happened to have.
##
## Records live in their own file rather than in the progression save. The
## progress file is read on every launch and written on every coin transaction;
## a player at level 300 would otherwise be parsing and rewriting three hundred
## board layouts to bank one merge.

const SAVE_PATH := "user://level_records.cfg"

## The fields a snapshot pins. Order is irrelevant; presence is not.
const RECORDED_FIELDS := [
	"seed",
	"gem_identity_by_tier",
	"launcher_sequence",
	"starting_board",
	"target_sequence",
	"shot_limit",
	"level_type",
	"background_index",
	"table_index",
]

## Stamped alongside every record so a config restored from an older generator
## is recognisable. Nothing reads it to decide behaviour today - the record is
## authoritative either way - but a record that did not say which generator
## produced it could never be audited.
const RECORD_VERSION := 1


static func _section(level_number: int) -> String:
	return "level_%d" % maxi(1, level_number)


## The stored snapshot for a level, or an empty Dictionary when it has never
## been played.
static func record_for(level_number: int) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {}
	var section := _section(level_number)
	if not config.has_section(section):
		return {}
	var record := {}
	for key in config.get_section_keys(section):
		record[key] = config.get_value(section, key)
	return record


static func has_record(level_number: int) -> bool:
	return not record_for(level_number).is_empty()


## Writes the snapshot for a level, once. A level already on file is left
## exactly as it is - that is the entire point, and an unconditional write would
## quietly re-pin the level to whatever the current generator produces the next
## time the player visits it.
static func store(level_number: int, config: Dictionary) -> Error:
	if level_number <= 0 or config.is_empty():
		return OK
	var file := ConfigFile.new()
	file.load(SAVE_PATH)
	var section := _section(level_number)
	if file.has_section(section):
		return OK
	file.set_value(section, "record_version", RECORD_VERSION)
	file.set_value(section, "generator_version", int(config.get("generator_version", 0)))
	file.set_value(section, "template_id", String(config.get("template_id", "")))
	for field in RECORDED_FIELDS:
		if config.has(field):
			file.set_value(section, field, config[field])
	return file.save(SAVE_PATH)


## Overlays a stored snapshot onto a freshly generated config.
##
## The generated config is still built first, so every derived field a record
## does not pin is present and current. Only the recorded fields are replaced,
## and only when a record exists - a level being met for the first time is
## generated exactly as before.
static func apply(config: Dictionary, record: Dictionary) -> Dictionary:
	if record.is_empty():
		return config
	var result := config
	for field in RECORDED_FIELDS:
		if record.has(field):
			result[field] = record[field]
	# Recorded, so an audit can tell a restored level from a regenerated one,
	# and so analytics can separate the two populations if a generator change
	# ever needs measuring.
	result["restored_from_record"] = true
	result["record_generator_version"] = int(record.get("generator_version", 0))
	return result


## Whether a regenerated config still matches its stored snapshot. Nothing in
## the game depends on the answer - the record wins regardless - but it is what
## `run_level_stars_v1_tests` uses to prove the generator has not drifted, and
## what a future migration would use to find out how far it had.
static func matches(config: Dictionary, record: Dictionary) -> bool:
	if record.is_empty():
		return true
	for field in RECORDED_FIELDS:
		if not record.has(field):
			continue
		if not _equal(config.get(field), record[field]):
			return false
	return true


## Structural comparison, because a ConfigFile round trip does not preserve
## Dictionary key order. Comparing `str()` of two identical opening boards
## reports a mismatch purely because the keys came back in a different order,
## which would make the drift detector cry wolf on every level.
static func _equal(left: Variant, right: Variant) -> bool:
	if left is Dictionary and right is Dictionary:
		var left_dict: Dictionary = left
		var right_dict: Dictionary = right
		if left_dict.size() != right_dict.size():
			return false
		for key in left_dict.keys():
			if not right_dict.has(key) or not _equal(left_dict[key], right_dict[key]):
				return false
		return true
	if left is Array and right is Array:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in range(left_array.size()):
			if not _equal(left_array[index], right_array[index]):
				return false
		return true
	# Numbers survive the round trip as int or float depending on how they were
	# written, so 5 and 5.0 must compare equal here; everything else falls back
	# to its own equality.
	if (left is int or left is float) and (right is int or right is float):
		return is_equal_approx(float(left), float(right))
	return left == right


static func clear_records() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
