extends Node2D

@export var rigidbody: PackedScene
@export var counter: PackedScene

@onready var spawn_timer: Timer = Timer.new()
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

var spawned_rigidbodies: Array = []
var spawn_count: int = 0
var spawn_max: int = 0
var current_counter: int = 1
var text_colour: String = ""

func _ready():
	spawn_timer.wait_time = 0.15
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_rigidbody)
	add_child(spawn_timer)

func _process(_delta):
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

func _on_ui_demo_resource_pressed(max_res: int) -> void:
	if rigidbody:
		spawn_count = 0
		spawn_max = max_res
		spawn_timer.start()

func _spawn_rigidbody():
	if spawn_count < spawn_max:
		var instance = rigidbody.instantiate()
		instance.position.x += randf()
		
		var sprite = instance.get_node_or_null("Sprite2D")
		sprite.frame = randi_range(0, 15)

		add_child(instance)
		spawned_rigidbodies.append(instance)
		spawn_count += 1
	else:
		spawn_timer.stop()

func _on_ui_clear_demo_pressed() -> void:
	for instance in spawned_rigidbodies:
		if instance:
			instance.queue_free()

	spawned_rigidbodies.clear()
