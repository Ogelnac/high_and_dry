extends Area2D

#var score: int = 0

#@onready var label: Label = get_tree().current_scene.get_node("%Label")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var collectable_type

func _ready() -> void:
	collectable_type = randi_range(0, 7)
	sprite_2d.frame = collectable_type

func _on_body_entered(body: Node2D) -> void:
	GameManager.add_resource(collectable_type)
	GameManager.stink_meter = clamp(GameManager.stink_meter - 10.0, 0.0, 100.0)
	queue_free()
