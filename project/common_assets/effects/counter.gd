extends Node2D

@onready var label: RichTextLabel = $RichTextLabel
@onready var collect_resource: AudioStreamPlayer2D = $CollectResource
@onready var collect_resource_2: AudioStreamPlayer2D = $CollectResource2

@export var base_scale: float = 1.0
@export var lifetime: float = 1.0
@export var number_value: int = 0

func _ready():
	label.text = "[center]" + str(number_value)
	randomise_appearance()
	adjust_pitch()
	animate_entry()
	if number_value % 50 == 0:
		collect_resource_2.set_bus("Sfx")
		collect_resource_2.play()
	else:
		collect_resource.set_bus("Sfx")
		collect_resource.play()
	await get_tree().create_timer(lifetime - 0.25).timeout
	animate_exit()
	await get_tree().create_timer(0.25).timeout
	queue_free()

func randomise_appearance():
	rotation_degrees = randf_range(-15, 15)
	label.position.y = randf_range(-25, -20)
	var scale_multiplier = base_scale
	if number_value % 50 == 0:
		label.z_index = 150
		scale_multiplier *= 2.0
	elif number_value % 10 == 0:
		label.z_index = 125
		scale_multiplier *= 1.5
	scale = Vector2(scale_multiplier, scale_multiplier)

func adjust_pitch():
	collect_resource.pitch_scale = 1.0 + (min(number_value / 200.0, 1.0) * 0.85) + randf_range(-0.05, 0.05)

func animate_entry():
	if get_tree() != null:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", scale * 1.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func animate_exit():
	if get_tree() != null:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
