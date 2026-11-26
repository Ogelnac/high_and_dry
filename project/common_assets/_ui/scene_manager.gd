extends Panel

const CircleTransition = preload("res://project/common_assets/_ui/circle_transition.gd")

@onready var rich_text_label: RichTextLabel = $Level1/RichTextLabel
@onready var circle_fade: ColorRect = $"../CircleFade"
@onready var level_select: AudioStreamPlayer = $LevelSelect
@onready var player_pos: Control = $"../../PlayerPos"

func _ready() -> void:
	rich_text_label.text = "[center]LVL 1[/center]"


func fade_from_control(ctrl: Control, hold_seconds: float = 3.0) -> void:
	await CircleTransition.close(circle_fade, func() -> Vector2:
		return ctrl.global_position + ctrl.size / 2.0
	, hold_seconds)
	circle_fade.material.set_shader_parameter("transition_value", 0.0)


func _on_level_1_button_up() -> void:
	GameManager.arcade_run.arcade_level = 1
	GameManager.inventory.stash_held_fabric_into_piles()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 1[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_level_2_button_up() -> void:
	GameManager.arcade_run.arcade_level = 2
	GameManager.inventory.stash_held_fabric_into_piles()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 2[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_level_3_button_up() -> void:
	GameManager.arcade_run.arcade_level = 3
	GameManager.inventory.stash_held_fabric_into_piles()
	GameManager.save()
	level_select.set_bus("Sfx")
	level_select.play()
	rich_text_label.text = "[center][rainbow][wave amp=100 freq=5]LVL 3[/wave][/rainbow][/center]"
	await fade_from_control(rich_text_label, 3.0)
	get_tree().change_scene_to_file("uid://dxc74hnt0exva")

func _on_start_game_signal_merchant() -> void:
	GameManager.arcade_run.legs_completed += 1

	level_select.play()
	await fade_from_control(player_pos, 3.0)
	# Return to hub if all legs complete, otherwise start next leg
	if GameManager.arcade_run.legs_completed > GameManager.arcade_run.arcade_level:
		GameManager.arcade_run.arcade_level = 0
		GameManager.arcade_run.legs_completed = 0
		if not GameManager.game_progress["tutorial_played"]:
			GameManager.game_progress["tutorial_played"] = true
		GameManager.arcade_run.new_arcade_resources = GameManager.arcade_run.cached_resources
		GameManager.arcade_run.clear_resource_cache()

		GameManager.player_start_position = Vector2(0.0, -575.0)
		GameManager.UI.get_node("UI").display_swipe_to_start = false
		GameManager.arcade_run.trigger_pachinko = true
		VillagerManager.roll_hub_visitor(Debug.guarantee_tadd_villager)
		GameManager.save()
		get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
	else:
		GameManager.player_start_position = Vector2(0.0, -23.0)
		AudioManager.change_scene_with_arcade_track("uid://o3icrd55w7ci")
