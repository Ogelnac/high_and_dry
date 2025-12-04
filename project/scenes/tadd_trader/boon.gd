extends Node2D

@export var speed: float = 5.0
@export var float_distance: float = 2.0
@export var phase: float = 1.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var tap_button: Area2D = $TapButton
@onready var popup: Sprite2D = $Popup
@onready var popup_animation: AnimationPlayer = $Popup/AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea

var theta: float = 0.0
var player_in_area: bool = false

func _ready() -> void:
	popup.visible = false
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	tap_button.input_event.connect(_on_tap_button_input_event)

func _process(delta: float) -> void:
	theta += speed * delta
	sprite_2d.position.y =  sin(theta + phase * PI) * float_distance

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		popup.visible = true
		popup_animation.play("OpenPopup")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if popup_animation.is_playing():
			popup_animation.stop()
			popup.visible = false
		else:
			popup.visible = false

func is_confirm_input(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch or event is InputEventMouseButton) \
		and event.pressed \
		and (not event is InputEventMouseButton or event.button_index == MOUSE_BUTTON_LEFT)

func _on_tap_button_input_event(_viewport, event, _shape_idx):
	if is_confirm_input(event) and player_in_area:
		var shop_item: ShopManager.ShopItem = get_meta("shop_item")
		var sprite2d = get_node("Sprite2D")
		ShopManager.display_box(sprite2d, shop_item)
