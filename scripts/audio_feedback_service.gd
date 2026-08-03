class_name AudioFeedbackService
extends Node

## Original procedural crystal synth. It makes short glass-like transients from
## inharmonic partials, a controlled bright noise tick, and exponential decay.
## No external or copyrighted samples are used; all tones are generated at run time.
var enabled := true:
	set(value):
		enabled = value
		_sync_ambience_volume()
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _ambience_player: AudioStreamPlayer
var _ambience_stream: AudioStreamWAV
var _clock := 0.0
var _variation_index := 0

func _ready() -> void:
	_build_stream_cache()
	for index in range(GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	_setup_ambience()

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
	return _ambience_player != null and _ambience_stream != null and _ambience_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD

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
		var sample := clampf((body + strike) * envelope * 0.43, -0.88, 0.88)
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
		var sample := clampf((body + sparkle) * envelope * 0.40, -0.88, 0.88)
		samples.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(GameConfig.AUDIO_SAMPLE_RATE)
	stream.stereo = false
	stream.data = samples
	return stream

func _setup_ambience() -> void:
	_ambience_stream = _build_ambience_stream()
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "CrystalBeachAmbience"
	_ambience_player.bus = "Master"
	_ambience_player.stream = _ambience_stream
	add_child(_ambience_player)
	_sync_ambience_volume()
	_ambience_player.play()

func _sync_ambience_volume() -> void:
	if _ambience_player == null:
		return
	_ambience_player.volume_db = linear_to_db(GameConfig.AUDIO_AMBIENCE_VOLUME) if enabled else -80.0

func _build_ambience_stream() -> AudioStreamWAV:
	# A seamless, original six-second crystal/beach bed removes dead air without
	# allocating audio resources during play. All carrier frequencies complete
	# whole cycles across the loop, preventing a boundary click.
	var duration := GameConfig.AUDIO_AMBIENCE_DURATION
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(frames * 2)
	for frame in range(frames):
		var t := float(frame) / GameConfig.AUDIO_SAMPLE_RATE
		var loop_phase := TAU * t / duration
		var swell := 0.68 + sin(loop_phase - PI * 0.5) * 0.20
		var low_wave := sin(TAU * 55.0 * t) * 0.20
		var soft_wave := sin(TAU * 82.5 * t + 0.45) * 0.12
		var crystal_air := sin(TAU * 165.0 * t + 1.10) * 0.045
		var shimmer := sin(TAU * 330.0 * t + 0.30) * (0.012 + 0.010 * (0.5 + 0.5 * sin(loop_phase)))
		var sample := clampf((low_wave + soft_wave + crystal_air + shimmer) * swell, -0.42, 0.42)
		samples.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(GameConfig.AUDIO_SAMPLE_RATE)
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = samples
	return stream
