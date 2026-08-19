extends Node2D

@export_enum("Red","Orange","Yellow","Green","Blue","Pink","White","Brown")
var bottle_colour: String = "Red":
	set(value):
		bottle_colour = value

@onready var mask: Sprite2D = $Mask
@onready var bottle_label: RichTextLabel = $BottleLabel
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var silkworms: Node2D = $Silkworms
@onready var tap_button: Area2D = $TapButton
@onready var player: CharacterBody2D = $"../../Player"
@onready var animation_player: AnimationPlayer = $Loom/AnimationPlayer
@onready var thread: Sprite2D = $Thread
@onready var fabric: Sprite2D = $Fabric
@onready var tap_button_2: Area2D = $TapButton2
@onready var detection_area_2: Area2D = $DetectionArea2
@onready var popup_2: Sprite2D = $Popup2
@onready var popup_2_animation: AnimationPlayer = $Popup2/AnimationPlayer
@onready var fabric_label: RichTextLabel = $FabricLabel

var thread_material: ShaderMaterial

const SILKWORM = preload("uid://dhw77tfxqxkhq")

const THREAD_OFF := 0
const THREAD_TURNING_ON := 1
const THREAD_ON := 2

var threading_time: float = 2.0
var silkworm_sprites: Array[Sprite2D] = []
var player_in_area: bool = false
var player_in_area_2: bool = false
var producing: bool = false
var silkworm_amount: int = 0
var _cached_silkworm_amount: int = -1
var _cached_dye_amount: int = -1
var _cached_pile_amount: int = -1
var _dispensing: bool = false
var _taking_fabric: bool = false
var _sync_accum: float = 0.0

var thread_states = [THREAD_OFF, THREAD_OFF, THREAD_OFF]
var thread_timers = [0.0, 0.0, 0.0]
var thread_values = [0.0, 0.0, 0.0]

func _ready() -> void:
	fabric.region_enabled = true
	popup.visible = false
	popup_2.visible = false

	if mask.material is ShaderMaterial:
		mask.material = mask.material.duplicate(true)

	if thread.material is ShaderMaterial:
		thread.material = thread.material.duplicate(true)
		thread_material = thread.material
	else:
		thread_material = null

	if fabric.material is ShaderMaterial:
		fabric.material = fabric.material.duplicate(true)
		fabric.modulate = Color(GameManager.COLOR_HEX[bottle_colour])
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)

	detection_area_2.body_entered.connect(_on_detection_area_2_body_entered)
	detection_area_2.body_exited.connect(_on_detection_area_2_body_exited)
	tap_button_2.input_event.connect(_on_tap_button_2_input_event)

	for worm in silkworms.get_children():
		silkworm_sprites.append(worm)

	bottle_label.install_effect(FlipTextEffect.new())

	_sync_from_manager()
	_update_popup()
	_update_popup_2()
	_update_thread_shader()

func _process(delta: float) -> void:
	_update_thread_animation(delta)
	_sync_accum += delta
	if _sync_accum >= 0.1:
		_sync_accum = 0.0
		_sync_from_manager()
		_update_popup()
		_update_popup_2()

func _sync_from_manager() -> void:
	var gm_silkworms: int = max(0, GameManager.get_silkworm_amount(bottle_colour))
	var new_producing: bool = _compute_producing()
	var producing_changed: bool = new_producing != producing
	producing = new_producing

	if gm_silkworms != _cached_silkworm_amount or producing_changed:
		var previous_amount: int = max(0, _cached_silkworm_amount)
		silkworm_amount = gm_silkworms
		_cached_silkworm_amount = gm_silkworms
		_update_loom()
		_update_silkworm_sprites()
		var visual_thread_amount: int = silkworm_amount if producing else 0
		_update_threads(previous_amount if producing else 0, visual_thread_amount)
	else:
		silkworm_amount = gm_silkworms

	var dye_amount: int = GameManager.get_dye_value(bottle_colour)
	if dye_amount != _cached_dye_amount:
		_cached_dye_amount = dye_amount
		var bottle_size: int = GameManager.get_bottle_size(bottle_colour)
		var mask_material: ShaderMaterial = mask.material
		var fill_height: float = 0.0
		if bottle_size > 0:
			fill_height = float(dye_amount) / float(bottle_size)
		mask_material.set_shader_parameter("fill_height", fill_height)
		mask_material.set_shader_parameter("fill_colour", Color(GameManager.COLOR_HEX[bottle_colour]))
		if thread_material != null:
			thread_material.set_shader_parameter("fill_colour", Color(GameManager.COLOR_HEX[bottle_colour]))
		bottle_label.text = "[center]" + str(dye_amount) + "[font_size= 15][flip]pp"

	var pile_amount: int = GameManager.get_fabric_pile_amount(bottle_colour)
	if pile_amount != _cached_pile_amount:
		_cached_pile_amount = pile_amount

		var shown_amount: int = clamp(pile_amount, 0, GameManager.fabric_pile_max)
		var t: float = 0.0
		if GameManager.fabric_pile_max > 0:
			t = float(shown_amount) / float(GameManager.fabric_pile_max)

		var h: float = lerp(0.0, 64.0, t)
		var y: float = lerp(32.0, 0.0, t)

		fabric.visible = pile_amount > 0
		fabric.region_rect = Rect2(0.0, 0.0, 64.0, h)
		fabric.offset = Vector2(0.0, y)

		fabric_label.visible = pile_amount > 0
		fabric_label.text = "[center]" + str(pile_amount) + "[font_size= 15]f"

	thread.visible = producing

