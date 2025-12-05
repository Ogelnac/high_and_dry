extends Node

var shop_box: Panel

var sprite_2d: Sprite2D
var name_label: Label
var description_label: RichTextLabel
var buy: Button
var cancel: Button

var player: CharacterBody2D

class ShopItem:
	var is_boost:bool
	var id:int
	var item_name:String
	var description:String
	var cost:int
	var currency:int
	var sprite_frame:int
	var use_alt_sheet:bool
	var type:int

func get_ui_reference():
	shop_box = get_node("/root/Main/CanvasLayer/ShopBox")

	sprite_2d = shop_box.get_node("Control/Sprite2D")
	name_label = shop_box.get_node("NameLabel")
	description_label = shop_box.get_node("DescriptionLabel")
	buy = shop_box.get_node("Options/Buy")
	cancel = shop_box.get_node("Options/Cancel")

	cancel.pressed.connect(shop_box.hide)

func display_box(sprite: Sprite2D, shop_item: ShopItem):
	player.dialogue_mode = true
	player.virtual_joystick_active = false
	player.virtual_joystick_offset = Vector2.ZERO
	player.virtual_joystick.visible = false

	sprite_2d.texture = sprite.texture
	sprite_2d.hframes = sprite.hframes
	sprite_2d.vframes = sprite.vframes
	sprite_2d.frame = sprite.frame

	name_label.text = shop_item.item_name
	description_label.text = "[center]" + shop_item.description

	var key: String = GameManager.COLOR_ORDER[shop_item.currency]
	var r: Vector4i = GameManager.INGREDIENT_REGIONS[key]
	buy.get_node("RichTextLabel").text = "[center]%d[img width=25 region=%d,%d,%d,%d]uid://bdfnifowl2amv[/img]" % [shop_item.cost, r.x, r.y, r.z, r.w]

	shop_box.show()
