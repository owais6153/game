class_name AudioFeedbackService
extends Node

const SuppliedBackgroundMusic: AudioStream = preload("res://assets/runtime/audio/supplied_background_music_v5.ogg")
const SuppliedCoinReward: AudioStream = preload("res://assets/runtime/audio/supplied_coin_reward_v4.ogg")
## Non-destructive, low-passed derivatives of the preserved supplied contact
## files. Short fades and restrained top end keep routine physics beneath rewards.
const SuppliedGemCollision: AudioStream = preload("res://assets/runtime/audio/gem_collision_soft_v1.ogg")
const SuppliedRailCollision: AudioStream = preload("res://assets/runtime/audio/rail_collision_soft_v1.ogg")
const SuppliedBasicMerge: AudioStream = preload("res://assets/runtime/audio/merge-basic.mp3")
## Runtime-only derivative of the preserved supplied MP3. Its measured 0.523 s
## leading silence is trimmed to 0.008 s so the audible attack matches the
## confirmed merge frame without changing gameplay or presentation timing.
const SuppliedTargetMerge: AudioStream = preload("res://assets/runtime/audio/merge-target-immediate.ogg")
const SuppliedUiTap: AudioStream = preload("res://assets/runtime/audio/mixkit-on-or-off-light-switch-tap-2585.wav")
const SuppliedTargetComplete: AudioStream = preload("res://assets/runtime/audio/target_complete_soft_v1.ogg")

## Confirmed controller events use cached one-shots. Independently supplied
## music owns one continuous player whose gain is intentionally below merge
## and coin feedback; movement never starts, seeks, or restarts it.
var sfx_enabled := true:
	set(value):
		sfx_enabled = value
		_sync_enabled_state()
var music_enabled := true:
	set(value):
		music_enabled = value
		_sync_enabled_state()
var enabled: bool:
	get:
		return sfx_enabled and music_enabled
	set(value):
		sfx_enabled = value
		music_enabled = value
		_sync_enabled_state()
