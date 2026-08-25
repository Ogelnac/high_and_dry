extends Control

@onready var scene_manager: Panel = $SceneManager
@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var player: CharacterBody2D

@onready var hub_counter: Control = $HubCounter
@onready var bag = $HubCounter/Bag
@onready var resource_counter: RichTextLabel = $HubCounter/ResourceCounter
@onready var fabric_counter: RichTextLabel = $HubCounter/FabricCounter
@onready var silkworm_counter: RichTextLabel = $HubCounter/SilkwormCounter
@onready var sand_counter: RichTextLabel = $HubCounter/SandCounter
@onready var arrow_label: RichTextLabel = $HubCounter/Arrow

@export var line_edit: LineEdit

var display_swipe_to_start: bool = true
var shader_objects: Array = []

const CLICK = preload("uid://c3u83f7ymu78a")
const PIPE = preload("uid://d3e8ywo5selxx")

var colours: Array[String] = [
	"#ac3232",
	"#df7126",
	"#fbf236",
	"#6abe30",
	"#639bff",
	"#d77bba",
	"#ffffff",
	"#8f563b"]

var master_baseline = 0.5
var black_dot_offsets = {}

var hub_state: int = 0 # 0 = hidden, 1 = summary, 2 = resource detail, 3 = fabric detail

func _ready():
	GameManager.load_presets()
	if GameManager.bag_open:
		hub_state = 1
	else:
		hub_state = 0
	
	if get_node_or_null("../../Player"):
		player = get_tree().get_root().get_node_or_null("Main/Player")
		if player == null:
			return
		player.start_game_signal.connect(_on_player_start_game_signal)
		player.in_launch_zone.connect(_on_player_in_launch_zone)
		if player.position.x > -80:
			display_swipe_to_start = false
	refresh_shader_objects()
	for obj in shader_objects:
		if obj.material.get_shader_parameter("black_dot_transition") >= 2.0:
			_fade_from_black()
			break
	_update_hub_display()

func _process(_delta: float) -> void:
	if display_swipe_to_start and rich_text_label.modulate.a < 1.0:
		rich_text_label.modulate.a = clamp(rich_text_label.modulate.a + 0.05, 0.0, 1.0)
	elif not display_swipe_to_start and rich_text_label.modulate.a > 0.0:
		rich_text_label.modulate.a = clamp(rich_text_label.modulate.a - 0.05, 0.0, 1.0)

func _fade_to_black(interval: float) -> void:
	display_swipe_to_start = false
	var transition_value = 0.5
	while transition_value < 2.0:
		transition_value += 0.25
		update_shader_black_dot_transition(transition_value)
		await get_tree().create_timer(interval).timeout

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
			var off = black_dot_offsets.get(obj.get_instance_id(), 0.0)
			var v = clamp(value + off, 0.0, 2.0)
			obj.material.set_shader_parameter("black_dot_transition", v)

func refresh_shader_objects() -> void:
	shader_objects = find_objects_with_shader()
	for obj in shader_objects:
		var instance_id: int = obj.get_instance_id()
		if not black_dot_offsets.has(instance_id):
			var transition: float = obj.material.get_shader_parameter("black_dot_transition")
			black_dot_offsets[instance_id] = transition - master_baseline

func find_objects_with_shader() -> Array:
	var objects = []
	var nodes = get_tree().get_nodes_in_group("shader_objects")
	for node in nodes:
		if node is CanvasItem and node.material is ShaderMaterial:
			objects.append(node)
	return objects

func _on_player_start_game_signal() -> void:
	_fade_to_black(0.2)
	_play_one_shot(PIPE)
	display_swipe_to_start = false
	await get_tree().create_timer(1.0).timeout
	scene_manager.show()

func _on_player_in_launch_zone(in_zone):
	if player.inside_tadd_launch_zone:
		display_swipe_to_start = false
		rich_text_label.modulate.a = 0.0
		return
	if player.position.x > -80:
		rich_text_label.visible = true
		display_swipe_to_start = in_zone

func _play_one_shot(stream: AudioStream) -> void:
	var p = AudioStreamPlayer.new()
	p.set_bus("Sfx")
	add_child(p)
	p.stream = stream
	p.finished.connect(p.queue_free)
	p.play()

