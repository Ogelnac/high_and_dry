extends Node


var player_start_position: Vector2 = Vector2(0.0, -30.0) #launch zone
#var player_start_position: Vector2 = Vector2(-586.0, -446.0) #pesto's
#var player_start_position: Vector2 = Vector2(-192.0, -575.0) #landing zone

const SPRITES = preload("uid://dyts0j2w4qv8n")
const INGREDIENTS = preload("uid://bdfnifowl2amv")

var game_progress: Dictionary[String, bool] = {
	"demo_played": false,
	"whack_a_pesto_played": false,
	"moth_mother_hatched": false}

var resources: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var dye_value: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var bottle_sizes: Dictionary[String, int] = {
	"Red": 160,
	"Orange": 160,
	"Yellow": 160,
	"Green": 160,
	"Blue": 160,
	"Pink": 160,
	"White": 160,
	"Brown": 160}

var silkworm_amount: Dictionary[String, int] = {
	"Red": 2,
	"Orange": 3,
	"Yellow": 1,
	"Green": 2,
	"Blue": 3,
	"Pink": 2,
	"White": 1,
	"Brown": 3}

var fabric: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var fabric_pile: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var new_arcade_resources: Array[int] = [] #used temporarily, by arcade mode
var cached_resources: Array[int] = []
var unprocessed_resources: Array[int] = [] #TEMPORARY FOR WHACK-A-PESTO the order unprocessed resources were collected
var fabric_pile_max: int = 100
var resource_cache: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0}

var silk_worms: int = 0
var sand: int = 0

var UI: Node
var circle_fade: ColorRect
var path = "user://highscore.save" #"%AppData%\Roaming\Godot\app_userdata\high_and_dry"

var dropdown_active: bool = false
var cached_counter: bool = false
var fade_out: bool = false
var trigger_pachinko: bool = false
var stage_level: Vector2i = Vector2i(0, 0)
var _save_dirty: bool = false
var _autosave_accum: float = 0.0
var autosave_interval_seconds: float = 15.0

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

var presets_path: String = "user://playerpresets.save"

var bag_open: bool = false
var sfx_volume: float = 1.0
var music_volume: float = 1.0

func _process(_delta: float) -> void:
	if fade_out and circle_fade:
		var trans_value: float = circle_fade.material.get_shader_parameter("transition_value") + 0.01
		circle_fade.material.set_shader_parameter("transition_value", trans_value)
		await get_tree().create_timer(0.5).timeout

	_autosave_accum += _delta
	if _autosave_accum >= autosave_interval_seconds:
		_autosave_accum = 0.0
		if _save_dirty:
			save()
			_save_dirty = false

func get_ui_reference():
	UI = get_node("/root/Main/CanvasLayer")
	circle_fade = get_node("/root/Main/CanvasLayer/UI/CircleFade")

func save():
	var data = {
		"game_progress": game_progress,
		"resources": resources,
		"dye_value": dye_value,
		"bottle_sizes": bottle_sizes,
		"silk_worms": silk_worms,
		"sand": sand,
		"unprocessed_resources": unprocessed_resources,
		"fabric_pile": fabric_pile
	}

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)

func load_game():
	if not FileAccess.file_exists(path):
		save()

	var file = FileAccess.open(path, FileAccess.READ)
	var data: Variant = file.get_var()

	if typeof(data) == TYPE_DICTIONARY:
		var d: Dictionary = data

		if "game_progress" in d: game_progress = d["game_progress"]
		if "resources" in d: resources = d["resources"]
		if "dye_value" in d: dye_value = d["dye_value"]
		if "bottle_sizes" in d: bottle_sizes = d["bottle_sizes"]
		if "silk_worms" in d: silk_worms = int(d["silk_worms"])
		if "sand" in d: sand = int(d["sand"])
		if "unprocessed_resources" in d: unprocessed_resources = d["unprocessed_resources"]

		if "fabric_pile" in d:
			fabric_pile = d["fabric_pile"]

	fabric = {
		"Red": 0,
		"Orange": 0,
		"Yellow": 0,
		"Green": 0,
		"Blue": 0,
		"Pink": 0,
		"White": 0,
		"Brown": 0
	}

func save_presets():
	var data = {
		"bag_open": bag_open,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume
	}
	var file = FileAccess.open(presets_path, FileAccess.WRITE)
	if file:
		file.store_var(data)

