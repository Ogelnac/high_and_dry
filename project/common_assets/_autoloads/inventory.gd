extends RefCounted

signal held_fabric_changed
signal save_requested

const COLOR_ORDER: Array[String] = ["Red","Orange","Yellow","Green","Blue","Pink","White","Brown"]

const COLOR_HEX: Dictionary[String, String] = {
	"Red": "ac3232",
	"Orange": "df7126",
	"Yellow": "fbf236",
	"Green": "6abe30",
	"Blue": "639bff",
	"Pink": "d77bba",
	"White": "ffffff",
	"Brown": "8f563b"}

const INGREDIENT_REGIONS: Dictionary[String, Vector4i] = {
	"Red": Vector4i(1, 1, 16, 16),
	"Orange": Vector4i(19, 1, 16, 16),
	"Yellow": Vector4i(37, 1, 16, 16),
	"Green": Vector4i(55, 1, 16, 16),
	"Blue": Vector4i(73, 1, 16, 16),
	"Pink": Vector4i(91, 1, 16, 16),
	"White": Vector4i(109, 1, 16, 16),
	"Brown": Vector4i(127, 1, 16, 16)}

const FABRIC_REGIONS: Dictionary[String, Vector4i] = {
	"Red": Vector4i(0, 0, 16, 16),
	"Orange": Vector4i(16, 0, 16, 16),
	"Yellow": Vector4i(32, 0, 16, 16),
	"Green": Vector4i(0, 16, 16, 16),
	"Blue": Vector4i(16, 16, 16, 16),
	"Pink": Vector4i(32, 16, 16, 16),
	"White": Vector4i(0, 32, 16, 16),
	"Brown": Vector4i(16, 32, 16, 16)}

var resources: Dictionary[String, int] = counts_by_color(0)

var dye_value: Dictionary[String, int] = counts_by_color(0)

var bottle_sizes: Dictionary[String, int] = counts_by_color(160)

var silkworm_amount: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 3,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var fabric: Dictionary[String, int] = counts_by_color(0)

var fabric_pile: Dictionary[String, int] = counts_by_color(0)

var unprocessed_resources: Array[int] = [] #TEMPORARY FOR WHACK-A-PESTO the order unprocessed resources were collected

var fabric_pile_max: int = 100

var fabric_pile_storage_max: int = 9999

var silk_worms: int = 0

var sand: int = 0

static func counts_by_color(initial_count: int = 0) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for color_name in COLOR_ORDER:
		counts[color_name] = initial_count
	return counts


func store_arcade_haul(collected: Array[int]) -> void:
	add_resources(collected)
	unprocessed_resources.append_array(collected)


func add_resources(collected: Array) -> void:
	for resource in collected:
		var idx: int = int(resource) % 8
		var key: String = COLOR_ORDER[idx]
		var inc: int = 2 if int(resource) >= 8 else 1
		var current: int = int(resources.get(key, 0))
		resources[key] = current + inc


func stash_held_fabric_into_piles() -> void:
	var stashed := false
	for color_name in COLOR_ORDER:
		var held: int = int(fabric.get(color_name, 0))
		if held > 0:
			var pile_current: int = int(fabric_pile.get(color_name, 0))
			fabric_pile[color_name] = min(pile_current + held, fabric_pile_storage_max)
			fabric[color_name] = 0
			stashed = true
	if stashed:
		save_requested.emit()


func get_dye_value(dye_name: String) -> int:
	return int(dye_value[dye_name])


func get_bottle_size(dye_name: String) -> int:
	return int(bottle_sizes[dye_name])


func get_silkworm_amount(dye_name: String) -> int:
	return int(silkworm_amount[dye_name])


func is_fabric_pile_full(color_name: String) -> bool:
	return int(fabric_pile.get(color_name, 0)) >= fabric_pile_max


func get_fabric_pile_amount(color_name: String) -> int:
	return int(fabric_pile.get(color_name, 0))


func increase_fabric_pile_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric_pile.get(color_name, 0))
	fabric_pile[color_name] = min(current + amount, fabric_pile_storage_max)
	save_requested.emit()


func decrease_fabric_pile_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric_pile.get(color_name, 0))
	fabric_pile[color_name] = max(current - amount, 0)
	save_requested.emit()


func increase_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] += 1


func decrease_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] -= 1


func get_fabric_amount(color_name: String) -> int:
	return int(fabric.get(color_name, 0))


func increase_fabric_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric.get(color_name, 0))
	fabric[color_name] = current + amount
	held_fabric_changed.emit()


func decrease_fabric_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric.get(color_name, 0))
	fabric[color_name] = current - amount
	held_fabric_changed.emit()


func get_dye_amount(color_name: String) -> int:
	return int(dye_value.get(color_name, 0))


func decrease_dye_amount(color_name: String, amount: int) -> void:
	var current: int = int(dye_value.get(color_name, 0))
	dye_value[color_name] = max(current - amount, 0)
	save_requested.emit()


func reset() -> void:
	resources = counts_by_color()
	dye_value = counts_by_color()
	bottle_sizes = counts_by_color(160)
	silkworm_amount = counts_by_color()
	fabric_pile = counts_by_color()
	fabric = counts_by_color()
	unprocessed_resources = []
	silk_worms = 0
	sand = 0
