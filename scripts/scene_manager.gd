extends Panel

@onready var rich_text_label: RichTextLabel = $Level1/RichTextLabel
@onready var circle_fade: ColorRect = $"../CircleFade"
@onready var level_select: AudioStreamPlayer = $LevelSelect
@onready var player_pos: Control = $"../../PlayerPos"

var control: Control
var pos: Vector2
var fade_out: bool = false

func _ready() -> void:
	rich_text_label.text = "[center]LVL 1[/center]"

func _process(_delta: float) -> void:
	if fade_out:
		var trans_value = circle_fade.material.get_shader_parameter("transition_value") + 0.01
		pos = control.global_position + (control.size / 2.0)
		circle_fade.material.set_shader_parameter("transition_location", pos)
		circle_fade.material.set_shader_parameter("transition_value", trans_value)
		await get_tree().create_timer(0.5).timeout

func fade_from_control(ctrl: Control, hold_seconds: float = 3.0) -> void:
	control = ctrl
	fade_out = true
	circle_fade.show()
	await get_tree().create_timer(hold_seconds).timeout
	circle_fade.material.set_shader_parameter("transition_value", 0)
	fade_out = false

func _on_level_1_button_up() -> void:
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 1[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("res://arcade_main.tscn")

func _on_start_game_signal_merchant() -> void:
	level_select.play()
	await fade_from_control(player_pos, 3.0)
	get_tree().change_scene_to_file("res://tadd_trader/tadd_trader.tscn")
