extends Node2D

const INGREDIENT = preload("res://ingredient.tscn")
const KARAKARA = preload("res://audio/karakara.wav")

@onready var tailor_wap: Node2D = $TailorWAP
@onready var sprite_2d: Sprite2D = $TailorWAP/Sprite2D
@onready var UI: Control = $CanvasLayer/UI

const COLOR_ORDER: Array[String] = ["Red","Orange","Yellow","Green","Blue","Pink","White","Brown"]

var resources_to_be_processed: Array[int]
var current_resource = 0
var number_of_resources: int = 50

var max_spawn_timer = 5.0
var spawn_timer = max_spawn_timer
var retrigger = true

var doinking = false
var max_doink = 0.3
var doink_timer = max_doink

var resource_count = 0
var music_started = false

func _ready() -> void:
	GameManager.get_ui_reference()
	GameManager.whack_a_pesto_UI()
	resources_to_be_processed = GameManager.unprocessed_resources.slice(0, number_of_resources)

func _process(delta: float) -> void:
	spawn_timer -= delta

	if doinking:
		doink_timer -= delta
	if doink_timer < 0.0:
		sprite_2d.frame = 21
		doinking = false
		doink_timer = max_doink

	if spawn_timer < 0.0 or retrigger:
		if spawn_timer < 0.0:
			spawn_timer = max_spawn_timer
		if current_resource == number_of_resources:
			return
		retrigger = false
		if Debug.infinite_resources:
			launch_ingredient(randi_range(0, 7))
		else:
			launch_ingredient(resources_to_be_processed[current_resource])
		current_resource += 1

	if resource_count == 3 and not music_started:
		music_started = true
		var bgm = AudioStreamPlayer.new()
		bgm.stream = KARAKARA
		bgm.autoplay = true
		bgm.volume_linear = 0.3
		add_child(bgm)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		var screen_position = event.position
		if screen_position.y < 100 or screen_position.y > 740:
			return

		var canvas_transform = get_viewport().get_canvas_transform()
		var world_position = canvas_transform.affine_inverse() * screen_position
		tailor_wap.global_position = world_position
		sprite_2d.frame = 22
		var dir: int = tailor_wap.global_position.x > 0.0
		sprite_2d.flip_h = dir
		tailor_wap.global_position.x += 16.0 * dir
		doinking = true
		doink_timer = max_doink

func launch_ingredient(ingredient_type: int) -> void:
	var ingredient_instance = INGREDIENT.instantiate()
	add_child(ingredient_instance)
	var start_height = 80
	ingredient_instance.start_height = start_height
	ingredient_instance.arc_size = randf_range(128.0, 192.0)
	ingredient_instance.global_position = Vector2(randf_range(-46.0, 46.0), start_height)
	ingredient_instance.sprite_2d.frame = ingredient_type

func update_counters(new_resource: int):
	var whack_meter = UI.get_node("WhackMeter")
	var colorrect: ColorRect = whack_meter.get_node("ColorRect")
	var idx: int = int(new_resource) % 8
	var key: String = COLOR_ORDER[idx].to_lower() + "_resources"
	var inc: int = 2 if int(new_resource) >= 8 else 1
	var current: int = int(colorrect.material.get_shader_parameter(key))
	colorrect.material.set_shader_parameter(key, current + inc)
	resource_count += 1

	UI.get_node("WhackCounter").text = "[center]" + str(resource_count) + "[font_size=50]/50"
	if resource_count == number_of_resources:
		end_game()

func end_game():
	if Debug.infinite_resources:
		return

	GameManager.unprocessed_resources = GameManager.unprocessed_resources.slice(number_of_resources, GameManager.unprocessed_resources.size())
	for i in range(0, 15):
		var idx: int = int(i) % 8
		var key: String = COLOR_ORDER[idx]
		GameManager.resources[key] -= resources_to_be_processed.count(i)
		GameManager.dye_value[key] += resources_to_be_processed.count(i)
	GameManager.save()
	GameManager.change_scene("res://main.tscn")
