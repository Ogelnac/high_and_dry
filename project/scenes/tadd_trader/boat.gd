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
@onready var launch_target: Marker2D = $LaunchTarget

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
	_centre_launch_target()

func _centre_launch_target() -> void:
	var has_bounds := false
	var minimum_x := 0.0
	var maximum_x := 0.0
	var visible_layers: Array[TileMapLayer] = [tile_map_layer, tile_map_layer_2, tile_map_layer_3, tile_map_layer_4]
	for layer: TileMapLayer in visible_layers:
		if not layer.visible:
			continue
		var used_rect: Rect2i = layer.get_used_rect()
		if used_rect.size.x <= 0:
			continue
		var first_cell := used_rect.position
		var last_cell := Vector2i(used_rect.end.x - 1, used_rect.position.y)
		var first_x: float = layer.position.x + layer.map_to_local(first_cell).x
		var last_x: float = layer.position.x + layer.map_to_local(last_cell).x
		var half_cell_width: float = float(layer.tile_set.tile_size.x) * 0.5
		var layer_minimum_x: float = min(first_x, last_x) - half_cell_width
		var layer_maximum_x: float = max(first_x, last_x) + half_cell_width
		if not has_bounds:
			minimum_x = layer_minimum_x
			maximum_x = layer_maximum_x
			has_bounds = true
		else:
			minimum_x = min(minimum_x, layer_minimum_x)
			maximum_x = max(maximum_x, layer_maximum_x)
	if has_bounds:
		launch_target.position.x = (minimum_x + maximum_x) * 0.5
