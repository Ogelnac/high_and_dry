extends Node2D

@onready var popup: Sprite2D = $Popup
@onready var popup_player: AnimationPlayer = $Popup/AnimationPlayer
@onready var cocoon: Sprite2D = $Cocoon
@onready var moth: Sprite2D = $Moth
@onready var detection_area: Area2D = $DetectionArea

var moth_mother_hatched: bool = false

func _ready() -> void:
	moth_mother_hatched = GameManager.game_progress.get("moth_mother_hatched")
	
	if moth_mother_hatched:
		cocoon.frame = 1
		cocoon.get_node("AnimationPlayer").stop()
		moth.visible = true
		moth.get_node("AnimationPlayer").play("cloaked_idle")
		detection_area.visible = true
	else:
		cocoon.frame = 0
		cocoon.get_node("AnimationPlayer").play("cocoon_idle")

# remove and make game work
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_M:
			GameManager.game_progress.set("moth_mother_hatched", true)
			moth_mother_hatched = GameManager.game_progress.get("moth_mother_hatched")
			GameManager.save()
			_ready()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		popup.visible = true
		popup_player.play("OpenPopup")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		popup.visible = false
