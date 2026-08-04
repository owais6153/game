class_name AudioFeedbackService
extends Node

## Production audio currently uses only short cached gem tones for confirmed
## controller events. The supplied recording contains music and reward sounds
## in one mixed track, so it is deliberately not used as a runtime music bed.
var enabled := true:
	set(value):
		enabled = value
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _clock := 0.0
var _variation_index := 0

func _ready() -> void:
	_build_stream_cache()
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
	player.stream = _stream_cache.get(event_name, _stream_cache.get("button"))
	player.volume_db = linear_to_db(float(tone.volume) * intensity)
	_variation_index += 1
	var variation := 0.94 + float(_variation_index % 5) * 0.03
	player.pitch_scale = variation
	player.play()

func cached_stream_count() -> int:
	return _stream_cache.size()

func ambience_is_ready() -> bool:
	return false

func has_ambience() -> bool:
	return false

func _build_stream_cache() -> void:
	if not _stream_cache.is_empty():
		return
	var seed := 1
	for event_name in GameConfig.AUDIO_TONES.keys():
		_stream_cache[event_name] = _build_coin_stream(GameConfig.AUDIO_TONES[event_name], seed, String(event_name)) if String(event_name).begins_with("coin_") else _build_crystal_stream(GameConfig.AUDIO_TONES[event_name], seed)
		seed += 1

func _build_coin_stream(tone: Dictionary, seed: int, event_name: String) -> AudioStreamWAV:
	# Original procedural metal reward cues: harmonic brass partials, a fast
	# strike, and a small upward pitch sweep. No reference audio is copied.
	var duration := float(tone.duration)
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * duration)
	var base := float(tone.frequency)
	var brightness := float(tone.brightness)
	var fall := float(tone.fall)
	var phase_a := 0.0
	var phase_b := 0.0
	var phase_c := 0.0
	var samples := PackedByteArray()
	samples.resize(frames * 2)
	for frame in range(frames):
		var t := float(frame) / GameConfig.AUDIO_SAMPLE_RATE
		var normalized := t / duration
		var sweep := lerpf(0.92, 1.12 if event_name != "coin_burst" else 1.02, normalized)
		var envelope := exp(-fall * 7.0 * normalized) * minf(1.0, normalized * 120.0)
		phase_a += TAU * base * sweep / GameConfig.AUDIO_SAMPLE_RATE
		phase_b += TAU * base * 2.02 * sweep / GameConfig.AUDIO_SAMPLE_RATE
		phase_c += TAU * base * 3.96 * sweep / GameConfig.AUDIO_SAMPLE_RATE
		var body := sin(phase_a) * 0.58 + sin(phase_b + 0.24) * (0.22 + brightness * 0.08) + sin(phase_c + 0.51) * (0.08 + brightness * 0.07)
		var strike := sin(float(frame + seed * 13) * 1.91) * brightness * exp(-normalized * 34.0) * 0.08
		var sample := clampf((body + strike) * envelope * 0.47, -0.90, 0.90)
		samples.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(GameConfig.AUDIO_SAMPLE_RATE)
	stream.stereo = false
	stream.data = samples
	return stream

func _build_crystal_stream(tone: Dictionary, seed: int) -> AudioStreamWAV:
	var duration := float(tone.duration)
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * duration)
	var base := float(tone.frequency)
	var brightness := float(tone.brightness)
	var fall := float(tone.fall)
	var phase_a := 0.0
	var phase_b := 0.0
	var phase_c := 0.0
	var samples := PackedByteArray()
	samples.resize(frames * 2)
	for frame in range(frames):
		var t := float(frame) / GameConfig.AUDIO_SAMPLE_RATE
		var normalized := t / duration
		var envelope := exp(-fall * 8.0 * normalized) * minf(1.0, normalized * 90.0)
		# Glass is intentionally inharmonic: 1.0, 2.73, and 4.18 partials.
		phase_a += TAU * base / GameConfig.AUDIO_SAMPLE_RATE
		phase_b += TAU * base * 2.73 / GameConfig.AUDIO_SAMPLE_RATE
		phase_c += TAU * base * 4.18 / GameConfig.AUDIO_SAMPLE_RATE
		var body := sin(phase_a) * 0.58 + sin(phase_b) * (0.22 + brightness * 0.12) + sin(phase_c) * (0.07 + brightness * 0.11)
		var deterministic_noise := sin(float(frame) * 1664525.0 + float(seed) * 1013904223.0)
		var sparkle := deterministic_noise * brightness * exp(-normalized * 22.0) * 0.10
		var sample := clampf((body + sparkle) * envelope * 0.45, -0.90, 0.90)
		samples.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(GameConfig.AUDIO_SAMPLE_RATE)
	stream.stereo = false
	stream.data = samples
	return stream
