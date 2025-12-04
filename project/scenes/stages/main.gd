extends Node2D

const LEVEL_0_0 = preload("uid://clie4grf2wmfy")
const LEVEL_0_1 = preload("uid://tjrjwyu0stqt")
const LEVEL_1_0 = preload("uid://u557m6xvcvqr")
const LEVEL_1_01 = preload("uid://bwygpnwblafg4")
const LEVEL_1_1 = preload("uid://deu25squitwvx")
const LEVEL_1_02 = preload("uid://b6erk81axuxl6")
const LEVEL_1_2 = preload("uid://cpv6jpxilgdk0")
const LEVEL_1_3 = preload("uid://chex3tojvu8j0")
const LEVEL_2_0 = preload("uid://bkff3ip4jih0v")
const LEVEL_2_1 = preload("uid://d2yys6p3i4ttj")
const LEVEL_2_2 = preload("uid://dcnbvwe0jkt64")

var levels: Array[PackedScene]

@onready var player: Node2D = $PlayerHost
@onready var rising_death: Area2D = $RisingDeath
@onready var arcade_player: CharacterBody2D = $ArcadePlayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var tiles_in_scene: Array[Object] = []
var is_playing: bool = false
var game_ended: bool = false
var current_tile: int = 1
var prev_tile: int = 1

# UI
var end_game_button #Debug
var rich_text_label: RichTextLabel
var dialogue_input: Panel
var ui: Control 

# Combo
var combo_timer: Timer
var combo_window: float = 1.0
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

	if not GameManager.game_progress["demo_played"]:
		GameManager.stage_level = Vector2i(0, 0)

	combo_timer = Timer.new()
	combo_timer.one_shot = true
	add_child(combo_timer)
	combo_timer.timeout.connect(_end_combo)

	setup_levels(GameManager.stage_level)
	pattern_update(0)

func _end_combo():
	combo_counter = 0

func restart_timer(at: Vector2):
	if combo_timer:
		combo_timer.stop()
	combo_counter += 1
	combo_timer.start(combo_window)
	spawn_counter(at)

func spawn_counter(pos: Vector2):
	var instance = COUNTER.instantiate()
	instance.number_value = combo_counter
	instance.lifetime = combo_window
	instance.global_position = pos
	add_child(instance)

func _process(_delta: float) -> void:
	if game_ended:
		return

	if (arcade_player and arcade_player.breath == 0.0) or Debug.game_ended:
		end_run()

	if is_playing:
		current_tile = round(player.global_position.y / 608.0) - 1
		if prev_tile > current_tile:
			pattern_update(current_tile)
			prev_tile = current_tile
	
	if tiles_in_scene.size() > 4:
		tiles_in_scene[4].queue_free()
		tiles_in_scene.remove_at(4)

func pattern_update(tile: int) -> void:
	var level_instance

	if tile == 0:
		# Start tile
		level_instance = levels[0].instantiate()
	if tile == Debug.number_of_levels:
		# Add interim level
		level_instance = levels[1].instantiate()
		level_instance.interim = true
	elif level_instance == null:
		# Add random level
		var rand_level = randi_range(2, levels.size() - 1)
		level_instance = levels[rand_level].instantiate()

	add_child(level_instance)
	if tile < 0 and tile % 5 == 0:
		# Every 5 levels has a Special Collectable (SC)
		level_instance.spawn_sc()
	level_instance.global_position.y = float(608 * tile)
	tiles_in_scene.insert(0, level_instance)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		is_playing = true
		rising_death.is_playing = true;

func end_run():
	game_ended = true
	Debug.game_ended = false

	rising_death.is_playing = false
	arcade_player.scale = Vector2.ONE
	arcade_player.velocity = Vector2.ZERO

	await player_end_animation_sequence()
	
	ui.shader_objects = ui.find_objects_with_shader()
	ui._fade_to_black(0.02)
	arcade_player.get_node("Sprite2D").z_index = 50
	arcade_player.get_node("ResourceTrail").z_index = 50
	
	if not GameManager.game_progress["demo_played"]:
		GameManager.game_progress["demo_played"] = true
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
	get_tree().change_scene_to_file("res://main.tscn")

func player_end_animation_sequence() -> void:
	arcade_player.kill()
	Engine.time_scale = 0.25
	var t := get_tree().create_timer(0.5)
	await t.timeout

func setup_levels(stage_and_level: Vector2i):
	if stage_and_level.x == 0:
		levels = [LEVEL_0_0, LEVEL_1_01, LEVEL_0_1]
		rich_text_label.visible = true
		rich_text_label.position = Vector2(0.0, 250.0)
		rich_text_label.text = "[rainbow][center][wave amp=25 freq=5]You are playing 
		the Demo![/wave][/center]"
		return
	elif stage_and_level.x == 1:
		if stage_and_level.y == 0:
			levels = [LEVEL_1_0, LEVEL_1_01, LEVEL_1_1, LEVEL_1_2, LEVEL_1_3, LEVEL_2_1, LEVEL_2_2]
			return
		elif stage_and_level.y == 1:
			levels = [LEVEL_1_02, LEVEL_1_01, LEVEL_1_1, LEVEL_1_2, LEVEL_1_3, LEVEL_2_1, LEVEL_2_2]
			return
		else:
			levels = [LEVEL_0_0, LEVEL_1_01, LEVEL_0_1]
			return
	else:
		levels = [LEVEL_0_0, LEVEL_1_01, LEVEL_0_1]
