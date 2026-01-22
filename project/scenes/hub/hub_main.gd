extends Node2D

func _ready() -> void:
	await get_tree().process_frame
	if !GameManager.game_progress["tutorial_played"]:
		get_tree().change_scene_to_file("uid://dxc74hnt0exva")
		return

	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput

	GameManager.get_ui_reference()
	GameManager.hub_UI()
	GameManager.circle_fade = $CanvasLayer/UI/CircleFade
