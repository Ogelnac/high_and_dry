extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var start_height: float
var arc_size: float = 128.0

var max_time: float = 5.0
var time: float = max_time
var bonked: bool
var phase_shift: float = 0.0
var phase_locked: bool = false

@onready var main: Node2D = $".."

func _process(delta: float) -> void:
	if bonked:
		delta *= 5.0
	time -= delta
	if global_position.y > start_height:
		main.retrigger = true
		main.update_ui(sprite_2d.frame)
		queue_free()
	else:
		var journey_percent: float = time / max_time
		if bonked and journey_percent > 0.5 and not phase_locked:
			phase_shift = 1.0 - 2.0 * journey_percent - phase_shift
			phase_locked = true
		global_position.y = start_height - arc_size * sin((journey_percent + phase_shift) * PI)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		bonked = true
		phase_locked = false
