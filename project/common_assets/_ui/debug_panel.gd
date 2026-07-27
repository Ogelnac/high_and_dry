extends PanelContainer

@onready var debug: Button = $"../HBoxContainer/Debug"

@onready var check_box: CheckBox = $MarginContainer/VBoxContainer/CheckBox
@onready var check_box_2: CheckBox = $MarginContainer/VBoxContainer/CheckBox2
@onready var check_box_3: CheckBox = $MarginContainer/VBoxContainer/CheckBox3
@onready var check_box_4: CheckBox = $MarginContainer/VBoxContainer/CheckBox4
@onready var world_notes_toggle: CheckButton = $MarginContainer/VBoxContainer/WorldNotesToggle
@onready var button: Button = $MarginContainer/VBoxContainer/Button
@onready var level_count: SpinBox = $MarginContainer/VBoxContainer/HBoxContainer/LevelCount

@onready var dialogue_input: Panel = $"../DialogueInput"

func _ready() -> void:
	debug.pressed.connect(_toggle_panel_visibility)
	check_box.toggled.connect(_pass_toggle_disable_rising_death)
	check_box_2.toggled.connect(_pass_toggle_infinite_health)
	check_box_3.toggled.connect(_pass_toggle_infinite_resources)
	check_box_4.toggled.connect(_pass_toggle_infinite_silkworms)
	world_notes_toggle.toggled.connect(Debug.set_world_notes_visible)
	button.pressed.connect(show_dialogue_box)

	check_box.button_pressed = Debug.disable_rising_death
	check_box_2.button_pressed = Debug.infinite_health
	check_box_3.button_pressed = Debug.infinite_resources
	check_box_4.button_pressed = Debug.infinite_silkworms
	world_notes_toggle.button_pressed = Debug.world_notes_visible

	level_count.value = Debug.number_of_levels
	level_count.value_changed.connect(_set_number_of_levels)

func _toggle_panel_visibility():
	visible = !visible

func _pass_toggle_disable_rising_death(toggled_on: bool):
	Debug.disable_rising_death = toggled_on

func _pass_toggle_infinite_health(toggled_on: bool):
	Debug.infinite_health = toggled_on
	Debug.end_game_button_visibility()

func _pass_toggle_infinite_resources(toggled_on: bool):
	Debug.infinite_resources = toggled_on

func _pass_toggle_infinite_silkworms(toggled_on: bool):
	Debug.infinite_silkworms = toggled_on

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

func _set_number_of_levels(value: float) -> void:
	Debug.number_of_levels = int(value)
