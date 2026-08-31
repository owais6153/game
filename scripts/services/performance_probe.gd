class_name PerformanceProbe
extends Node

## Frame-time telemetry for device validation. Presentation and diagnostics
## only: it reads engine counters and never touches simulation, merge, launcher,
## or collision state, and it is disabled unless
## GameConfig.PERFORMANCE_TELEMETRY_ENABLED is turned on for a measurement
## build.
##
## It exists because the desktop editor cannot answer the question that matters.
## The reported stalls were specific to a low-end phone on a crowded table, and
## `dumpsys gfxinfo` cannot see inside a Godot GLSurfaceView, so the frame times
## have to come from the running game itself.
##
## Percentiles rather than an average: an average hides exactly the thing being
## chased. A 60 fps average with a 120 ms worst frame is what a stall feels like.

const REPORT_INTERVAL := 2.0
## Two seconds of headroom at 60 fps. Sampling is bounded so a long session
## cannot grow this buffer without limit.
const SAMPLE_LIMIT := 240

var _samples: PackedFloat32Array = PackedFloat32Array()
var _elapsed := 0.0
var _label := "boot"


func _ready() -> void:
	# Home and every overlay pause the tree, and an inheriting node stops being
	# processed with it. A frame-time probe that goes silent exactly when the UI
	# is on screen cannot measure the UI, so it opts out of pausing.
	process_mode = Node.PROCESS_MODE_ALWAYS

## Names the phase the next report covers, so a log line can be attributed to
## Home, a level, or a specific board state instead of just a timestamp.
func set_label(label: String) -> void:
	if label == _label:
		return
	_flush()
	_label = label


func _process(delta: float) -> void:
	if _samples.size() < SAMPLE_LIMIT:
		_samples.append(delta * 1000.0)
	_elapsed += delta
	if _elapsed >= REPORT_INTERVAL:
		_flush()


func _flush() -> void:
	var elapsed := _elapsed
	_elapsed = 0.0
	if _samples.is_empty():
		return
	var sorted := _samples.duplicate()
	sorted.sort()
	var count := sorted.size()
	# script/render split so a spike can be attributed instead of guessed at: if
	# the worst frames are long while script time stays flat, the cost is not in
	# GDScript and looking there is wasted effort.
	print("[PERF] %-18s frames=%3d fps=%5.1f med=%6.2f p90=%6.2f p99=%6.2f worst=%6.2f | script=%5.2fms phys=%5.2fms draws=%3d nodes=%4d orphans=%3d mem=%5.1fMB gems=%d" % [
		_label,
		count,
		float(count) / maxf(0.001, elapsed),
		sorted[int(count * 0.50)],
		sorted[mini(count - 1, int(count * 0.90))],
		sorted[mini(count - 1, int(count * 0.99))],
		sorted[count - 1],
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		tracked_gem_count,
	])
	_samples.clear()


## Set by the controller each frame so a report says how crowded the board was.
## Presentation-only: nothing here is read back into gameplay.
var tracked_gem_count := 0
