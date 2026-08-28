extends Node2D

@onready var villager: Node2D = $Villager
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var tap_button: Area2D = $TapButton

var villager_id: StringName
var player_in_area := false
var interaction_active := false
var nearby_player: CharacterBody2D

func _ready() -> void:
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func set_villager_id(value: StringName) -> void:
	villager_id = value
	villager.set_villager_id(value)
	villager.set_running(false)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = body as CharacterBody2D
		player_in_area = true
		_face_villager_toward_player()
		if not interaction_active:
			popup.visible = true
			popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		nearby_player = null
		player_in_area = false
		popup_animation.stop()
		popup.visible = false

func _on_tap_button_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if _is_confirm_input(event) and player_in_area and not interaction_active and not nearby_player.dialogue_mode:
		_start_interaction()

func _start_interaction() -> void:
	var definition: VillagerDefinition = VillagerManager.get_definition(villager_id)
	if definition == null or nearby_player == null:
		return
	interaction_active = true
	popup_animation.stop()
	popup.visible = false
	_face_nearby_player()
	nearby_player.interaction_controls_locked = true
	DialogueManager.start_inline_dialogue([{
		"name": definition.display_name,
		"pitch": [0.9, 1.1],
		"text": "[PLACEHOLDER DIALOGUE]"
	}])

func _on_dialogue_finished() -> void:
	if not interaction_active:
		return
	interaction_active = false
	if nearby_player != null:
		nearby_player.interaction_controls_locked = false
	if player_in_area:
		popup.visible = true
		popup_animation.play("OpenPopup")

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
