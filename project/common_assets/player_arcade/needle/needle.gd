extends CharacterBody2D

signal needle_stuck(needle: CharacterBody2D, location: Vector2)
signal needle_collected(needle: CharacterBody2D)

@export var max_thread_distance: float = 560.0
@onready var thread: Line2D = $Thread
var thread_target: CharacterBody2D

var stuck = false
var recalled = false
var collected = false

# Wobble thread configuration
const THREAD_RESOLUTION := 10
var wave_amplitude := 15.0
var wave_speed := 5.0
var wave_time := 0.0

func _ready() -> void:
	thread_target = get_parent()
	thread.width = 1.0
	thread.points.resize(THREAD_RESOLUTION)
	thread_target.recall_needles.connect(_on_recall_needles)

func _physics_process(delta: float) -> void:
	if thread_target and thread_target.is_inside_tree():
		if thread_target.global_position.distance_to(global_position) > max_thread_distance:
			recalled = true
			stuck = false

	if recalled:
		global_position = global_position.move_toward(thread_target.global_position, 300.0 * delta)
		rotation = (global_position - thread_target.global_position).normalized().angle()
		if (thread_target.global_position - global_position).length() < 32.0:
			on_needle_collected()
	else:
		if !stuck:
			if velocity.length() > 0.1:
				rotation = velocity.angle()
			move_and_slide()

			if (is_on_floor() or is_on_wall() or is_on_ceiling()):
				if is_tile_pierceable():
					stuck = true
					needle_stuck.emit(self, global_position)
					velocity = Vector2.ZERO
				else:
					recalled = true

	update_thread(delta)

func update_thread(delta: float) -> void:
	wave_time += delta

	var needle_eye = global_position - Vector2.from_angle(rotation) * 28.0
	var start = thread.to_local(needle_eye)
	var end = thread.to_local(thread_target.global_position)

	var new_points: Array[Vector2] = []
	
	for i in THREAD_RESOLUTION:
		var t = float(i) / (THREAD_RESOLUTION - 1)
		var base_pos = start.lerp(end, t)

		if stuck or recalled:
			new_points.append(base_pos)
		else:
			var dir = (end - start).normalized()
			var normal = dir.orthogonal()
			var fade = sin(t * PI)
			var offset = sin(wave_time * wave_speed + t * PI * 2.0) * wave_amplitude * fade
			new_points.append(base_pos + normal * offset)

	thread.points = new_points

func is_tile_pierceable() -> bool:
	var collision := get_last_slide_collision()
	if collision:
		var tilemap: TileMapLayer = collision.get_collider()
		var rid: RID = collision.get_collider_rid()
		if tilemap:
			var cell: Vector2i = tilemap.get_coords_for_body_rid(rid)
			var data: TileData = tilemap.get_cell_tile_data(cell)
			if data:
				return data.get_custom_data("pierceable")
	return true

func _on_recall_needles():
	recalled = true
	stuck = false

func _on_pickup_area_body_entered(_body: Node2D) -> void:
	if stuck or recalled:
		on_needle_collected()

func on_needle_collected():
	if !collected:
		needle_collected.emit(self)
		collected = true
