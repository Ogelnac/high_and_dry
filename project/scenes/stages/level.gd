extends Node2D

@onready var camera_2d: Camera2D = $"../Camera2D"
var contains_sc: bool = false

# INTERIM
var resource_collection: Area2D

var interim: bool = false

func _ready() -> void:
	resource_collection = get_node_or_null("ResourceCollection")

func _process(_delta: float) -> void:
	if resource_collection and !resource_collection.body_entered.is_connected(start_interim_seq):
		resource_collection.body_entered.connect(start_interim_seq)

func start_interim_seq(body: Node2D):
	if body.is_in_group("player"):
		camera_2d.interim = true
		GameManager.add_resources_to_cache(GameManager.new_arcade_resources)
		Debug.expel_res = true
