extends Sprite2D

const RUN_SPEED_THRESHOLD: float = 5.0

@export var squash_intensity: float = 0.5
@export var landing_squash_multiplier: float = 2.5
@export var landing_squash_threshold: float = 200.0

@onready var player: CharacterBody2D = get_parent()
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var floor_ray_cast: RayCast2D = $"../CollisionShape2D/FloorRayCast"

var current_angle: float = 0.0
var last_surface_angle: float = 0.0
var landing_squash_timer: float = 0.0
var previous_velocity: Vector2 = Vector2.ZERO

func update_animation(delta: float) -> void:
	_update_orientation(delta)
	var movement_velocity: Vector2 = player.get_real_velocity()
	if player.is_on_floor():
		movement_velocity = movement_velocity.slide(player.get_floor_normal())
	elif floor_ray_cast.is_colliding():
		movement_velocity = movement_velocity.slide(floor_ray_cast.get_collision_normal())
	elif player.is_on_wall():
		movement_velocity = movement_velocity.slide(player.get_wall_normal())
	elif player.is_on_ceiling():
		movement_velocity = movement_velocity.slide(Vector2.DOWN.rotated(last_surface_angle))
	_handle_animation(movement_velocity)
	_apply_squash_and_stretch(delta)
	_update_facing(movement_velocity)
	previous_velocity = player.velocity

func show_death_frame() -> void:
	animation_player.stop()
	frame = 28

func _handle_animation(movement_velocity: Vector2) -> void:
	if player.aiming:
		animation_player.stop()
		var local_aim: Vector2 = -player.release_displacement.rotated(-current_angle)
		frame = 4 + _directional_pose(local_aim)
		flip_h = player.release_displacement.x > 0.0
		return

	if player.needle_thrown or player.climbing_thread:
		animation_player.stop()
		var local_velocity: Vector2 = player.velocity.rotated(-current_angle)
		frame = 9 + _directional_pose(local_velocity)
	else:
		var on_surface := floor_ray_cast.is_colliding() or player.is_on_floor() or player.is_on_wall() or player.is_on_ceiling()
		var animation := &"idle"
		if on_surface and movement_velocity.length() >= RUN_SPEED_THRESHOLD:
			animation = &"run"
		if animation_player.current_animation != animation:
			animation_player.play(animation)

func _directional_pose(direction: Vector2) -> int:
	var angle := rad_to_deg(atan2(absf(direction.x), -direction.y))
	if angle < 45.0:
		return 4
	if angle < 70.0:
		return 3
	if angle < 90.0:
		return 2
	if angle < 120.0:
		return 1
	return 0

func _update_orientation(delta: float) -> void:
	if player.in_water:
		current_angle = lerp_angle(current_angle, 0.0, delta * 5.0)
		rotation = current_angle
		position = Vector2(0, -6).rotated(current_angle)
		return

	var floor_detected := floor_ray_cast.is_colliding()
	var on_surface := floor_detected or player.is_on_wall() or player.is_on_ceiling()
	if on_surface:
		var surface_normal := Vector2.ZERO
		if floor_detected:
			surface_normal = floor_ray_cast.get_collision_normal()
		else:
			for i in range(player.get_slide_collision_count()):
				surface_normal += player.get_slide_collision(i).get_normal()
		if surface_normal != Vector2.ZERO:
			surface_normal = surface_normal.normalized()
			last_surface_angle = Vector2(-surface_normal.y, surface_normal.x).angle()
			current_angle = lerp_angle(current_angle, last_surface_angle, delta * 10.0)
	else:
		current_angle = lerp_angle(current_angle, 0.0, delta * 5.0)

	rotation = current_angle
	position = Vector2(0, -6).rotated(current_angle)

func _apply_squash_and_stretch(delta: float) -> void:
	var target_scale := Vector2.ONE
	var grounded := floor_ray_cast.is_colliding()

	if not grounded:
		if player.velocity.y < 0.0:
			target_scale = Vector2(1.0 + squash_intensity * 0.2, 1.0 - squash_intensity * 0.2)
		else:
			target_scale = Vector2(1.0 - squash_intensity * 0.2, 1.0 + squash_intensity * 0.2)

	if grounded and previous_velocity.y > landing_squash_threshold and landing_squash_timer <= 0.0:
		landing_squash_timer = 0.2
		target_scale = Vector2(1.2 * landing_squash_multiplier, 0.6)

	landing_squash_timer = maxf(landing_squash_timer - delta, 0.0)
	scale = scale.lerp(target_scale, delta * 10.0)

func _update_facing(movement_velocity: Vector2) -> void:
	if player.aiming:
		return
	if player.needle_thrown or player.climbing_thread:
		movement_velocity = player.velocity
	elif movement_velocity.length() < RUN_SPEED_THRESHOLD:
		return
	var local_velocity_x: float = movement_velocity.rotated(-current_angle).x
	if local_velocity_x < -1.0:
		flip_h = true
	elif local_velocity_x > 1.0:
		flip_h = false