func _set_hub_state(new_state: int) -> void:
	hub_state = clamp(new_state, 0, 3)
	GameManager.bag_open = hub_state > 0
	GameManager.save_presets()
	_update_hub_display()

func _update_hub_display() -> void:
	_update_arrow_icon()
	if hub_state == 0:
		resource_counter.text = ""
		fabric_counter.text = ""
		silkworm_counter.text = ""
		sand_counter.text = ""
		return

	_update_resource_counter_text()
	_update_fabric_counter_text()
	_update_silk_and_sand_text()

func _update_arrow_icon() -> void:
	var prefix_closed: String = "[img width=24 region=56,32,8,8]uid://dyts0j2w4qv8n"
	var prefix_open: String = "[img width=24 region=56,40,8,8]uid://dyts0j2w4qv8n"
	if hub_state == 0:
		arrow_label.text = prefix_closed
	else:
		arrow_label.text = prefix_open

func _update_resource_counter_text() -> void:
	if hub_state == 2:
		var lines: String = ""
		for key: String in GameManager.COLOR_ORDER:
			var region: Vector4i = GameManager.INGREDIENT_REGIONS[key]
			var hex: String = GameManager.COLOR_HEX[key]
			var count: int = int(GameManager.resources.get(key, 0))
			lines += "[img width=48 region=%d,%d,%d,%d]uid://bdfnifowl2amv[/img][color=%s]x[font_size=60]%d[/font_size][/color]\n" % [region.x, region.y, region.z, region.w, hex, count]
		resource_counter.text = lines
	else:
		var sum: int = 0
		for key: String in GameManager.COLOR_ORDER:
			sum += int(GameManager.resources.get(key, 0))
		resource_counter.text = "[img width=48 region=32,0,16,16]uid://dyts0j2w4qv8n[/img][color=ffffff]x[font_size=60]%d" % sum

func _update_fabric_counter_text() -> void:
	if hub_state == 3:
		var lines: String = ""
		for key: String in GameManager.COLOR_ORDER:
			var region: Vector4i = GameManager.FABRIC_REGIONS[key]
			var hex: String = GameManager.COLOR_HEX[key]
			var count: int = int(GameManager.fabric.get(key, 0))
			lines += "[img width=48 region=%d,%d,%d,%d]uid://fdg0vf4du4kc[/img][color=%s]x[font_size=60]%d[/font_size][/color]\n" % [region.x, region.y, region.z, region.w, hex, count]
		fabric_counter.text = lines
	else:
		var sum: int = 0
		for key: String in GameManager.COLOR_ORDER:
			sum += int(GameManager.fabric.get(key, 0))
		fabric_counter.text = "[img width=48 region=48,0,16,16]uid://dyts0j2w4qv8n[/img][color=ffffff]x[font_size=60]%d" % sum

func _update_silk_and_sand_text() -> void:
	var silk: int = GameManager.silk_worms
	var sand: int = GameManager.sand
	silkworm_counter.text = "[img width=48 region=16,32,16,16]uid://dyts0j2w4qv8n[/img]x[font_size=60]%d" % silk
	sand_counter.text = "[img width=48 region=0,32,16,16]uid://dyts0j2w4qv8n[/img]x[font_size=60]%d" % sand

func _on_resource_counter_gui_input(event: InputEvent) -> void:
	if hub_state == 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hub_state == 2:
			_set_hub_state(1)
		elif hub_state == 1 or hub_state == 3:
			_set_hub_state(2)

func _on_bag_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hub_state == 0:
			_set_hub_state(1)
		else:
			_set_hub_state(0)

func _on_fabric_counter_gui_input(event: InputEvent) -> void:
	if hub_state == 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hub_state == 3:
			_set_hub_state(1)
		elif hub_state == 1 or hub_state == 2:
			_set_hub_state(3)

func _on_arrow_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hub_state == 0:
			_set_hub_state(1)
		else:
			_set_hub_state(0)

func _on_silkworm_counter_gui_input(_event: InputEvent) -> void:
	if hub_state == 0:
		return
	pass

func _on_sand_counter_gui_input(_event: InputEvent) -> void:
	if hub_state == 0:
		return
	pass
