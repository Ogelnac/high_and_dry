extends Panel

@onready var menu: Button = $"../HBoxContainer/Menu"

@onready var check_box: CheckBox = $VBoxContainer/CheckBox
@onready var check_box_2: CheckBox = $VBoxContainer/CheckBox2
@onready var check_box_3: CheckBox = $VBoxContainer/CheckBox3
@onready var button: Button = $VBoxContainer/Button
@onready var button_2: Button = $VBoxContainer/Button2

const TEST_AUDIO = preload("uid://d4mg7pipglpkh")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu.pressed.connect(_toggle_panel_visibility)
	check_box.toggled.connect(_mute_music)
	check_box_2.toggled.connect(_mute_sfx)
	check_box_3.toggled.connect(_donate_to_devs)
	button.pressed.connect(_test_bgm)
	button_2.pressed.connect(_test_sfx)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _toggle_panel_visibility():
	visible = !visible

func _mute_music(_toggled_on: bool) -> void:
	AudioServer.set_bus_mute(1, _toggled_on)

func _mute_sfx(_toggled_on: bool) -> void:
	AudioServer.set_bus_mute(2, _toggled_on)

func _donate_to_devs(_toggled_on: bool) -> void:
	check_box_3.button_pressed = true
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
