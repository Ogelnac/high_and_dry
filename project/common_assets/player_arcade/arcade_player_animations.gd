extends Sprite2D

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
	_handle_animation()
	_update_orientation(delta)
	_apply_squash_and_stretch(delta)
	_update_facing()
	previous_velocity = player.velocity

func show_death_frame() -> void:
	animation_player.stop()
	frame = 23

func _handle_animation() -> void:
	if player.aiming:
		animation_player.stop()
		var local_aim: Vector2 = -player.release_displacement.rotated(-current_angle)
		var angle := rad_to_deg(atan2(-local_aim.x, -local_aim.y))
		if angle < 0.0:
			angle += 360.0

		frame = 8
		if angle < 45.0:
			frame = 8
		elif angle < 70.0:
			frame = 7
		elif angle < 90.0:
			frame = 6
		elif angle < 120.0:
			frame = 5
		elif angle < 240.0:
			frame = 4
		elif angle < 270.0:
			frame = 5
		elif angle < 290.0:
			frame = 6
		elif angle < 315.0:
			frame = 7
		else:
			frame = 8

		flip_h = player.release_displacement.x > 0.0
		return

	if player.needle_thrown or player.climbing_thread:
		animation_player.play("idle_temp")
	elif player.is_on_floor() or player.is_on_wall() or player.is_on_ceiling():
		animation_player.play("idle" if player.velocity.length() < 5.0 else "run")
	else:
		animation_player.play("idle")

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

func _update_facing() -> void:
	if player.aiming:
		return
	var local_velocity_x: float = player.velocity.rotated(-current_angle).x
	if local_velocity_x < -1.0:
		flip_h = true
	elif local_velocity_x > 1.0:
		flip_h = false
