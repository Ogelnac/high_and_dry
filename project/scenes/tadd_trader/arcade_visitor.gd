extends Node2D

signal interaction_requested

@export var walk_speed := 85.0
@export var minimum_idle_time := 1.5
@export var maximum_idle_time := 4.0

@onready var villager: Node2D = $Villager
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var tap_button: Area2D = $TapButton

var villager_id: StringName
var player_in_area := false
var walk_min_x := -80.0
var walk_max_x := 240.0
var walk_y := -31.0
var target_x := 0.0
var idle_time_remaining := 0.0
var is_walking := false
var interaction_paused := false
var nearby_player: CharacterBody2D

func _ready() -> void:
	villager.set_villager_id(villager_id)
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)
	_begin_idle()

func _process(delta: float) -> void:
	if interaction_paused:
		return
	if is_walking:
		var direction: float = float(sign(target_x - position.x))
		villager.set_facing_direction(direction)
		position.x = move_toward(position.x, target_x, walk_speed * delta)
		if is_equal_approx(position.x, target_x):
			_begin_idle()
	else:
		idle_time_remaining -= delta
		if idle_time_remaining <= 0.0:
			_begin_walk()

func setup(value: StringName) -> void:
	villager_id = value
	var villager_node := get_node_or_null("Villager")
	if villager_node != null:
		villager_node.set_villager_id(value)

func configure_walk_area(minimum_x: float, maximum_x: float, y_position: float) -> void:
	walk_min_x = min(minimum_x, maximum_x)
	walk_max_x = max(minimum_x, maximum_x)
	walk_y = y_position
	position = Vector2(randf_range(walk_min_x, walk_max_x), walk_y)
	target_x = position.x

func resume_wandering() -> void:
	interaction_paused = false
	_begin_idle()

func _begin_idle() -> void:
	is_walking = false
	idle_time_remaining = randf_range(minimum_idle_time, maximum_idle_time)
	if villager != null:
		villager.set_running(false)

func _begin_walk() -> void:
	target_x = randf_range(walk_min_x, walk_max_x)
	if abs(target_x - position.x) < 24.0:
		target_x = walk_max_x if position.x < (walk_min_x + walk_max_x) * 0.5 else walk_min_x
	is_walking = true
	villager.set_facing_direction(sign(target_x - position.x))
	villager.set_running(true)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = body as CharacterBody2D
		player_in_area = true
		popup.visible = true
		popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = null
		player_in_area = false
		popup_animation.stop()
		popup.visible = false

func _on_tap_button_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if _is_confirm_input(event) and player_in_area and not interaction_paused:
		interaction_paused = true
		is_walking = false
		villager.set_running(false)
		_face_nearby_player()
		interaction_requested.emit()

func _face_nearby_player() -> void:
	if nearby_player == null:
		return
	var direction_to_player: float = nearby_player.global_position.x - global_position.x
	villager.set_facing_direction(direction_to_player)
	nearby_player.velocity.x = 0.0
	nearby_player.direction = 1 if direction_to_player < 0.0 else -1
	nearby_player.is_facing_right = direction_to_player < 0.0
	nearby_player.sprite.flip_h = not nearby_player.is_facing_right
	nearby_player.change_state("Idle")

func _is_confirm_input(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch or event is InputEventMouseButton) \
		and event.pressed \
		and (not event is InputEventMouseButton or event.button_index == MOUSE_BUTTON_LEFT)
