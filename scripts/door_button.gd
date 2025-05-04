extends Area2D

signal sprite_tapped

func _ready():
	input_pickable = true

func _input_event(viewport, event, shape_idx):
	if event is InputEventScreenTouch and event.pressed:
		_on_sprite_tapped()
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_sprite_tapped()

func _on_sprite_tapped():
	sprite_tapped.emit()
