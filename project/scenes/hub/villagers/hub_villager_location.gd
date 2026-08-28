class_name HubVillagerLocation
extends Marker2D

@export_enum("home", "lamppost", "ramen", "upper_piers", "weavers", "pestos", "title") var location_type: String = "home"
@export_range(-1, 20, 1) var house_index := -1
@export_range(0.0, 200.0, 1.0) var roam_radius := 28.0
@export_range(1, 2, 1) var max_villagers := 2
@export var enabled := true

func get_assignment_record() -> Dictionary:
	return {
		"location_id": StringName(name),
		"location_type": StringName(location_type),
		"house_index": house_index,
		"capacity": max_villagers
	}
