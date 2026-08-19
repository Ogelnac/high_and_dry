extends Node2D

@export var player_path: NodePath = NodePath("../Player")
@export var camera_path: NodePath = NodePath("../Camera2D")

var _player: Node2D
var _camera: Camera2D
var _reference_position := Vector2.ZERO
var _layers: Array[Dictionary] = []


func _ready() -> void:
	_player = get_node(player_path)
	_camera = get_node(camera_path)
	_find_parallax_layers(self)
	reset_reference()


func _process(_delta: float) -> void:
	var source_position := Vector2(
		_player.global_position.x,
		_camera.global_position.y
	)
	var source_offset := source_position - _reference_position

	for entry in _layers:
		var layer: Node2D = entry.node
		var origin: Vector2 = entry.origin
		var motion_scale: Vector2 = entry.motion_scale
		layer.global_position = origin + source_offset * motion_scale


func reset_reference() -> void:
	_reference_position = Vector2(
		_player.global_position.x,
		_camera.global_position.y
	)
	for entry in _layers:
		var layer: Node2D = entry.node
		layer.global_position = entry.origin


func _find_parallax_layers(parent: Node) -> void:
	for child in parent.get_children():
		if child is Node2D and child.has_meta("parallax_motion_scale"):
			_layers.append({
				"node": child,
				"origin": child.global_position,
				"motion_scale": child.get_meta("parallax_motion_scale")
			})
		_find_parallax_layers(child)
