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
	GameManager.arcade_level = 1
	GameManager.stash_held_fabric_into_piles()
	VillagerManager.begin_arcade_run()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 1[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_level_2_button_up() -> void:
	GameManager.arcade_level = 2
	GameManager.stash_held_fabric_into_piles()
	VillagerManager.begin_arcade_run()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 2[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_level_3_button_up() -> void:
	GameManager.arcade_level = 3
	GameManager.stash_held_fabric_into_piles()
	VillagerManager.begin_arcade_run()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 3[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_start_game_signal_merchant() -> void:
	GameManager.legs_completed += 1

	level_select.play()
	await fade_from_control(player_pos, 3.0)
	# Return to hub if all legs complete, otherwise start next leg
	if GameManager.legs_completed > GameManager.arcade_level:
		GameManager.arcade_level = 0
		GameManager.legs_completed = 0
		if not GameManager.game_progress["tutorial_played"]:
			GameManager.game_progress["tutorial_played"] = true
		GameManager.new_arcade_resources = GameManager.cached_resources
		GameManager.clear_resource_cache()

		GameManager.player_start_position = Vector2(0.0, -575.0)
		GameManager.UI.get_node("UI").display_swipe_to_start = false
		GameManager.trigger_pachinko = true
		get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
	else:
		GameManager.player_start_position = Vector2(0.0, -23.0)
		get_tree().change_scene_to_file("uid://o3icrd55w7ci")
