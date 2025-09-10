extends Control

@onready var player: CharacterBody2D

func _process(_delta: float) -> void:
	if player:
		var player_pos = player.get_global_transform_with_canvas()
		position = player_pos.get_origin()
