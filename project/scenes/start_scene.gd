extends Node2D

func _ready() -> void:
	GameManager.load_game()
	var demo_played := GameManager.game_progress["demo_played"]
	call_deferred("_switch_scene", demo_played)

func _switch_scene(demo_played: bool) -> void:
	if demo_played:
		get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
	else:
		get_tree().change_scene_to_file("uid://dxc74hnt0exva")
