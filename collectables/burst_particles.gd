extends RigidBody2D

@onready var color_rect: ColorRect = $ColorRect

var flash_timer := 0.0
var flash_interval := 0.075
var lifetime := 3.0
var age := 0.0

func _ready() -> void:
	lifetime = randf_range(3.0, 5.0)
	flash_timer = flash_interval


func _process(delta: float) -> void:
	age += delta
	flash_timer -= delta
	if flash_timer <= 0.0:
		color_rect.visible = !color_rect.visible
		flash_timer = flash_interval
	if age >= lifetime:
		queue_free()
