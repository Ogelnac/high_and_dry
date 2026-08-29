extends Node

const STARTING_HOUSE_COUNT := 5
const RECENT_DIALOGUE_LIMIT := 3
const HUB_VISITOR_CHANCE := 0.25
const DIALOGUE_PATH := "res://project/common_assets/_data/dialogue/villagers.json"
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
var dialogue_entries: Array[Dictionary] = []
var initial_debug_visitor_seeded := false

func _ready() -> void:
	for definition in DEFINITIONS:
		definitions_by_id[definition.villager_id] = definition
	_load_dialogue_entries()
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
		"upgrade_comment_pending": false,
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

func get_house_tier(house_index: int) -> int:
	if house_index < 0 or house_index >= houses.size():
		return 0
	return int(houses[house_index].get("tier", 0))

func get_villager_dialogue(villager_id: StringName, context: StringName, home_tier: int = 0, remember: bool = true) -> Array[Dictionary]:
	var selected: Dictionary = select_villager_dialogue_entry(villager_id, context, home_tier, remember)
	var lines: Array[Dictionary] = []
	if selected.is_empty():
		return lines
	var definition := get_definition(villager_id)
	if definition == null:
		return lines
	var raw_lines: Variant = selected.get("lines", [])
	if not raw_lines is Array:
		return lines
	for raw_line: Variant in raw_lines:
		if not raw_line is Dictionary:
			continue
		var line: Dictionary = raw_line.duplicate(true)
		if str(line.get("name", "")).is_empty():
			line["name"] = definition.display_name
		if not line.has("pitch"):
			line["pitch"] = [0.9, 1.1]
		lines.append(line)
	return lines

func select_villager_dialogue_entry(villager_id: StringName, context: StringName, home_tier: int = 0, remember: bool = true) -> Dictionary:
	var definition := get_definition(villager_id)
	if definition == null:
		return {}
	var eligible: Array[Dictionary] = []
	for entry: Dictionary in dialogue_entries:
		var dialogue_id := str(entry.get("id", ""))
		if dialogue_id.is_empty():
			continue
		if not _tag_list_matches(entry.get("contexts", []), str(context)):
			continue
		if not _tag_list_matches(entry.get("personalities", []), str(definition.personality)):
			continue
		if home_tier < int(entry.get("min_home_tier", 0)):
			continue
		if home_tier > int(entry.get("max_home_tier", 99)):
			continue
		eligible.append(entry)
	if eligible.is_empty():
		return {}
	var selected: Dictionary = _pick_least_recent_dialogue(eligible)
	if remember and bool(selected.get("repeatable", true)):
		remember_dialogue(str(selected.get("id", "")))
	return selected.duplicate(true)

func _load_dialogue_entries() -> void:
	dialogue_entries.clear()
	if not FileAccess.file_exists(DIALOGUE_PATH):
		return
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return
	for entry: Variant in parsed:
		if entry is Dictionary:
			dialogue_entries.append(entry)

func _tag_list_matches(value: Variant, target: String) -> bool:
	if not value is Array:
		return false
	if value.is_empty():
		return true
	for tag: Variant in value:
		if str(tag).to_lower() == target.to_lower() or str(tag) == "*":
			return true
	return false

func _pick_least_recent_dialogue(entries: Array[Dictionary]) -> Dictionary:
	var unseen: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if not recent_dialogue_ids.has(str(entry.get("id", ""))):
			unseen.append(entry)
	if not unseen.is_empty():
		return unseen[randi_range(0, unseen.size() - 1)]
	var oldest_index := RECENT_DIALOGUE_LIMIT + 1
	var oldest: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var recent_index := recent_dialogue_ids.find(str(entry.get("id", "")))
		if recent_index < oldest_index:
			oldest_index = recent_index
			oldest.clear()
			oldest.append(entry)
		elif recent_index == oldest_index:
			oldest.append(entry)
	if oldest.is_empty():
		return entries[randi_range(0, entries.size() - 1)]
	return oldest[randi_range(0, oldest.size() - 1)]

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

func get_house_index_for_villager(villager_id: StringName) -> int:
	for index in range(houses.size()):
		if StringName(str(houses[index].get("occupant_id", ""))) == villager_id:
			return index
	return -1

