extends Sprite2D

@onready var mask: Sprite2D = $Mask
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	var dye_amount = GameManager.get_dye_value(name)
	var bottle_size = GameManager.get_bottle_size(name)
	var mask_material: ShaderMaterial = mask.material
	var fill_height: float = float(dye_amount) / float(bottle_size)

	mask_material.set_shader_parameter("fill_height", fill_height) 
	rich_text_label.text = "[center]" + str(dye_amount)
