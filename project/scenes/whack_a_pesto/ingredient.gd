extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var main: Node2D = $".."

const POW = preload("uid://dbu1mtwo6ccdo")
const IMPACT = [
	preload("uid://d4mg7pipglpkh"),
	preload("uid://d0may6dhmvyq1"),
	preload("uid://bqwcy347ol74v"),
	preload("uid://b32n54dgbbqd8"),
	preload("uid://cb2av56vlq5eo"),
	preload("uid://dqj358mgss1fu"),
	preload("uid://cryj52l7m7adl"),
	preload("uid://dktx2p1x31kgs")
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
var gravity: float
var airtime: float
var height: float

var r_vel: float
var angle: float = r_vel

var max_hitlag = 0.2
var hitlag = max_hitlag

var max_time: float = 5.0
var time: float = max_time
var bonked: bool

var lock_self_retrigger = false

func _process(delta: float) -> void:
	rotate(angle * delta)
	if bonked:
		if hitlag > 0.0:
			velocity = Vector2.ZERO
			angle = 0.0
			hitlag -= delta
			var scaling = sin((1.0 - (hitlag/max_hitlag)) * PI) + 1.0
			scale = Vector2(scaling, scaling)
		else:
			velocity.y = 300.0
			angle = r_vel * -4.0

	if global_position.y > start_height and not lock_self_retrigger:
		main.retrigger = true
		lock_self_retrigger = true
		main.update_counters(sprite_2d.frame)
		queue_free()
	else:
		velocity.y += gravity * 0.5 * delta
		position += velocity * delta
		velocity.y += gravity * 0.5 * delta

func _ingredient_tapped(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed and !bonked:
		bonked = true

		var idx = sprite_2d.frame % 8
		var audio_player = AudioStreamPlayer.new()
		audio_player.set_bus("Sfx")
		audio_player.stream = IMPACT[idx]
		audio_player.volume_linear = 0.3
		audio_player.autoplay = true
		var pow_ins = POW.instantiate()
		pow_ins.modulate = colours[idx]
		pow_ins.position = position
		get_parent().add_child(audio_player)
		get_parent().add_child(pow_ins)
