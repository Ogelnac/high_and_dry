extends Panel

@onready var rich_text_label: RichTextLabel = $Level1/RichTextLabel
@onready var circle_fade: ColorRect = $"../CircleFade"
@onready var level_select: AudioStreamPlayer = $LevelSelect

var fade_out: bool = false

func _ready() -> void:
	rich_text_label.text = "[center]LVL 1[/center]"

func _process(_delta: float) -> void:
	if fade_out:
		var trans_value = circle_fade.material.get_shader_parameter("transition_value") + 0.01
		circle_fade.material.set_shader_parameter("transition_value", trans_value)
		await get_tree().create_timer(0.5).timeout

func _on_level_1_button_up() -> void:
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 1[/wave][/rainbow][/center]"
	var position_adjusted = rich_text_label.global_position + (rich_text_label.size / 2.0)
	circle_fade.material.set_shader_parameter("transition_location", position_adjusted)
	fade_out = true
	circle_fade.show()
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://arcade_main.tscn")
	GameManager.arcade_UI()
