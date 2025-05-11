extends Node

const SAVE_PATH := "user://player_progress.json"
const DIALOGUE_PATH := "res://data/dialogue/"

var player_progress := {}
var current_dialogue := []
var dialogue_index := 0
var is_typing := false
var typing_speed := 0.03

var dialogue_box: Node 
var player: CharacterBody2D 

func _ready():
	load_player_progress()

func load_player_progress():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		player_progress = JSON.parse_string(file.get_as_text()) or {}
	else:
		player_progress = {}

func save_player_progress():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(player_progress))

func load_npc_dialogue(npc_id: String) -> Array:
	var file_path = DIALOGUE_PATH + npc_id + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var result = JSON.parse_string(file.get_as_text())
		if typeof(result) == TYPE_ARRAY:
			return result
	return []

func start_dialogue(npc_id: String):
	if is_typing:
		return

	player.dialogue_mode = true
	player.virtual_joystick_active = false
	player.virtual_joystick_offset = Vector2.ZERO
	player.virtual_joystick.visible = false

	current_dialogue = load_npc_dialogue(npc_id)
	dialogue_index = 0
	dialogue_box.visible = true

	if current_dialogue.size() > 0:
		show_line(current_dialogue[0])

func show_next_line():
	if is_typing:
		return
	dialogue_index += 1
	if dialogue_index < current_dialogue.size():
		show_line(current_dialogue[dialogue_index])
	else:
		end_dialogue()

func show_line(dialogue_data: Dictionary):
	var name_label = dialogue_box.get_node("NameLabel") as Label
	var text_label = dialogue_box.get_node("TextLabel") as RichTextLabel

	name_label.text = dialogue_data.get("name", "")
	text_label.clear()

	var text = dialogue_data.get("text", "")
	is_typing = true
	_typing_effect(text_label, text)

func end_dialogue():
	player.dialogue_mode = false

	is_typing = false
	dialogue_box.visible = false

func _typing_effect(label: RichTextLabel, full_text: String) -> void:
	label.clear()
	await _yield_typing(full_text, label)
	is_typing = false

func _yield_typing(text: String, label: RichTextLabel):
	var tag_stack := []
	var output := ""
	var i := 0

	while i < text.length():
		if text[i] == "[":
			var end_idx := text.find("]", i)
			if end_idx != -1:
				var tag := text.substr(i, end_idx - i + 1)
				output += tag
				tag_stack.append(tag)
				i = end_idx + 1
				continue
		elif text[i] == "/" and text[i+1] == "[":
			var end_idx := text.find("]", i)
			if end_idx != -1:
				var end_tag := text.substr(i, end_idx - i + 1)
				output += end_tag
				tag_stack.pop_back()
				i = end_idx + 1
				continue

		output += text[i]
		label.clear()
		label.append_text(output)
		await get_tree().create_timer(typing_speed).timeout
		i += 1

	return null