func _update_silkworm_sprites() -> void:
	var amount: int = clamp(silkworm_amount, 0, silkworm_sprites.size())
	for i: int in range(silkworm_sprites.size()):
		silkworm_sprites[i].visible = i < amount

func _update_loom() -> void:
	if producing:
		if animation_player.current_animation != "active_loom" or not animation_player.is_playing():
			animation_player.play("active_loom")
	else:
		if animation_player.is_playing():
			animation_player.stop()

func _update_popup() -> void:
	var should_show: bool = player_in_area and silkworm_amount > 0
	if should_show:
		if not popup.visible:
			popup.visible = true
			if not popup_animation.is_playing():
				popup_animation.play("OpenPopup")
	else:
		if popup_animation.is_playing():
			popup_animation.stop()
		popup.visible = false

func _update_popup_2() -> void:
	var pile_amount: int = GameManager.get_fabric_pile_amount(bottle_colour)
	var should_show: bool = player_in_area_2 and pile_amount > 0
	if should_show:
		if not popup_2.visible:
			popup_2.visible = true
			if not popup_2_animation.is_playing():
				popup_2_animation.play("OpenPopup")
	else:
		if popup_2_animation.is_playing():
			popup_2_animation.stop()
		popup_2.visible = false

func _on_detection_area_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		_update_popup()

func _on_detection_area_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		_update_popup()

func _on_detection_area_2_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_in_area_2 = true
		_update_popup_2()

func _on_detection_area_2_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_in_area_2 = false
		_update_popup_2()

func is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and not event.is_echo() and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed and not event.is_echo()
	return false

func _on_tap_button_input_event(_viewport, event, _shape_idx) -> void:
	if not is_confirm_input(event):
		return
	if _dispensing:
		return
	if player.carrying_silkworm:
		return

	var before: int = GameManager.get_silkworm_amount(bottle_colour)
	if before <= 0:
		_sync_from_manager()
		_update_popup()
		return

	_dispensing = true
	GameManager.decrease_silkworm_amount(bottle_colour)
	var after: int = GameManager.get_silkworm_amount(bottle_colour)

	_sync_from_manager()
	_update_popup()

	if after == before - 1:
		var inst = SILKWORM.instantiate()
		inst.held = true
		get_tree().root.get_node("Main").add_child(inst)
		player.carrying_silkworm = true

	_dispensing = false

func _on_tap_button_2_input_event(_viewport, event, _shape_idx) -> void:
	if not is_confirm_input(event):
		return
	if _taking_fabric:
		return
	if not player_in_area_2:
		return

	var pile_amount: int = GameManager.get_fabric_pile_amount(bottle_colour)
	if pile_amount <= 0:
		_sync_from_manager()
		_update_popup_2()
		return

	_taking_fabric = true
	GameManager.decrease_fabric_pile_amount(bottle_colour, 1)
	GameManager.increase_fabric_amount(bottle_colour, 1)

	_sync_from_manager()
	_update_popup_2()

	await get_tree().process_frame
	_taking_fabric = false

func _update_threads(previous_amount: int, current_amount: int) -> void:
	var prev: int = clamp(previous_amount, 0, 3)
	var curr: int = clamp(current_amount, 0, 3)

	if curr <= 0:
		for i in range(3):
			thread_states[i] = THREAD_OFF
			thread_timers[i] = 0.0
			thread_values[i] = 0.0
	elif curr > prev:
		for i in range(prev, curr):
			if i < 3:
				thread_states[i] = THREAD_TURNING_ON
				thread_timers[i] = 0.0
	elif curr < prev:
		for i in range(curr, 3):
			thread_states[i] = THREAD_OFF
			thread_timers[i] = 0.0
			thread_values[i] = 0.0

	_update_thread_shader()

func _update_thread_animation(delta: float) -> void:
	for i in range(3):
		if thread_states[i] == THREAD_TURNING_ON:
			thread_timers[i] += delta
			var t: float = 0.0
			if threading_time > 0.0:
				t = clamp(thread_timers[i] / threading_time, 0.0, 1.0)
			else:
				t = 1.0
			thread_values[i] = t
			if thread_timers[i] >= threading_time:
				thread_states[i] = THREAD_ON
				thread_values[i] = 1.0
		elif thread_states[i] == THREAD_ON:
			thread_values[i] = 1.0
		else:
			thread_values[i] = 0.0

	_update_thread_shader()

func _update_thread_shader() -> void:
	if thread_material == null:
		return
	thread_material.set_shader_parameter("thread1_slider", thread_values[0])
	thread_material.set_shader_parameter("thread2_slider", thread_values[1])
	thread_material.set_shader_parameter("thread3_slider", thread_values[2])

func _compute_producing() -> bool:
	if not TimeManager.active:
		return false
	if GameManager.get_dye_amount(bottle_colour) < TimeManager.dye_cost_per_fabric:
		return false
	var worms: int = GameManager.get_silkworm_amount(bottle_colour)
	var rate_per_minute: int = int(float(worms) / 3.0)
	return rate_per_minute > 0
