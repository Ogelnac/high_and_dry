extends Node2D

@onready var popup: Sprite2D = $Popup
@onready var popup_player: AnimationPlayer = $Popup/AnimationPlayer
@onready var cocoon: Sprite2D = $Cocoon
@onready var moth: Sprite2D = $Moth
@onready var detection_area: Area2D = $DetectionArea
@onready var tap_button: Area2D = $TapButton
@onready var player: CharacterBody2D = $"../Player"

const SILKWORM = preload("uid://dhw77tfxqxkhq")

var player_in_area: bool = false
var moth_mother_hatched: bool = false

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)

	GameManager.load_game()
	if GameManager.game_progress:
		moth_mother_hatched = GameManager.game_progress.get("moth_mother_hatched")

	if moth_mother_hatched:
		_hatched()
	else:
		cocoon.frame = 0
		cocoon.get_node("AnimationPlayer").play("cocoon_idle")
		detection_area.monitoring = false

func _input(event: InputEvent) -> void:# remove and make game work
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_M:
			GameManager.game_progress.set("moth_mother_hatched", true)
			GameManager.save()
			_hatched()

func is_confirm_input(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch or event is InputEventMouseButton) \
		and event.pressed \
		and (not event is InputEventMouseButton or event.button_index == MOUSE_BUTTON_LEFT)

func _hatched() -> void:
	cocoon.frame = 1
	cocoon.get_node("AnimationPlayer").stop()
	moth.visible = true
	moth.get_node("AnimationPlayer").play("cloaked_idle")
	detection_area.monitoring = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		popup.visible = true
		popup_player.play("OpenPopup")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		popup.visible = false

func _on_tap_button_input_event(_viewport, event, _shape_idx):
	if is_confirm_input(event) and player_in_area:
		if GameManager.silk_worms > 0 or Debug.infinite_silkworms:
			DialogueManager.start_dialogue("moth_give_silkworm", false)
			GameManager.silk_worms -= 1
			GameManager.save()
			var inst = SILKWORM.instantiate()
			inst.held = true
			get_tree().root.get_node("Main").add_child(inst)
			player.carrying_silkworm = true
		else:
			DialogueManager.start_dialogue("moth_no_silkworm", false)
