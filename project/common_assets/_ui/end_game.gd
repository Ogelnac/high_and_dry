extends Button

func _ready() -> void:
	pressed.connect(end_game)

func end_game():
	#Debug.game_ended = true
	pass
