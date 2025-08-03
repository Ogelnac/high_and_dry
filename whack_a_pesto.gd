extends Node2D

const INGREDIENT = preload("res://ingredient.tscn")

@onready var tailor_wap: Node2D = $TailorWAP
@onready var sprite_2d: Sprite2D = $TailorWAP/Sprite2D

var max_spawn_timer = 0.1
var spawn_timer = max_spawn_timer

var doinking = false
var max_doink = 0.3
var doink_timer = max_doink

func _process(delta: float) -> void:
	spawn_timer -= delta
	if doinking:
		doink_timer -= delta
	if doink_timer < 0.0:
		sprite_2d.frame = 21
		doinking = false
		doink_timer = max_doink
	if spawn_timer < 0.0:
		spawn_timer = max_spawn_timer
		launch_ingredient(randi_range(0, 15))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		var screen_position = event.position
		var canvas_transform = get_viewport().get_canvas_transform()
		var world_position = canvas_transform.affine_inverse() * screen_position
		tailor_wap.global_position = world_position
		sprite_2d.frame = 22
		var dir = randi_range(0,1)
		sprite_2d.flip_h = dir
		tailor_wap.global_position.x += 16.0 * dir
		doinking = true
		doink_timer = max_doink


func launch_ingredient(ingredient_type: int) -> void:
	var ingredient_instance = INGREDIENT.instantiate()
	add_child(ingredient_instance)
	var start_height = randf_range(80.0, 112.0)
	ingredient_instance.start_height = start_height
	ingredient_instance.global_position = Vector2(randf_range(-46.0, 46.0), start_height)
	ingredient_instance.sprite_2d.frame = ingredient_type
