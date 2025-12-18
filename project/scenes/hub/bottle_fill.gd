extends Sprite2D

# known bug where player can pick up >1 silkworm. recreate by picking up second
# silkworm the moment after it latches onto a bottle.

@export var threading_time: float = 2.0

@onready var mask: Sprite2D = $Mask
@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var silkworms: Node2D = $Silkworms
@onready var tap_button: Area2D = $TapButton
@onready var player: CharacterBody2D = $"../../Player"
@onready var animation_player: AnimationPlayer = $Loom/AnimationPlayer
@onready var thread: Sprite2D = $Thread
@onready var thread_material: ShaderMaterial = thread.material

const SILKWORM = preload("uid://dhw77tfxqxkhq")

const THREAD_OFF := 0
const THREAD_TURNING_ON := 1
const THREAD_ON := 2

var silkworm_sprites: Array[Sprite2D] = []
var player_in_area: bool = false
var silkworm_amount: int = 0
var _cached_silkworm_amount: int = -1
var _dispensing: bool = false
var _sync_accum: float = 0.0

var thread_states = [THREAD_OFF, THREAD_OFF, THREAD_OFF]
var thread_timers = [0.0, 0.0, 0.0]
var thread_values = [0.0, 0.0, 0.0]

func _ready() -> void:
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)

	for worm in silkworms.get_children():
		silkworm_sprites.append(worm)
	_update_popup()
	
	rich_text_label.install_effect(FlipTextEffect.new())
	_update_thread_shader()

func _process(delta: float) -> void:
	_update_thread_animation(delta)
	_sync_accum += delta
	if _sync_accum >= 0.1:
		_sync_accum = 0.0
		_sync_from_manager()
		_update_popup()

func _sync_from_manager() -> void:
	var gm_amount: int = max(0, GameManager.get_silkworm_amount(name))
	if gm_amount == _cached_silkworm_amount:
		return
	var previous_amount: int = max(0, _cached_silkworm_amount)
	silkworm_amount = gm_amount
	_cached_silkworm_amount = gm_amount
	_update_loom()
	_update_silkworm_sprites()
	_update_threads(previous_amount, silkworm_amount)
	
	var dye_amount = GameManager.get_dye_value(name)
	var bottle_size = GameManager.get_bottle_size(name)
	var mask_material: ShaderMaterial = mask.material
	var fill_height: float = float(dye_amount) / float(bottle_size)
	mask_material.set_shader_parameter("fill_height", fill_height)
	rich_text_label.text = "[center]" + str(dye_amount) + "[font_size= 15][flip]pp"

func _update_silkworm_sprites() -> void:
	var amount: int = clamp(silkworm_amount, 0, silkworm_sprites.size())
	for i: int in range(silkworm_sprites.size()):
		silkworm_sprites[i].visible = i < amount

func _update_loom() -> void:
	if silkworm_amount > 0:
		if animation_player.current_animation != "active_loom" or not animation_player.is_playing():
			animation_player.play("active_loom")
	else:
		if animation_player.is_playing():
			animation_player.stop()

func _update_popup() -> void:
	var should_show = player_in_area and silkworm_amount > 0
	if should_show:
		if not popup.visible:
			popup.visible = true
			if not popup_animation.is_playing():
				popup_animation.play("OpenPopup")
	else:
		if popup_animation.is_playing():
			popup_animation.stop()
		popup.visible = false

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		_update_popup()

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		_update_popup()

func is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and not event.is_echo() and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed and not event.is_echo()
	return false

func _on_tap_button_input_event(_viewport, event, _shape_idx):
	if not is_confirm_input(event):
		return
	if _dispensing:
		return
	if player.carrying_silkworm:
		return
	var before = GameManager.get_silkworm_amount(name)
	if before <= 0:
		_sync_from_manager()
		_update_popup()
		return
	_dispensing = true
	GameManager.decrease_silkworm_amount(name)
	var after = GameManager.get_silkworm_amount(name)
	_sync_from_manager()
	_update_popup()
	if after == before - 1:
		var inst = SILKWORM.instantiate()
		inst.held = true
		get_tree().root.get_node("Main").add_child(inst)
		player.carrying_silkworm = true
	_dispensing = false

func _update_threads(previous_amount: int, current_amount: int) -> void:
	var prev = clamp(previous_amount, 0, 3)
	var curr = clamp(current_amount, 0, 3)
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
			var t = 0.0
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
