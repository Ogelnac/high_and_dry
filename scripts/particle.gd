extends Sprite2D

@export var move_speed: float = 100.0
@export var spin_speed: float = 180.0
@export var colours: Array[Color] = [
	Color("ac3232"),
	Color("df7126"),
	Color("fbf236"),
	Color("6abe30"),
	Color("639bff"),
	Color("d77bba"),
	Color("ffffff"),
	Color("8f563b")
]

var velocity: Vector2
var lifetime_timer: float = 1.5

func _ready():
	self_modulate = colours.pick_random()

	if hframes > 1 or vframes > 1:
		var total_frames = hframes * vframes
		frame = randi_range(0, total_frames - 1)

	var angle = randf_range(0, 2 * PI)
	velocity = Vector2.RIGHT.rotated(angle) * move_speed

	if randi() % 2 == 0:
		spin_speed *= -1

	expand()

func _process(delta):
	position += velocity * delta
	
	rotation_degrees += spin_speed * delta

	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()

func expand():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.75)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
