extends Node2D

func _ready() -> void:
	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	
	GameManager.get_ui_reference()
	GameManager.hub_UI()
