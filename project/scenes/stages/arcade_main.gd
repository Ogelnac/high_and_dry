extends Node2D

# Level 0 - Tutorial
# Level 1 - Sewer
# Level 2 - Temple
# Level 3 - Depths

const LEVEL_TEMPLATE = preload("uid://cne0knoik5exi")
const LEVEL_1_0 = preload("uid://u557m6xvcvqr")
const LEVEL_1_BOAT_PICKUP = preload("uid://bwygpnwblafg4")
const LEVEL_1_BOAT_DROPOFF = preload("uid://b6erk81axuxl6")

const LEVEL_VISUALS = preload("uid://q1i62eqp5m7v")


var levels: Array[PackedScene]

@onready var player_host: Node2D = $PlayerHost
@onready var rising_death: Area2D = $RisingDeath
@onready var arcade_player: CharacterBody2D = $ArcadePlayer
@onready var arcade_ui: CanvasLayer = $CanvasLayer

var current_tile: int = 0
var max_tile_seen: int = 0
var max_tiles_loaded: int = 5
var tiles_in_scene: Array[Object] = []
var visuals_in_scene: Array[Object] = []

var is_playing: bool = false
var game_ended: bool = false

# UI
var end_game_button #Debug
var rich_text_label: RichTextLabel
var dialogue_input: Panel
var ui: Control

# Combo
var combo_counter: int = 0
const COUNTER = preload("uid://cpphloewhd56b")

func _ready() -> void:
	Debug.arcade_main_node_id = get_tree().get_current_scene()

	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput

	GameManager.get_ui_reference()
	GameManager.arcade_UI()

	ui = GameManager.UI.get_node("UI")
	dialogue_input = GameManager.UI.get_node("DialogueInput")
	rich_text_label = GameManager.UI.get_node("UI/RichTextLabel")
	if Debug.infinite_health:
		end_game_button = GameManager.UI.get_node("HBoxContainer/EndGame")
		end_game_button.show()

	if !GameManager.game_progress["tutorial_played"]:
		load_tutorial()

	pattern_update(0)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		is_playing = true
		rising_death.is_playing = true

func _process(_delta: float) -> void:
	if game_ended:
		return

	if arcade_player and arcade_player.breath == 0.0:
		end_run()
		return

	if is_playing:
		current_tile = -(round((player_host.global_position.y + 304.0) / 608.0) - 1)
		if current_tile > max_tile_seen:
			pattern_update(current_tile)
			max_tile_seen = current_tile
	
	if tiles_in_scene.size() > max_tiles_loaded:
		tiles_in_scene[max_tiles_loaded].queue_free()
		tiles_in_scene.remove_at(max_tiles_loaded)
	
	if visuals_in_scene.size() > max_tiles_loaded:
		visuals_in_scene[max_tiles_loaded].queue_free()
		visuals_in_scene.remove_at(max_tiles_loaded)

func load_tutorial():
	rich_text_label.visible = true
	rich_text_label.position = Vector2(0.0, 250.0)
	rich_text_label.text = "[rainbow][center][wave amp=25 freq=5]You are playing 
	the tutorial![/wave][/center]"

func pattern_update(tile: int) -> void:
	var visuals_instance: Node
	visuals_instance = LEVEL_VISUALS.instantiate()
	add_child(visuals_instance)
	visuals_instance.global_position.y = float(-608 * tile)
	
	var level_instance: Node
	if tile == 0:
		if GameManager.legs_completed == 0:
			# Start tile
			level_instance = LEVEL_1_0.instantiate()
			visuals_instance.find_child("ForegroundStart").visible = true
		else:
			# Boat dropoff
			level_instance = LEVEL_1_BOAT_DROPOFF.instantiate()
			visuals_instance.find_child("BackgroundDropOff").visible = true
			visuals_instance.find_child("ForegroundDropOff").visible = true
	elif tile == Debug.tiles_per_leg:
		# Add interim level
		level_instance = LEVEL_1_BOAT_PICKUP.instantiate()
		visuals_instance.find_child("ForegroundPickUp").visible = true
		level_instance.interim = true
	else:
		# Add random level
		level_instance = LEVEL_TEMPLATE.instantiate()
	
	add_child(level_instance)
	level_instance.global_position.y = float(-608 * tile)
	tiles_in_scene.insert(0, level_instance)
	visuals_in_scene.insert(0, visuals_instance)
	
	if tile > 0 and tile % 5 == 0:
		# Every 5 tiles spawn a special collectable
		pass

func end_run():
	game_ended = true

	rising_death.is_playing = false
	arcade_player.scale = Vector2.ONE
	arcade_player.velocity = Vector2.ZERO

	await player_end_animation_sequence()
	
	ui.shader_objects = ui.find_objects_with_shader()
	ui._fade_to_black(0.02)
	arcade_player.get_node("Sprite2D").z_index = 20
	arcade_player.get_node("ResourceTrail").z_index = 20
	
	if not GameManager.game_progress["tutorial_played"]:
		GameManager.game_progress["tutorial_played"] = true
		leave_arcade()
		return

	end_game_dialogue()

func end_game_dialogue():
	var option_1 = dialogue_input.get_node("Option1") as Button
	var option_2 = dialogue_input.get_node("Option2") as Button
	if not option_1.pressed.is_connected(reload_scene):
		option_1.pressed.connect(reload_scene)
	if not option_2.pressed.is_connected(leave_arcade):
		option_2.pressed.connect(leave_arcade)

	dialogue_input.get_node("Text").text = "[center]Try Again?"
	dialogue_input.show()

func player_end_animation_sequence() -> void:
	arcade_player.kill()
	Engine.time_scale = 0.25
	var t := get_tree().create_timer(0.5)
	await t.timeout

func reload_scene():
	GameManager.new_arcade_resources = []
	GameManager.clear_resource_cache()

	ui.update_shader_black_dot_transition(0.5)
	get_tree().reload_current_scene()

func leave_arcade():
	GameManager.player_start_position = Vector2(-192.0, -575.0)
	GameManager.UI.get_node("UI").display_swipe_to_start = false
	GameManager.trigger_pachinko = true
	GameManager.clear_resource_cache()

	rich_text_label.position = Vector2(0.0, 750.0)
	rich_text_label.text = "[center][wave amp=25 freq=5]Swipe up 
	to Play![/wave][/center]"

	if end_game_button != null:
		end_game_button.hide()

	Engine.time_scale = 1.0
	GameManager.save()
	ui.update_shader_black_dot_transition(0.5)
	get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
