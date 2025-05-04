extends Area2D

@onready var player: CharacterBody2D = $"../Player"
@onready var main: Node2D = $".."
var is_playing: bool = 0

func _process(delta: float) -> void:
	if is_playing:
		#global_position.y = move_toward(global_position.y, player.global_position.y - 50.0, 30.0 * delta) 
		var offset = 0.0
		if player.global_position.y <= global_position.y + offset:
			#global_position.y = global_position.lerp(player.global_position - Vector2(0.0, offset), 2.0 * delta).y
			global_position.y = player.global_position.y - offset
		global_position.y = global_position.y - 50.0 * delta
		#elif global_position.y > player.global_position.y:

func _on_body_entered(body: Node2D) -> void:
	main.stink_multiplier = 4.0

func _on_body_exited(body: Node2D) -> void:
	main.stink_multiplier = 1.0
