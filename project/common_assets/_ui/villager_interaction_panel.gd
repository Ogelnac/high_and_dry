extends Panel

signal invite_requested
signal closed

@onready var request_label: RichTextLabel = $RequestLabel
@onready var invite_button: Button = $Options/Invite
@onready var chat_button: Button = $Options/Chat
@onready var leave_button: Button = $Options/Leave

var _definition: VillagerDefinition
var _dialogue_completion_pending := false

func _ready() -> void:
	invite_button.pressed.connect(_on_invite_pressed)
	chat_button.pressed.connect(_on_chat_pressed)
	leave_button.pressed.connect(close)

func begin_interaction(definition: VillagerDefinition, invited: bool) -> void:
	_definition = definition
	request_label.text = _format_request(definition.invite_cost)
	invite_button.disabled = invited
	_start_villager_dialogue("[PLACEHOLDER DIALOGUE]")

func mark_invited() -> void:
	invite_button.disabled = true
	_start_villager_dialogue("[PLACEHOLDER INVITE RESPONSE]")

func close() -> void:
	hide()
	if DialogueManager.player != null:
		DialogueManager.player.dialogue_mode = false
	closed.emit()

func _open() -> void:
	if DialogueManager.player != null:
		DialogueManager.player.dialogue_mode = true
		DialogueManager.player.virtual_joystick_active = false
		DialogueManager.player.virtual_joystick_offset = Vector2.ZERO
		DialogueManager.player.virtual_joystick.visible = false
	show()

func _start_villager_dialogue(text: String) -> void:
	if _dialogue_completion_pending or DialogueManager.is_typing:
		return
	_dialogue_completion_pending = true
	hide()
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

func _format_request(cost: Dictionary[String, int]) -> String:
	var parts: Array[String] = []
	for colour_name in GameManager.COLOR_ORDER:
		var amount := int(cost.get(colour_name, 0))
		if amount <= 0:
			continue
		var region: Vector4i = GameManager.INGREDIENT_REGIONS[colour_name]
		parts.append("%d[img width=25 region=%d,%d,%d,%d]uid://bdfnifowl2amv[/img]" % [amount, region.x, region.y, region.z, region.w])
	return "[center]Move-in request\n" + "   ".join(parts)

func _on_invite_pressed() -> void:
	invite_requested.emit()

func _on_chat_pressed() -> void:
	_start_villager_dialogue("[PLACEHOLDER DIALOGUE]")
