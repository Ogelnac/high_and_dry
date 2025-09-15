extends Node2D

@export var normal_sheet: Texture2D
@export var normal_hframes: int = 3
@export var normal_vframes: int = 3
@export var boost_sheet: Texture2D
@export var boost_hframes: int = 8
@export var boost_vframes: int = 2

class BoonDef:
	var id:int
	var probability:int
	var boon_name:String
	var description:String
	var cost:int
	var currencies:Array[int]
	var sprite_frame:int
	var use_alt_sheet:bool

class BoostBoonDef:
	var id:int
	var probability:int
	var type:int
	var description_template:String
	var cost:int
	var sprite_frame:int

@onready var player: CharacterBody2D = $Player
@onready var boons: Array[Node2D] = [$Boon1,$Boon2,$Boon3]

var colour_names:Array[String] = [
	"Red",
	"Orange",
	"Yellow",
	"Green",
	"Blue",
	"Pink",
	"White",
	"Brown"]

var normal_defs:Array[BoonDef] = []
var boost_defs:Array[BoostBoonDef] = []

func _ready() -> void:
	randomize()
	DialogueManager.dialogue_box = $CanvasLayer/UI/DialogueBox
	DialogueManager.player = $Player
	DialogueManager.dialogue_input = $CanvasLayer/DialogueInput

	GameManager.get_ui_reference()
	GameManager.load_game()
	GameManager.shop_UI()

	ShopManager.player = $Player
	ShopManager.get_ui_reference()

	_init_item_defs()
	var picks := _pick_unique_items(3)
	_apply_shop_selection(picks)

func _init_item_defs() -> void:
	normal_defs = []
	normal_defs.append(_mk_boon(1,1,"Multi Needle","Throw two needles at once.",100,[0,1,2,3,4,5,6,7],0,false))
	normal_defs.append(_mk_boon(2,1,"Jetpack","Fly for a while, great when your're in a pinch.",100,[0,1,2,3,4,5,6,7],1,false))
	normal_defs.append(_mk_boon(3,1,"Deep Breath","Last longer without air.",100,[0,1,2,3,4,5,6,7],2,false))
	normal_defs.append(_mk_boon(4,1,"Resource Magnet","Attract nearby resources.",100,[0,1,2,3,4,5,6,7],3,false))
	normal_defs.append(_mk_boon(5,1,"2x","Each resource is worth double. Lasts 60s.",100,[0,1,2,3,4,5,6,7],4,false))
	normal_defs.append(_mk_boon(6,1,"4x","Each resource is worth quadrouple! Lasts 60s.",200,[0,1,2,3,4,5,6,7],5,false))
	normal_defs.append(_mk_boon(7,0,"Square Px","Undetermined.",100,[0,1,2,3,4,5,6,7],6,false))
	normal_defs.append(_mk_boon(8,0,"Triangle Px","Undetermined.",100,[0,1,2,3,4,5,6,7],7,false))
	normal_defs.append(_mk_boon(9,0,"Circle Px","Undetermined.",100,[0,1,2,3,4,5,6,7],8,false))
	boost_defs = []
	for t in range(8):
		var b := BoostBoonDef.new()
		b.id = 100 + t
		b.type = t
		b.probability = 1
		var colour_name := colour_names[t]
		var hex := str(GameManager.COLOR_HEX.get(colour_name, "#FFFFFF"))
		b.description_template = "An increased chance of finding [color=" + hex + "]" + colour_name + "[/color] resources."
		b.cost = 100
		b.sprite_frame = t
		boost_defs.append(b)

func _mk_boon(id:int,prob:int,boon_name:String,desc:String,cost:int,currencies:Array[int],sprite_frame:int,use_alt:bool) -> BoonDef:
	var d := BoonDef.new()
	d.id = id
	d.probability = prob
	d.boon_name = boon_name
	d.description = desc
	d.cost = cost
	d.currencies = currencies
	d.sprite_frame = sprite_frame
	d.use_alt_sheet = use_alt
	return d

func _pick_unique_items(n:int) -> Array[ShopManager.ShopItem]:
	var pool_ids = []
	var weights:Array[int] = []
	for d in normal_defs:
		pool_ids.append(["normal", d.id])
		weights.append(max(d.probability, 0))
	for b in boost_defs:
		pool_ids.append(["boost", b.id])
		weights.append(max(b.probability, 0))
	var result:Array[ShopManager.ShopItem] = []
	var k = min(n, pool_ids.size())
	for i in range(k):
		if _weights_total(weights) <= 0:
			break
		var pick_index := _weighted_pick(weights)
		var tag = pool_ids[pick_index][0]
		var sel_id = pool_ids[pick_index][1]
		var item := _resolve_item(tag, sel_id)
		result.append(item)
		pool_ids.remove_at(pick_index)
		weights.remove_at(pick_index)
	return result

func _weights_total(weights:Array[int]) -> int:
	var total := 0
	for w in weights:
		total += w
	return total

func _weighted_pick(weights:Array[int]) -> int:
	var total := _weights_total(weights)
	var r := randi() % total
	var accum := 0
	for i in weights.size():
		accum += weights[i]
		if r < accum:
			return i
	return weights.size() - 1

func _resolve_item(tag:String, sel_id:int) -> ShopManager.ShopItem:
	if tag == "normal":
		for d in normal_defs:
			if d.id == sel_id:
				var s := ShopManager.ShopItem.new()
				s.is_boost = false
				s.id = d.id
				s.item_name = d.boon_name
				s.description = d.description
				s.cost = d.cost
				s.currency = d.currencies[randi() % d.currencies.size()]
				s.sprite_frame = d.sprite_frame
				s.use_alt_sheet = d.use_alt_sheet
				s.type = -1
				return s
	else:
		for b in boost_defs:
			if b.id == sel_id:
				var s2 := ShopManager.ShopItem.new()
				s2.is_boost = true
				s2.id = b.id
				s2.type = b.type
				s2.item_name = colour_names[b.type] + " Boost"
				s2.description = b.description_template
				s2.cost = b.cost
				s2.currency = b.type
				s2.sprite_frame = b.sprite_frame
				s2.use_alt_sheet = true
				return s2
	return ShopManager.ShopItem.new()

func _apply_shop_selection(items:Array[ShopManager.ShopItem]) -> void:
	for i in boons.size():
		var boon_node := boons[i]
		if i < items.size():
			var it:ShopManager.ShopItem = items[i]
			var sprite:Sprite2D = boon_node.get_node("Sprite2D")
			if it.is_boost:
				sprite.texture = boost_sheet
				sprite.hframes = boost_hframes
				sprite.vframes = boost_vframes
			else:
				sprite.texture = normal_sheet
				sprite.hframes = normal_hframes
				sprite.vframes = normal_vframes
			sprite.frame = it.sprite_frame
			boon_node.set_meta("shop_item", it)
			boon_node.visible = true
		else:
			boon_node.visible = false

func leave_shop():
	Debug.switch_player = false
	get_tree().change_scene_to_file("res://arcade_main.tscn")
