extends Node

var active: bool = false

var accumulators: Dictionary[String, float] = {
	"Red": 0.0,
	"Orange": 0.0,
	"Yellow": 0.0,
	"Green": 0.0,
	"Blue": 0.0,
	"Pink": 0.0,
	"White": 0.0,
	"Brown": 0.0
}

var dye_cost_per_fabric: int = 10
var storage_cap: int:
	get:
		return GameManager.fabric_pile_storage_max

func set_active(v: bool) -> void:
	active = v

func _process(delta: float) -> void:
	if not active:
		return

	for color in GameManager.COLOR_ORDER:
		if GameManager.get_fabric_pile_amount(color) >= storage_cap:
			accumulators[color] = 0.0
			continue

		var dye_amt: int = GameManager.get_dye_amount(color)
		if dye_amt < dye_cost_per_fabric:
			accumulators[color] = 0.0
			continue

		var worms: int = GameManager.get_silkworm_amount(color)
		var rate_per_minute: int = int(float(worms) / 3.0)
		if rate_per_minute <= 0:
			accumulators[color] = 0.0
			continue

		accumulators[color] += (float(rate_per_minute) / 60.0) * delta

		while accumulators[color] >= 1.0:
			if GameManager.get_fabric_pile_amount(color) >= storage_cap:
				accumulators[color] = 0.0
				break

			dye_amt = GameManager.get_dye_amount(color)
			if dye_amt < dye_cost_per_fabric:
				accumulators[color] = 0.0
				break

			accumulators[color] -= 1.0
			GameManager.decrease_dye_amount(color, dye_cost_per_fabric)
			GameManager.increase_fabric_pile_amount(color, 1)
