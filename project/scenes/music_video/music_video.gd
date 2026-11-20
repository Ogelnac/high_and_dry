extends Node2D

const VILLAGER_SCENE := preload("res://project/scenes/hub/villagers/villager.tscn")
const TAILOR_SCENE := preload("res://project/common_assets/player_hub/player.tscn")
const FRAME_SIZE := Vector2i(960, 540)
const SPACING := 80.0
const WALK_SPEED := 92.0
const SPRITE_SCALE := Vector2(3, 3)
const OFFSCREEN_LEFT := -80.0

@onready var procession: Node2D = $Procession
@onready var music: AudioStreamPlayer = $Music

var walkers: Array[Node2D] = []
var walk_animations: Array[AnimationPlayer] = []
var distance := 0.0
var walking := false


func _ready() -> void:
	var window := get_window()
	window.content_scale_size = FRAME_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.size = FRAME_SIZE
	window.title = "High & Dry Music Video"

	# Keep the hub tailor's sprite and animation without the player controller.
	var player := TAILOR_SCENE.instantiate()
	var tailor := player.get_node("Sprite2D") as Sprite2D
	player.remove_child(tailor)
	player.free()
	_register_walker(tailor, tailor.get_node("AnimationPlayer"))
	tailor.position.y = -48.0

	for definition in VillagerManager.get_all_definitions():
		var villager := VILLAGER_SCENE.instantiate()
		villager.villager_id = definition.villager_id
		_register_walker(villager, villager.get_node("AnimationPlayer"))
		villager.set_process_input(false)
		villager.position.y = -48.0

	_position_walkers()
	music.finished.connect(_finish_take)


func _register_walker(walker: Node2D, animation: AnimationPlayer) -> void:
	procession.add_child(walker)
	walker.scale = SPRITE_SCALE
	walkers.append(walker)
	walk_animations.append(animation)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SPACE and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		if not music.playing:
			_start_take()


func _start_take() -> void:
	distance = 0.0
	_position_walkers()
	for index in walk_animations.size():
		var animation := walk_animations[index]
		animation.play(&"Run" if index == 0 else &"run")
		animation.seek(fmod(index * 0.19, animation.current_animation_length), true)
	walking = true
	music.play()


func _process(delta: float) -> void:
	if walking:
		distance += WALK_SPEED * delta
		_position_walkers()


func _position_walkers() -> void:
	var track_width := SPACING * walkers.size()
	for index in walkers.size():
		var start_x := 890.0 - index * SPACING
		walkers[index].position.x = roundf(
			OFFSCREEN_LEFT + fposmod(start_x + distance - OFFSCREEN_LEFT, track_width)
		)


func _finish_take() -> void:
	walking = false
	for index in walk_animations.size():
		walk_animations[index].play(&"Idle" if index == 0 else &"idle")
