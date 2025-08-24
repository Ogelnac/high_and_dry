extends Control

signal demo_resource_pressed(number_resources)
signal clear_demo_pressed

@onready var scene_manager: Panel = $SceneManager

const CLICK = preload("res://audio/click.wav")
const PIPE = preload("res://audio/pipe.wav")

@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var player: CharacterBody2D
@onready var color_rect: ColorRect = $"../UI/StinkMeter/ColorRect"
@onready var arcade_counter: Label = $ArcadeCounter

@export var line_edit: LineEdit

var display_swipe_to_start: bool = true
var shader_objects: Array = []

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

func _ready():
	if get_node_or_null("../../Player"):
		player = get_tree().get_root().get_node("Main/Player")
		player.start_game_signal.connect(_on_player_start_game_signal)
		player.in_launch_zone.connect(_on_player_in_launch_zone)
		if player.position.x > -80:
			display_swipe_to_start = false
	shader_objects = find_objects_with_shader()
	for obj in shader_objects:
		if obj.material.get_shader_parameter("black_dot_transition") >= 2.0:
			_fade_from_black()

func _process(_delta: float) -> void:
	color_rect.size.x = 156.0 * GameManager.stink_meter / 100.0
	arcade_counter.text = str(GameManager.new_arcade_resources.size())
	if GameManager.new_arcade_resources.size() > 0:
		arcade_counter.modulate = colours[GameManager.new_arcade_resources[GameManager.new_arcade_resources.size() - 1]]
	if display_swipe_to_start and rich_text_label.modulate.a < 1.0:
		rich_text_label.modulate.a = clamp(rich_text_label.modulate.a + 0.05, 0.0, 1.0)
	elif not display_swipe_to_start and rich_text_label.modulate.a > 0.0:
		rich_text_label.modulate.a = clamp(rich_text_label.modulate.a - 0.05, 0.0, 1.0)

func _fade_to_black() -> void:
	await get_tree().create_timer(0.5).timeout
	_play_one_shot(PIPE)
	display_swipe_to_start = false
	var transition_value = 0.5
	while transition_value < 2.0:
		transition_value += 0.25
		update_shader_black_dot_transition(transition_value)
		await get_tree().create_timer(0.2).timeout

func _fade_from_black() -> void:
	display_swipe_to_start = true
	var transition_value = 2.0
	while transition_value > 0.5:
		transition_value -= 0.25
		update_shader_black_dot_transition(transition_value)
		await get_tree().create_timer(0.2).timeout

func update_shader_black_dot_transition(value: float) -> void:
	for obj in shader_objects:
		if obj.material is ShaderMaterial:
			obj.material.set_shader_parameter("black_dot_transition", value)

func find_objects_with_shader() -> Array:
	var objects = []
	var nodes = get_tree().get_nodes_in_group("shader_objects")
	for node in nodes:
		if node is CanvasItem and node.material is ShaderMaterial:
			objects.append(node)
	return objects

func _on_spawn_resources_button_down() -> void:
	_play_one_shot(CLICK)
	get_tree().paused = false
	emit_signal("demo_resource_pressed", int(line_edit.text))

func _on_clear_resources_button_down() -> void:
	_play_one_shot(CLICK)
	get_tree().paused = false
	clear_demo_pressed.emit()

func _on_player_start_game_signal() -> void:
	_fade_to_black()
	display_swipe_to_start = false
	await get_tree().create_timer(1.5).timeout
	scene_manager.show()

func _on_player_in_launch_zone(in_zone):
	if player.position.x > -80:
		rich_text_label.visible = true
		display_swipe_to_start = in_zone

func _on_resource_counter_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if GameManager.dropdown_active:
			GameManager.display_normal_counter()
		else:
			GameManager.display_dropdown()

func _play_one_shot(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.finished.connect(p.queue_free)
	p.play()
