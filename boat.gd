extends Node2D

@export var radius: Vector2 = Vector2(8.0, 4.0)
@export var angular_speed: float = 0.7
@export var speed: float = 30.0
@export var brake_k: float = 2.0
@export var stop_epsilon: float = 0.5

@onready var cpu_particles_2d: CPUParticles2D = $SubViewport/Offset/CPUParticles2D

var _centre: Vector2
var _gpu_centre: Vector2
var _theta: float = 0.0
var moving: bool = false

func _ready():
	_centre = position

func _process(delta):
	_theta += angular_speed * delta
	position = _centre + Vector2(cos(_theta) * radius.x, sin(_theta) * radius.y)
	rotation = sin(_theta * 2.0) * -0.025

	cpu_particles_2d.rotation = rotation
	cpu_particles_2d.position = position

	if moving:
		var dist = -position.x
		var v = clamp(dist * brake_k, -speed, speed)
		
		if abs(dist) <= stop_epsilon and abs(v) < 1.0:
			position.x = 0.0
			moving = false
		else:
			_centre.x += v * delta
