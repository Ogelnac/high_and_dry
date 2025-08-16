extends Node

var player_start_position: Vector2 = Vector2(0.0, -30.0)
#var player_start_position: Vector2 = Vector2(-640.0, -447.0)

var resources = Array()

var red_resources: int = 0
var yellow_resources: int = 0
var orange_resources: int = 0
var green_resources: int = 0
var blue_resources: int = 0
var pink_resources: int = 0
var brown_resources: int = 0
var white_resources: int = 0

var red_dye: int = 0
var yellow_dye: int = 0
var orange_dye: int = 0
var green_dye: int = 0
var blue_dye: int = 0
var pink_dye: int = 0
var brown_dye: int = 0
var white_dye: int = 0

var red_dye_bottle_size: int = 160
var yellow_dye_bottle_size: int = 160
var orange_dye_bottle_size: int = 160
var green_dye_bottle_size: int = 160
var blue_dye_bottle_size: int = 160
var pink_dye_bottle_size: int = 160
var brown_dye_bottle_size: int = 160
var white_dye_bottle_size: int = 160

var silk_worms: int = 0
var sand: int = 0

@onready var stink_meter: float = 0.0
@onready var UI: Node
@onready var circle_fade: ColorRect

var path = "user://highscore.save"
var dropdown_active: bool = false;
var fade_out: bool = false

func _process(_delta: float) -> void:
	if fade_out and circle_fade:
		var trans_value = circle_fade.material.get_shader_parameter("transition_value") + 0.01
		circle_fade.material.set_shader_parameter("transition_value", trans_value)
		await get_tree().create_timer(0.5).timeout

func get_ui_reference():
	UI = get_node("/root/Main/CanvasLayer")

func save():
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_var(red_resources)
	file.store_var(yellow_resources)
	file.store_var(orange_resources)
	file.store_var(green_resources)
	file.store_var(blue_resources)
	file.store_var(pink_resources)
	file.store_var(brown_resources)
	file.store_var(white_resources)

func load_game():
	var file = FileAccess.open(path,FileAccess.READ)
	red_resources = file.get_var(red_resources)
	yellow_resources = file.get_var(yellow_resources)
	orange_resources = file.get_var(orange_resources)
	green_resources = file.get_var(green_resources)
	blue_resources = file.get_var(blue_resources)
	pink_resources = file.get_var(pink_resources)
	brown_resources = file.get_var(brown_resources)
	white_resources = file.get_var(white_resources)

func add_resource(collectable_type: int):
	resources.append(collectable_type)

func arcade_UI():
	UI.find_child("StinkMeter").show()
	UI.find_child("ArcadeCounter").show()
	UI.find_child("RichTextLabel").hide()

func hub_UI():
	load_game()
	display_normal_counter()

func whack_a_pesto_UI():
	return

func add_resources(collected: Array):
	var resource_map := {
		0: "red_resources", 8: "red_resources",
		1: "orange_resources", 9: "orange_resources",
		2: "yellow_resources", 10: "yellow_resources",
		3: "green_resources", 11: "green_resources",
		4: "blue_resources", 12: "blue_resources",
		5: "pink_resources", 13: "pink_resources",
		6: "brown_resources", 14: "brown_resources",
		7: "white_resources", 15: "white_resources"
	}

	for resource in collected:
		if resource in resource_map:
			var variable_name = resource_map[resource]
			var value = 2 if resource >= 8 else 1
			set(variable_name, get(variable_name) + value)

func display_dropdown():
	dropdown_active = true
	var hub_counter = UI.find_child("HubCounter")
	var resource_counter = hub_counter.find_child("ResourceCounter")
	
	resource_counter.text = ("[img width=48 region=1,1,16,16]res://textures/Ingredients.png[/img][color=ac3232]x[font_size=60]"+str(red_resources)+"[/font_size][/color]
[img width=48 region=19,1,16,16]res://textures/Ingredients.png[/img][color=df7126]x[font_size=60]"+str(orange_resources)+"[/font_size][/color]
[img width=48 region=37,1,16,16]res://textures/Ingredients.png[/img][color=fbf236]x[font_size=60]"+str(yellow_resources)+"[/font_size][/color]
[img width=48 region=55,1,16,16]res://textures/Ingredients.png[/img][color=6abe30]x[font_size=60]"+str(green_resources)+"[/font_size][/color]
[img width=48 region=73,1,16,16]res://textures/Ingredients.png[/img][color=639bff]x[font_size=60]"+str(blue_resources)+"[/font_size][/color]
[img width=48 region=91,1,16,16]res://textures/Ingredients.png[/img][color=d77bba]x[font_size=60]"+str(pink_resources)+"[/font_size][/color]
[img width=48 region=109,1,16,16]res://textures/Ingredients.png[/img][color=ffffff]x[font_size=60]"+str(brown_resources)+"[/font_size][/color]
[img width=48 region=127,1,16,16]res://textures/Ingredients.png[/img][color=8f563b]x[font_size=60]"+str(white_resources)+"[/font_size][/color]
")

func display_normal_counter():
	dropdown_active = false
	var hub_counter = UI.find_child("HubCounter")
	var resource_counter = hub_counter.find_child("ResourceCounter")
	var silk_sand_counter = hub_counter.find_child("SilkSandCounter")

	var sum = red_resources + orange_resources + yellow_resources + green_resources + blue_resources + pink_resources + brown_resources + white_resources
	
	resource_counter.text = ("[img width=48 region=32,0,16,16]res://textures/Sprites.png[/img][color=ffffff]x[font_size=60]"+str(sum))

	silk_sand_counter.text = (" [img width=48 region=16,32,16,16]res://textures/Sprites.png[/img]x[font_size=60]"+str(silk_worms)+
" [img width=48 region=32,32,16,16]res://textures/Sprites.png[/img]x[font_size=60]"+str(sand))

func change_scene(scene_file: String):
	var position = get_window().size / 2.0
	circle_fade.material.set_shader_parameter("transition_location", position)
	fade_out = true
	circle_fade.show()
	await get_tree().create_timer(3.0).timeout
	circle_fade.material.set_shader_parameter("transition_value", 0)
	get_tree().change_scene_to_file(scene_file)

func get_dye_value(dye_name: String):
	match dye_name:
		"Red":
			return red_dye
		"Yellow":
			return yellow_dye
		"Orange":
			return orange_dye
		"Green":
			return green_dye
		"Blue":
			return blue_dye
		"Pink":
			return pink_dye
		"White":
			return white_dye
		"Brown":
			return brown_dye

func get_bottle_size(dye_name: String):
	match dye_name:
		"Red":
			return red_dye_bottle_size
		"Yellow":
			return yellow_dye_bottle_size
		"Orange":
			return orange_dye_bottle_size
		"Green":
			return green_dye_bottle_size
		"Blue":
			return blue_dye_bottle_size
		"Pink":
			return pink_dye_bottle_size
		"White":
			return white_dye_bottle_size
		"Brown":
			return brown_dye_bottle_size
