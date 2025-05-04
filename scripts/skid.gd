extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skid: AudioStreamPlayer = $Skid

func _ready():
	skid.play()
	animation_player.play("skid")
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "skid":
		queue_free()
