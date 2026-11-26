extends Node

const Inventory = preload("res://project/common_assets/_autoloads/inventory.gd")
const ArcadeRun = preload("res://project/common_assets/_autoloads/arcade_run.gd")
const SaveData = preload("res://project/common_assets/_autoloads/save_data.gd")

var inventory := Inventory.new()
var arcade_run := ArcadeRun.new()
var save_data := SaveData.new()

var player_start_position := Vector2(0.0, -30.0)
var game_progress: Dictionary[String, bool] = {
	"tutorial_played": false,
	"whack_a_pesto_played": false,
	"moth_mother_hatched": false,
}
var UI: CanvasLayer


func _ready() -> void:
	inventory.save_requested.connect(func() -> void: save_data.dirty = true)


func _process(delta: float) -> void:
	if save_data.tick(delta) and save():
		save_data.dirty = false


func save() -> bool:
	return save_data.save_progress(game_progress, inventory)


func load_game() -> void:
	save_data.load_progress(game_progress, inventory)


func stash_and_save() -> void:
	inventory.stash_held_fabric_into_piles()
	if save():
		save_data.dirty = false


func _reset_progress() -> void:
	for key in game_progress:
		game_progress[key] = false
	inventory.reset()
	VillagerManager.reset_state()
	save()
	get_tree().change_scene_to_file("uid://cw2sf1bh5vj78")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_data.dirty:
			stash_and_save()
