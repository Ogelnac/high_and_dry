class_name HubResident
extends Node2D

signal home_request_requested(resident: Node2D)

@export var walk_speed := 85.0
@export var roam_radius := 28.0
@export var minimum_idle_time := 1.5
@export var maximum_idle_time := 4.0

@onready var villager: Node2D = $Villager
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var tap_button: Area2D = $TapButton

var villager_id: StringName
var location_id: StringName
var house_index := -1
var player_in_area := false
var interaction_active := false
var panel_interaction_active := false
var consume_upgrade_comment_after_dialogue := false
var nearby_player: CharacterBody2D
var roam_center_x := 0.0
var target_x := 0.0
var idle_time_remaining := 0.0
var is_walking := false
var roaming_enabled := false
var proximity_paused := false

func _ready() -> void:
	roam_center_x = position.x
	target_x = position.x
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_begin_idle()

func _process(delta: float) -> void:
	if not roaming_enabled or interaction_active or proximity_paused:
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

func set_villager_id(value: StringName) -> void:
	villager_id = value
	villager.set_villager_id(value)
	villager.set_running(false)

func setup(value: StringName, value_house_index: int, tier: int) -> void:
	set_villager_id(value)
	house_index = value_house_index
	roaming_enabled = tier >= 1
	_begin_idle()

func configure_location(value_location_id: StringName, center_global_position: Vector2, value_roam_radius: float, can_roam: bool, starting_offset_x: float = 0.0) -> void:
	location_id = value_location_id
	var resident_parent := get_parent() as Node2D
	if resident_parent == null:
		return
	var center_local_position: Vector2 = resident_parent.to_local(center_global_position)
	position = center_local_position + Vector2(starting_offset_x, 0.0)
	roam_center_x = center_local_position.x
	target_x = position.x
	roam_radius = maxf(value_roam_radius, 0.0)
	roaming_enabled = can_roam
	_begin_idle()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = body as CharacterBody2D
		player_in_area = true
		proximity_paused = true
		is_walking = false
		villager.set_running(false)
		_face_villager_toward_player()
		if not interaction_active:
			popup.visible = true
			popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = null
		player_in_area = false
		proximity_paused = false
		popup_animation.stop()
		popup.visible = false
		if not interaction_active:
			_begin_idle()

func _on_tap_button_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if _is_confirm_input(event) and player_in_area and not interaction_active and not nearby_player.dialogue_mode:
		_start_interaction()

func _start_interaction() -> void:
	var definition: VillagerDefinition = VillagerManager.get_definition(villager_id)
	if definition == null or nearby_player == null:
		return
	interaction_active = true
	tap_button.input_pickable = false
	popup_animation.stop()
	popup.visible = false
	_face_nearby_player()
	nearby_player.interaction_controls_locked = true
	if VillagerManager.has_home_upgrade_request(house_index):
		panel_interaction_active = true
		home_request_requested.emit(self)
		return
	var dialogue_context := &"normal"
	var fallback_text := "[PLACEHOLDER DIALOGUE]"
	if VillagerManager.has_upgrade_comment(house_index):
		dialogue_context = &"home_upgrade_comment"
		fallback_text = "[PLACEHOLDER HOME UPGRADE COMMENT]"
		consume_upgrade_comment_after_dialogue = true
	var dialogue_lines: Array[Dictionary] = VillagerManager.get_villager_dialogue(villager_id, dialogue_context, VillagerManager.get_house_tier(house_index))
	if dialogue_lines.is_empty():
		dialogue_lines.append({
			"name": definition.display_name,
			"pitch": [0.9, 1.1],
			"text": fallback_text
		})
	if dialogue_context == &"normal":
		GameManager.save()
	DialogueManager.start_inline_dialogue(dialogue_lines)

func _on_dialogue_finished() -> void:
	if not interaction_active or panel_interaction_active:
		return
	if consume_upgrade_comment_after_dialogue:
		VillagerManager.consume_upgrade_comment(house_index)
		GameManager.save()
		consume_upgrade_comment_after_dialogue = false
	call_deferred("_finish_interaction")

func finish_panel_interaction() -> void:
	panel_interaction_active = false
	call_deferred("_finish_interaction")

func _finish_interaction() -> void:
	interaction_active = false
	tap_button.input_pickable = true
	if nearby_player != null:
		nearby_player.interaction_controls_locked = false
	if player_in_area:
		popup.visible = true
		popup_animation.play("OpenPopup")
	else:
		_begin_idle()

func _begin_idle() -> void:
	is_walking = false
	idle_time_remaining = randf_range(minimum_idle_time, maximum_idle_time)
	if villager != null:
		villager.set_running(false)

func _begin_walk() -> void:
	target_x = randf_range(roam_center_x - roam_radius, roam_center_x + roam_radius)
	if abs(target_x - position.x) < 12.0:
		target_x = roam_center_x + roam_radius if position.x < roam_center_x else roam_center_x - roam_radius
	is_walking = true
	villager.set_facing_direction(sign(target_x - position.x))
	villager.set_running(true)

func _face_villager_toward_player() -> void:
	if nearby_player == null:
		return
	var direction_to_player: float = nearby_player.global_position.x - global_position.x
	villager.set_facing_direction(direction_to_player)

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
