class_name AudioFeedbackService
extends Node

## Lightweight procedural one-shot audio router. Gameplay only sends confirmed
## event names here; this service owns routing, cooldowns, and playback.
var enabled := true
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _clock := 0.0

func _ready() -> void:
	for index in range(GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

func _process(delta: float) -> void:
	_clock += delta

func emit_event(event_name: String, intensity: float = 1.0) -> bool:
	if not enabled:
		return false
	var cooldown := float(GameConfig.AUDIO_COOLDOWN_BY_EVENT.get(event_name, 0.0))
	if _clock - float(_last_played_at.get(event_name, -100.0)) < cooldown:
		return false
	_last_played_at[event_name] = _clock
	emitted_events.append(event_name)
	_play_tone(event_name, clampf(intensity, 0.25, 1.0))
	return true

func clear_trace() -> void:
	emitted_events.clear()

func _play_tone(event_name: String, intensity: float) -> void:
	if _players.is_empty():
		return
	var player: AudioStreamPlayer = _players.filter(func(candidate: AudioStreamPlayer) -> bool: return not candidate.playing).front() if _players.any(func(candidate: AudioStreamPlayer) -> bool: return not candidate.playing) else _players[0]
	var tone: Dictionary = GameConfig.AUDIO_TONES.get(event_name, GameConfig.AUDIO_TONES.button)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = GameConfig.AUDIO_SAMPLE_RATE
	stream.buffer_length = 0.12
	player.stream = stream
	player.volume_db = linear_to_db(float(tone.volume) * intensity)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * float(tone.duration))
	for frame in range(frames):
		var progress := float(frame) / maxf(1.0, float(frames))
		var frequency := lerpf(float(tone.frequency), float(tone.frequency) * float(tone.sweep), progress)
		var envelope := sin(progress * PI)
		var sample := sin(TAU * frequency * float(frame) / GameConfig.AUDIO_SAMPLE_RATE) * envelope * 0.28
		playback.push_frame(Vector2(sample, sample))
