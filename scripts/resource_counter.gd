extends Label

func _process(delta: float) -> void:
	text = ":" + str(
		GameManager.red_resources +
		GameManager.blue_resources +
		GameManager.yellow_resources +
		GameManager.orange_resources +
		GameManager.green_resources +
		GameManager.pink_resources +
		GameManager.brown_resources +
		GameManager.white_resources)
