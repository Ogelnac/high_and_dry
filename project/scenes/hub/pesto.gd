extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer

var player_in_area: bool = false

func _ready():
	animation_player.play("Idle")
	popup.visible = false

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
		if GameManager.unprocessed_resources.size()>= 50 or Debug.infinite_resources:
			DialogueManager.start_dialogue("pesto_start", true)
			DialogueManager.set_input("[center]Would you like to play [color=CHARTREUSE]Whack-A-Pesto[/color]?", "Yes", "No")
			DialogueManager.bind_input("res://whack_a_pesto.tscn")
		else:
			DialogueManager.start_dialogue("pesto_wait", false)
