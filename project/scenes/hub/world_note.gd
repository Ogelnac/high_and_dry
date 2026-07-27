@tool
extends Area2D

@export_multiline var note_text: String = "Add your note here.":
	set(value):
		note_text = value.left(160)
		if is_node_ready():
			_update_note_text()

@onready var marker: Node2D = $Marker
@onready var note_display: MarginContainer = $NoteCanvas/NoteDisplay
@onready var note_label: Label = $NoteCanvas/NoteDisplay/NoteText
@onready var close_timer: Timer = $CloseTimer

var _note_is_open := false
var _note_tween: Tween
const MARKER_HIT_RADIUS := 28.0


func _ready() -> void:
	_update_note_text()
	if Engine.is_editor_hint():
		return

	Debug.world_notes_visibility_changed.connect(_set_marker_visible)
	_set_marker_visible(Debug.world_notes_visible)
	close_timer.timeout.connect(_close_note)
	note_display.visible = false
	note_display.scale = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if Debug.world_note_input_captured:
		if _is_release(event):
			_release_captured_input.call_deferred()
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return

	if not _is_press(event):
		return

	var hovered_control := get_viewport().gui_get_hovered_control()
	if hovered_control and hovered_control.mouse_filter == Control.MOUSE_FILTER_STOP:
		return

	var pointer_position := _get_pointer_position(event)
	var local_pointer_position := make_canvas_position_local(pointer_position)
	if local_pointer_position.length() > MARKER_HIT_RADIUS:
		return

	Debug.world_note_input_captured = true
	get_viewport().set_input_as_handled()
	if _note_is_open:
		_close_note()
	else:
		_open_note()


func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false


func _is_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not event.pressed
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	return false


func _release_captured_input() -> void:
	Debug.world_note_input_captured = false


func _get_pointer_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.INF


func _set_marker_visible(show_markers: bool) -> void:
	marker.visible = show_markers
	input_pickable = show_markers
	set_process_input(show_markers)


func _open_note() -> void:
	if is_instance_valid(Debug.active_world_note) and Debug.active_world_note != self:
		Debug.active_world_note._close_note()

	Debug.active_world_note = self
	_note_is_open = true
	close_timer.start()
	_animate_note(true)


func _close_note() -> void:
	if not _note_is_open:
		return

	_note_is_open = false
	close_timer.stop()
	if Debug.active_world_note == self:
		Debug.active_world_note = null
	_animate_note(false)


func _animate_note(show_note: bool) -> void:
	if _note_tween and _note_tween.is_valid():
		_note_tween.kill()

	if show_note:
		note_display.visible = true
		note_display.pivot_offset = note_display.size * 0.5

	_note_tween = create_tween()
	_note_tween.set_parallel(true)
	_note_tween.set_trans(Tween.TRANS_BACK)
	_note_tween.set_ease(Tween.EASE_OUT if show_note else Tween.EASE_IN)
	_note_tween.tween_property(
		note_display,
		"scale",
		Vector2.ONE if show_note else Vector2.ZERO,
		0.22
	)
	_note_tween.tween_property(
		note_display,
		"modulate:a",
		1.0 if show_note else 0.0,
		0.14
	)

	if not show_note:
		_note_tween.chain().tween_callback(note_display.hide)


func _update_note_text() -> void:
	if note_label:
		note_label.text = note_text.left(160)
