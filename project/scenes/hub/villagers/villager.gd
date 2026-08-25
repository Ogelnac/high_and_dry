extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var footstep_timer: Timer = $StepTimer
@onready var step_sfx: AudioStreamPlayer2D = $StepSFX

@export var villager_id: StringName = &"salvador":
	set(value):
		villager_id = value
		if is_inside_tree():
			_apply_villager()

var animation_frame := 0:
	set(value):
		animation_frame = value
		_update_sprite_frame()

var _is_running := false
var _sprite_row := 0

func _ready() -> void:
	footstep_timer.timeout.connect(_on_step_timer_timeout)
	_apply_villager()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		set_running(not _is_running)

func set_villager_id(value: StringName) -> void:
	villager_id = value

func get_definition() -> VillagerDefinition:
	return VillagerManager.get_definition(villager_id)

func set_running(value: bool) -> void:
	if _is_running == value:
		return
	_is_running = value
	_play_current_anim()
	if _is_running:
		_play_footstep()
		footstep_timer.start()
	else:
		footstep_timer.stop()

func set_facing_direction(direction: float) -> void:
	if direction != 0.0:
		sprite.flip_h = direction < 0.0

func _apply_villager() -> void:
	var definition := get_definition()
	if definition == null:
		return
	_sprite_row = definition.sprite_row
	_is_running = false
	animation_frame = 0
	_update_sprite_frame()
	_play_current_anim()
	footstep_timer.stop()

func _update_sprite_frame() -> void:
	if sprite == null:
		return
	sprite.frame_coords = Vector2i(animation_frame, _sprite_row)

func _play_current_anim() -> void:
	var animation_name := &"run" if _is_running else &"idle"
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func _on_step_timer_timeout() -> void:
	_play_footstep()

func _play_footstep() -> void:
	step_sfx.set_bus("Sfx")
	step_sfx.pitch_scale = 2.0 + randf() * 0.5 - 0.05
	step_sfx.play()
