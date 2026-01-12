extends Node

var accumulators: Dictionary[String, float] = {
	"Red": 0.0,
	"Orange": 0.0,
	"Yellow": 0.0,
	"Green": 0.0,
	"Blue": 0.0,
	"Pink": 0.0,
	"White": 0.0,
	"Brown": 0.0}

func _process(delta: float) -> void:
	for color in GameManager.COLOR_ORDER:
		if GameManager.is_fabric_pile_full(color):
			accumulators[color] = 0.0
			continue

		var worms: int = GameManager.get_silkworm_amount(color)
		var rate_per_minute: int = int(float(worms) / 3.0)
		if rate_per_minute <= 0:
			continue

		accumulators[color] += (float(rate_per_minute) / 60.0) * delta

		while accumulators[color] >= 1.0 and not GameManager.is_fabric_pile_full(color):
			accumulators[color] -= 1.0
			GameManager.increase_fabric_pile_amount(color, 1)
