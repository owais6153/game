extends SceneTree

## Curates verified production-scene captures into a consistent 1080x1920
## delivery set. Each source frame was rendered by the live Game scene through
## the production controller; this utility only resamples its pixels.

const OUTPUT_DIR := "res://reports/playable-game-moments-v1/"
const OUTPUT_SIZE := Vector2i(1080, 1920)
const MOMENTS := {
	"01-warm-color-crowded-board.png": "res://reports/gem-pattern-feedback-v1/screenshots/pattern-color-warm-level-05.png",
	"02-blue-color-crowded-board.png": "res://reports/gem-pattern-feedback-v1/screenshots/pattern-color-cool-level-12.png",
	"03-rounded-square-packed-board.png": "res://reports/gem-pattern-feedback-v1/screenshots/pattern-shape-rounded-square-level-01.png",
	"04-circle-pattern-packed-board.png": "res://reports/gem-pattern-feedback-v1/screenshots/pattern-shape-circle-level-09.png",
	"05-pink-target-wave-and-blast.png": "res://reports/rail-target-blast-gem-expansion-v1/screenshots/enlarged-target-five-ring-wave-and-blast.png",
	"06-combo-one-reward-pop.png": "res://reports/reward-gem-simultaneous-physics-v6/screenshots/combo1-410ms-result-and-rewards-pop-together.png",
	"07-combo-two-multi-merge.png": "res://reports/reward-gem-simultaneous-physics-v6/screenshots/combo2-670ms-result-and-rewards-pop-together.png",
	"08-final-target-hero-moment.png": "res://reports/reward-gem-simultaneous-physics-v6/screenshots/final-0900ms-phaseC-readable-label.png",
}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for filename in MOMENTS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(MOMENTS[filename])))
		if image == null or image.is_empty():
			push_error("Unable to load source capture %s" % MOMENTS[filename])
			quit(1)
			return
		image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + filename))
		if error != OK:
			push_error("Unable to save %s (error %d)" % [filename, error])
			quit(1)
			return
	print("PLAYABLE_GAME_MOMENTS_V1_RENDER: PASS")
	quit(0)
