extends RigidBody2D

@onready var color_rect: ColorRect = $ColorRect

var lifetime := 0.0
var age := 0.0

func _ready() -> void:
	lifetime = randf_range(1.0, 2.0)

func _process(delta: float) -> void:
	age += delta
	var remaining = clamp(1.0 - (age / lifetime), 0.0, 1.0)
	color_rect.modulate.a = remaining
	if age >= lifetime:
		queue_free()
