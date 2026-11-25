extends Node

const HIGH_AND_DRY_TRACK_3_DEMO = preload("res://project/common_assets/_audio/music/high_and_dry_track3_demo.wav")
const HIGH_AND_DRY_TRACK_4_DEMO = preload("res://project/common_assets/_audio/music/high_and_dry_track4_demo.wav")

const STEAMBOAT_FOGHORN := preload("res://project/common_assets/_audio/ambient/steamboat_foghorn.wav")
const STEAMBOAT_ENGINE := preload("res://project/common_assets/_audio/ambient/steamboat_engine_loop.wav")
const AMBIENT_SEWAGE = preload("res://project/common_assets/_audio/ambient/ambient_sewage.wav")

const SPLASH_HEAVY = preload("res://project/common_assets/_audio/sfxs/splash_heavy.wav")
const SPLASH_LIGHT = preload("res://project/common_assets/_audio/sfxs/splash_light.wav")
const SPLASH_MEDIUM = preload("res://project/common_assets/_audio/sfxs/splash_medium.wav")

const splashes: Array[AudioStream] = [SPLASH_HEAVY, SPLASH_LIGHT, SPLASH_MEDIUM]

var _arcade_track_position: float = 0.0
var _arcade_track_handoff_usec: int = -1
var _arcade_track: AudioStreamWAV

func _ready() -> void:
	_arcade_track = HIGH_AND_DRY_TRACK_4_DEMO.duplicate()
	_arcade_track.loop_begin = 0
	_arcade_track.loop_end = roundi(_arcade_track.get_length() * _arcade_track.mix_rate) - 1
	_arcade_track.loop_mode = AudioStreamWAV.LOOP_FORWARD

func play_arcade_track(main: Node2D, bus: StringName = &"Bgm") -> void:
	if not is_instance_valid(main) or not main.is_visible_in_tree() or main.has_node("BGM"):
		return

	var bgm := AudioStreamPlayer.new()
	bgm.name = &"BGM"
	bgm.stream = _arcade_track
	bgm.bus = bus
	bgm.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	main.add_child(bgm)

	var position := 0.0
	if _arcade_track_handoff_usec >= 0:
		var elapsed := (Time.get_ticks_usec() - _arcade_track_handoff_usec) / 1000000.0
		position = fposmod(_arcade_track_position + elapsed, _arcade_track.get_length())
		_arcade_track_handoff_usec = -1
	bgm.play(position)

func resume_arcade_track(main: Node2D) -> void:
	if _arcade_track_handoff_usec >= 0:
		play_arcade_track(main)

func change_scene_with_arcade_track(scene_path: String) -> void:
	_arcade_track_handoff_usec = -1
	var bgm := get_tree().current_scene.get_node_or_null("BGM") as AudioStreamPlayer
	if bgm != null and bgm.playing:
		_arcade_track_position = bgm.get_playback_position() + AudioServer.get_time_since_last_mix()
		_arcade_track_handoff_usec = Time.get_ticks_usec()

	if get_tree().change_scene_to_file(scene_path) != OK:
		_arcade_track_handoff_usec = -1

func play_steamboat_audio(boat: Node2D) -> void:
	if not is_instance_valid(boat) or not boat.is_visible_in_tree() or boat.has_node("EngineLoop"):
		return

	var engine := _add_steamboat_player(boat, &"EngineLoop", STEAMBOAT_ENGINE, -16.0, 400.0, 2.0)
	engine.play()

	var foghorn := _add_steamboat_player(boat, &"Foghorn", STEAMBOAT_FOGHORN, 0.0, 1400.0, 1.0)
	foghorn.finished.connect(foghorn.queue_free)
	foghorn.play()

func play_rising_death_audio(rising_death: Node2D) -> void:
	if not is_instance_valid(rising_death) or not rising_death.is_visible_in_tree():
		return

	var ambience := _add_rising_death_player(rising_death, &"Ambience", AMBIENT_SEWAGE, 16.0, 400.0, 2.0)
	ambience.play()

func play_splash_audio(player_host: Node2D) -> void:
	if not is_instance_valid(player_host) or not player_host.is_visible_in_tree():
		return

	var splash := _add_splash_player(player_host, &"Splash", splashes, 0.0)
	splash.finished.connect(splash.queue_free)
	splash.play()

func _add_steamboat_player(boat: Node2D, player_name: StringName, stream: AudioStream, volume_db: float, max_distance: float, attenuation: float) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	player.stream = stream
	player.bus = &"Steamboat"
	player.max_distance = max_distance
	player.attenuation = attenuation
	player.volume_db = volume_db
	boat.add_child(player)
	return player

func _add_rising_death_player(rising_death: TileMapLayer, player_name: StringName, stream: AudioStream, volume_db: float, max_distance: float, attenuation: float) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	player.stream = stream
	player.bus = &"RisingDeath"
	player.max_distance = max_distance
	player.attenuation = attenuation
	player.volume_db = volume_db
	rising_death.add_child(player)
	return player

func _add_splash_player(player_host: Node2D, player_name: StringName, streams: Array[AudioStream], volume_db: float) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	player.stream = streams.get(randi_range(0, streams.size() - 1))
	player.bus = &"RisingDeath"
	player.panning_strength = 0.0
	player.volume_db = volume_db
	player_host.add_child(player)
	return player
