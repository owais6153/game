class_name LevelMilestone
extends RefCounted

## Milestone chests on the level path. Pure arithmetic over level numbers, with
## no save, UI, or reward dependency, so the level-select map and the controller
## that grants a chest agree on where the chests are without either owning the
## rule.
##
## A chest sits after every twentieth level: clearing 20 opens the first, 40 the
## second, and so on forever. The map draws each chest on its own slot between
## two level nodes, which is why slot arithmetic lives here too - a chest drawn
## at one position and granted at another would read as a bug in the reward.

## Levels between consecutive chests.
const INTERVAL := 20

## Coins a milestone chest pays, on top of the daily chest's power grant.
##
## The daily chest deliberately pays no coins (DailyMissionService.CHEST_REWARD
## is 0) because coins already arrive from every level; a milestone is the
## opposite case - it is earned once per twenty levels rather than once a day,
## so it has to land as an event. 800 is roughly two levels' income at the
## measured 310-480 coins per level, and exactly one Skip Level, which makes the
## reward legible against a price the player already knows.
const COIN_REWARD := 800


## Chests are one-indexed: chest 1 is the one that follows level 20.
static func level_for_chest(chest_index: int) -> int:
	return maxi(1, chest_index) * INTERVAL


## The chest a level completion unlocks, or 0 when the level is not a milestone.
## Only the twentieth level of each block returns non-zero, so replaying an
## earlier level never re-offers a chest that was already earned.
static func chest_for_level(level_number: int) -> int:
	if level_number <= 0 or level_number % INTERVAL != 0:
		return 0
	return int(level_number / INTERVAL)


## How many chests are unlocked once every level below `highest_level` is
## cleared. `highest_level` is the furthest level the player may play, so the
## last cleared level is the one below it.
static func unlocked_chest_count(highest_level: int) -> int:
	return int((maxi(1, highest_level) - 1) / INTERVAL)


## The map lays levels and chests on one shared column of slots. Every block of
## INTERVAL levels is followed by a single chest slot, so slots and levels stay
## in step forever without the map having to search for the next chest.
static func slot_for_level(level_number: int) -> int:
	var index := maxi(1, level_number) - 1
	return index + int(index / INTERVAL)


static func slot_for_chest(chest_index: int) -> int:
	return maxi(1, chest_index) * (INTERVAL + 1) - 1


## Inverse of the two mappings above: what occupies a slot. Returns the level
## number in `level` (0 for a chest slot) and the chest index in `chest` (0 for
## a level slot), so a caller draws one row without a second lookup.
static func slot_contents(slot: int) -> Dictionary:
	if slot < 0:
		return {"level": 0, "chest": 0}
	var block := int(slot / (INTERVAL + 1))
	var offset := slot % (INTERVAL + 1)
	if offset == INTERVAL:
		return {"level": 0, "chest": block + 1}
	return {"level": block * INTERVAL + offset + 1, "chest": 0}


## Total slots needed to draw every level up to and including `top_level`.
static func slot_count_through(top_level: int) -> int:
	return slot_for_level(maxi(1, top_level)) + 1
