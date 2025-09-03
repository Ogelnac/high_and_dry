extends Node2D

@export var platform_player_scene: PackedScene
@export var arcade_player_scene: PackedScene
@export var existing_player: CharacterBody2D

var current: CharacterBody2D
var player_parent: Node

func _ready():
	if not existing_player:
		return
	current = existing_player
	player_parent = get_parent()

func _process(_delta: float) -> void:
	if Debug.switch_player:
		_toggle()
		Debug.switch_player = false

	if current:
		global_position = current.global_position

func _toggle():
	if not current:
		return
	if arcade_player_scene and current.scene_file_path == arcade_player_scene.resource_path:
		switch_to_platform()
	else:
		switch_to_arcade()

func switch_to_arcade():
	if not current or not arcade_player_scene:
		return
	if current.scene_file_path == arcade_player_scene.resource_path:
		return
	call_deferred("_replace_with", true)

func switch_to_platform():
	if not current or not platform_player_scene:
		return
	if current.scene_file_path == platform_player_scene.resource_path:
		return
	call_deferred("_replace_with", false)

func _replace_with(to_arcade: bool):
	if not current:
		return
	var pos = current.global_position
	var vel = current.velocity
	var parent := current.get_parent()
	var idx = current.get_index()
	var scene_to_use: PackedScene = arcade_player_scene if to_arcade else platform_player_scene
	if not scene_to_use:
		return
	var n: CharacterBody2D = scene_to_use.instantiate()
	n.global_position = pos
	n.velocity = vel
	n.get_node("Sprite2D").material.set_shader_parameter("black_dot_transition", 0.5)
	parent.call_deferred("add_child", n)
	await get_tree().process_frame
	if idx >= 0:
		parent.move_child(n, idx)
	n.global_position = pos
	current.queue_free()
	await get_tree().process_frame
	current = n
	if not player_parent:
		player_parent = parent
