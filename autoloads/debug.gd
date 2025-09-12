extends Node

var infinite_resources: bool = false
var infinite_health: bool = false
var disable_rising_death: bool = false

var game_ended: bool = false

# Add a cache for resources between runs not seperate by hub. should fix resource string

#Demo tadd trader
var expell_res: bool = false
var res_expelled: bool = false
var switch_player: bool = false

var arcade_main_node_id: Node

func end_game_button_visibility():
	if get_tree().get_current_scene() == arcade_main_node_id:
		var end_game_button = GameManager.UI.get_node("HBoxContainer/EndGame")
		end_game_button.visible = infinite_health

func _process(_delta: float) -> void:
	if res_expelled:
		expell_res = false
		switch_player = true
		res_expelled = false
