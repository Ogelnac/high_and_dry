extends Sprite2D

const INGREDIENT = preload("res://minigames/ingredient.tscn")
const POT_SIZE = 300.0

@export var spawn_time = 0.5
var spawn_timer = spawn_time

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer < 0.0:
		spawn_ingredient()
		spawn_timer = spawn_time

func spawn_ingredient() -> void:
	var ingredient_instance = INGREDIENT.instantiate()
	add_child(ingredient_instance)
	ingredient_instance.global_position.x = randf_range(200.0, 600.0)
	ingredient_instance.global_position.y = randf_range(2100.0, 2300.0)
	ingredient_instance.original_position = ingredient_instance.global_position
	ingredient_instance.ingredient_type = randi_range(0, 7)
	ingredient_instance.ingredient_added.connect(_on_ingredient_added)
	pass

func _on_ingredient_added(ingredient_type: int):
	pass
