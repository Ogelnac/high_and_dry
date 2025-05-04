extends Node2D

@export var horizontal_motion_scale: float = 0.5
@export var vertical_motion_scale: float = 0.0
@onready var player = null
@onready var camera = null

var initial_position: Vector2 = Vector2.ZERO
var reference_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	player = get_node("/root/Main/Player")
	camera = get_node("/root/Main/Camera2D")

	if player and camera:
		reference_position = Vector2(player.global_position.x, camera.global_position.y)

	initial_position = global_position

func _process(_delta):
	if not player or not camera:
		return

	var delta_x = player.global_position.x - reference_position.x
	var delta_y = camera.global_position.y - reference_position.y

	global_position = initial_position + Vector2(delta_x * horizontal_motion_scale, delta_y * vertical_motion_scale)