func assign_hub_locations(locations: Array[Dictionary]) -> Dictionary[StringName, StringName]:
	var assignments: Dictionary[StringName, StringName] = {}
	var occupancy: Dictionary[StringName, int] = {}
	var occupied_house_indices: Array[int] = []
	for location: Dictionary in locations:
		var location_id := StringName(str(location.get("location_id", "")))
		if not location_id.is_empty():
			occupancy[location_id] = 0
	for house_index in range(houses.size()):
		if not str(houses[house_index].get("occupant_id", "")).is_empty():
			occupied_house_indices.append(house_index)
	for house_index in occupied_house_indices:
		var house: Dictionary = houses[house_index]
		if int(house.get("tier", 0)) >= 1:
			continue
		var home_candidates := _get_hub_location_candidates(&"home", house_index, locations, occupied_house_indices, occupancy)
		if home_candidates.is_empty():
			continue
		var home_location: Dictionary = home_candidates[0]
		_assign_hub_location(assignments, occupancy, StringName(str(house.get("occupant_id", ""))), home_location)
	var roaming_house_indices := occupied_house_indices.duplicate()
	roaming_house_indices.shuffle()
	for house_index in roaming_house_indices:
		var house: Dictionary = houses[house_index]
		if int(house.get("tier", 0)) < 1:
			continue
		var villager_id := StringName(str(house.get("occupant_id", "")))
		var definition := get_definition(villager_id)
		if definition == null:
			continue
		var available_categories: Array[StringName] = []
		for category_name: String in definition.location_weights:
			var category := StringName(category_name)
			if int(definition.location_weights.get(category_name, 0)) <= 0:
				continue
			if not _get_hub_location_candidates(category, house_index, locations, occupied_house_indices, occupancy).is_empty():
				available_categories.append(category)
		var chosen_category := _pick_weighted_location_category(definition.location_weights, available_categories)
		if chosen_category.is_empty():
			continue
		var candidates := _get_hub_location_candidates(chosen_category, house_index, locations, occupied_house_indices, occupancy)
		var chosen_location: Dictionary = candidates[randi_range(0, candidates.size() - 1)]
		_assign_hub_location(assignments, occupancy, villager_id, chosen_location)
	return assignments

func _get_hub_location_candidates(category: StringName, own_house_index: int, locations: Array[Dictionary], occupied_house_indices: Array[int], occupancy: Dictionary[StringName, int]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for location: Dictionary in locations:
		var location_id := StringName(str(location.get("location_id", "")))
		var location_type := StringName(str(location.get("location_type", "")))
		var location_house_index := int(location.get("house_index", -1))
		var capacity := int(location.get("capacity", 2))
		if location_id.is_empty() or int(occupancy.get(location_id, 0)) >= capacity:
			continue
		if category == &"home":
			if location_type == &"home" and location_house_index == own_house_index:
				candidates.append(location)
		elif category == &"other_home":
			if location_type == &"home" and location_house_index != own_house_index and occupied_house_indices.has(location_house_index):
				candidates.append(location)
		elif location_type == category:
			candidates.append(location)
	return candidates

func _pick_weighted_location_category(weights: Dictionary[String, int], available_categories: Array[StringName]) -> StringName:
	var total_weight := 0
	for category in available_categories:
		total_weight += int(weights.get(str(category), 0))
	if total_weight <= 0:
		return &""
	var roll := randi_range(1, total_weight)
	for category in available_categories:
		roll -= int(weights.get(str(category), 0))
		if roll <= 0:
			return category
	return available_categories.back()

func _assign_hub_location(assignments: Dictionary[StringName, StringName], occupancy: Dictionary[StringName, int], villager_id: StringName, location: Dictionary) -> void:
	var location_id := StringName(str(location.get("location_id", "")))
	if villager_id.is_empty() or location_id.is_empty():
		return
	assignments[villager_id] = location_id
	occupancy[location_id] = int(occupancy.get(location_id, 0)) + 1

func has_home_upgrade_request(house_index: int) -> bool:
	if house_index < 0 or house_index >= houses.size():
		return false
	var house: Dictionary = houses[house_index]
	if str(house.get("occupant_id", "")).is_empty():
		return false
	if int(house.get("pending_tier", -1)) >= 0:
		return false
	return int(house.get("tier", 0)) == 0 and Debug.unlock_villager_dye_requests

func get_home_upgrade_cost(house_index: int) -> Dictionary[String, int]:
	var empty_cost: Dictionary[String, int] = {}
	if not has_home_upgrade_request(house_index):
		return empty_cost
	var villager_id := StringName(str(houses[house_index].get("occupant_id", "")))
	var definition := get_definition(villager_id)
	if definition == null:
		return empty_cost
	return definition.dye_cost.duplicate()

func can_pay_home_upgrade(house_index: int) -> bool:
	if not has_home_upgrade_request(house_index):
		return false
	if Debug.infinite_resources:
		return true
	var cost: Dictionary[String, int] = get_home_upgrade_cost(house_index)
	for colour_name: String in cost:
		if int(GameManager.dye_value.get(colour_name, 0)) < int(cost[colour_name]):
			return false
	return true

func pay_home_upgrade(house_index: int) -> bool:
	if not can_pay_home_upgrade(house_index):
		return false
	var cost: Dictionary[String, int] = get_home_upgrade_cost(house_index)
	if not Debug.infinite_resources:
		for colour_name: String in cost:
			GameManager.dye_value[colour_name] = int(GameManager.dye_value.get(colour_name, 0)) - int(cost[colour_name])
	houses[house_index]["pending_tier"] = 1
	return true

func complete_pending_home_upgrades() -> bool:
	var completed := false
	for house in houses:
		var tier := int(house.get("tier", 0))
		var pending_tier := int(house.get("pending_tier", -1))
		if pending_tier <= tier:
			continue
		house["tier"] = pending_tier
		house["pending_tier"] = -1
		house["upgrade_comment_pending"] = true
		completed = true
	return completed

func has_upgrade_comment(house_index: int) -> bool:
	if house_index < 0 or house_index >= houses.size():
		return false
	return bool(houses[house_index].get("upgrade_comment_pending", false))

func consume_upgrade_comment(house_index: int) -> void:
	if house_index < 0 or house_index >= houses.size():
		return
	houses[house_index]["upgrade_comment_pending"] = false

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
