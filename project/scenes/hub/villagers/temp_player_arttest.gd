extends AnimationPlayer

var _is_running:bool = false

func _ready() -> void:
	_play_current_anim()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R:
			_toggle_run()

func _toggle_run() -> void:
	_is_running = not _is_running
	_play_current_anim()

func _play_current_anim() -> void:
	var suffix: String = "run" if _is_running else "idle"
	var anim_name: String = "no_stripe_" + suffix
	if has_animation(anim_name):
		play(anim_name)
