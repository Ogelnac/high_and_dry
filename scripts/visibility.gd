extends Node2D

# Enables any node on start (used for collision shapes as their UI is annoying)

func _ready():
	if has_method("show"):
		show()
