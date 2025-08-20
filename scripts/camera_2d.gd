extends Camera2D

@export var market_min_y: float = -396.0
@export var market_max_y: float = 70.0
@export var weavers_min_x: float = 190.0
@export var weavers_max_x: float = 610.0

@export var fade_duration: float = 1.0
@export var music_mute: bool = false
signal start_music_mute(new_state)

var is_in_market: bool = false
var is_in_weavers: bool = false
var player: Node2D = null

@onready var landing_zone: Area2D = $"../LandingZone"
@onready var hub: Area2D = $"../Hub"
@onready var trophy_room: Area2D = $"../TrophyRoom"
@onready var weavers: Area2D = $"../Weavers"
@onready var market: Area2D = $"../Market"

@onready var track1: AudioStreamPlayer2D = $Track1
@onready var track2: AudioStreamPlayer2D = $Track2
@onready var track3: AudioStreamPlayer2D = $Track3
@onready var ui: Control = $"../CanvasLayer/UI"

@onready var parallax_array: Array[Node2D] = [
	$"../Background",
	$"../MidBackground",
	$"../ForeGround",
	$"../TownBeauty"]

var current_track: AudioStreamPlayer2D = null
var active_timer: Timer = null

func _ready() -> void:
	connect("start_music_mute", Callable(ui, "_on_camera_2d_start_music_mute"))
	emit_signal("start_music_mute", music_mute)
	_initialize_tracks()

func _initialize_tracks() -> void:
	track1.volume_db = _get_muted_volume(0)
	track2.volume_db = _get_muted_volume(-50)
	track3.volume_db = _get_muted_volume(-50)
	track1.play()
	track2.play()
	track3.play()
	current_track = track1

func _on_market_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position.x = market.global_position.x
		is_in_market = true
		is_in_weavers = false
		player = body
		transition_to_track(track2)
		_reset_parallax(market.global_position)

func _on_hub_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = hub.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		transition_to_track(track1)
		_reset_parallax(hub.global_position)

func _on_landing_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = landing_zone.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		transition_to_track(track3)
		_reset_parallax(landing_zone.global_position)

func _on_trophy_room_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = trophy_room.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		transition_to_track(track1)
		_reset_parallax(trophy_room.global_position)

func _on_weavers_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = weavers.global_position
		is_in_market = false
		is_in_weavers = true
		player = body
		transition_to_track(track1)
		_reset_parallax(weavers.global_position)

func transition_to_track(new_track: AudioStreamPlayer2D) -> void:
	if current_track == new_track:
		return

	if active_timer and active_timer.is_inside_tree():
		active_timer.queue_free()

	current_track = new_track
	fade_music(new_track)

func fade_music(target_track: AudioStreamPlayer2D) -> void:
	for track in [track1, track2, track3]:
		if track != target_track:
			track.volume_db = max(track.volume_db, _get_muted_volume(-50))

	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(Callable(self, "_on_fade_timer_timeout").bind(target_track, timer))
	timer.start()
	active_timer = timer

func _on_fade_timer_timeout(target_track: AudioStreamPlayer2D, timer: Timer) -> void:
	var fade_step = 50 * 0.05 / fade_duration
	var is_fade_complete = true

	for track in [track1, track2, track3]:
		if track != target_track and track.volume_db > _get_muted_volume(-50):
			track.volume_db -= fade_step
			is_fade_complete = false

	if target_track.volume_db < _get_muted_volume(0):
		target_track.volume_db += fade_step
		is_fade_complete = false

	if is_fade_complete:
		for track in [track1, track2, track3]:
			if track != target_track:
				track.volume_db = _get_muted_volume(-50)
		target_track.volume_db = _get_muted_volume(0)
		timer.queue_free()
		active_timer = null

func _mute_all_tracks() -> void:
	emit_signal("start_music_mute", music_mute)
	for track in [track1, track2, track3]:
		track.volume_db = _get_muted_volume(track.volume_db)

func _unmute_all_tracks() -> void:
	emit_signal("start_music_mute", music_mute)

	# Ensure all tracks are at their default low volume
	for track in [track1, track2, track3]:
		track.volume_db = -50

	# If there's a current track, fade it back in immediately
	if current_track:
		current_track.volume_db = 0  # Ensure it's the active track
		fade_music(current_track)  # Resume normal transition behavior

func _get_muted_volume(normal_volume: float) -> float:
	"""Returns a modified volume that respects mute but allows transitions."""
	return -80.0 if music_mute else normal_volume

func _physics_process(_delta: float) -> void:
	if is_in_market and player:
		global_position.y = clamp(player.global_position.y - 160, market_min_y, market_max_y)

	if is_in_weavers and player:
		global_position.x = clamp(player.global_position.x, weavers_min_x, weavers_max_x)

func _on_ui_music_mute_toggled(new_state: bool) -> void:
	music_mute = new_state

	if music_mute:
		_mute_all_tracks()
	else:
		_unmute_all_tracks()

func _reset_parallax(new_position: Vector2):
	for parallax in parallax_array:
		parallax._reset_reference(new_position)
