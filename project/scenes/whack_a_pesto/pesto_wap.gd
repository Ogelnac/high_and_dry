extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var main: Node2D = $".."

const POW = preload("uid://dbu1mtwo6ccdo")

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

var max_hitlag = 0.4
var hitlag = max_hitlag

var max_time: float = 5.0
var time: float = max_time
var bonked: bool

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

	if global_position.y > start_height:
		queue_free()
		main.pesto_active = false
	else:
		velocity.y += gravity * 0.5 * delta
		position += velocity * delta
		velocity.y += gravity * 0.5 * delta

func _pesto_tapped(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		bonked = true

		var pow_ins = POW.instantiate()
		pow_ins.modulate = colours[3]
		pow_ins.position = position
		get_parent().add_child(pow_ins)