func load_presets():
	if not FileAccess.file_exists(presets_path):
		save_presets()
	var file = FileAccess.open(presets_path, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		if typeof(data) == TYPE_DICTIONARY:
			var d: Dictionary = data
			if "bag_open" in d: bag_open = bool(d["bag_open"])
			if "sfx_volume" in d: sfx_volume = float(d["sfx_volume"])
			if "music_volume" in d: music_volume = float(d["music_volume"])

func add_resource(collectable_type: int):
	new_arcade_resources.append(collectable_type)

func stash_held_fabric_into_piles() -> void:
	for color_name in COLOR_ORDER:
		var held: int = int(fabric.get(color_name, 0))
		if held > 0:
			var pile_current: int = int(fabric_pile.get(color_name, 0))
			fabric_pile[color_name] = min(pile_current + held, fabric_pile_max)
			fabric[color_name] = 0
			_save_dirty = true

func stash_and_save() -> void:
	stash_held_fabric_into_piles()
	save()
	_save_dirty = false

func arcade_UI():
	UI.find_child("RichTextLabel").hide()

func hub_UI():
	cached_counter = false
	update_bottles()

func shop_UI():
	cached_counter = true

func whack_a_pesto_UI():
	var whack_metre = UI.find_child("WhackMetre")
	whack_metre.show()
	for string in COLOR_ORDER:
		var param = string.to_lower() + "_resources"
		var colorrect: ColorRect = whack_metre.get_node("ColorRect")
		colorrect.material.set_shader_parameter(param, 0)

	UI.find_child("WhackMetre").show()
	UI.find_child("WhackCounter").show()
	UI.find_child("RichTextLabel").hide()

func add_resources(collected: Array) -> void:
	for resource in collected:
		var idx: int = int(resource) % 8
		var key: String = COLOR_ORDER[idx]
		var inc: int = 2 if int(resource) >= 8 else 1
		var current: int = int(resources.get(key, 0))
		resources[key] = current + inc

func add_resources_to_cache(collected: Array) -> void:
	cached_resources.append_array(collected)
	for resource in collected:
		var idx: int = int(resource) % 8
		var key: String = COLOR_ORDER[idx]
		var inc: int = 2 if int(resource) >= 8 else 1
		var current: int = int(resource_cache.get(key, 0))
		resource_cache[key] = current + inc

func clear_resource_cache():
	cached_resources = []
	GameManager.resource_cache = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0}

func display_dropdown():
	dropdown_active = false

func display_normal_counter():
	dropdown_active = false

func update_bottles():
	var dye_bottles = get_node("../Main/DyeBottles")
	for child in dye_bottles.get_children():
		child._sync_from_manager()

func change_scene(scene_file: String):
	circle_fade.material.set_shader_parameter("transition_value", 0)
	var position: Vector2 = get_window().size / 2.0
	circle_fade.material.set_shader_parameter("transition_location", position)
	fade_out = true
	circle_fade.show()
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file(scene_file)

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
	fabric_pile[color_name] = min(current + amount, fabric_pile_max)
	_save_dirty = true

func decrease_fabric_pile_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric_pile.get(color_name, 0))
	fabric_pile[color_name] = max(current - amount, 0)
	_save_dirty = true

func increase_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] += 1

func decrease_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] -= 1

func get_fabric_amount(color_name: String) -> int:
	return int(fabric.get(color_name, 0))

func increase_fabric_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric.get(color_name, 0))
	fabric[color_name] = current + amount

func decrease_fabric_amount(color_name: String, amount: int = 1) -> void:
	var current: int = int(fabric.get(color_name, 0))
	fabric[color_name] = current - amount

func _reset_progress() -> void:
	game_progress = {
		"demo_played": false, "whack_a_pesto_played": false, "moth_mother_hatched": false,
	}
	resources = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	}
	dye_value = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	}
	bottle_sizes = {
		"Red": 160, "Orange": 160, "Yellow": 160, "Green": 160,
		"Blue": 160, "Pink": 160, "White": 160, "Brown": 160
	}
	silkworm_amount = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	}
	fabric_pile = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	}
	fabric = {
		"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	}
	unprocessed_resources = []
	silk_worms = 0
	sand = 0
	save()
	get_tree().change_scene_to_file("uid://cw2sf1bh5vj78")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_dirty:
			stash_and_save()
