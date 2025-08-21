extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var main: Node2D = $".."

const POW = preload("res://effects/pow.tscn")
const IMPACT = [
	preload("res://audio/cartoon_impacts/impact_1.wav"),
	preload("res://audio/cartoon_impacts/impact_2.wav"),
	preload("res://audio/cartoon_impacts/impact_3.wav"),
	preload("res://audio/cartoon_impacts/impact_4.wav"),
	preload("res://audio/cartoon_impacts/impact_5.wav"),
	preload("res://audio/cartoon_impacts/impact_6.wav"),
	preload("res://audio/cartoon_impacts/impact_7.wav"),
	preload("res://audio/cartoon_impacts/impact_8.wav"),
]
const colours: Array[String] = [
	"#ac3232",
	"#df7126",
	"#fbf236",
	"#6abe30",
	"#639bff",
	"#d77bba",
	"#ffffff",
	"#8f563b"
]

var start_height: float
var arc_size: float = 128.0

var max_time: float = 5.0
var time: float = max_time
var bonked: bool
var phase_shift: float = 0.0
var phase_locked: bool = false

var lock_self_retrigger = false

func _process(delta: float) -> void:
	if bonked:
		delta *= 5.0
	time -= delta
	if global_position.y > start_height and not lock_self_retrigger:
		main.retrigger = true
		lock_self_retrigger = true
		main.update_counters(sprite_2d.frame)
		queue_free()
	else:
		var journey_percent: float = time / max_time
		if bonked and journey_percent > 0.5 and not phase_locked:
			phase_shift = 1.0 - 2.0 * journey_percent - phase_shift
			phase_locked = true
		global_position.y = start_height - arc_size * sin((journey_percent + phase_shift) * PI)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		bonked = true
		phase_locked = false

		var idx = sprite_2d.frame % 8
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = IMPACT[idx]
		audio_player.autoplay = true
		var pow = POW.instantiate()
		pow.modulate = colours[idx]
		pow.position = position
		get_parent().add_child(audio_player)
		get_parent().add_child(pow)
