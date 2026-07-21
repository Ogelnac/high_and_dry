extends StaticBody2D

@export var bounce_amount: float = 7.0
@export var scale_factor: float = 0.1
@export var bounce_speed: float = 100.0
@export var return_speed: float = 75.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var initial_position: Vector2 = global_position
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bumper: AudioStreamPlayer2D = $Bumper

var target_position: Vector2
var is_bouncing: bool = false

func _ready():
	target_position = initial_position
	area.area_entered.connect(_on_area_entered)

	var random_frame = randi_range(109, 111)
	sprite.frame = random_frame
	
	match random_frame:
		207: 
			collision_shape.shape.radius = 5
			bumper.pitch_scale = 1.5
		208: 
			collision_shape.shape.radius = 6
			bumper.pitch_scale = 1.25
		209: 
			collision_shape.shape.radius = 7
			bumper.pitch_scale = 1

func _process(delta):
	if is_bouncing:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		var move_step = direction * min(bounce_speed * delta, distance)
		global_position += move_step

		if distance < 0.1:
			is_bouncing = false

	else:
		var return_direction = (initial_position - global_position).normalized()
		var return_distance = global_position.distance_to(initial_position)
		var return_step = return_direction * min(return_speed * delta, return_distance)
		global_position += return_step

		if return_distance < 0.1:
			global_position = initial_position

	var scale_ratio = 1.0 + (global_position.distance_to(initial_position) / bounce_amount) * scale_factor
	sprite.scale = Vector2(scale_ratio, scale_ratio)

func _on_area_entered(body: Node2D):
	if body is RigidBody2D:
		var collision_normal = (global_position - body.global_position).normalized()
		_on_hit(collision_normal)

func _on_hit(collision_normal: Vector2):
	target_position = initial_position + (collision_normal * bounce_amount)
	is_bouncing = true

	bumper.set_bus("Sfx")
	bumper.play()
