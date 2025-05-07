extends TextureRect

@export var joystick_handle: TextureRect
@export var follow_weight: float = 0.5
@export var move_speed: float = 10.0

var target_position: Vector2

func _ready():
	if joystick_handle:
		target_position = get_centered_position(joystick_handle.global_position, joystick_handle.size)
		global_position = target_position

func _process(delta: float):
	if joystick_handle:
		var handle_center = get_centered_position(joystick_handle.global_position, joystick_handle.size)
		var blended_position = handle_center.lerp(target_position, follow_weight)
		global_position = global_position.lerp(blended_position, move_speed * delta)

func set_base_position(new_center_position: Vector2) -> void:
	target_position = get_centered_position(new_center_position, size)
	global_position = target_position

func get_centered_position(ctr_position: Vector2, rect_size: Vector2) -> Vector2:
	return ctr_position - (size * scale * 0.5)
