extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var start_height = 0.0

var max_time = 5.0
var time = max_time

func _process(delta: float) -> void:
	time -= delta
	if time < 0.0:
		queue_free()
	else:
		var journey_percent = time/max_time
		global_position.y = start_height - 128.0 * sin(journey_percent*PI)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		print("Ew! You just touched me!")
		queue_free()
