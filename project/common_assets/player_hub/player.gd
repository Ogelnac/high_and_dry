extends CharacterBody2D

signal start_game_signal
signal in_launch_zone

@export var max_speed: float = 150.0
@export var acceleration: float = 500.0
@export var air_control_acceleration: float = 200.0
@export var jump_force: float = -230.0
@export var max_air_speed: float = 100.0
@export var movement_delay: float = 0.15
@export var squash_intensity: float = 0.5
@export var landing_squash_multiplier: float = 2.5
@export var landing_squash_threshold: float = 200.0

const SKID = preload("uid://bvspdyryeddrv")
const JUMP = preload("uid://cd8tp2oh1fgdx")
const ONEWAY_LAYER := 1 << 3
const DROP_TIME := 0.3

var deceleration: float = 300.0
var gravity: float = 500.0
var max_fall_speed: float = 1000.0
var falling_through = false

var virtual_joystick_active: bool = false
var virtual_joystick_start: Vector2
var virtual_joystick_offset: Vector2
var dialogue_mode: bool = false

var direction: int = 0
var is_facing_right: bool = true
var current_state: String = "Idle"
var is_jumping: bool = false
var jump_requested: bool = false
var jump_velocity: Vector2 = Vector2.ZERO
var input_position: Vector2 = Vector2.ZERO
var holding_side: int = 0
var swipe_start: Vector2 = Vector2.ZERO
var is_holding: bool = false
var one_way_fall: bool = false
var movement_start_timer: float = 0.0
var movement_locked: bool = false
var previous_velocity: Vector2 = Vector2.ZERO
var landing_squash_timer: float = 0.0
var inside_launch_zone: bool = false
var launch_commence: bool = false
var wait_to_change_layer: bool = false
var launch_end: bool = false
var prev_velocity: float = 0.0
var prev_sign: int = 0
var change_sign: bool = false
var carrying_silkworm: bool = false
var _saved_mask := 0

@onready var footstep_timer: Timer = $StepTimer
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var step_sfx: AudioStreamPlayer2D = $StepSFX
@onready var sprite: Node2D = $Sprite2D

@onready var launch_zone: Area2D

@onready var hub_counter: Control = $"../CanvasLayer/UI/HubCounter"
@onready var virtual_joystick: Control = $"../CanvasLayer/UI/VirtualJoystick"
@onready var joystick_base: TextureRect = $"../CanvasLayer/UI/VirtualJoystick/JoystickBase"
@onready var joystick_handle: TextureRect = $"../CanvasLayer/UI/VirtualJoystick/JoystickHandle"

func _ready():
	launch_zone = get_node_or_null("../LaunchZone")
	position = GameManager.player_start_position
	footstep_timer.timeout.connect(_on_step_timer_timeout)

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.position.y < 100:
		return

	if dialogue_mode:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			if event.pressed:
				DialogueManager.show_next_line()
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			virtual_joystick_active = true
			virtual_joystick_start = virtual_joystick.get_local_mouse_position()
			swipe_start = event.position

			joystick_base.set_base_position(virtual_joystick_start)
			virtual_joystick.visible = true
			joystick_base.target_position = virtual_joystick_start - ((joystick_base.size * joystick_base.scale) /  2.0)
			joystick_handle.position = virtual_joystick_start - ((joystick_handle.size * joystick_handle.scale) /  4.0)

		else:
			virtual_joystick_active = false
			virtual_joystick_offset = Vector2.ZERO
			virtual_joystick.visible = false 

			var swipe_vector = event.position - swipe_start
			var swipe_length = swipe_vector.length()
			var swipe_normalized = swipe_vector.normalized()

			if swipe_length > 50 and abs(swipe_normalized.y) > 0.2 and !carrying_silkworm:
				if swipe_normalized.y < -0.5 and is_on_floor():
					if inside_launch_zone:
						hub_counter.visible = false
						launch_commence = true
					else:
						var horizontal_jump_strength = max(abs(swipe_normalized.x) * max_speed, 50.0)
						jump_velocity = Vector2(swipe_normalized.x * horizontal_jump_strength, swipe_normalized.y * abs(jump_force))
						jump_requested = true

						direction = sign(jump_velocity.x)
						var jump_instance = JUMP.instantiate()
						get_tree().root.add_child(jump_instance)
						jump_instance.position = position + Vector2(0, 5)
						if sign(jump_velocity.x) == 1:
							jump_instance.scale = Vector2(-1, 1)

				elif swipe_normalized.y > 0.5 and is_on_floor():
					fall_through_one_way_platforms()

	if launch_commence == false and (event is InputEventScreenDrag or event is InputEventMouseMotion) and virtual_joystick_active:
		virtual_joystick_offset = virtual_joystick.get_local_mouse_position() - virtual_joystick_start

		joystick_handle.position = virtual_joystick.get_local_mouse_position()

