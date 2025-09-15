extends Panel

@onready var debug: Button = $"../HBoxContainer/Debug"

@onready var check_box: CheckBox = $VBoxContainer/CheckBox
@onready var check_box_2: CheckBox = $VBoxContainer/CheckBox2
@onready var check_box_3: CheckBox = $VBoxContainer/CheckBox3
@onready var button: Button = $VBoxContainer/Button
@onready var line_edit: LineEdit = $VBoxContainer/HBoxContainer/LineEdit

@onready var dialogue_input: Panel = $"../DialogueInput"

var previous_value: int = 5

func _ready() -> void:
	debug.pressed.connect(_toggle_panel_visibility)
	check_box.toggled.connect(_pass_toggle_disable_rising_death)
	check_box_2.toggled.connect(_pass_toggle_infinite_health)
	check_box_3.toggled.connect(_pass_toggle_infinite_resources)
	button.pressed.connect(show_dialogue_box)

	check_box.button_pressed = Debug.disable_rising_death
	check_box_2.button_pressed = Debug.infinite_health
	check_box_3.button_pressed = Debug.infinite_resources

	line_edit.text = str(previous_value)
	line_edit.text_submitted.connect(_validate_line_edit)
	line_edit.focus_exited.connect(_validate_line_edit_on_focus_exit)

func _toggle_panel_visibility():
	visible = !visible

func _pass_toggle_disable_rising_death(toggled_on: bool):
	Debug.disable_rising_death = toggled_on

func _pass_toggle_infinite_health(toggled_on: bool):
	Debug.infinite_health = toggled_on
	Debug.end_game_button_visibility()

func _pass_toggle_infinite_resources(toggled_on: bool):
	Debug.infinite_resources = toggled_on

func show_dialogue_box():
	dialogue_input.get_node("Text").text = "Are you sure you want to reset your progress?"

	var option1 = dialogue_input.get_node("Option1")
	if not option1.pressed.is_connected(_confirm):
		option1.pressed.connect(_confirm)

	var option2 = dialogue_input.get_node("Option2")
	if not option2.pressed.is_connected(_deny):
		option2.pressed.connect(_deny)

	dialogue_input.show()

func _confirm():
	GameManager._reset_progress()

func _deny():
	dialogue_input.hide()

func _validate_line_edit(new_text: String) -> void:
	var num = new_text.to_int()
	if str(num) != new_text.strip_edges() and not new_text.is_valid_int():
		line_edit.text = str(previous_value)
		return
	num = clamp(num, 1, 100)
	line_edit.text = str(num)
	previous_value = num
	Debug.number_of_levels = -(num + 1)

func _validate_line_edit_on_focus_exit() -> void:
	_validate_line_edit(line_edit.text)
