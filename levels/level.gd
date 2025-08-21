extends Node2D

var contains_sc: bool = false
var special_collectables

func _ready() -> void:
	special_collectables = $SpecialCollectables

func spawn_sc():
	var number_of_collectables = special_collectables.get_children()
	var random_collectable = randi_range(0, number_of_collectables.size())
	special_collectables.get_child(random_collectable).collectable_type = "Silkworm"
