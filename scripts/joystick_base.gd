extends TextureRect

@export var joystick_handle: TextureRect
@export var follow_weight: float = 0.5
@export var move_speed: float = 10.0

var target_position: Vector2

func _ready():
	if joystick_handle:
		target_position = get_centered_position(joystick_handle.global_position, joystick_handle.size)

func _process(delta: float):
	if joystick_handle:
		var handle_center = get_centered_position(joystick_handle.global_position, joystick_handle.size)
		var blended_position = handle_center.lerp(target_position, follow_weight)
		global_position = global_position.lerp(blended_position, move_speed * delta)

func update_target(new_position: Vector2):
	target_position = get_centered_position(new_position, size)

func get_centered_position(position: Vector2, rect_size: Vector2) -> Vector2:
	return position - (size * scale * 0.5)
