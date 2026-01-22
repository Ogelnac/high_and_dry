extends Node

var infinite_resources: bool = false
var infinite_health: bool = false
var disable_rising_death: bool = false
var tiles_per_leg: int = 4

# Tutorial Tadd trader
var expel_res: bool = false
var res_expelled: bool = false
var switch_player: bool = false

var arcade_main_node_id: Node

func end_game_button_visibility():
	if get_tree().get_current_scene() == arcade_main_node_id:
		var end_game_button = GameManager.UI.get_node("HBoxContainer/EndGame")
		end_game_button.visible = infinite_health

func _process(_delta: float) -> void:
	if res_expelled:
		expel_res = false
		switch_player = true
		res_expelled = false
