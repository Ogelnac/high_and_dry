extends Area2D

var score: int = 0

@onready var label: Label = get_tree().current_scene.get_node("%Label")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	var rand_index = randi_range(0, 7)
	sprite_2d.frame = rand_index

func _on_body_entered(body: Node2D) -> void:
	score = int(label.text)
	label.text = str(score + 1)
	queue_free()
