extends CharacterBody2D

# WORLD
@export var friction: float = 1.0
@export var lung_capacity: float = 150.0
var damping = 0.0
var in_water = false
var breath = 1.0
var prev_resources = 0
var dead = false

# VELOCITIES
@export var hop_velocity: Vector2 = Vector2(50.0, -150.0)
@export var climb_velocity: float = 250.0
@export var climb_stop_velocity: float = 0.0 #150.0
@export var throw_velocity: float = 800.0
@export var collect_velocity: float = 0.0 #50.0

# ANIMATION
@export var squash_intensity: float = 0.5
@export var landing_squash_multiplier: float = 2.5
@export var landing_squash_threshold: float = 200.0
@onready var sprite:= $Sprite2D
var landing_squash_timer: float = 0.0
var previous_velocity: Vector2 = Vector2.ZERO

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

#AUDIO
const TAILOR_DEATH = preload("res://audio/tailor_death.wav")

func _ready() -> void:
	aim_line.points = [Vector2.ZERO, Vector2.ZERO]
	$Sprite2D.scale = Vector2.ONE # keep this. player was spawning all strectched body horror style

func _physics_process(delta: float) -> void:
	if dead:
		move_and_slide()
		return

	if aiming:
		if slowmo_count > 0.0:
			slowmo_count -= delta
			Engine.time_scale = 1.0 - pow(slowmo_count / slowmo_max, 4)
		else:
			Engine.time_scale = 1.0
	elif not dead:
		Engine.time_scale = 1.0

	if climbing_thread:
		var collision = move_and_collide((climbing_target_location - global_position).normalized() * climb_velocity * delta, true)
		if collision:
			climbing_thread = false
			recall_needles.emit()
		else:
			velocity = (climbing_target_location - global_position).normalized() * climb_velocity
			move_and_slide()
	else:
		move_and_slide()
		apply_friction_and_gravity(delta)

	if get_slide_collision_count() > 0:
		if touched_spikes():
			print("Yeooowch!")

	handle_animation()
	update_sprite_orientation(delta)
	apply_squash_and_stretch(delta)
	previous_velocity = velocity

	if touching and tap_timer.is_stopped():
		# Aiming
		release_displacement = tap_screen_pos - tap_initial_screen_pos
		if aiming and release_displacement.length() > 64.0:
			aim_ray.target_position = get_throw_velocity(release_displacement)
			if aim_ray.is_colliding():
				aim_line.points = [
					aim_line.to_local(Vector2(global_position.x, global_position.y - 4)),
					aim_line.to_local(aim_ray.get_collision_point())
				]
			else:
				aim_line.points = [
					aim_line.to_local(Vector2(global_position.x, global_position.y - 4)),
					aim_line.to_local(global_position + get_throw_velocity(release_displacement))
				]

	var local_aim_x = (-release_displacement).rotated(-current_angle).x
	var wall_dir = get_wall_collision_direction()

	if aiming:
		sprite.flip_h = local_aim_x < 0
	elif wall_dir != 0:
		var local_wall_x = Vector2(wall_dir, 0).rotated(-current_angle).x
		sprite.flip_h = local_wall_x > 0
	elif abs(velocity.x) > 0.5:
		var local_vel_x = velocity.rotated(-current_angle).x
		sprite.flip_h = local_vel_x < 0

func _process(_delta: float) -> void:
	if Debug.infinite_health:
		breath = 1.0
		return

	if in_water and breath > 0.0:
		breath -= 1.0 / lung_capacity
	elif in_water:
		breath = 0.0

	if not in_water and breath < 1.0:
		breath += 1.0 / lung_capacity
	elif not in_water:
		breath = 1.0

