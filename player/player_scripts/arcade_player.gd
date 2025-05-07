extends CharacterBody2D

# WORLD
@export var gravity: float = 98.0
@export var friction: float = 1.0

# VELOCITIES
@export var hop_velocity: Vector2 = Vector2(50.0, -150.0)
@export var climb_velocity: float = 250.0
@export var climb_stop_velocity: float = 0.0 #150.0
@export var throw_velocity: float = 800.0
@export var collect_velocity: float = 0.0 #50.0

# NEEDLE
const NEEDLE = preload("res://player/needle/needle.tscn")
@export var max_needle_count: int = 1
@export var needle_count: int = 1
signal recall_needles
var needle_thrown := false
var current_angle := 0.0
var aiming = false
@export var slowmo_max = 1.0
var slowmo_count = slowmo_max
var climbing_thread = false
var climbing_target_location = Vector2.ZERO
var climbing_target: CharacterBody2D

# AIMING
@onready var aim_line: Line2D = $AimLine
@onready var aim_ray: RayCast2D = $AimRay
var release_displacement: Vector2 = Vector2.ZERO
var last_surface_angle := 0.0

# TOUCH
var touching: bool = false
var tap_initial_screen_pos: Vector2 = Vector2.ZERO
var tap_screen_pos: Vector2 = Vector2.ZERO

# TIMERS
@export var tap_timer: Timer

func _ready() -> void:
	aim_line.points = [Vector2.ZERO, Vector2.ZERO]

func _process(delta: float) -> void:
	if aiming:
		if slowmo_count > 0.0:
			slowmo_count -= delta
			Engine.time_scale = 1.0 - pow(slowmo_count/slowmo_max, 4)
		else:
			Engine.time_scale = 1.0
		
	if climbing_thread:
		var collision = move_and_collide((climbing_target_location-global_position).normalized() * climb_velocity * delta, true)
		if collision:
			climbing_thread = false
			recall_needles.emit()
		else:
			velocity = (climbing_target_location-global_position).normalized() * climb_velocity;
			move_and_slide()
	else:
		move_and_slide()
		apply_friction_and_gravity(delta)
	
	if get_slide_collision_count() > 0:
		if touched_spikes():
			print("Yeooowch!")
	
	handle_animation()
	update_sprite_orientation(delta)
	
	if touching and tap_timer.is_stopped():
		# Aiming
		release_displacement = tap_screen_pos - tap_initial_screen_pos
		if aiming and release_displacement.length() > 64.0:
			aim_ray.target_position = get_throw_velocity(release_displacement)
			if aim_ray.is_colliding():
				aim_line.points = [aim_line.to_local(Vector2(global_position.x, global_position.y - 4)), aim_line.to_local(aim_ray.get_collision_point())]
			else:
				aim_line.points = [aim_line.to_local(Vector2(global_position.x, global_position.y - 4)), aim_line.to_local(global_position + get_throw_velocity(release_displacement))]

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		# Initial touch
		if event.is_pressed():
			touching = true
			tap_initial_screen_pos = event.position
			tap_screen_pos = tap_initial_screen_pos
			tap_timer.start()
			recall_needles.emit()
		
		# Touch release
		elif event.is_released():
			# Reset variables
			touching = false
			aim_line.points = [Vector2.ZERO, Vector2.ZERO]
			Engine.time_scale = 1.0
			# Touch was a tap
			if tap_timer.time_left > 0.0:
				if climbing_thread:
					climbing_thread = false
					velocity += (climbing_target_location - global_position).normalized() * climb_stop_velocity
					recall_needles.emit()
				elif is_on_wall():
					# Wall jump
					velocity.y = hop_velocity.y
					velocity.x = get_wall_collision_direction() * hop_velocity.x
				elif is_on_floor():
					# Hop
					velocity.y = hop_velocity.y
					if abs(velocity.x) > 0.5:
						velocity.x = sign(velocity.x) * hop_velocity.x
			tap_timer.stop()
		
		release_displacement = tap_screen_pos - tap_initial_screen_pos
		if aiming and release_displacement.length() > 64.0:
			if needle_count > 0:
				needle_count -= 1
				throw_needle(get_throw_velocity(release_displacement))
		aiming = false
	
	# Drag
	if event is InputEventScreenDrag:
		tap_screen_pos = event.position

func get_throw_velocity(released_displacement: Vector2) -> Vector2:
	var normalised_displacement = -released_displacement.normalized()
	return normalised_displacement * throw_velocity

