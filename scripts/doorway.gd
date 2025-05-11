extends Node2D

@export var teleport_point: Transform2D
@export var player: Node2D
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var door_button: Area2D = $DoorButton
@onready var door: AudioStreamPlayer = $Door

var player_in_area: bool = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		popup.visible = true
		door_button.visible = true
		popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if popup_animation.is_playing():
			popup_animation.stop()
			popup.visible = false
			door_button.visible = false
		else:
			popup.visible = false
			door_button.visible = false

func _on_door_button_input_event(viewport, event, shape_idx):
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		door.play()
		player.global_transform = teleport_point
