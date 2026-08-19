extends Node2D

func _ready() -> void:
	GameManager.load_game()
	var tutorial_played := GameManager.game_progress["tutorial_played"]
	call_deferred("_switch_scene", tutorial_played)

func _switch_scene(tutorial_played: bool) -> void:
	if tutorial_played:
		get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
	else:
		get_tree().change_scene_to_file("uid://dxc74hnt0exva")
