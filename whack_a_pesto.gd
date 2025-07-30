extends Node2D

const INGREDIENT = preload("res://ingredient.tscn")

var max_spawn_timer = 0.1
var spawn_timer = max_spawn_timer

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer < 0.0:
		spawn_timer = max_spawn_timer
		launch_ingredient(randi_range(0, 7))

func launch_ingredient(ingredient_type: int) -> void:
	var ingredient_instance = INGREDIENT.instantiate()
	add_child(ingredient_instance)
	var start_height = randf_range(80.0, 112.0)
	ingredient_instance.start_height = start_height
	ingredient_instance.global_position = Vector2(randf_range(-46.0, 46.0), start_height)
	ingredient_instance.sprite_2d.frame = ingredient_type
