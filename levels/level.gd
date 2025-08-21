extends Node2D

var contains_sc: bool = false
@onready var special_collectables: Node2D = $SpecialCollectables

func spawn_sc():
	var number_of_collectables = special_collectables.get_children()
	var random_collectable = randi_range(0, number_of_collectables.size())
	special_collectables.get_child(random_collectable).collectable_type = "Silkworm"