func _input(event: InputEvent):
	if dead:
		return

	if event is InputEventScreenTouch and not dead:
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
	var direction = -released_displacement.normalized()
	var vel = direction * throw_velocity

	if is_on_wall() or is_on_ceiling() or is_on_floor():
		var normal = get_contact_normal()

		if direction.dot(normal) > 0.0:
			var parallel = vel - normal * vel.dot(normal)
			if parallel.length() < 0.0:
				vel = parallel * throw_velocity
		else:
			var tangent = Vector2(-normal.y, normal.x).normalized()
			if direction.dot(tangent) < 0.0:
				tangent = -tangent
			vel = tangent * throw_velocity
	return vel

func apply_friction_and_gravity(delta: float) -> void:
	var arcade_resources = GameManager.new_arcade_resources.size()
	if in_water:
		velocity.y -= (100 - (arcade_resources * 5.0)) * delta
		if damping > 0.0:
			velocity = velocity.move_toward(Vector2.ZERO, damping * delta)
		return

	if not is_on_floor():
		velocity.y += (200.0 + (arcade_resources * 5.0)) * delta
	else:
		var normal = get_floor_normal()
		var tangential = Vector2(-normal.y, normal.x)
		var tangential_velocity = velocity.dot(tangential)
		tangential_velocity = move_toward(tangential_velocity, 0.0, friction)
		velocity = tangential * tangential_velocity

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

func get_contact_normal() -> Vector2:
	var normal := Vector2.ZERO
	for i in range(get_slide_collision_count()):
		normal += get_slide_collision(i).get_normal()
	return normal.normalized()

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

	if needle_thrown or climbing_thread:
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
	if in_water:
		current_angle = lerp_angle(current_angle, 0.0, delta * 5.0)
		sprite.rotation = current_angle
		sprite.position = Vector2(0, -6).rotated(current_angle)
		return

	var on_surface := is_on_floor() or is_on_wall() or is_on_ceiling()
	if on_surface:
		var surface_normal = Vector2.ZERO
		for i in range(get_slide_collision_count()):
			surface_normal += get_slide_collision(i).get_normal()
		if surface_normal != Vector2.ZERO:
			surface_normal = surface_normal.normalized()
			var tangent = Vector2(-surface_normal.y, surface_normal.x)
			last_surface_angle = tangent.angle()
		current_angle = lerp_angle(current_angle, last_surface_angle, delta * 10.0)
	else:
		current_angle = lerp_angle(current_angle, 0.0, delta * 5.0)

	sprite.rotation = current_angle
	sprite.position = Vector2(0, -6).rotated(current_angle)

func wrapf(value: float, min_val: float, max_val: float) -> float:
	return fmod((value - min_val), (max_val - min_val)) + min_val

func apply_squash_and_stretch(delta: float) -> void:
	var target_stretch_x = 1.0
	var target_stretch_y = 1.0

	if not is_on_floor():
		if velocity.y < 0:
			target_stretch_x = 1.0 + (squash_intensity * 0.2)
			target_stretch_y = 1.0 - (squash_intensity * 0.2)
		else:
			target_stretch_x = 1.0 - (squash_intensity * 0.2)
			target_stretch_y = 1.0 + (squash_intensity * 0.2)

	if is_on_floor() and previous_velocity.y > landing_squash_threshold and landing_squash_timer <= 0:
		landing_squash_timer = 0.2
		target_stretch_x = 1.2 * landing_squash_multiplier
		target_stretch_y = 0.6

	if landing_squash_timer > 0:
		landing_squash_timer -= delta
	else:
		landing_squash_timer = 0.0

	sprite.scale.x = lerp(sprite.scale.x, target_stretch_x, delta * 10)
	sprite.scale.y = lerp(sprite.scale.y, target_stretch_y, delta * 10)

func kill():
	dead = true
	aiming = false
	climbing_thread = false
	aim_line.points = [Vector2.ZERO, Vector2.ZERO]
	$AnimationPlayer.stop()
	sprite.frame = 23
	var sfx := AudioStreamPlayer.new()
	sfx.stream = TAILOR_DEATH
	sfx.volume_db = -20.0
	add_child(sfx)
	sfx.play()
