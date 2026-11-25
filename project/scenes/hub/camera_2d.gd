extends Camera2D

@export var debug_pan_speed: float = 300.0

@export var pestos_min_x: float = -776.0
@export var pestos_max_x: float = -376.0
@export var weavers_min_x: float = -800.0
@export var weavers_max_x: float = -417.0

var is_in_pestos: bool = false
var is_in_weavers: bool = false
var player: Node2D = null
var active_zone: Area2D = null

@onready var pestos: Area2D = $"../CameraZones/Pestos"
@onready var weavers: Area2D = $"../CameraZones/Weavers"

@onready var left: Area2D = $"../CameraZones/Left"
@onready var mid_left: Area2D = $"../CameraZones/MidLeft"
@onready var middle: Area2D = $"../CameraZones/Middle"
@onready var mid_right: Area2D = $"../CameraZones/MidRight"
@onready var right: Area2D = $"../CameraZones/Right"

@onready var ui: Control = $"../CanvasLayer/UI"
@onready var parallax_controller: Node = $"../Environment"
@onready var audio_listener: AudioListener2D = $AudioListener2D
@onready var hub_player: Node2D = $"../Player"

func _ready() -> void:
	audio_listener.make_current()
	pestos.body_entered.connect(_on_pestos_body_entered)
	weavers.body_entered.connect(_on_weavers_body_entered)

	left.body_entered.connect(_on_left_body_entered)
	mid_left.body_entered.connect(_on_mid_left_body_entered)
	middle.body_entered.connect(_on_middle_body_entered)
	mid_right.body_entered.connect(_on_mid_right_body_entered)
	right.body_entered.connect(_on_right_body_entered)
	Debug.hub_free_camera_changed.connect(_on_hub_free_camera_changed)
	player = hub_player
	call_deferred("_sync_active_zone")

func _on_left_body_entered(body: Node2D) -> void:
	_activate_zone(body, left)

func _on_mid_left_body_entered(body: Node2D) -> void:
	_activate_zone(body, mid_left)

func _on_middle_body_entered(body: Node2D) -> void:
	_activate_zone(body, middle)

func _on_mid_right_body_entered(body: Node2D) -> void:
	_activate_zone(body, mid_right)

func _on_right_body_entered(body: Node2D) -> void:
	_activate_zone(body, right)

func _on_pestos_body_entered(body: Node2D) -> void:
	_activate_zone(body, pestos, true)

func _on_weavers_body_entered(body: Node2D) -> void:
	_activate_zone(body, weavers, false, true)

func _activate_zone(body: Node2D, zone: Area2D, in_pestos: bool = false, in_weavers: bool = false) -> void:
	if body.name != "Player":
		return
	active_zone = zone
	is_in_pestos = in_pestos
	is_in_weavers = in_weavers
	player = body
	if Debug.hub_free_camera:
		return
	global_position = zone.global_position
	_reset_parallax()

func _sync_active_zone() -> void:
	for zone: Area2D in [pestos, weavers, left, mid_left, middle, mid_right, right]:
		if zone.overlaps_body(hub_player):
			_activate_zone(hub_player, zone, zone == pestos, zone == weavers)
			return

func _on_hub_free_camera_changed(free_enabled: bool) -> void:
	if free_enabled or not is_instance_valid(active_zone):
		return
	global_position = active_zone.global_position
	_reset_parallax()

func _physics_process(delta: float) -> void:
	if Debug.hub_free_camera:
		var direction := Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		)
		global_position += direction.normalized() * debug_pan_speed * delta
		audio_listener.global_position = get_screen_center_position()
		return

	if player:
		global_position.y = player.global_position.y - 120.0

	if is_in_pestos and player:
		global_position.x = clamp(player.global_position.x, pestos_min_x, pestos_max_x)
		global_position.y = pestos.global_position.y

	if is_in_weavers and player:
		global_position.x = clamp(player.global_position.x, weavers_min_x, weavers_max_x)

	audio_listener.global_position = get_screen_center_position()

func _reset_parallax() -> void:
	parallax_controller.reset_reference()
