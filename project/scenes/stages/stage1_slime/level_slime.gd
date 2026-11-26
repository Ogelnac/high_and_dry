extends Node2D


func _ready() -> void:
	Debug.arcade_main_node_id = self

	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput

	GameManager.get_ui_reference($CanvasLayer)
	GameManager.arcade_UI()
	$CanvasLayer/HBoxContainer/EndGame.visible = Debug.infinite_health

	var resource_trail: Line2D = $ArcadePlayer/ResourceTrail
	resource_trail.hide()
	resource_trail.process_mode = Node.PROCESS_MODE_DISABLED
