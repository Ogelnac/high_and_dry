extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tadd_launch_zone: Area2D = $Environment/Boat/LaunchZone
@onready var resident_box: Panel = $CanvasLayer/VisitorBox
@onready var villager_locations_root: Node2D = $VillagerLocations
@onready var resident_slots: Array[HubResident] = [
	$Residents/House1Resident,
	$Residents/House2Resident,
	$Residents/House3Resident,
	$Residents/House4Resident,
	$Residents/House5Resident
]

var active_resident: HubResident

func _ready() -> void:
	await get_tree().process_frame
	var enter_callable := Callable(player, "_on_tadd_launch_zone_body_entered")
	var exit_callable := Callable(player, "_on_tadd_launch_zone_body_exited")
	if not tadd_launch_zone.body_entered.is_connected(enter_callable):
		tadd_launch_zone.body_entered.connect(enter_callable)
	if not tadd_launch_zone.body_exited.is_connected(exit_callable):
		tadd_launch_zone.body_exited.connect(exit_callable)
	var village_state_changed := VillagerManager.complete_pending_move_in()
	if VillagerManager.complete_pending_home_upgrades():
		village_state_changed = true
	if village_state_changed:
		GameManager.save()
	_setup_residents()
	if !GameManager.game_progress["tutorial_played"]:
		get_tree().change_scene_to_file("uid://dxc74hnt0exva")
		return

	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput
	resident_box.payment_requested.connect(_on_resident_payment_requested)
	resident_box.closed.connect(_on_resident_panel_closed)

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

func _setup_residents() -> void:
	var locations := _get_enabled_villager_locations()
	var location_records: Array[Dictionary] = []
	var locations_by_id: Dictionary[StringName, HubVillagerLocation] = {}
	for location in locations:
		var location_id := StringName(location.name)
		location_records.append(location.get_assignment_record())
		locations_by_id[location_id] = location
	var assignments := VillagerManager.assign_hub_locations(location_records)
	var location_totals: Dictionary[StringName, int] = {}
	for assigned_villager_id: StringName in assignments:
		var assigned_location_id: StringName = assignments[assigned_villager_id]
		location_totals[assigned_location_id] = int(location_totals.get(assigned_location_id, 0)) + 1
	var location_slots_used: Dictionary[StringName, int] = {}
	for house_index: int in range(resident_slots.size()):
		var resident: HubResident = resident_slots[house_index]
		resident.visible = false
		resident.process_mode = Node.PROCESS_MODE_DISABLED
		if house_index >= VillagerManager.houses.size():
			continue
		var house: Dictionary = VillagerManager.houses[house_index]
		var occupant_id := StringName(str(house.get("occupant_id", "")))
		if occupant_id.is_empty():
			continue
		var tier := int(house.get("tier", 0))
		resident.setup(occupant_id, house_index, tier)
		var location_id := StringName(str(assignments.get(occupant_id, "")))
		var location := locations_by_id.get(location_id) as HubVillagerLocation
		if location != null:
			var slot_index := int(location_slots_used.get(location_id, 0))
			var starting_offset := 0.0
			if int(location_totals.get(location_id, 0)) == 2:
				starting_offset = -10.0 if slot_index == 0 else 10.0
			location_slots_used[location_id] = slot_index + 1
			resident.configure_location(location_id, location.global_position, location.roam_radius, tier >= 1, starting_offset)
		if not resident.home_request_requested.is_connected(_on_resident_home_request_requested):
			resident.home_request_requested.connect(_on_resident_home_request_requested)
		resident.visible = true
		resident.process_mode = Node.PROCESS_MODE_INHERIT

func _get_enabled_villager_locations() -> Array[HubVillagerLocation]:
	var locations: Array[HubVillagerLocation] = []
	for child in villager_locations_root.get_children():
		var location := child as HubVillagerLocation
		if location != null and location.enabled:
			locations.append(location)
	return locations

func _on_resident_home_request_requested(resident: Node2D) -> void:
	active_resident = resident as HubResident
	if active_resident == null:
		return
	var definition := VillagerManager.get_definition(active_resident.villager_id)
	if definition == null:
		active_resident.finish_panel_interaction()
		active_resident = null
		return
	var cost: Dictionary[String, int] = VillagerManager.get_home_upgrade_cost(active_resident.house_index)
	resident_box.begin_home_request(definition, cost, VillagerManager.can_pay_home_upgrade(active_resident.house_index))

func _on_resident_payment_requested() -> void:
	if active_resident == null:
		return
	if VillagerManager.pay_home_upgrade(active_resident.house_index):
		GameManager.save()
		GameManager.update_bottles()
		resident_box.mark_paid("Home request accepted", "[PLACEHOLDER HOME REQUEST ACCEPTED]")

func _on_resident_panel_closed() -> void:
	if active_resident == null:
		return
	active_resident.finish_panel_interaction()
	active_resident = null
