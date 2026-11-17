extends CanvasLayer

@onready var menu_panel: Control = $MenuPanel
@onready var debug_panel: Control = $DebugPanel
@onready var menu_button: Button = $HBoxContainer/Menu
@onready var debug_button: Button = $HBoxContainer/Debug
@onready var dialogue_input: Control = $DialogueInput


func _ready() -> void:
	menu_button.pressed.connect(_toggle_panel.bind(menu_panel))
	debug_button.pressed.connect(_toggle_panel.bind(debug_panel))


func _toggle_panel(panel: Control) -> void:
	var opening := not panel.visible
	menu_panel.visible = opening and panel == menu_panel
	debug_panel.visible = opening and panel == debug_panel


func _input(event: InputEvent) -> void:
	if not (menu_panel.visible or debug_panel.visible) or dialogue_input.is_visible_in_tree():
		return
	var pointer_position: Vector2
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pointer_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pointer_position = event.position
	else:
		return
	var panel := menu_panel if menu_panel.visible else debug_panel
	for control in [panel, menu_button, debug_button]:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(control.get_canvas_transform().affine_inverse() * pointer_position):
			return
	panel.hide()
	get_viewport().set_input_as_handled()
