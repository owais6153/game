class_name NotificationService
extends RefCounted

## Daily reminder that unclaimed missions are waiting.
##
## The decision of *whether* and *what* to send lives here as pure functions, so
## the interesting behaviour is testable without a device: the Android side is a
## thin scheduler this module drives, not a place where rules live.
##
## The rule that matters: a reminder is only scheduled when the player actually
## has something outstanding. A notification that fires on a day the player has
## already finished everything teaches them the notification is noise, and the
## next one gets swiped away with it. `should_remind()` is what enforces that,
## and it is re-evaluated every time mission state changes rather than once a
## day, so claiming the last mission at 18:55 cancels the 19:00 reminder.
##
## Delivery is deliberately local, not push. There is no server, the reminder is
## about state the device already knows, and a scheduled local notification
## survives with no network and no account.

const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")

## Android plugin singleton name. Absent on desktop and on any build without the
## plugin, which is why every call site checks first and degrades to a no-op:
## the game must never depend on the reminder existing.
const PLUGIN_NAME := "MajesticNotifications"

## One reminder a day, at 19:00 device-local. Evening beats morning for a
## session-length game: the player has time to actually play when it lands.
const REMINDER_HOUR := 19
const REMINDER_MINUTE := 0

## Stable id so a reschedule replaces the pending alarm instead of stacking a
## second one behind it.
const REMINDER_ID := 1001

const CHANNEL_ID := "daily_missions"
const CHANNEL_NAME := "Daily missions"


static func plugin() -> Object:
	if not Engine.has_singleton(PLUGIN_NAME):
		return null
	return Engine.get_singleton(PLUGIN_NAME)


static func is_available() -> bool:
	return plugin() != null


## Whether a reminder should be pending at all, given the player's settings and
## today's mission state.
static func should_remind(settings: Dictionary, daily_state: Dictionary) -> bool:
	if not bool(settings.get("notifications_enabled", true)):
		return false
	return unclaimed_count(daily_state) > 0


## Missions generated today that are not yet claimed, plus the chest if every
## mission is claimed but the chest is not. The chest counts because it is the
## one remaining reason to open the game.
static func unclaimed_count(daily_state: Dictionary) -> int:
	var missions: Array = daily_state.get("missions", []) as Array
	var outstanding := 0
	for entry in missions:
		var mission: Dictionary = entry as Dictionary
		if mission == null:
			continue
		if not bool(mission.get("claimed", false)):
			outstanding += 1
	if outstanding == 0 and DailyMissionServiceType.chest_ready(daily_state):
		outstanding = 1
	return outstanding


## The body text for a given number of outstanding items. Kept here rather than
## in the Android layer so the wording is covered by the test suite and can be
## changed without touching native code.
static func reminder_title() -> String:
	return "Your daily missions are waiting"


static func reminder_body(outstanding: int) -> String:
	if outstanding <= 0:
		return ""
	if outstanding == 1:
		return "1 mission left today. Finish it before the day resets!"
	return "%d missions left today. Finish them before the day resets!" % outstanding


## Seconds from `now` until the next REMINDER_HOUR:REMINDER_MINUTE in local time.
##
## Always strictly in the future: at exactly 19:00 the answer is tomorrow, not
## zero, so a reschedule triggered by a claim at the reminder minute cannot fire
## an alarm immediately.
static func seconds_until_next_reminder(now: Dictionary) -> int:
	var hour := int(now.get("hour", 0))
	var minute := int(now.get("minute", 0))
	var second := int(now.get("second", 0))
	var current := hour * 3600 + minute * 60 + second
	var target := REMINDER_HOUR * 3600 + REMINDER_MINUTE * 60
	var delta := target - current
	if delta <= 0:
		delta += 24 * 3600
	return delta


## Brings the pending alarm in line with the current state. Safe to call as
## often as state changes: scheduling reuses one id, so it replaces rather than
## accumulates, and cancelling something that was never scheduled is harmless.
##
## Returns what it decided, so callers and tests can assert on it without
## reaching into the plugin.
static func refresh(settings: Dictionary, daily_state: Dictionary, now: Dictionary = {}) -> Dictionary:
	var wanted := should_remind(settings, daily_state)
	var outstanding := unclaimed_count(daily_state)
	var when := seconds_until_next_reminder(now if not now.is_empty() else Time.get_datetime_dict_from_system())
	var decision := {
		"scheduled": wanted,
		"delay_seconds": when,
		"outstanding": outstanding,
		"title": reminder_title(),
		"body": reminder_body(outstanding),
		"delivered_to_plugin": false,
	}
	var android := plugin()
	if android == null:
		return decision
	if wanted:
		android.call("schedule", REMINDER_ID, when, decision.title, decision.body, CHANNEL_ID, CHANNEL_NAME)
	else:
		android.call("cancel", REMINDER_ID)
	decision.delivered_to_plugin = true
	return decision


## Android 13+ will not deliver anything until the runtime permission is
## granted. Asking on the first launch that wants to schedule keeps the prompt
## attached to a reason rather than firing it at a cold start.
static func request_permission_if_needed() -> void:
	var android := plugin()
	if android == null:
		return
	if android.has_method("has_permission") and bool(android.call("has_permission")):
		return
	if android.has_method("request_permission"):
		android.call("request_permission")
