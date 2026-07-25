extends Camera2D

@export var pestos_min_y: float = -396.0
@export var pestos_max_y: float = 70.0
@export var weavers_min_x: float = 190.0
@export var weavers_max_x: float = 610.0

var is_in_pestos: bool = false
var is_in_weavers: bool = false
var player: Node2D = null

@onready var pestos: Area2D = $"../CameraZones/Pestos"
@onready var weavers: Area2D = $"../CameraZones/Weavers"

@onready var left: Area2D = $"../CameraZones/Left"
@onready var mid_left: Area2D = $"../CameraZones/MidLeft"
@onready var middle: Area2D = $"../CameraZones/Middle"
@onready var mid_right: Area2D = $"../CameraZones/MidRight"
@onready var right: Area2D = $"../CameraZones/Right"

@onready var ui: Control = $"../CanvasLayer/UI"

@onready var parallax_array: Array[Node2D] = [
	$"../Environment/Background",
	$"../Environment/MidBackground",
	$"../Environment/ForeGround",
	$"../Environment/ForeGround",
	$"../Environment/Pachinko",
	$"../Environment/Title",
	$"../Environment/Water",
	$"../Environment/Ink",
	$"../Environment/Lava",
	$"../Environment/Sewage"]

func _ready() -> void:
	pestos.body_entered.connect(_on_pestos_body_entered)
	weavers.body_entered.connect(_on_weavers_body_entered)

	left.body_entered.connect(_on_left_body_entered)
	mid_left.body_entered.connect(_on_mid_left_body_entered)
	middle.body_entered.connect(_on_middle_body_entered)
	mid_right.body_entered.connect(_on_mid_right_body_entered)
	right.body_entered.connect(_on_right_body_entered)

func _on_left_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = left.global_position
		is_in_pestos = false
		is_in_weavers = false
		player = body
		_reset_parallax(left.global_position)

func _on_mid_left_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = mid_left.global_position
		is_in_pestos = false
		is_in_weavers = false
		player = body
		_reset_parallax(mid_left.global_position)

func _on_middle_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = middle.global_position
		is_in_pestos = false
		is_in_weavers = false
		player = body
		_reset_parallax(middle.global_position)

func _on_mid_right_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = mid_right.global_position
		is_in_pestos = false
		is_in_weavers = false
		player = body
		_reset_parallax(mid_right.global_position)

func _on_right_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = right.global_position
		is_in_pestos = false
		is_in_weavers = false
		player = body
		_reset_parallax(right.global_position)

func _on_pestos_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = pestos.global_position
		is_in_pestos = true
		is_in_weavers = false
		player = body
		_reset_parallax(pestos.global_position)

func _on_weavers_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = weavers.global_position
		is_in_pestos = false
		is_in_weavers = true
		player = body
		_reset_parallax(weavers.global_position)

func _physics_process(_delta: float) -> void:
	if player:
		global_position.y = player.global_position.y - 120.0

	if is_in_pestos and player:
		global_position.y = clamp(player.global_position.y - 160, pestos_min_y, pestos_max_y)

	if is_in_weavers and player:
		global_position.x = clamp(player.global_position.x, weavers_min_x, weavers_max_x)

func _reset_parallax(new_position: Vector2):
	for parallax in parallax_array:
		parallax._reset_reference(new_position)
