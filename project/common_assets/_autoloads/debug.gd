extends Node

signal world_notes_visibility_changed(visible: bool)
signal hub_free_camera_changed(enabled: bool)
signal villagers_enabled_changed(enabled: bool)

var infinite_resources: bool = false
var infinite_silkworms: bool = false
var infinite_health: bool = false
var disable_rising_death: bool = false
var guarantee_tadd_villager: bool = false
var unlock_villager_dye_requests: bool = true
var world_notes_visible: bool = false
var hub_free_camera: bool = false
var villagers_enabled: bool = false
var world_note_input_captured: bool = false
var active_world_note: Node = null
var number_of_levels: int = 5
var tiles_per_leg: int = 4

# Tutorial Tadd trader
var expel_res: bool = false
var res_expelled: bool = false
var switch_player: bool = false

var arcade_main_node_id: Node

func set_world_notes_visible(visible: bool) -> void:
	world_notes_visible = visible
	world_notes_visibility_changed.emit(visible)

func set_hub_free_camera(enabled: bool) -> void:
	hub_free_camera = enabled
	hub_free_camera_changed.emit(enabled)

func set_villagers_enabled(enabled: bool) -> void:
	villagers_enabled = enabled
	villagers_enabled_changed.emit(enabled)

func end_game_button_visibility():
	if get_tree().get_current_scene() == arcade_main_node_id:
		var end_game_button = GameManager.UI.get_node("HBoxContainer/EndGame")
		end_game_button.visible = infinite_health

func _process(_delta: float) -> void:
	if res_expelled:
		expel_res = false
		switch_player = true
		res_expelled = false
