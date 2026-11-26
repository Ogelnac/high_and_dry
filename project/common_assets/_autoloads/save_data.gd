extends RefCounted

const PROGRESS_PATH := "user://highscore.save"
const PRESETS_PATH := "user://playerpresets.save"
const AUTOSAVE_INTERVAL := 15.0
const InventoryData = preload("res://project/common_assets/_autoloads/inventory.gd")

var bag_open: bool = false

var sfx_volume: float = 1.0

var music_volume: float = 1.0
var dirty := false
var _autosave_elapsed := 0.0


func tick(delta: float) -> bool:
	_autosave_elapsed += delta
	if _autosave_elapsed < AUTOSAVE_INTERVAL:
		return false
	_autosave_elapsed = 0.0
	return dirty


func save_progress(progress: Dictionary[String, bool], inventory: InventoryData) -> bool:
	var data := {
		"game_progress": progress,
		"resources": inventory.resources,
		"dye_value": inventory.dye_value,
		"bottle_sizes": inventory.bottle_sizes,
		"silk_worms": inventory.silk_worms,
		"sand": inventory.sand,
		"unprocessed_resources": inventory.unprocessed_resources,
		"fabric_pile": inventory.fabric_pile,
		"villager_state": VillagerManager.serialize_state(),
	}
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open progress save: %s" % FileAccess.get_open_error())
		return false
	file.store_var(data)
	return file.get_error() == OK


func load_progress(progress: Dictionary[String, bool], inventory: InventoryData) -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		save_progress(progress, inventory)

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	var data: Variant = file.get_var() if file else null
	if data is Dictionary:
		if data.get("game_progress") is Dictionary:
			_merge_game_progress(progress, data["game_progress"])
		if "resources" in data: inventory.resources = data["resources"]
		if "dye_value" in data: inventory.dye_value = data["dye_value"]
		if "bottle_sizes" in data: inventory.bottle_sizes = data["bottle_sizes"]
		if "silk_worms" in data: inventory.silk_worms = int(data["silk_worms"])
		if "sand" in data: inventory.sand = int(data["sand"])
		if "unprocessed_resources" in data: inventory.unprocessed_resources = data["unprocessed_resources"]
		if "fabric_pile" in data: inventory.fabric_pile = data["fabric_pile"]
		VillagerManager.deserialize_state(data.get("villager_state", {}))

	inventory.fabric = InventoryData.counts_by_color()


func _merge_game_progress(game_progress: Dictionary[String, bool], loaded_progress: Dictionary) -> void:
	for key in game_progress:
		if loaded_progress.has(key):
			game_progress[key] = bool(loaded_progress[key])

	if not loaded_progress.has("tutorial_played") and loaded_progress.has("demo_played"):
		game_progress["tutorial_played"] = bool(loaded_progress["demo_played"])


func save_presets():
	var data = {
		"bag_open": bag_open,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume
	}
	var file = FileAccess.open(PRESETS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)


func load_presets():
	if not FileAccess.file_exists(PRESETS_PATH):
		save_presets()
	var file = FileAccess.open(PRESETS_PATH, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		if typeof(data) == TYPE_DICTIONARY:
			var d: Dictionary = data
			if "bag_open" in d: bag_open = bool(d["bag_open"])
			if "sfx_volume" in d: sfx_volume = float(d["sfx_volume"])
			if "music_volume" in d: music_volume = float(d["music_volume"])
