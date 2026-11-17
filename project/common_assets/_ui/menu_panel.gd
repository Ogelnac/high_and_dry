extends PanelContainer

@onready var check_box: CheckBox = $MarginContainer/VBoxContainer/CheckBox
@onready var check_box_2: CheckBox = $MarginContainer/VBoxContainer/CheckBox2
@onready var check_box_3: CheckBox = $MarginContainer/VBoxContainer/CheckBox3
@onready var button: Button = $MarginContainer/VBoxContainer/Button
@onready var button_2: Button = $MarginContainer/VBoxContainer/Button2

const TEST_AUDIO = preload("uid://d4mg7pipglpkh")

func _ready() -> void:
	check_box.set_pressed_no_signal(AudioServer.is_bus_mute(1))
	check_box_2.set_pressed_no_signal(AudioServer.is_bus_mute(2))
	check_box.toggled.connect(_mute_music)
	check_box_2.toggled.connect(_mute_sfx)
	check_box_3.toggled.connect(_donate_to_devs)
	button.pressed.connect(_test_bgm)
	button_2.pressed.connect(_test_sfx)

func _mute_music(_toggled_on: bool) -> void:
	AudioServer.set_bus_mute(1, _toggled_on)

func _mute_sfx(_toggled_on: bool) -> void:
	AudioServer.set_bus_mute(2, _toggled_on)

func _donate_to_devs(_toggled_on: bool) -> void:
	check_box_3.set_pressed_no_signal(true)
	check_box_3.text = "No take backs!"
	
func _test_bgm() -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.set_bus("Bgm")
	audio_player.stream = TEST_AUDIO
	audio_player.volume_linear = 0.1
	audio_player.autoplay = true
	get_parent().add_child(audio_player)

func _test_sfx() -> void:
	var audio_player = AudioStreamPlayer.new()
	audio_player.set_bus("Sfx")
	audio_player.stream = TEST_AUDIO
	audio_player.volume_linear = 0.1
	audio_player.autoplay = true
	get_parent().add_child(audio_player)
