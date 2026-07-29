class_name AudioFeedbackService
extends Node

## Original procedural crystal synth. It makes short glass-like transients from
## inharmonic partials, a controlled bright noise tick, and exponential decay.
## No external or copyrighted samples are used; all tones are generated at run time.
var enabled := true
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _clock := 0.0
var _variation_index := 0

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
	_play_crystal(event_name, clampf(intensity, 0.20, 1.0))
	return true

func clear_trace() -> void:
	emitted_events.clear()

func _play_crystal(event_name: String, intensity: float) -> void:
	if _players.is_empty():
		return
	var available := _players.filter(func(candidate: AudioStreamPlayer) -> bool: return not candidate.playing)
	var player: AudioStreamPlayer = available.front() if not available.is_empty() else _players[0]
	var tone: Dictionary = GameConfig.AUDIO_TONES.get(event_name, GameConfig.AUDIO_TONES.button)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = GameConfig.AUDIO_SAMPLE_RATE
	stream.buffer_length = 0.35
	player.stream = stream
	player.volume_db = linear_to_db(float(tone.volume) * intensity)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	_variation_index += 1
	var variation := 0.94 + float(_variation_index % 5) * 0.03
	var duration := float(tone.duration)
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * duration)
	var base := float(tone.frequency) * variation
	var brightness := float(tone.brightness)
	var fall := float(tone.fall)
	var phase_a := 0.0
	var phase_b := 0.0
	var phase_c := 0.0
	for frame in range(frames):
		var t := float(frame) / GameConfig.AUDIO_SAMPLE_RATE
		var normalized := t / duration
		var envelope := exp(-fall * 8.0 * normalized) * minf(1.0, normalized * 90.0)
		# Glass is intentionally inharmonic: 1.0, 2.73, and 4.18 partials.
		phase_a += TAU * base / GameConfig.AUDIO_SAMPLE_RATE
		phase_b += TAU * base * 2.73 / GameConfig.AUDIO_SAMPLE_RATE
		phase_c += TAU * base * 4.18 / GameConfig.AUDIO_SAMPLE_RATE
		var body := sin(phase_a) * 0.58 + sin(phase_b) * (0.22 + brightness * 0.12) + sin(phase_c) * (0.07 + brightness * 0.11)
		var deterministic_noise := sin(float(frame * 1664525 + _variation_index * 1013904223))
		var sparkle := deterministic_noise * brightness * exp(-normalized * 22.0) * 0.10
		var sample := clampf((body + sparkle) * envelope * 0.40, -0.88, 0.88)
		playback.push_frame(Vector2(sample, sample))
