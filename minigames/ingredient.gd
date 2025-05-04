extends Sprite2D

signal ingredient_added(ingredient_type: int)

@export var ingredient_type: int = 0
@export var ingredient_size = 64.0

var tap_global_pos = Vector2.ZERO
var tap_offset = Vector2.ZERO
var grabbed = false

var original_position = Vector2.ZERO

func _ready() -> void:
	original_position = global_position

func _process(delta: float) -> void:
	if grabbed:
		global_position = tap_global_pos + tap_offset

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.is_pressed() and sprite_tapped():
			tap_global_pos = get_global_mouse_position()
			tap_offset = global_position - get_global_mouse_position()
			grabbed = true
		if event.is_released():
			grabbed = false
			if dropped_in_pot():
				ingredient_added.emit(ingredient_type)
				queue_free()
			else:
				global_position = original_position
	
	if event is InputEventScreenDrag:
		tap_global_pos = get_global_mouse_position()

func sprite_tapped() -> bool:
	if abs(get_global_mouse_position().x - global_position.x) < ingredient_size \
	and abs(get_global_mouse_position().y - global_position.y) < ingredient_size:
		return true
	else:
		return false

func dropped_in_pot() -> bool:
	if (global_position - get_parent().global_position).length() < get_parent().POT_SIZE:
		return true
	else:
		return false
