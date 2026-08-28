extends Panel

signal payment_requested
signal closed

@onready var request_label: RichTextLabel = $RequestLabel
@onready var payment_button: Button = $Options/GiveResources
@onready var chat_button: Button = $Options/Chat
@onready var leave_button: Button = $Options/Leave

var _definition: VillagerDefinition
var _dialogue_completion_pending := false

func _ready() -> void:
	payment_button.pressed.connect(_on_payment_pressed)
	chat_button.pressed.connect(_on_chat_pressed)
	leave_button.pressed.connect(close)

func begin_interaction(definition: VillagerDefinition, can_pay: bool) -> void:
	_definition = definition
	request_label.text = _format_request(definition.invite_cost, "Move-in request", &"resources")
	payment_button.text = "Give Resources"
	payment_button.disabled = not can_pay
	_start_villager_dialogue("[PLACEHOLDER DIALOGUE]")

func begin_home_request(definition: VillagerDefinition, cost: Dictionary[String, int], can_pay: bool) -> void:
	_definition = definition
	request_label.text = _format_request(cost, "Home request", &"dye")
	payment_button.text = "Give Dye"
	payment_button.disabled = not can_pay
	_start_villager_dialogue("[PLACEHOLDER HOME REQUEST]")

func mark_paid(completion_text: String = "Move-in request complete", dialogue_text: String = "[PLACEHOLDER MOVE-IN RESPONSE]") -> void:
	payment_button.disabled = true
	request_label.text = "[center]" + completion_text
	_start_villager_dialogue(dialogue_text)

func close() -> void:
	hide()
	if DialogueManager.player != null:
		DialogueManager.player.dialogue_mode = false
		DialogueManager.player.interaction_controls_locked = false
	closed.emit()

func _open() -> void:
	if DialogueManager.player != null:
		DialogueManager.player.dialogue_mode = false
		DialogueManager.player.interaction_controls_locked = true
		DialogueManager.player.virtual_joystick_active = false
		DialogueManager.player.virtual_joystick_offset = Vector2.ZERO
		DialogueManager.player.virtual_joystick.visible = false
	show()

func _start_villager_dialogue(text: String) -> void:
	if _dialogue_completion_pending or DialogueManager.is_typing:
		return
	_dialogue_completion_pending = true
	hide()
	if DialogueManager.player != null:
		DialogueManager.player.interaction_controls_locked = true
	if not DialogueManager.dialogue_finished.is_connected(_on_villager_dialogue_finished):
		DialogueManager.dialogue_finished.connect(_on_villager_dialogue_finished)
	DialogueManager.start_inline_dialogue([{
		"name": _definition.display_name,
		"pitch": [0.9, 1.1],
		"text": text
	}], true)

func _on_villager_dialogue_finished() -> void:
	if not _dialogue_completion_pending:
		return
	_dialogue_completion_pending = false
	_open()

func _format_request(cost: Dictionary[String, int], heading: String, cost_type: StringName) -> String:
	var parts: Array[String] = []
	for colour_name in GameManager.COLOR_ORDER:
		var amount := int(cost.get(colour_name, 0))
		if amount <= 0:
			continue
		if cost_type == &"dye":
			parts.append("[color=#%s]%d %s[/color]" % [GameManager.COLOR_HEX[colour_name], amount, colour_name.to_lower()])
		else:
			var region: Vector4i = GameManager.INGREDIENT_REGIONS[colour_name]
			parts.append("%d[img width=25 region=%d,%d,%d,%d]uid://bdfnifowl2amv[/img]" % [amount, region.x, region.y, region.z, region.w])
	return "[center]" + heading + "\n" + "   ".join(parts)

func _on_payment_pressed() -> void:
	payment_requested.emit()

func _on_chat_pressed() -> void:
	_start_villager_dialogue("[PLACEHOLDER DIALOGUE]")
