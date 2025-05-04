extends CharacterBody2D

signal needle_stuck(needle: CharacterBody2D, location: Vector2)
signal needle_collected(needle: CharacterBody2D)

@onready var thread: Line2D = $Thread
var thread_target: CharacterBody2D

var stuck = false
var recalled = false
var collected = false

func _ready() -> void:
	thread_target = get_parent()
	thread.points = [thread.to_local(global_position), thread.to_local(thread_target.global_position)]
	thread_target.recall_needles.connect(_on_recall_needles)

func _physics_process(delta: float) -> void:
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
			#velocity += get_gravity() * 0.1 * delta
			
			if (is_on_floor() or is_on_wall() or is_on_ceiling()):
				if is_tile_pierceable():
					stuck = true
					needle_stuck.emit(self, global_position)
					velocity = Vector2.ZERO
				else:
					recalled = true
	
	var needle_eye = global_position - Vector2.from_angle(rotation) * 28.0
	thread.points[0] = thread.to_local(needle_eye)
	thread.points[1] = thread.to_local(thread_target.global_position)

func is_tile_pierceable() -> bool:
	var tilemap: TileMapLayer = get_last_slide_collision().get_collider()
	var rid: RID = get_last_slide_collision().get_collider_rid()
	if tilemap:
		var cell: Vector2i = tilemap.get_coords_for_body_rid(rid)
		var data: TileData = tilemap.get_cell_tile_data(cell)
		
		if data:
			var pierceable: bool = data.get_custom_data("pierceable")
			return pierceable
	
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
