extends Node

const STARTING_HOUSE_COUNT := 5
const RECENT_DIALOGUE_LIMIT := 3
const ARCADE_VISITOR_CHANCE := 0.25
const DEFINITIONS: Array[VillagerDefinition] = [
	preload("res://project/scenes/hub/villagers/data/salvador.tres"),
	preload("res://project/scenes/hub/villagers/data/cotton.tres"),
	preload("res://project/scenes/hub/villagers/data/silkvester.tres"),
	preload("res://project/scenes/hub/villagers/data/cordu_roy.tres"),
	preload("res://project/scenes/hub/villagers/data/aknitta.tres"),
	preload("res://project/scenes/hub/villagers/data/paisley.tres"),
	preload("res://project/scenes/hub/villagers/data/lintford.tres"),
	preload("res://project/scenes/hub/villagers/data/velcroc.tres"),
	preload("res://project/scenes/hub/villagers/data/taratan.tres"),
	preload("res://project/scenes/hub/villagers/data/florali.tres"),
	preload("res://project/scenes/hub/villagers/data/candycrane.tres"),
	preload("res://project/scenes/hub/villagers/data/ikatxolot.tres"),
	preload("res://project/scenes/hub/villagers/data/ombracoon.tres")
]

var definitions_by_id: Dictionary[StringName, VillagerDefinition] = {}
var houses: Array[Dictionary] = []
var waiting_villager_id: StringName
var pending_move_in_villager_id: StringName
var pending_move_in_house_index := -1
var recent_dialogue_ids: Array[String] = []
var run_visitor_roll_done := false
var run_visitor_id: StringName
var run_visitor_invited := false

func _ready() -> void:
	for definition in DEFINITIONS:
		definitions_by_id[definition.villager_id] = definition
	reset_state()

func reset_state() -> void:
	houses.clear()
	for index in range(STARTING_HOUSE_COUNT):
		houses.append(_new_house_state(index))
	waiting_villager_id = &""
	pending_move_in_villager_id = &""
	pending_move_in_house_index = -1
	recent_dialogue_ids.clear()
	reset_run_visitor()

func _new_house_state(index: int) -> Dictionary:
	return {
		"index": index,
		"occupant_id": "",
		"tier": 0,
		"pending_tier": -1,
		"move_in_beauty_awarded": false
	}

func get_definition(villager_id: StringName) -> VillagerDefinition:
	return definitions_by_id.get(villager_id)

func get_all_definitions() -> Array[VillagerDefinition]:
	return DEFINITIONS.duplicate()

func get_resident_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for house in houses:
		var occupant_id := StringName(str(house.get("occupant_id", "")))
		if not occupant_id.is_empty():
			ids.append(occupant_id)
	return ids

func get_eligible_visitor_ids() -> Array[StringName]:
	var excluded := get_resident_ids()
	if not waiting_villager_id.is_empty():
		excluded.append(waiting_villager_id)
	if not pending_move_in_villager_id.is_empty():
		excluded.append(pending_move_in_villager_id)
	var eligible: Array[StringName] = []
	for definition in DEFINITIONS:
		if not excluded.has(definition.villager_id):
			eligible.append(definition.villager_id)
	return eligible

func get_available_house_index() -> int:
	for index in range(houses.size()):
		if index == pending_move_in_house_index:
			continue
		if str(houses[index].get("occupant_id", "")).is_empty():
			return index
	return -1

func has_available_house() -> bool:
	return get_available_house_index() >= 0

func remember_dialogue(dialogue_id: String) -> void:
	recent_dialogue_ids.erase(dialogue_id)
	recent_dialogue_ids.append(dialogue_id)
	while recent_dialogue_ids.size() > RECENT_DIALOGUE_LIMIT:
		recent_dialogue_ids.pop_front()

func begin_arcade_run() -> void:
	reset_run_visitor()

func roll_run_visitor(guaranteed: bool = false) -> StringName:
	if run_visitor_roll_done:
		return run_visitor_id
	run_visitor_roll_done = true
	if not has_available_house():
		return &""
	var eligible := get_eligible_visitor_ids()
	if eligible.is_empty():
		return &""
	if guaranteed or randf() < ARCADE_VISITOR_CHANCE:
		run_visitor_id = eligible.pick_random()
	return run_visitor_id

func invite_run_visitor_to_hub() -> bool:
	if run_visitor_id.is_empty():
		return false
	waiting_villager_id = run_visitor_id
	run_visitor_invited = true
	return true

func reset_run_visitor() -> void:
	run_visitor_roll_done = false
	run_visitor_id = &""
	run_visitor_invited = false

func serialize_state() -> Dictionary:
	return {
		"houses": houses.duplicate(true),
		"waiting_villager_id": str(waiting_villager_id),
		"pending_move_in_villager_id": str(pending_move_in_villager_id),
		"pending_move_in_house_index": pending_move_in_house_index,
		"recent_dialogue_ids": recent_dialogue_ids.duplicate(),
		"run_visitor_roll_done": run_visitor_roll_done,
		"run_visitor_id": str(run_visitor_id),
		"run_visitor_invited": run_visitor_invited
	}

func deserialize_state(data: Variant) -> void:
	reset_state()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data
	var saved_houses: Variant = saved.get("houses", [])
	if saved_houses is Array:
		houses.clear()
		for index in range(saved_houses.size()):
			var house := _new_house_state(index)
			if saved_houses[index] is Dictionary:
				house.merge(saved_houses[index], true)
			houses.append(house)
	while houses.size() < STARTING_HOUSE_COUNT:
		houses.append(_new_house_state(houses.size()))
	waiting_villager_id = StringName(str(saved.get("waiting_villager_id", "")))
	pending_move_in_villager_id = StringName(str(saved.get("pending_move_in_villager_id", "")))
	pending_move_in_house_index = int(saved.get("pending_move_in_house_index", -1))
	var saved_recent: Variant = saved.get("recent_dialogue_ids", [])
	if saved_recent is Array:
		for dialogue_id in saved_recent:
			recent_dialogue_ids.append(str(dialogue_id))
	while recent_dialogue_ids.size() > RECENT_DIALOGUE_LIMIT:
		recent_dialogue_ids.pop_front()
	run_visitor_roll_done = bool(saved.get("run_visitor_roll_done", false))
	run_visitor_id = StringName(str(saved.get("run_visitor_id", "")))
	run_visitor_invited = bool(saved.get("run_visitor_invited", false))
