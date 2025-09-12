extends Node2D

@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var special_collectables: Node2D = $SpecialCollectables
var contains_sc: bool = false

# INTERIM
var resource_collection: Area2D
var left_pipe: TileMapLayer
var right_pipe: TileMapLayer

var interim: bool = false

func _ready() -> void:
	resource_collection = get_node_or_null("ResourceCollection")
	left_pipe = get_node_or_null("LeftPipe")
	right_pipe = get_node_or_null("RightPipe")

func _process(_delta: float) -> void:
	if resource_collection and not resource_collection.body_entered.is_connected(start_interim_seq):
		resource_collection.body_entered.connect(start_interim_seq)

func start_interim_seq(body: Node2D):
	if body.is_in_group("player"):
		camera_2d.interim = true
		GameManager.add_resources_to_cache(GameManager.new_arcade_resources)
		Debug.expell_res = true

func spawn_sc():
	var number_of_collectables = special_collectables.get_children()
	var random_collectable = randi_range(0, number_of_collectables.size() - 1)
	special_collectables.get_child(random_collectable).collectable_type = "Silkworm"
	special_collectables.get_child(random_collectable).set_active()
