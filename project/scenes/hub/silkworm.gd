extends RigidBody2D

@onready var dye_bottles_parent: Node2D = $"../DyeBottles"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite2d: Sprite2D = $Sprite2D
@onready var player: CharacterBody2D = $"../Player"

const THROW_POWER := 0.1
const SWIPE_MIN_SPEED := 800.0
const REST_SPEED := 30.0
const REST_TIME := 0.25

var swipe_start: Vector2 = Vector2.ZERO
var swipe_start_time: float = 0.0
var airbound: bool = false
var held: bool = true
var target: Node2D
var rest_timer: float = 0.0

func _ready() -> void:
	target = find_nearest_bottle()
	freeze = held
	_set_friction(0.5)

func _physics_process(delta: float) -> void:
	if held and player:
		freeze = true
		sprite2d.z_index = 1
		global_position = player.global_position + Vector2(0.0, -15.0)
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		_set_friction(0.5)
		return

	if airbound:
		if player:
			player.carrying_silkworm = false
		if linear_velocity.length() <= REST_SPEED:
			rest_timer += delta
			if rest_timer >= REST_TIME or sleeping:
				airbound = false
				rest_timer = 0.0
				target = find_nearest_bottle()
		else:
			rest_timer = 0.0
		_set_friction(0.5)
		return

	_set_friction(0.0)
	if target == null or not is_instance_valid(target):
		target = find_nearest_bottle()
		if target == null:
			return

	var dx := target.global_position.x - global_position.x
	if abs(dx) > 0.5:
		linear_velocity.x = move_toward(linear_velocity.x, sign(dx) * 10.0, 120.0 * delta)
		if sprite2d.frame == 0:
			animation_player.play("walk")
		sprite2d.flip_h = dx < 0.0
	else:
		linear_velocity.x = 0.0
		animation_player.play("idle")
		GameManager.increase_silkworm_amount(target.name)
		var new_amount: int = GameManager.get_silkworm_amount(target.name)
		if target.has_method("set_silkworm_amount"):
			target.set_silkworm_amount(new_amount)
		queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.position.y < 100:
			return
		if event.pressed:
			swipe_start_time = Time.get_ticks_msec() / 1000.0
			swipe_start = _screen_to_world(event.position)
		else:
			if not held:
				return
			var release_pos := _screen_to_world(event.position)
			var swipe_vec: Vector2 = release_pos - swipe_start
			var swipe_time: float = max(0.001, (Time.get_ticks_msec() / 1000.0) - swipe_start_time)
			var swipe_speed: float = swipe_vec.length() / swipe_time
			if swipe_speed > SWIPE_MIN_SPEED:
				held = false
				freeze = false
				sleeping = false
				linear_velocity = swipe_vec.normalized() * (swipe_speed * THROW_POWER)
				airbound = true
				sprite2d.z_index = 0
				_set_friction(0.5)

func _screen_to_world(p: Vector2) -> Vector2:
	var xform: Transform2D = get_viewport().get_canvas_transform()
	return xform.affine_inverse() * p

func find_nearest_bottle() -> Node2D:
	var best: Node2D = null
	var best_d2 := INF
	for c in dye_bottles_parent.get_children():
		if c is Node2D:
			var d2 := global_position.distance_squared_to(c.global_position)
			if d2 < best_d2:
				best_d2 = d2
				best = c
	if best and sprite2d:
		sprite2d.flip_h = best.global_position.x < global_position.x
	return best

func _ensure_material() -> PhysicsMaterial:
	var mat := physics_material_override
	if mat == null:
		mat = PhysicsMaterial.new()
		physics_material_override = mat
	return mat

func _set_friction(v: float) -> void:
	var mat := _ensure_material()
	mat.friction = v
