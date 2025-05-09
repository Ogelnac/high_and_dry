extends Node2D

func _ready() -> void:
	GameManager.get_ui_reference()
	GameManager.hub_UI()
