extends Node2D

@onready var player: CharacterBody2D = $".."
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	modulate.a = 0.0
	animation_player.play("fill")
	animation_player.speed_scale = 0.0

func _process(delta: float) -> void:
	var anim := animation_player.get_animation("fill")
	if anim:
		var t = clamp(player.breath, 0.0, 1.0) * anim.length
		animation_player.seek(1.0 - t, true)

	var target_a = 1.0 if player.breath < 1.0 else 0.0
	modulate.a = clamp(lerp(modulate.a, target_a, 10.0 * delta), 0.0, 1.0)
