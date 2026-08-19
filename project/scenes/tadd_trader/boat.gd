extends Node2D

@export var radius: Vector2 = Vector2(8.0, 4.0)
@export var angular_speed: float = 0.7
@export var speed: float = 30.0
@export var brake_k: float = 2.0
@export var stop_epsilon: float = 0.5
@export var flip_sprite: bool = false

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var tile_map_layer_2: TileMapLayer = $TileMapLayer2
@onready var tile_map_layer_3: TileMapLayer = $TileMapLayer3
@onready var tile_map_layer_4: TileMapLayer = $TileMapLayer4

const SMOKE_EMITTER_OFFSET := Vector2(-8.0, -46.0)

@onready var cpu_particles_2d: CPUParticles2D = $SubViewport/Offset/CPUParticles2D
@onready var smoke_sprite: Sprite2D = get_parent().get_node("BoatSmoke")

var _centre: Vector2
var _theta: float = 0.0
var moving: bool = false

func _ready():
	_centre = position
	_update_smoke_emitter()
	update_orientation(flip_sprite)
	cpu_particles_2d.emitting = true
	cpu_particles_2d.restart()

func _process(delta):
	_theta += angular_speed * delta
	position = _centre + Vector2(cos(_theta) * radius.x, sin(_theta) * radius.y)
	rotation = sin(_theta * 2.0) * -0.025
	_update_smoke_emitter()

	if moving:
		var dist = -position.x
		var v = clamp(dist * brake_k, -speed, speed)
		
		if abs(dist) <= stop_epsilon and abs(v) < 1.0:
			position.x = 0.0
			moving = false
		else:
			_centre.x += v * delta

func _update_smoke_emitter() -> void:
	cpu_particles_2d.position = position + SMOKE_EMITTER_OFFSET - smoke_sprite.position
	cpu_particles_2d.rotation = rotation

func update_orientation(dir: bool) -> void:
	tile_map_layer.visible = !dir
	tile_map_layer_2.visible = !dir
	tile_map_layer_3.visible = dir
	tile_map_layer_4.visible = dir
