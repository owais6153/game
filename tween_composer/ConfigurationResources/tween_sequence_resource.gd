@tool
class_name TweenSequence
extends Resource
## TweenSequence is the resource that contains the full instructions for a tween to be created by [TweenComposer]

## Sets the name of the tween sequence. Not used in the code.
@export var sequence_name: String:
	set(value):
		sequence_name = value
		resource_name = value
		emit_changed()
	get:
		return sequence_name

## Loads a [TweenStepCollection] to get the configuration for each step of the tween.
@export var tween_steps: TweenStepCollection

@export_group("Duration settings")

## Total duration of tween, in seconds. [br]
## Tip: Change the duration_ratio in each [TweenConfigStep] to adjust the time of their individual tween.
@export var tween_duration: float = 1.0:
	set(value):
		tween_duration = max(0.0, value) # Blocks negative numbers

## Sets if the tween will be looped, or one-shot.
@export var loop: bool = true

## How many times the tween will loop before it stops. Use zero for infinite.
@export var loop_repetitions: int = 0

## Tween information is usually deleted after the tween is finished.
## Set this to [code]true[/code] if you intend to play this tween again after it stops.
## If set to [code]false[/code], the tween will need to be composed again before running.
@export var persist_tween_information: bool = false
