extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer

var player_in_area: bool = false

func _ready():
	animation_player.play("Idle")
	popup.visible = false
	start_flip_timer()

func start_flip_timer():
	var wait_time = randf_range(1.0, 5.0)
	await get_tree().create_timer(wait_time).timeout
	sprite.flip_h = not sprite.flip_h
	start_flip_timer()

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
	if is_confirm_input(event):
		DialogueManager.start_dialogue("pesto_welcome")
		
