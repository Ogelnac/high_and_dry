extends Node2D

func _ready() -> void:
	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/UI/DialogueInput

	GameManager.get_ui_reference()
	GameManager.hub_UI()
	GameManager.circle_fade = $CanvasLayer/UI/CircleFade
