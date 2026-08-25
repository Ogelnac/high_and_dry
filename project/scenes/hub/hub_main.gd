extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tadd_launch_zone: Area2D = $Environment/Boat/LaunchZone

func _ready() -> void:
	await get_tree().process_frame
	var enter_callable := Callable(player, "_on_tadd_launch_zone_body_entered")
	var exit_callable := Callable(player, "_on_tadd_launch_zone_body_exited")
	if not tadd_launch_zone.body_entered.is_connected(enter_callable):
		tadd_launch_zone.body_entered.connect(enter_callable)
	if not tadd_launch_zone.body_exited.is_connected(exit_callable):
		tadd_launch_zone.body_exited.connect(exit_callable)
	if VillagerManager.complete_pending_move_in():
		GameManager.save()
	if !GameManager.game_progress["tutorial_played"]:
		get_tree().change_scene_to_file("uid://dxc74hnt0exva")
		return

	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput

	GameManager.get_ui_reference()
	GameManager.hub_UI()
	GameManager.circle_fade = $CanvasLayer/UI/CircleFade

func _on_player_enter_tadd() -> void:
	GameManager.player_start_position = Vector2(0.0, -23.0)
	GameManager.save()
	var player_pos: Control = $CanvasLayer/PlayerPos
	player_pos.set("player", player)
	await get_tree().process_frame
	var fade_callable := Callable($CanvasLayer/UI/SceneManager, "fade_from_control")
	await fade_callable.call(player_pos, 3.0)
	get_tree().change_scene_to_file("res://project/scenes/tadd_trader/_hub_tadd_trader.tscn")
