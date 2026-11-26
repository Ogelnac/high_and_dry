extends Node2D

@export_file("*.tscn") var boss_scene_path: String

@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var tap_button: Area2D = $TapButton

var player_in_area: bool = false

func _ready():
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

func _on_tap_button_input_event(_viewport, event, _shape_idx):
	if is_confirm_input(event) and player_in_area:
		if not boss_scene_path.is_empty():
			if DialogueManager.player.dialogue_mode:
				return
			DialogueManager.start_dialogue("tadd_boss", true)
			DialogueManager.set_input("[center]Ready to clear the blockage?[/center]", "Yes", "No")
			DialogueManager.bind_input(boss_scene_path)
			return
		var rand_dialogue: String = "tadd_" + str(randi_range(0, 5))
		DialogueManager.start_dialogue(rand_dialogue, false)
