extends Node

var game_progress: Dictionary[String, bool] = {
	"demo_played": false,
	"whack_a_pesto_played": false,
}
var resources: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0
}

var dye_value: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0
}

var bottle_sizes: Dictionary[String, int] = {
	"Red": 160,
	"Orange": 160,
	"Yellow": 160,
	"Green": 160,
	"Blue": 160,
	"Pink": 160,
	"White": 160,
	"Brown": 160
}

var silkworm_amount: Dictionary[String, int] = {
	"Red": 0,
	"Orange": 0,
	"Yellow": 0,
	"Green": 0,
	"Blue": 0,
	"Pink": 0,
	"White": 0,
	"Brown": 0
}

var player_start_position: Vector2 = Vector2(0.0, -30.0) #launch zone
#var player_start_position: Vector2 = Vector2(-586.0, -446.0) #pesto's
#var player_start_position: Vector2 = Vector2(-192.0, -575.0) #landing zone

var new_arcade_resources: Array[int] = [] #used temporarily, by arcade mode
var unprocessed_resources: Array[int] = [] #the order unprocessed resources were collected in

var silk_worms: int = 0
var sand: int = 0

var stink_meter: float = 0.0
var UI: Node
var circle_fade: ColorRect
var path := "user://highscore.save" #"%AppData%\Roaming\Godot\app_userdata\high_and_dry"
var dropdown_active: bool = false
var fade_out: bool = false
var trigger_pachinko: bool = false

const COLOR_ORDER: Array[String] = ["Red","Orange","Yellow","Green","Blue","Pink","White","Brown"]
const COLOR_HEX: Dictionary[String, String] = {
	"Red": "ac3232",
	"Orange": "df7126",
	"Yellow": "fbf236",
	"Green": "6abe30",
	"Blue": "639bff",
	"Pink": "d77bba",
	"White": "ffffff",
	"Brown": "8f563b"
}
const INGREDIENT_REGIONS: Dictionary[String, Vector4i] = {
	"Red": Vector4i(1, 1, 16, 16),
	"Orange": Vector4i(19, 1, 16, 16),
	"Yellow": Vector4i(37, 1, 16, 16),
	"Green": Vector4i(55, 1, 16, 16),
	"Blue": Vector4i(73, 1, 16, 16),
	"Pink": Vector4i(91, 1, 16, 16),
	"White": Vector4i(109, 1, 16, 16),
	"Brown": Vector4i(127, 1, 16, 16)
}

##UNCOMMENT TO CLEAR SAVE DATA
#func _ready() -> void:
	#game_progress = {
		#"demo_played": false, "whack_a_pesto_played": false,
	#}
	#resources = {
		#"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		#"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	#}
	#dye_value = {
		#"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		#"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	#}
	#bottle_sizes = {
		#"Red": 160, "Orange": 160, "Yellow": 160, "Green": 160,
		#"Blue": 160, "Pink": 160, "White": 160, "Brown": 160
	#}
	#silkworm_amount = {
		#"Red": 0, "Orange": 0, "Yellow": 0, "Green": 0,
		#"Blue": 0, "Pink": 0, "White": 0, "Brown": 0
	#}
	#unprocessed_resources = []
	#silk_worms = 0
	#sand = 0
	#save()

func _process(_delta: float) -> void:
	if fade_out and circle_fade:
		var trans_value: float = circle_fade.material.get_shader_parameter("transition_value") + 0.01
		circle_fade.material.set_shader_parameter("transition_value", trans_value)
		await get_tree().create_timer(0.5).timeout

func get_ui_reference():
	UI = get_node("/root/Main/CanvasLayer")
	circle_fade = get_node("/root/Main/CanvasLayer/UI/CircleFade")

func save():
	var data := {
		"game_progress": game_progress,
		"resources": resources,
		"dye_value": dye_value,
		"bottle_sizes": bottle_sizes,
		"silk_worms": silk_worms,
		"sand": sand,
		"unprocessed_resources": unprocessed_resources
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)

func load_game():
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
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

func add_resource(collectable_type: int):
	new_arcade_resources.append(collectable_type)

func arcade_UI():
	load_game()
	UI.find_child("StinkMeter").show()
	UI.find_child("ArcadeCounter").show()
	UI.find_child("RichTextLabel").hide()

func hub_UI():
	load_game()
	if not game_progress["demo_played"]:
		get_tree().change_scene_to_file("res://arcade_main.tscn")
	display_normal_counter()
	update_bottles()

func whack_a_pesto_UI():
	var whack_meter = UI.find_child("WhackMeter")
	whack_meter.show()
	for string in COLOR_ORDER:
		var param = string.to_lower() + "_resources"
		var colorrect: ColorRect = whack_meter.get_node("ColorRect")
		colorrect.material.set_shader_parameter(param, 0)

	UI.find_child("WhackMeter").show()
	UI.find_child("WhackCounter").show()
	UI.find_child("RichTextLabel").hide()

func add_resources(collected: Array) -> void:
	for resource in collected:
		var idx: int = int(resource) % 8
		var key: String = COLOR_ORDER[idx]
		var inc: int = 2 if int(resource) >= 8 else 1
		var current: int = int(resources.get(key, 0))
		resources[key] = current + inc

func display_dropdown():
	dropdown_active = true
	var hub_counter: Node = UI.find_child("HubCounter")
	var resource_counter: RichTextLabel = hub_counter.find_child("ResourceCounter")
	var lines: String = ""
	for key: String in COLOR_ORDER:
		var r: Vector4i = INGREDIENT_REGIONS[key]
		var hex: String = COLOR_HEX[key]
		var count: int = int(resources.get(key, 0))
		lines += "[img width=48 region=%d,%d,%d,%d]res://textures/Ingredients.png[/img][color=%s]x[font_size=60]%d[/font_size][/color]\n" % [r.x, r.y, r.z, r.w, hex, count]
	resource_counter.text = lines

func display_normal_counter():
	dropdown_active = false
	var hub_counter: Node = UI.find_child("HubCounter")
	var resource_counter: RichTextLabel = hub_counter.find_child("ResourceCounter")
	var silk_sand_counter: RichTextLabel = hub_counter.find_child("SilkSandCounter")
	var sum: int = 0
	for key: String in COLOR_ORDER:
		sum += int(resources.get(key, 0))
	resource_counter.text = "[img width=48 region=32,0,16,16]res://textures/Sprites.png[/img][color=ffffff]x[font_size=60]%d" % sum
	silk_sand_counter.text = " [img width=48 region=16,32,16,16]res://textures/Sprites.png[/img]x[font_size=60]%d [img width=48 region=32,32,16,16]res://textures/Sprites.png[/img]x[font_size=60]%d" % [silk_worms, sand]

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

func increase_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] += 1

func decrease_silkworm_amount(dye_name: String):
	silkworm_amount[dye_name] -= 1
