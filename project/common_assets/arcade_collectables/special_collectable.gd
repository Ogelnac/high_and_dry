extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var backdrop: Sprite2D = $Backdrop
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var collect_particles: PackedScene

var collectable_type
var phase_offset := randf() * TAU
var t := 0.0
var collected := false
var hue := 0.0

func _ready() -> void:
	match collectable_type:
		"Silkworm":
			sprite_2d.frame = 7
		"Sand":
			sprite_2d.frame = 8

func _process(delta: float) -> void:
	if collected:
		return
	t += delta * 2.0
	var wave := sin(t + phase_offset) + 0.3 * sin(5 * (t + phase_offset))
	rotation = wave * 0.25
	backdrop.rotation = wave * -1.0

	if hue >= 1.0:
		hue = 0.0
	else:
		hue += 0.01
	backdrop.modulate = Color.from_hsv(hue, 0.9, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.name == "arcade_player":
			if body.dead:
				return
		if collected:
			return

		collected = true
		set_deferred("monitoring", false)
		collision_shape_2d.set_deferred("disabled", true)

		match collectable_type:
			"Silkworm":
				GameManager.silk_worms += 1
			"Sand":
				GameManager.sand += 1

		audio_player.play()

		await get_tree().process_frame
		spawn_particles()

		await animate_and_destroy()

func spawn_particles() -> void:
	if collect_particles:
		var count = randi_range(16, 18)
		for i in count:
			var p = collect_particles.instantiate()
			get_parent().add_child(p)
			p.global_position = global_position
			var angle = (TAU / count) * i
			p.linear_velocity = Vector2.RIGHT.rotated(angle) * randf_range(50.0, 90.0)
			p.color_rect.color = Color(1.0 ,1.0 ,1.0 , randf_range(0.5, 1.0))

func animate_and_destroy() -> void:
	var duration := 0.3
	var time := 0.0
	var original_scale := scale

	while time < duration:
		time += get_process_delta_time()
		var ct := time / duration
		scale = original_scale * (1.0 + ct * 1.2)
		await get_tree().process_frame

	queue_free()

func set_active():
	collision_shape_2d.set_disabled(false)
	backdrop.visible = true
	sprite_2d.visible = true
