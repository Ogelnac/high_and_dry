extends TextureRect

@export var velocity: Vector2 = Vector2.ZERO
@export var max_stretch: float = 1.75
@export var min_squash: float = 0.25
@export var rotation_speed: float = 20.0
@export var stretch_sensitivity: float = 0.01

var base_scale: Vector2
var faux_velocity: Vector2
var prev_position: Vector2

func _ready():
	base_scale = scale

func _process(delta: float) -> void:
	faux_velocity = position - prev_position
	
	if faux_velocity.length() > 0.01 and faux_velocity.length() < 100.0:
		rotation = faux_velocity.angle() - PI / 2
		var speed_factor = faux_velocity.length() * stretch_sensitivity
		var stretch = lerp(1.0, max_stretch, speed_factor)
		var squash = lerp(1.0, min_squash, speed_factor)
		scale = Vector2(base_scale.x * squash, base_scale.y * stretch)
	else:
		scale = base_scale
		
	prev_position = position
