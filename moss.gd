extends Node2D

@onready var detection_area: Area2D = $DetectionArea
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var tap_button: Area2D = $TapButton

var player_in_area: bool = false

func _ready() -> void:
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		popup.visible = true
		popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if popup_animation.is_playing():
			popup_animation.stop()
			popup.visible = false
		else:
			popup.visible = false

func is_confirm_input(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch or event is InputEventMouseButton) \
		and event.pressed \
		and (not event is InputEventMouseButton or event.button_index == MOUSE_BUTTON_LEFT)

func _on_tap_button_input_event(viewport, event, shape_idx):
	if is_confirm_input(event) and player_in_area:
		DialogueManager.start_dialogue("moss_1", false)
