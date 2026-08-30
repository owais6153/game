extends SceneTree

## Prints the feasibility audit for every limited-shot level, so balance can be
## reviewed as data. Developer aid only; nothing loads it at runtime.

const L = preload("res://scripts/core/level_config.gd")
const Solver = preload("res://scripts/core/level_solver.gd")

func _init() -> void:
	print("lvl | shots | board | used | spare | matRatio | class")
	var worst := INF
	var worst_level := 0
	var avoid := 0
	for n in range(1, 81):
		if not L.is_limited_shots_level(n):
			continue
		var report := Solver.analyse(L.generated(n, L.seed_for_level(n)))
		print("%3d | %5d | %5d | %4d | %5d | %8.2f | %s" % [
			n, report.shot_limit, report.board_gems,
			report.shots_used, report.spare_shots, report.material_ratio, report.classification])
		if float(report.material_ratio) < worst:
			worst = float(report.material_ratio)
			worst_level = n
		if String(report.classification) == "AVOID":
			avoid += 1
	print("\nworst ratio %.2f at level %d; AVOID count = %d" % [worst, worst_level, avoid])
	quit(0)
