extends Area2D

var searching := false

func _ready() -> void:
	if has_node("../../../PlayerHost"):
		var player_host = get_node("../../../PlayerHost")
		player_host.launch_zone = self

func _process(_delta):
	if searching:
		var player = get_node_or_null("../../../Player")
		if player:
			player.launch_zone = self
			searching = false
