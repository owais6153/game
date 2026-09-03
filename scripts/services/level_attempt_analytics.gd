class_name LevelAttemptAnalytics
extends RefCounted

## Per-attempt gameplay aggregates.
##
## A merge game fires a great many small events - every shot, every merge, every
## chain link. Sending each one to GA4 would cost event volume, blow past
## per-event parameter limits, and still not answer the questions that matter,
## because the interesting quantities are *ratios over an attempt*: how often a
## shot merged at all, how deep chains actually ran, how many powers were spent
## before the player gave up.
##
## So the per-event stream stays as it is - one `merge` event, which already
## existed - and everything else is accumulated here and attached to the single
## event that ends the attempt. One event per attempt carries the whole picture.
##
## This object owns no gameplay state and makes no decisions. It is written to
## from confirmed controller events only, and reading it can never fail: an
## attempt that ends without a single shot reports zeroes, not nulls.

## Chain depth at or above which a chain counts as "combo 3+". Depth is
## zero-based - depth 0 is an ordinary merge, depth 1 is the first chained
## follow-up - so combo N is depth N.
const COMBO_HIGH_BAND := 3

var shots_fired := 0
var shots_with_merge := 0
var shots_with_chain := 0
var total_merges := 0
var total_chains := 0
var max_chain_depth := 0
var combo_1_count := 0
var combo_2_count := 0
var combo_3_plus_count := 0
var targets_completed := 0
var powers_used_count := 0
var coins_earned := 0
var continues_used := 0
var extra_shots_used := 0

var _powers_used_by_type: Dictionary = {}
var _started_msec := 0
var _shot_merged := false
var _shot_chained := false


func begin() -> void:
	shots_fired = 0
	shots_with_merge = 0
	shots_with_chain = 0
	total_merges = 0
	total_chains = 0
	max_chain_depth = 0
	combo_1_count = 0
	combo_2_count = 0
	combo_3_plus_count = 0
	targets_completed = 0
	powers_used_count = 0
	coins_earned = 0
	continues_used = 0
	extra_shots_used = 0
	_powers_used_by_type.clear()
	_shot_merged = false
	_shot_chained = false
	_started_msec = Time.get_ticks_msec()


func record_shot() -> void:
	shots_fired += 1
	# Per-shot merge/chain flags are resolved when the *next* shot begins, so a
	# shot's whole cascade has settled before it is classified.
	_flush_shot_flags()


## Called from the confirmed merge event. `depth` is the chain position: 0 for a
## merge caused directly by a shot, 1+ for each chained follow-up.
func record_merge(depth: int) -> void:
	total_merges += 1
	_shot_merged = true
	if depth <= 0:
		return
	total_chains += 1
	_shot_chained = true
	max_chain_depth = maxi(max_chain_depth, depth)
	match depth:
		1:
			combo_1_count += 1
		2:
			combo_2_count += 1
		_:
			combo_3_plus_count += 1


func record_target_completed() -> void:
	targets_completed += 1


func record_power_used(power: String) -> void:
	powers_used_count += 1
	_powers_used_by_type[power] = int(_powers_used_by_type.get(power, 0)) + 1


func record_coins_earned(amount: int) -> void:
	coins_earned += maxi(0, amount)


func record_continue() -> void:
	continues_used += 1


func record_extra_shots() -> void:
	extra_shots_used += 1


## The power spent most often this attempt, or "" if none was used. A stable
## categorical value, safe as a GA4 dimension.
func most_used_power() -> String:
	var best := ""
	var best_count := 0
	var keys: Array = _powers_used_by_type.keys()
	# Sorted so a tie resolves the same way every run rather than by dictionary
	# insertion order, which would make the dimension unstable.
	keys.sort()
	for key in keys:
		var count := int(_powers_used_by_type[key])
		if count > best_count:
			best_count = count
			best = String(key)
	return best


func duration_seconds() -> float:
	if _started_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - _started_msec) / 1000.0


## Percentage 0-100, rounded to an integer. GA4 aggregates integers far more
## usefully than floats, and one decimal place of a per-attempt ratio is noise.
static func _percent(part: int, whole: int) -> int:
	if whole <= 0:
		return 0
	return int(round(float(part) * 100.0 / float(whole)))


## The aggregate block attached to whichever event ends the attempt.
func summary() -> Dictionary:
	# Resolve the final shot, which has no successor to flush it.
	var merged := shots_with_merge + (1 if _shot_merged else 0)
	var chained := shots_with_chain + (1 if _shot_chained else 0)
	# Sized against GA4's 25-parameter ceiling: this block plus the nine-field
	# level context plus the outcome's own fields must stay under it, or GA4
	# drops the overflow without reporting it.
	#
	# `coins_earned`, `continues_used` and `extra_shots_used` are deliberately
	# absent even though this object tracks them - each already has a dedicated
	# event (`coin_earned`, `continue_used`, `extra_shots_used`) and repeating
	# them here would double-count in any report that sums across events. They
	# stay readable on the object for tests and for the result screen.
	return {
		"shots_used": shots_fired,
		"total_merges": total_merges,
		"total_chains": total_chains,
		# One field, not two: "max combo" and "max chain depth" are the same
		# measurement, and shipping both invites two reports that disagree.
		"max_chain_depth": max_chain_depth,
		"combo_1_count": combo_1_count,
		"combo_2_count": combo_2_count,
		"combo_3_plus_count": combo_3_plus_count,
		"shot_merge_percent": _percent(merged, shots_fired),
		"shot_chain_percent": _percent(chained, shots_fired),
		"targets_completed": targets_completed,
		"powers_used_count": powers_used_count,
		"most_used_power": most_used_power(),
		"attempt_duration": snappedf(duration_seconds(), 0.1),
	}


func _flush_shot_flags() -> void:
	if _shot_merged:
		shots_with_merge += 1
	if _shot_chained:
		shots_with_chain += 1
	_shot_merged = false
	_shot_chained = false
