extends RefCounted

const InventoryData = preload("res://project/common_assets/_autoloads/inventory.gd")

var arcade_level: int = 0

var legs_completed: int = 0

var new_arcade_resources: Array[int] = [] #used temporarily, by arcade mode

var cached_resources: Array[int] = []

var resource_cache: Dictionary[String, int] = InventoryData.counts_by_color()

var trigger_pachinko: bool = false


func add_resource(collectable_type: int):
	new_arcade_resources.append(collectable_type)


func add_resources_to_cache(collected: Array) -> void:
	cached_resources.append_array(collected)
	for resource in collected:
		var idx: int = int(resource) % 8
		var key: String = InventoryData.COLOR_ORDER[idx]
		var inc: int = 2 if int(resource) >= 8 else 1
		var current: int = int(resource_cache.get(key, 0))
		resource_cache[key] = current + inc


func clear_resource_cache() -> void:
	cached_resources = []
	resource_cache = InventoryData.counts_by_color()


func take_hub_haul() -> Array[int]:
	trigger_pachinko = false
	var haul := new_arcade_resources
	new_arcade_resources = []
	return haul
