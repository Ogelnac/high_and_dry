extends Node

const STARTING_HOUSE_COUNT := 5
const RECENT_DIALOGUE_LIMIT := 3
const HUB_VISITOR_CHANCE := 0.25
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
var initial_debug_visitor_seeded := false

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
	initial_debug_visitor_seeded = false

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

func roll_hub_visitor(guaranteed: bool = false) -> StringName:
	if not waiting_villager_id.is_empty():
		if guaranteed:
			initial_debug_visitor_seeded = true
		return waiting_villager_id
	if not has_available_house():
		return &""
	var eligible: Array[StringName] = get_eligible_visitor_ids()
	if eligible.is_empty():
		return &""
	if guaranteed or randf() < HUB_VISITOR_CHANCE:
		waiting_villager_id = eligible.pick_random()
		if guaranteed:
			initial_debug_visitor_seeded = true
	return waiting_villager_id

func seed_initial_debug_visitor() -> bool:
	if not Debug.guarantee_tadd_villager or initial_debug_visitor_seeded:
		return false
	return not roll_hub_visitor(true).is_empty()

func can_pay_waiting_villager() -> bool:
	if waiting_villager_id.is_empty() or not has_available_house():
		return false
	if Debug.infinite_resources:
		return true
	var definition := get_definition(waiting_villager_id)
	if definition == null:
		return false
	for colour_name: String in definition.invite_cost:
		var required: int = int(definition.invite_cost.get(colour_name, 0))
		if int(GameManager.resources.get(colour_name, 0)) < required:
			return false
	return true

func pay_waiting_villager() -> bool:
	if not can_pay_waiting_villager():
		return false
	var definition := get_definition(waiting_villager_id)
	var house_index: int = get_available_house_index()
	if definition == null or house_index < 0:
		return false
	if not Debug.infinite_resources:
		for colour_name: String in definition.invite_cost:
			var required: int = int(definition.invite_cost.get(colour_name, 0))
			GameManager.resources[colour_name] = int(GameManager.resources.get(colour_name, 0)) - required
	pending_move_in_villager_id = waiting_villager_id
	pending_move_in_house_index = house_index
	waiting_villager_id = &""
	return true

func complete_pending_move_in() -> bool:
	if pending_move_in_villager_id.is_empty():
		return false
	if pending_move_in_house_index < 0 or pending_move_in_house_index >= houses.size():
		return false
	var house: Dictionary = houses[pending_move_in_house_index]
	if not str(house.get("occupant_id", "")).is_empty():
		return false
	house["occupant_id"] = str(pending_move_in_villager_id)
	house["tier"] = 0
	pending_move_in_villager_id = &""
	pending_move_in_house_index = -1
	return true

func serialize_state() -> Dictionary:
	return {
		"houses": houses.duplicate(true),
		"waiting_villager_id": str(waiting_villager_id),
		"pending_move_in_villager_id": str(pending_move_in_villager_id),
		"pending_move_in_house_index": pending_move_in_house_index,
		"recent_dialogue_ids": recent_dialogue_ids.duplicate(),
		"initial_debug_visitor_seeded": initial_debug_visitor_seeded
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
	initial_debug_visitor_seeded = bool(saved.get("initial_debug_visitor_seeded", false))
	var saved_recent: Variant = saved.get("recent_dialogue_ids", [])
	if saved_recent is Array:
		for dialogue_id in saved_recent:
			recent_dialogue_ids.append(str(dialogue_id))
	while recent_dialogue_ids.size() > RECENT_DIALOGUE_LIMIT:
		recent_dialogue_ids.pop_front()
