extends Node2D

@onready var head: Sprite2D = $Head
@onready var body: Sprite2D = $Body
@onready var animation_player: AnimationPlayer = $Body/AnimationPlayer

@export_enum(
	"Salvador",
	"Cotton",
	"Silkvester",
	"Cordu Roy",
	"Aknitta",
	"Paisley",
	"Lintford",
	"Velcroc",
	"Taratan",
	"Florali",
	"Crocargyle",
	"Candycrane",
	"Herringbone",
	"Ikatxolot",
	"Ombracoon",
	"Pinstripe",
	"Nyanlon",
	"Spanducks"
)
var villager_name: String = "Salvador":
	set(value):
		villager_name = value
		if is_inside_tree():
			_apply_villager()

const VILLAGERS: Dictionary = {
	"Salvador": {"type": "Fox", "personality": "Posh", "colour": "Red"},
	"Cotton": {"type": "Rabbit", "personality": "Shy/Anxious", "colour": "White"},
	"Silkvester": {"type": "Deer", "personality": "Posh", "colour": "Yellow"},
	"Cordu Roy": {"type": "Lizard", "personality": "Smarty Pants", "colour": "Green"},
	"Aknitta": {"type": "Ant", "personality": "Gloomy", "colour": "Brown"},
	"Paisley": {"type": "Badger", "personality": "Sleepy", "colour": "Blue"},
	"Lintford": {"type": "Duck", "personality": "Normal", "colour": "Orange"},
	"Velcroc": {"type": "Crocodile", "personality": "Aggressive", "colour": "Brown"},
	"Taratan": {"type": "Rat", "personality": "Friendly", "colour": "Blue"},
	"Florali": {"type": "Chick", "personality": "Shy/Anxious", "colour": "Yellow"},
	"Crocargyle": {"type": "Crocodile", "personality": "Smarty Pants", "colour": "White"},
	"Candycrane": {"type": "Crow", "personality": "Rude", "colour": "Pink"},
	"Herringbone": {"type": "Crow", "personality": "Distracted", "colour": "Red"},
	"Ikatxolot": {"type": "Axolotl", "personality": "Distracted", "colour": "Pink"},
	"Ombracoon": {"type": "Raccoon", "personality": "Friendly", "colour": "Green"},
	"Pinstripe": {"type": "Badger", "personality": "Rude", "colour": "Orange"},
	"Nyanlon": {"type": "Rabbit", "personality": "Friendly", "colour": "Yellow"},
	"Spanducks": {"type": "Duck", "personality": "Smarty Pants", "colour": "Brown"}
}

const HEAD_FRAME_BY_TYPE: Dictionary = {
	"Rat": 1,
	"Rabbit": 2,
	"Badger": 3,
	"Fox": 4,
	"Raccoon": 5,
	"Deer": 6,
	"Ant": 7,
	"Crocodile": 8,
	"Axolotl": 9,
	"Lizard": 10,
	"Duck": 11,
	"Chick": 12,
	"Crow": 13
}

const BODY_TYPE_BY_ANIMAL: Dictionary = {
	"Rat": "no_stripe",
	"Raccoon": "no_stripe",
	"Rabbit": "no_stripe",
	"Badger": "stripe",
	"Fox": "stripe",
	"Deer": "stripe",
	"Ant": "insect",
	"Crocodile": "tail",
	"Axolotl": "tail",
	"Lizard": "tail",
	"Duck": "bird",
	"Chick": "bird",
	"Crow": "bird"
}

var _is_running: bool = false
var _current_body_type: String = "stripe"

func _ready() -> void:
	_apply_villager()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R:
			_toggle_run()

func _toggle_run() -> void:
	_is_running = not _is_running
	_play_current_anim()

func _apply_villager() -> void:
	if not VILLAGERS.has(villager_name):
		return

	var data: Dictionary = VILLAGERS[villager_name]
	var animal_type: String = String(data.get("type", "Rat"))
	var colour_name: String = String(data.get("colour", "White"))

	if HEAD_FRAME_BY_TYPE.has(animal_type):
		head.frame = int(HEAD_FRAME_BY_TYPE[animal_type])

	_current_body_type = String(BODY_TYPE_BY_ANIMAL.get(animal_type, "stripe"))

	var hex: String = ""
	if GameManager.COLOR_HEX.has(colour_name):
		hex = String(GameManager.COLOR_HEX[colour_name])

	if hex != "":
		var c: Color = Color.html(hex)
		head.modulate = c
		body.modulate = c

	_is_running = false
	_play_current_anim()

func _play_current_anim() -> void:
	var suffix: String = "run" if _is_running else "idle"
	var anim_name: String = _current_body_type + "_" + suffix
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
