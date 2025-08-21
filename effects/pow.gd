extends Sprite2D

var lifetime := 0.1
var age := 0.0

func _process(delta: float) -> void:
	age += delta
	var remaining = clamp(1.0 + (age / lifetime), 1.0, 1.5)
	scale = Vector2(remaining, remaining)
	rotate(PI * remaining)
	if age >= lifetime:
		queue_free()
