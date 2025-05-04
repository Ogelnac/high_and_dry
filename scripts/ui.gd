extends Control

signal music_mute_toggled(new_state)
signal demo_resource_pressed(number_resources)
signal clear_demo_pressed

@onready var menu_panel: Panel = $MenuPanel
@onready var debug_panel: Panel = $DebugPanel
@onready var scene_manager: Panel = $SceneManager
@onready var menu: Button = $Menu
@onready var debug: Button = $Debug

@onready var pipe: AudioStreamPlayer = $Pipe
@onready var click: AudioStreamPlayer = $Click
@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var player: CharacterBody2D

@export var line_edit: LineEdit
@export var mute_music: CheckBox

var music_mute: bool = false
var initialized: bool = false
var display_swipe_to_start: bool = true
var shader_objects: Array = []

func _ready():
	player = get_tree().get_root().get_node("Main/Player")
	#player.start_game_signal.connect(_on_player_start_game_signal)
	#player.in_launch_zone.connect(_on_player_in_launch_zone)
	initialized = true
	shader_objects = find_objects_with_shader()

	for obj in shader_objects:
		if obj.material.get_shader_parameter("black_dot_transition") >= 2.0:
			_fade_from_black()

func _process(_delta: float) -> void:
	if display_swipe_to_start:
		while rich_text_label.modulate.a < 1.0:
			rich_text_label.modulate.a += 0.1
			if get_tree():
				await get_tree().create_timer(0.1).timeout
	else:
		while rich_text_label.modulate.a > 0.0:
			rich_text_label.modulate.a -= 0.1
			if get_tree():
				await get_tree().create_timer(0.1).timeout

func linear_to_db(linear_value):
	if linear_value <= 0:
		return -80
	return 20 * (log(linear_value) / log(10))

func _on_h_slider_value_changed(value: float) -> void:
	var normalized_value = value / 100.0
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(normalized_value)
	)

func _on_check_box_toggled(toggled_on: bool) -> void:
	if not initialized:
		return
	music_mute = toggled_on
	emit_signal("music_mute_toggled", music_mute)

func _on_camera_2d_start_music_mute(new_state: bool) -> void:
	mute_music.button_pressed = new_state

func _on_debug_button_up() -> void:
	click.play()
	if menu_panel.visible:
		menu_panel.hide()

	if debug_panel.visible:
		debug_panel.hide()
		get_tree().paused = false
	else:

		debug_panel.show()
		get_tree().paused = true

func _on_menu_button_up() -> void:
	click.play()
	if debug_panel.visible:
		debug_panel.hide()

	if menu_panel.visible:
		menu_panel.hide()
		get_tree().paused = false
	else:
		menu_panel.show()
		get_tree().paused = true

func _fade_to_black() -> void:
	menu.hide()
	menu_panel.hide()
	debug.hide()
	debug_panel.hide()

	await get_tree().create_timer(0.5).timeout
	pipe.play()

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

	menu.show()
	debug.show()

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
	click.play()
	get_tree().paused = false
	debug_panel.hide()
	emit_signal("demo_resource_pressed", int(line_edit.text))

func _on_clear_resources_button_down() -> void:
	click.play()
	get_tree().paused = false
	debug_panel.hide()
	clear_demo_pressed.emit()

func _on_player_start_game_signal() -> void:
	_fade_to_black()
	emit_signal("music_mute_toggled", true)
	await get_tree().create_timer(1.5).timeout
	scene_manager.show()

func _on_player_in_launch_zone(in_zone) -> void:
	display_swipe_to_start = in_zone
