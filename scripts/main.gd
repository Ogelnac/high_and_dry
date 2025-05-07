extends Node2D

#const LEVEL_0_0 = preload("res://levels/level_0_0.tscn")
const LEVEL_0_1 = preload("res://levels/level_0_1.tscn")

const LEVEL_1_0 = preload("res://levels/level_1_0.tscn")
const LEVEL_1_1 = preload("res://levels/level_1_1.tscn")
const LEVEL_1_2 = preload("res://levels/level_1_2.tscn")
#const LEVEL_1_3 = preload("res://levels/level_1_3.tscn")

var levels = [LEVEL_1_0, LEVEL_0_1, LEVEL_1_1, LEVEL_1_2]


@onready var camera_2d: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $ArcadePlayer
@onready var rising_death: Area2D = $RisingDeath
@export var stink_multiplier: float = 1.0

var tiles_in_scene: Array[Object] = []
var is_playing: bool = 0
var current_tile: int = 1
var prev_tile: int = 1

func _ready() -> void:
	pattern_update(0, 1)
	GameManager.resources = []
	GameManager.stink_meter = 0.0

func _process(delta: float) -> void:
	# CAMERA MOVEMENT
	camera_2d.global_position.y = player.global_position.y - 120.0
	camera_2d.global_position.x = player.global_position.x * 0.01
	
	if is_playing:
		if GameManager.stink_meter <= 100.0:
			GameManager.stink_meter += 5.0 * stink_multiplier * delta
		else:
			GameManager.hub_UI()
			GameManager.player_start_position = Vector2(-192.0, -575.0)
			GameManager.add_resources(GameManager.resources)
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://main.tscn")
		
		current_tile = round(player.global_position.y / 608.0)
		if prev_tile > current_tile:
			pattern_update(-1, current_tile)
			prev_tile = current_tile
	
	if tiles_in_scene.size() > 4:
		tiles_in_scene[4].queue_free()
		tiles_in_scene.remove_at(4)

func pattern_update(level: int, tile: int) -> void:
	var level_instance
	if level < 0:
		# Add random level
		var rand_level = randi_range(1, levels.size()-1)
		level_instance = levels[rand_level].instantiate()
	else:
		# Add level from index
		level_instance = levels[level].instantiate()
	add_child(level_instance)
	level_instance.global_position.y = float(608 * (tile - 1))
	tiles_in_scene.insert(0, level_instance)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		is_playing = 1
		rising_death.is_playing = 1;