func apply_friction_and_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, friction)
	else:
		velocity.y += gravity * delta
	if is_on_wall():
		velocity.y = move_toward(velocity.y, 0.0, friction)

func touched_spikes() -> bool:
	if (is_on_floor() or is_on_wall() or is_on_ceiling()):
		var tilemap: TileMapLayer = get_last_slide_collision().get_collider()
		var rid: RID = get_last_slide_collision().get_collider_rid()
		if tilemap:
			var cell: Vector2i = tilemap.get_coords_for_body_rid(rid)
			var data: TileData = tilemap.get_cell_tile_data(cell)
			
			if data:
				var spiky: bool = data.get_custom_data("spiky")
				return spiky
	
	return false

func get_wall_collision_direction() -> float:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal().x > 0:
			return 1.0
		elif collision.get_normal().x < 0:
			return -1.0
	return 0.0

func throw_needle(thrown_velocity: Vector2) -> void:
	var needle_instance = NEEDLE.instantiate()
	add_child(needle_instance)
	needle_instance.global_position = global_position
	needle_instance.velocity = thrown_velocity
	needle_instance.needle_stuck.connect(_on_needle_stuck)
	needle_instance.needle_collected.connect(_on_needle_collected)
	needle_thrown = true

func _on_needle_stuck(needle: CharacterBody2D, location: Vector2) -> void:
	climbing_thread = true
	climbing_target = needle
	climbing_target_location = location

func _on_needle_collected(needle: CharacterBody2D) -> void:
	needle.queue_free()
	needle_count += 1
	if needle == climbing_target:
		climbing_thread = false
	if needle.stuck:
		velocity += (climbing_target_location - global_position).normalized() * climb_stop_velocity
	else:
		velocity += (needle.global_position - global_position).normalized() * collect_velocity
	
	needle_thrown = false

func _on_tap_timer_timeout() -> void:
	if touching and needle_count > 0:
		aiming = true
		slowmo_count = slowmo_max
	pass

func handle_animation() -> void:
	var sprite := $Sprite2D
	var anim := $AnimationPlayer

	if aiming:
		anim.stop()
		var local_aim = -release_displacement.rotated(-current_angle)
		var angle = rad_to_deg(atan2(-local_aim.x, -local_aim.y))

		if angle < 0:
			angle += 360

		var frame := 8
		if angle >= 0 and angle < 45:
			frame = 8
		elif angle < 70:
			frame = 7
		elif angle < 90:
			frame = 6
		elif angle < 120:
			frame = 5
		elif angle < 180:
			frame = 4
		elif angle < 240:
			frame = 4
		elif angle < 270:
			frame = 5
		elif angle < 290:
			frame = 6
		elif angle < 315:
			frame = 7
		else:
			frame = 8

		sprite.frame = frame

		sprite.flip_h = release_displacement.x > 0
		return

	if needle_thrown and not climbing_thread:
		anim.play("idle_temp")
		return

	if is_on_floor() or is_on_wall() or is_on_ceiling():
		if velocity.length() < 5.0:
			anim.play("idle")
		else:
			anim.play("run")
	else:
		anim.play("idle")

func update_sprite_orientation(delta: float) -> void:
	var sprite := $Sprite2D
	var on_surface := is_on_floor() or is_on_wall() or is_on_ceiling()
	var target_angle := last_surface_angle

	if on_surface:
		var surface_normal = Vector2.ZERO
		for i in range(get_slide_collision_count()):
			surface_normal += get_slide_collision(i).get_normal()
		if surface_normal != Vector2.ZERO:
			surface_normal = surface_normal.normalized()
			var tangent = Vector2(-surface_normal.y, surface_normal.x)
			target_angle = tangent.angle()
			last_surface_angle = target_angle
	else:
		target_angle = lerp_angle(last_surface_angle, 0.0, delta * 1.0)

	current_angle = lerp_angle(current_angle, target_angle, delta * 10.0)
	sprite.rotation = current_angle

	sprite.position = Vector2(0, -4).rotated(current_angle)

	if aiming:
		sprite.flip_h = release_displacement.x > 0
	elif abs(velocity.x) > 0.5:
		sprite.flip_h = velocity.x < 0

func wrapf(value: float, min_val: float, max_val: float) -> float:
	return fmod((value - min_val), (max_val - min_val)) + min_val
