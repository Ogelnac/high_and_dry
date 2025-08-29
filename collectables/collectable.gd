extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var collect_particles: PackedScene

@export var colours: Array[String] = [
	"#ac3232",
	"#df7126",
	"#fbf236",
	"#6abe30",
	"#639bff",
	"#d77bba",
	"#ffffff",
	"#8f563b"
]

var collectable_type
var phase_offset := randf() * TAU
var t := 0.0
var collected := false

func _ready() -> void:
	collectable_type = randi_range(0, 7)
	sprite_2d.frame = collectable_type

func _process(delta: float) -> void:
	if collected:
		return
	t += delta * 2.0
	var wave := sin(t + phase_offset) + 0.3 * sin(5 * (t + phase_offset))
	rotation = wave * 0.25

func _on_body_entered(_body: Node2D) -> void:
	if collected:
		return
	collected = true

	set_deferred("monitoring", false)
	collision_shape_2d.set_deferred("disabled", true)

	GameManager.add_resource(collectable_type)
	GameManager.stink_metre = clamp(GameManager.stink_metre - 10.0, 0.0, 100.0)

	audio_player.play()

	await get_tree().process_frame
	spawn_particles()

	await animate_and_destroy()

func spawn_particles() -> void:
	if collect_particles:
		var count = randi_range(6, 8)
		for i in count:
			var p = collect_particles.instantiate()
			get_parent().add_child(p)
			p.global_position = global_position
			var angle = (TAU / count) * i
			p.linear_velocity = Vector2.RIGHT.rotated(angle) * randf_range(50.0, 90.0)
			p.color_rect.color = Color(colours[collectable_type], randf_range(0.5, 1.0))

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
