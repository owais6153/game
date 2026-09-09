class_name TreasureDrop
extends RefCounted

## What, if anything, a level win hands the player before the win popup.
##
## Pure arithmetic over the level number and the chests already opened, in the
## same spirit as LevelMilestone: the controller that grants a treasure and the
## tests that describe when one appears agree without either owning the rule.
##
## Two drops exist and they are deliberately different sizes.
##
## The milestone drop is the twenty-level chest. It used to wait on the map for
## the player to notice and tap it, which meant the biggest reward in the game
## arrived as a chore rather than as a moment; it is now handed over the instant
## the twentieth level is cleared, and the map simply shows it already opened.
##
## The bonus drop is small and occasional. It exists so that any level win can
## turn into a treasure, which is what makes the chest presentation worth
## building at all - a ceremony the player meets twice a day is a ceremony.
##
## The roll is a pure function of the level number, not of the clock or of a
## random seed, for the same reason level seeds are: replaying level 7 must
## reproduce level 7. A treasure that appeared only on the first clear would
## make a replay quietly worse than the original.

const LevelMilestoneType = preload("res://scripts/core/level_milestone.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

const KIND_MILESTONE := "milestone"
const KIND_BONUS := "bonus"

## Percent of level wins that drop a bonus treasure. Low enough that it stays an
## event rather than a step in the completion flow: at 15% a player meets one
## about every seventh level, which is roughly once per session.
const BONUS_CHANCE_PERCENT := 15

## The bonus payout. 120 coins is well under a level's own 310-480 income, so a
## bonus treasure is a garnish on the win rather than a reason to farm easy
## levels, and the single power keeps the sequence at two claims - long enough
## to read as a haul, short enough not to delay the win popup.
const BONUS_COIN_REWARD := 120
const BONUS_POWER_COUNT := 1


## The treasure a completed level drops, or an empty Dictionary for none.
##
## `claimed_chests` is consulted so replaying level 20 after its chest has been
## opened drops nothing - the milestone is earned once, not once per clear.
static func for_level_win(level_number: int, claimed_chests: Array[int]) -> Dictionary:
	if level_number <= 0:
		return {}
	var chest_index := LevelMilestoneType.chest_for_level(level_number)
	if chest_index > 0 and not claimed_chests.has(chest_index):
		return {
			"kind": KIND_MILESTONE,
			"chest_index": chest_index,
			"coins": LevelMilestoneType.COIN_REWARD,
			"powers": DailyMissionServiceType.CHEST_POWER_REWARD.duplicate(),
		}
	if not rolls_bonus(level_number):
		return {}
	return {
		"kind": KIND_BONUS,
		"chest_index": 0,
		"coins": BONUS_COIN_REWARD,
		"powers": {bonus_power(level_number): BONUS_POWER_COUNT},
	}


## Whether the bonus treasure lands on this level. Separate from
## `for_level_win()` so the odds can be asserted over a range of levels without
## having to stand up a chest list.
static func rolls_bonus(level_number: int) -> bool:
	if level_number <= 0:
		return false
	return _hash(level_number, 1) % 100 < BONUS_CHANCE_PERCENT


## Which power the bonus pays. Drawn from the same display-ordered list the shop
## and HUD use, so a new power joins the drop table by existing.
static func bonus_power(level_number: int) -> String:
	var pool := PowerInventoryServiceType.ALL
	return pool[_hash(level_number, 2) % pool.size()]


## An integer hash with `salt` separating the two independent decisions above.
## Without it, whether a bonus drops and which power it pays would be the same
## bit pattern and every bonus in the game would hand out the same power.
static func _hash(level_number: int, salt: int) -> int:
	var value := (level_number * 2654435761 + salt * 40503) & 0x7fffffff
	value = ((value >> 13) ^ value) & 0x7fffffff
	value = (value * 1274126177) & 0x7fffffff
	return ((value >> 16) ^ value) & 0x7fffffff