var emitted_events: Array[String] = []
var _last_played_at: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _music_player: AudioStreamPlayer
var _clock := 0.0
var _variation_index := 0
var _play_serial := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_stream_cache()
	for index in range(GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % (index + 1)
		player.bus = "SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.set_meta("audio_priority", 0)
		player.set_meta("play_serial", 0)
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.name = "SuppliedBackgroundMusic"
	_music_player.bus = "Music"
	var loop_stream := SuppliedBackgroundMusic.duplicate()
	if loop_stream is AudioStreamOggVorbis:
		loop_stream.loop = true
	_music_player.stream = loop_stream
	_music_player.volume_db = linear_to_db(GameConfig.AUDIO_MUSIC_VOLUME)
	add_child(_music_player)
	_sync_enabled_state()

func _process(delta: float) -> void:
	_clock += delta

func emit_event(event_name: String, intensity: float = 1.0) -> bool:
	if not sfx_enabled:
		return false
	var cooldown := float(GameConfig.AUDIO_COOLDOWN_BY_EVENT.get(event_name, 0.0))
	if _clock - float(_last_played_at.get(event_name, -100.0)) < cooldown:
		return false
	if not _play_event(event_name, clampf(intensity, 0.20, 1.0)):
		return false
	_last_played_at[event_name] = _clock
	emitted_events.append(event_name)
	return true

func clear_trace() -> void:
	emitted_events.clear()

func _play_event(event_name: String, intensity: float) -> bool:
	if _players.is_empty() or not _stream_cache.has(event_name):
		return false
	var available := _players.filter(func(candidate: AudioStreamPlayer) -> bool: return not candidate.playing)
	var event_priority := int(GameConfig.AUDIO_PRIORITY_BY_EVENT.get(event_name, 0))
	var player: AudioStreamPlayer
	if not available.is_empty():
		player = available.front()
	else:
		player = _players[0]
		for candidate in _players:
			var candidate_priority := int(candidate.get_meta("audio_priority", 0))
			var selected_priority := int(player.get_meta("audio_priority", 0))
			if candidate_priority < selected_priority or (candidate_priority == selected_priority and int(candidate.get_meta("play_serial", 0)) < int(player.get_meta("play_serial", 0))):
				player = candidate
		if event_priority < int(player.get_meta("audio_priority", 0)):
			return false
	var tone: Dictionary = GameConfig.AUDIO_TONES.get(event_name, GameConfig.AUDIO_TONES.button)
	player.stream = _stream_cache[event_name]
	player.volume_db = linear_to_db(float(tone.volume) * intensity)
	var pitch_range: Vector2 = GameConfig.AUDIO_PITCH_RANGE_BY_EVENT.get(event_name, Vector2.ONE)
	if pitch_range.is_equal_approx(Vector2.ONE):
		player.pitch_scale = 1.0
	else:
		_variation_index += 1
		player.pitch_scale = lerpf(pitch_range.x, pitch_range.y, float(_variation_index % 5) / 4.0)
	_play_serial += 1
	player.set_meta("audio_priority", event_priority)
	player.set_meta("play_serial", _play_serial)
	player.play()
	return true

func cached_stream_count() -> int:
	return _stream_cache.size()

func stream_for_event(event_name: String) -> AudioStream:
	return _stream_cache.get(event_name)

func ambience_is_ready() -> bool:
	return _music_player != null and _music_player.stream != null and _music_player.playing

func has_ambience() -> bool:
	return _music_player != null and _music_player.stream != null

func music_volume_linear() -> float:
	return GameConfig.AUDIO_MUSIC_VOLUME

func _build_stream_cache() -> void:
	if not _stream_cache.is_empty():
		return
	_stream_cache = {
		"launch": _build_crystal_stream(GameConfig.AUDIO_TONES.launch, 1),
		"gem_contact": SuppliedGemCollision,
		"wall_contact": SuppliedRailCollision,
		"normal_merge": SuppliedTargetMerge,
		"merge_2": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_2, 2),
		"merge_3": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_3, 3),
		"merge_4": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_4, 4),
		"merge_5": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_5, 5),
		"merge_6": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_6, 6),
		"merge_7": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_7, 7),
		"merge_8": _build_crystal_stream(GameConfig.AUDIO_TONES.merge_8, 8),
		"chain": _build_crystal_stream(GameConfig.AUDIO_TONES.chain, 9),
		"target_collect": _build_reward_chime_stream(GameConfig.AUDIO_TONES.target_collect),
		"target_complete": SuppliedTargetComplete,
		"coin_tick": _build_crystal_stream(GameConfig.AUDIO_TONES.coin_tick, 11),
		"coin_reward": SuppliedCoinReward,
		"win": SuppliedBasicMerge,
		"button": SuppliedUiTap,
	}

func _sync_enabled_state() -> void:
	if _music_player == null:
		return
	if music_enabled:
		if not _music_player.playing:
			_music_player.play()
	else:
		_music_player.stop()
	if not sfx_enabled:
		for player in _players:
			player.stop()

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


func _build_reward_chime_stream(tone: Dictionary) -> AudioStreamWAV:
	var duration := float(tone.duration)
	var frames := int(GameConfig.AUDIO_SAMPLE_RATE * duration)
	var base := float(tone.frequency)
	var samples := PackedByteArray()
	samples.resize(frames * 2)
	for frame in range(frames):
		var t := float(frame) / GameConfig.AUDIO_SAMPLE_RATE
		var normalized := t / duration
		var attack := minf(1.0, normalized * 55.0)
		var body_envelope := attack * exp(-normalized * 4.8)
		var shimmer_delay := maxf(0.0, normalized - 0.20)
		var shimmer_envelope := minf(1.0, shimmer_delay * 16.0) * exp(-shimmer_delay * 7.0)
		# Soft harmonic body plus a delayed, quiet shimmer. Unlike routine contact
		# ticks, this avoids sharp inharmonic upper partials at the target card.
		var body := sin(TAU * base * t) * 0.56 + sin(TAU * base * 1.5 * t) * 0.18
		var shimmer := (sin(TAU * base * 2.0 * t) * 0.15 + sin(TAU * base * 2.5 * t) * 0.08) * shimmer_envelope
		var sample := clampf((body * body_envelope + shimmer) * 0.42, -0.88, 0.88)
		samples.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(GameConfig.AUDIO_SAMPLE_RATE)
	stream.stereo = false
	stream.data = samples
	return stream
