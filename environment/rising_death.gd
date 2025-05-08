extends Area2D

@onready var player: CharacterBody2D = $"../ArcadePlayer"
@onready var main: Node2D = $".."
@onready var drip_timer: Timer = Timer.new()
@onready var burst_scene: PackedScene = preload("res://effects/burst_particle.tscn")

var is_playing: bool = false
var drip_duration := 3.0
var drip_time_left := 0.0

func _ready():
	add_child(drip_timer)
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
	main.stink_multiplier = 4.0
	call_deferred("_spawn_splash", player.global_position)

func _on_body_exited(_body: Node2D) -> void:
	main.stink_multiplier = 1.0
	drip_time_left = drip_duration
	drip_timer.start()

func _spawn_splash(position: Vector2):
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
		particle.global_position = position

		particle.collision_mask = 0
		particle.gravity_scale = 0.75
		particle.linear_velocity = velocity

func _spawn_drip():
	var velocity := Vector2(randf_range(-20.0, 20.0), randf_range(40.0, 60.0))
	var particle := burst_scene.instantiate()
	get_tree().current_scene.add_child(particle)
	particle.global_position = player.position
	particle.linear_velocity = velocity
	particle.collision_mask = 0
	particle.z_index = 5
	particle.gravity_scale = 0.75
