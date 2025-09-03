extends Node2D

const LEVEL_0_0 = preload("res://levels/level_0_0.tscn")
const LEVEL_0_1 = preload("res://levels/level_0_1.tscn")

const LEVEL_1_0 = preload("res://levels/level_1_0.tscn")
const LEVEL_1_1 = preload("res://levels/level_1_1.tscn")
const LEVEL_1_2 = preload("res://levels/level_1_2.tscn")
const LEVEL_1_3 = preload("res://levels/level_1_3.tscn")
const LEVEL_1_01 = preload("res://levels/level_1_01.tscn")

#const LEVEL_2_0 = preload("res://levels/level_2_0.tscn")
const LEVEL_2_1 = preload("res://levels/level_2_1.tscn")
const LEVEL_2_2 = preload("res://levels/level_2_2.tscn")

var levels = [LEVEL_1_0, LEVEL_1_01, LEVEL_1_1, LEVEL_1_2, LEVEL_1_3, LEVEL_2_1, LEVEL_2_2]

@onready var player: Node2D = $PlayerHost
@onready var rising_death: Area2D = $RisingDeath
@onready var arcade_player: CharacterBody2D = $ArcadePlayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var rich_text_label: RichTextLabel
var tiles_in_scene: Array[Object] = []
var is_playing: bool = false
var game_ended: bool = false
var current_tile: int = 1
var prev_tile: int = 1
var tile_counter: int = 0

#DEBUG
var end_game_button

func _ready() -> void:
	pattern_update(0, 1)

	Debug.arcade_main_node_id = get_tree().get_current_scene()

	GameManager.get_ui_reference()
	GameManager.arcade_UI()
	rich_text_label = GameManager.UI.get_node("UI/RichTextLabel")
	if Debug.infinite_health:
		end_game_button = GameManager.UI.get_node("HBoxContainer/EndGame")
		end_game_button.show()

	if not GameManager.game_progress["demo_played"]:
		setup_demo()

func _process(_delta: float) -> void:
	if game_ended:
		return

	if (arcade_player and arcade_player.breath == 0.0) or Debug.game_ended:
		end_game()

	if is_playing:
		current_tile = round(player.global_position.y / 608.0)
		if prev_tile > current_tile:
			pattern_update(-1, current_tile)
			tile_counter += 1
			prev_tile = current_tile
	
	if tiles_in_scene.size() > 4:
		tiles_in_scene[4].queue_free()
		tiles_in_scene.remove_at(4)

func pattern_update(level: int, tile: int) -> void:
	var level_instance
	if level < 0:
		if tile_counter > 0 and tile_counter % 5 == 0:
			# Add interim level
			level_instance = levels[1].instantiate()
			level_instance.interim = true
		else:
			# Add random level
			var rand_level = randi_range(2, levels.size() - 1)
			level_instance = levels[rand_level].instantiate()
	else:
		# Add level from index
		level_instance = levels[level].instantiate()

	add_child(level_instance)
	# Every 5 levels has a Special Collectable (SC)
	if tile_counter > 1 and tile_counter % 5 == 0:
		level_instance.spawn_sc()
	level_instance.global_position.y = float(608 * (tile - 1))
	tiles_in_scene.insert(0, level_instance)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		is_playing = true
		rising_death.is_playing = 1;

func end_game():
	game_ended = true
	Debug.game_ended = false
	GameManager.player_start_position = Vector2(-192.0, -575.0)
	GameManager.add_resources(GameManager.new_arcade_resources)
	if not GameManager.game_progress["demo_played"]:
		GameManager.game_progress["demo_played"] = true
	GameManager.save()

	GameManager.UI.get_node("UI").display_swipe_to_start = false
	if end_game_button != null:
		end_game_button.hide()

	rich_text_label.position = Vector2(0.0, 750.0)
	rich_text_label.text = "[center][wave amp=25 freq=5]Swipe up 
	to Play![/wave][/center]"
	GameManager.trigger_pachinko = true
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://main.tscn")

func setup_demo():
	levels = [LEVEL_0_0, LEVEL_1_01, LEVEL_0_1]
	rich_text_label.visible = true
	rich_text_label.position = Vector2(0.0, 250.0)
	rich_text_label.text = "[rainbow][center][wave amp=25 freq=5]You are playing 
	the Demo![/wave][/center]"
