extends Node2D

@onready var visitor_walk_start: Marker2D = $VisitorWalkStart
@onready var visitor_walk_end: Marker2D = $VisitorWalkEnd
@onready var visitor_box: Panel = $CanvasLayer/VisitorBox
@onready var waiting_villager: Node2D = $WaitingVillager

var visitor_definition: VillagerDefinition

func _ready() -> void:
	randomize()
	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput
	GameManager.get_ui_reference()
	GameManager.load_game()
	if VillagerManager.seed_initial_debug_visitor():
		GameManager.save()
	GameManager.shop_UI()
	visitor_box.payment_requested.connect(_on_visitor_payment_requested)
	visitor_box.closed.connect(_on_visitor_panel_closed)
	_setup_waiting_visitor()

func _setup_waiting_visitor() -> void:
	waiting_villager.visible = false
	waiting_villager.process_mode = Node.PROCESS_MODE_DISABLED
	if VillagerManager.waiting_villager_id.is_empty():
		return
	visitor_definition = VillagerManager.get_definition(VillagerManager.waiting_villager_id)
	if visitor_definition == null:
		return
	waiting_villager.setup(VillagerManager.waiting_villager_id)
	waiting_villager.configure_walk_area(visitor_walk_start.position.x, visitor_walk_end.position.x, visitor_walk_start.position.y)
	waiting_villager.visible = true
	waiting_villager.process_mode = Node.PROCESS_MODE_INHERIT
	if not waiting_villager.interaction_requested.is_connected(_on_visitor_interaction_requested):
		waiting_villager.interaction_requested.connect(_on_visitor_interaction_requested)
	GameManager.UI.get_node("UI").refresh_shader_objects()

func _on_visitor_interaction_requested() -> void:
	if visitor_definition != null:
		visitor_box.begin_interaction(visitor_definition, VillagerManager.can_pay_waiting_villager())

func _on_visitor_payment_requested() -> void:
	if VillagerManager.pay_waiting_villager():
		GameManager.save()
		visitor_box.mark_paid()

func _on_visitor_panel_closed() -> void:
	waiting_villager.resume_wandering()

func leave_shop() -> void:
	Debug.switch_player = false
	GameManager.player_start_position = Vector2(867.0, -23.0)
	GameManager.save()
	get_tree().change_scene_to_file("uid://cjyisk7r6qf4c")
