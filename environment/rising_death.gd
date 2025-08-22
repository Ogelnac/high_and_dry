extends Area2D

@onready var player: CharacterBody2D = $"../ArcadePlayer"
@onready var main: Node2D = $".."
var drip_timer: Timer
@onready var burst_scene: PackedScene = preload("res://effects/burst_particle.tscn")

var is_playing: bool = false
var drip_duration := 3.0
var drip_time_left := 0.0

func _enter_tree() -> void:
	drip_timer = Timer.new()
	add_child(drip_timer)

func _ready() -> void:
	drip_timer.wait_time = 0.25
	drip_timer.one_shot = false
	drip_timer.timeout.connect(_spawn_drip)

func _process(delta: float) -> void:
	if is_playing:
		var offset = 0.0
		if player.global_position.y <= global_position.y + offset:
			global_position.y = player.global_position.y - offset
		global_position.y -= 50.0 * delta
	if drip_time_left > 0.0:
		drip_time_left -= delta
		if drip_time_left <= 0.0:
			drip_timer.stop()

func _on_body_entered(_body: Node2D) -> void:
	player.gravity = -150.0
	player.damping = 0.0
	player.in_water = true
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	main.stink_multiplier = 4.0
	call_deferred("_spawn_splash", player.global_position)

func _on_body_exited(_body: Node2D) -> void:
	player.gravity = 200.0
	player.damping = 0.0
	player.in_water = false
	player.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	main.stink_multiplier = 1.0
	drip_time_left = drip_duration
	if drip_timer.is_inside_tree():
		drip_timer.start()

func _spawn_splash(splash_position: Vector2) -> void:
	var num_particles := 6
	var base_angle := -PI / 2
	var angle_spread := PI / 2
	for i in range(num_particles):
		var angle = base_angle - angle_spread / 2 + (angle_spread / (num_particles - 1)) * i
		var horizontal = cos(angle) * randf_range(40.0, 80.0)
		var vertical = -randf_range(150.0, 300.0)
		var velocity = Vector2(horizontal, vertical)
		var particle := burst_scene.instantiate()
		get_tree().current_scene.add_child(particle)
		particle.global_position = splash_position
		particle.collision_mask = 0
		particle.gravity_scale = 0.75
		particle.linear_velocity = velocity

func _spawn_drip() -> void:
	var velocity := Vector2(randf_range(-20.0, 20.0), randf_range(40.0, 60.0))
	var particle := burst_scene.instantiate()
	get_tree().current_scene.add_child(particle)
	particle.global_position = player.position
	particle.linear_velocity = velocity
	particle.collision_mask = 0
	particle.z_index = 5
	particle.gravity_scale = 0.75
