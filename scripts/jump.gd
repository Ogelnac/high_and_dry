extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var jump: AudioStreamPlayer = $Jump

func _ready():
	jump.play()
	animation_player.play("jump")
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "jump":
		queue_free()
