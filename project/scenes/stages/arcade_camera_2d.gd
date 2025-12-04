extends Camera2D

@onready var player: Node2D = $"../PlayerHost"

var interim: bool = false

func _process(_delta: float) -> void:
	if not interim:
		global_position.y = player.global_position.y - 120.0
		global_position.x = player.global_position.x * 0.01
