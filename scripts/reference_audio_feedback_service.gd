class_name ReferenceAudioFeedbackService
extends Node

## Reference-derived gameplay audio. These short Ogg streams were cut without
## gain, EQ, synthesis, or music replacement from the user-supplied reference
## recording. Playback stays behind the same typed thresholds, cooldowns, and
## bounded player pool and never influences gameplay state.
const REFERENCE_LAUNCH: AudioStream = preload("res://assets/runtime/audio/reference_launch.ogg")
const REFERENCE_CONTACT: AudioStream = preload("res://assets/runtime/audio/reference_contact.ogg")
const REFERENCE_MERGE_REWARD: AudioStream = preload("res://assets/runtime/audio/reference_merge_reward.ogg")
const REFERENCE_TARGET_REWARD: AudioStream = preload("res://assets/runtime/audio/reference_target_reward.ogg")

const STREAM_BY_EVENT := {
	"launch": REFERENCE_LAUNCH,
	"gem_contact": REFERENCE_CONTACT,
	"wall_contact": REFERENCE_CONTACT,
	"merge_reward": REFERENCE_MERGE_REWARD,
	"target_reward": REFERENCE_TARGET_REWARD,
	"fail": REFERENCE_CONTACT,
	"button": REFERENCE_LAUNCH,
}

var enabled := true
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _clock := 0.0


func _ready() -> void:
	_build_stream_cache()
	for index in range(GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func _process(delta: float) -> void:
	_clock += delta


func emit_event(event_name: String, _intensity: float = 1.0) -> bool:
	# Several headless controller fixtures call the parent `_ready()` off-tree.
	# Cache ownership is still deterministic and resource-only, so make that
	# development path safe without allocating during live gameplay.
	_build_stream_cache()
	if not enabled or not _stream_cache.has(event_name):
		return false
	var cooldown := float(GameConfig.AUDIO_COOLDOWN_BY_EVENT.get(event_name, 0.0))
	if _clock - float(_last_played_at.get(event_name, -100.0)) < cooldown:
		return false
	_last_played_at[event_name] = _clock
	emitted_events.append(event_name)
	_play_reference_clip(event_name)
	return true


func clear_trace() -> void:
	emitted_events.clear()


func cached_stream_count() -> int:
	return _stream_cache.size()


func has_ambience() -> bool:
	return false


func _build_stream_cache() -> void:
	if _stream_cache.is_empty():
		_stream_cache = STREAM_BY_EVENT.duplicate()


func _play_reference_clip(event_name: String) -> void:
	if _players.is_empty():
		return
	var available := _players.filter(func(candidate: AudioStreamPlayer) -> bool: return not candidate.playing)
	var player: AudioStreamPlayer = available.front() if not available.is_empty() else _players[0]
	player.stop()
	player.stream = _stream_cache[event_name]
	player.pitch_scale = 1.0
	player.volume_db = linear_to_db(float(GameConfig.AUDIO_EVENT_VOLUME.get(event_name, 1.0)))
	player.play()
