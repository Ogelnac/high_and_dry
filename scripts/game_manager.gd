extends Node

var player_start_position: Vector2 = Vector2(0.0, -30.0)

var resources = Array()

var red_resources: int = 0
var blue_resources: int = 0
var yellow_resources: int = 0
var orange_resources: int = 0
var green_resources: int = 0
var pink_resources: int = 0
var brown_resources: int = 0
var white_resources: int = 0

var UI = preload("res://canvas_layer.tscn").instantiate()

@onready var stink_meter: float = 0.0

func _ready():
	add_child(UI)

func add_resource(collectable_type: int):
	resources.append(collectable_type)

func arcade_UI():
	UI.find_child("SceneManager").hide()
	UI.find_child("StinkMeter").show()
	UI.find_child("ArcadeCounter").show()

func hub_UI():
	UI.find_child("StinkMeter").hide()
	UI.find_child("ArcadeCounter").hide()
	
func add_resources(collected: Array):
	var resource_map := {
		0: "red_resources", 7: "red_resources",
		1: "orange_resources", 8: "orange_resources",
		2: "yellow_resources", 9: "yellow_resources",
		3: "green_resources", 10: "green_resources",
		4: "blue_resources", 11: "blue_resources",
		5: "pink_resources", 12: "pink_resources",
		6: "brown_resources", 13: "brown_resources",
		14: "white_resources", 15: "white_resources"
	}

	for resource in collected:
		if resource in resource_map:
			var variable_name = resource_map[resource]
			var value = 2 if resource >= 8 else 1
			set(variable_name, get(variable_name) + value)
