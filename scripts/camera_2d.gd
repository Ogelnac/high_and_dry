extends Camera2D

@export var market_min_y: float = -396.0
@export var market_max_y: float = 70.0
@export var weavers_min_x: float = 190.0
@export var weavers_max_x: float = 610.0

var is_in_market: bool = false
var is_in_weavers: bool = false
var player: Node2D = null

@onready var landing_zone: Area2D = $"../LandingZone"
@onready var hub: Area2D = $"../Hub"
@onready var trophy_room: Area2D = $"../TrophyRoom"
@onready var weavers: Area2D = $"../Weavers"
@onready var market: Area2D = $"../Market"

@onready var ui: Control = $"../CanvasLayer/UI"

@onready var parallax_array: Array[Node2D] = [
	$"../Background",
	$"../MidBackground",
	$"../ForeGround",
	$"../ForeGround",
	$"../Pachinko",
	$"../TownBeauty",
	$"../Title",
	$"../Water",
	$"../Ink",
	$"../Lava",
	$"../Sewage"]

func _on_market_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position.x = market.global_position.x
		is_in_market = true
		is_in_weavers = false
		player = body
		_reset_parallax(market.global_position)

func _on_hub_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = hub.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		_reset_parallax(hub.global_position)

func _on_landing_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = landing_zone.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		_reset_parallax(landing_zone.global_position)

func _on_trophy_room_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = trophy_room.global_position
		is_in_market = false
		is_in_weavers = false
		player = null
		_reset_parallax(trophy_room.global_position)

func _on_weavers_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		global_position = weavers.global_position
		is_in_market = false
		is_in_weavers = true
		player = body
		_reset_parallax(weavers.global_position)

func _physics_process(_delta: float) -> void:
	if is_in_market and player:
		global_position.y = clamp(player.global_position.y - 160, market_min_y, market_max_y)

	if is_in_weavers and player:
		global_position.x = clamp(player.global_position.x, weavers_min_x, weavers_max_x)

func _reset_parallax(new_position: Vector2):
	for parallax in parallax_array:
		parallax._reset_reference(new_position)
