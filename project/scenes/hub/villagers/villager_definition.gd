class_name VillagerDefinition
extends Resource

@export var villager_id: StringName
@export var display_name: String
@export var animal_type: StringName
@export_enum("Friendly", "Shy", "Clever", "Posh", "Grumpy", "Dreamy") var personality: String = "Friendly"
@export_range(0, 31) var sprite_row: int
@export var invite_cost: Dictionary[String, int] = {}
@export var dye_cost: Dictionary[String, int] = {}
@export var fabric_cost: Dictionary[String, int] = {}
@export var glass_cost: int
@export var location_weights: Dictionary[String, int] = {}
