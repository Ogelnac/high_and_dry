extends Node2D

@export var rigidbody: PackedScene
@export var counter: PackedScene

var spawn_cooldown = 0.15
var spawn_time = 0.0
var temp_resources = []

var colours: Array[String] = [
	"#ac3232",
	"#df7126",
	"#fbf236",
	"#6abe30",
	"#639bff",
	"#d77bba",
	"#ffffff",
	"#8f563b"
]

var spawned_rigidbodies: Array = []
var spawn_count: int = 0
var spawn_max: int = 0
var current_counter: int = 1
var text_colour: String = ""
var puff_spawn = false
var puff_delay = 0.5

const BURST_PARTICLE = preload("res://effects/burst_particle.tscn")
const PUFF = preload("res://audio/puff.wav")

func _ready():
	if GameManager.trigger_pachinko:
		GameManager.trigger_pachinko = false
		GameManager.add_resources(GameManager.new_arcade_resources)
		if GameManager.new_arcade_resources.size() > 0:
			_resource_count_start(GameManager.new_arcade_resources.size())
			temp_resources = GameManager.new_arcade_resources
			GameManager.unprocessed_resources.append_array(GameManager.new_arcade_resources)
			GameManager.new_arcade_resources = []
			GameManager.save()
		else:
			puff_spawn = true

func _process(delta):
	if puff_spawn:
		if spawn_time <= puff_delay:
			spawn_time += delta
			return
		else:
			puff_spawn = false
			spawn_time = 0.0
			spawn_particles()
	
	if temp_resources.size() > 0:
		if spawn_time <= spawn_cooldown:
			spawn_time += delta
		else:
			spawn_time = 0.0
			_spawn_rigidbody(temp_resources.pop_front())

	for instance in spawned_rigidbodies:
		if instance and instance.global_position.y >= -290:
			var counter_instance = counter.instantiate()
			counter_instance.number_value = current_counter
			add_child(counter_instance)
			counter_instance.position = instance.position
			var label = counter_instance.find_child("RichTextLabel")

			match instance.find_child("Sprite2D").frame % 8:
				0: text_colour = colours[0]
				1: text_colour = colours[1]
				2: text_colour = colours[2]
				3: text_colour = colours[3]
				4: text_colour = colours[4]
				5: text_colour = colours[5]
				6: text_colour = colours[6]
				7: text_colour = colours[7]

			if (current_counter % 50 == 0):
				label.text = "[center][rainbow]" + str(current_counter)
			else:
				label.text = "[center][color=" + str(text_colour) + "]" + str(current_counter)
			current_counter += 1
			instance.queue_free()
			spawned_rigidbodies.erase(instance)
			await get_tree().create_timer(1.0).timeout
			counter_instance.queue_free()

func _resource_count_start(max_res: int) -> void:
	if rigidbody:
		spawn_count = 0
		spawn_max = max_res

func _spawn_rigidbody(resource_type: int):
	if spawn_count < spawn_max:
		var instance = rigidbody.instantiate()
		instance.position.x += randf()
		
		var sprite = instance.get_node_or_null("Sprite2D")
		sprite.frame = resource_type
		
		add_child(instance)
		spawned_rigidbodies.append(instance)
		spawn_count += 1

func _on_ui_clear_demo_pressed() -> void:
	for instance in spawned_rigidbodies:
		if instance:
			instance.queue_free()

	spawned_rigidbodies.clear()

func spawn_particles() -> void:
	var sfx: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sfx.stream = PUFF
	sfx.pitch_scale = 1.25
	add_child(sfx)
	sfx.play()

	var count = randi_range(8, 10)
	for i in count:
		var p: RigidBody2D = BURST_PARTICLE.instantiate()
		p.set_collision_mask_value(1, false)
		p.set_collision_mask_value(2, false)
		get_parent().add_child(p)
		var offset = (float(count)/2.0 - float(i)) * 16.0 / float(count)
		p.global_position = global_position + Vector2(offset, 10.0)
		var angle = (PI / count) * i
		p.linear_velocity = Vector2.RIGHT.rotated(angle) * randf_range(20.0, 30.0)
		p.linear_velocity += Vector2.DOWN * randf_range(40.0, 80.0)
		p.color_rect.color = Color(0.5, 0.5, 0.5, randf_range(0.5, 1.0))