func _process(delta: float) -> void:
	if launch_zone and not launch_zone.body_entered.is_connected(_on_launch_zone_body_entered):
		launch_zone.body_entered.connect(_on_launch_zone_body_entered)
		launch_zone.body_exited.connect(_on_launch_zone_body_exited)

	if movement_locked:
		movement_start_timer += delta
		if movement_start_timer >= movement_delay:
			movement_locked = false

	if virtual_joystick_active and virtual_joystick_offset.length() > 10:
		direction = sign(virtual_joystick_offset.x)
		velocity.x = direction * max_speed * min(1.0, abs(virtual_joystick_offset.x) / 50.0)
	else:
		velocity.x = 0

	if launch_commence == true and launch_end == false:
		virtual_joystick_active = false

		var target_x = launch_zone.global_position.x
		var direction_to_center = sign(target_x - position.x)

		if abs(position.x - target_x) > 5:
			velocity.x = direction_to_center * max_speed * 0.5
		else:
			velocity.x = 0
			start_game()

		move_and_slide()
		return

	if wait_to_change_layer and position.y <= launch_zone.global_position.y -55.0:
		z_index = -110
		start_game_signal.emit()
		wait_to_change_layer = false

	if change_sign and abs(velocity.x) >= 8.5:
		var skid_instance = SKID.instantiate()
		get_tree().root.add_child(skid_instance)
		if sign(velocity.x) == -1:
			skid_instance.position = position + Vector2(15, 5)
		else:
			skid_instance.position = position + Vector2(-15, 5)
			skid_instance.scale = Vector2(-1, 1)

	change_sign = false
	if prev_sign != 0 and sign(velocity.x) != 0 and prev_sign != sign(velocity.x):
		change_sign = true

	prev_velocity = velocity.x
	prev_sign = sign(prev_velocity)

func start_game() -> void:
	launch_end = true
	wait_to_change_layer = true;
	
	jump_velocity = Vector2(0.0, -260.0)
	jump_requested = true
	var jump_instance = JUMP.instantiate()
	get_tree().root.add_child(jump_instance)
	jump_instance.position = position + Vector2(0, 5)
	if sign(jump_velocity.x) == 1:
		jump_instance.scale = Vector2(-1, 1)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0
		is_jumping = false

	if launch_commence == true and launch_end == false:
		virtual_joystick_active = false

		var target_x = launch_zone.global_position.x
		var direction_to_center = sign(target_x - position.x)

		if abs(position.x - target_x) > 5:
			velocity.x = move_toward(velocity.x, direction_to_center * max_speed * 0.5, acceleration * delta)
			change_state("Run")
		else:
			velocity.x = 0
			start_game()

		move_and_slide()
		update_state()
		return

	if jump_requested:
		is_jumping = true
		jump_requested = false
		velocity = jump_velocity

	if not is_on_floor():
		if is_jumping:
			velocity.x = jump_velocity.x
	
	var max_vel = 0
	var acc = 0
	if is_on_floor():
		max_vel = max_speed
		acc = 50.0
	else:
		max_vel = max_air_speed
		acc = 100.0
	
	if virtual_joystick_active and virtual_joystick_offset.length() > 10:
		direction = sign(virtual_joystick_offset.x)
		velocity.x = direction * max_vel * min(1.0, abs(virtual_joystick_offset.x) / acc)
	elif not virtual_joystick_active:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)


	move_and_slide()

	if velocity.x != 0:
		is_facing_right = velocity.x > 0
		$Sprite2D.flip_h = not is_facing_right

	apply_squash_and_stretch(delta)

	previous_velocity = velocity

	update_state()

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

func update_state() -> void:
	if not is_on_floor():
		change_state("Jump")
	elif velocity.x == 0:
		change_state("Idle")
	else:
		change_state("Run")

func change_state(new_state: String) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	match new_state:
		"Idle":
			animation_player.play("Idle")
			footstep_timer.stop()
		"Run":
			animation_player.play("Run")
			footstep_timer.start()
		"Jump":
			animation_player.play("Jump")
			footstep_timer.stop()

func _on_step_timer_timeout() -> void:
	step_sfx.pitch_scale = 2.0 + randf() * 0.5 - 0.05
	step_sfx.play()

func fall_through_one_way_platforms() -> void:
	if falling_through:
		return
	falling_through = true
	_saved_mask = collision_mask
	collision_mask &= ~ONEWAY_LAYER
	velocity.y = max(velocity.y, 50.0)
	await get_tree().create_timer(DROP_TIME).timeout
	collision_mask = _saved_mask
	falling_through = false

func _on_launch_zone_body_exited(body: Node2D) -> void:
	if body == self:
		inside_launch_zone = false
		in_launch_zone.emit(false)

func _on_launch_zone_body_entered(body: Node2D) -> void:
	if body == self:
		inside_launch_zone = true
		in_launch_zone.emit(true)
