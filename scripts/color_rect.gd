extends ColorRect

@onready var shader_material: ShaderMaterial = material

func _ready():
	update_shader_size()
	connect("resized", _on_resized)

func update_shader_size():
	if shader_material:
		shader_material.set_shader_parameter("colorrect_size", size)

func _on_resized():
	update_shader_size()
