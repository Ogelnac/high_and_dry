extends RefCounted

const SECONDS_TO_CLOSE := 1.0 / 0.6


static func close(circle: ColorRect, center: Callable, hold_seconds: float) -> void:
	var material := circle.material as ShaderMaterial
	material.set_shader_parameter("transition_location", center.call())
	material.set_shader_parameter("transition_value", 0.0)
	circle.show()

	var tween := circle.create_tween()
	tween.tween_method(func(value: float) -> void:
		material.set_shader_parameter("transition_location", center.call())
		material.set_shader_parameter("transition_value", value)
	, 0.0, 1.0, SECONDS_TO_CLOSE)
	await circle.get_tree().create_timer(hold_seconds).timeout
	tween.kill()


static func change_scene(canvas: CanvasLayer, scene_file: String) -> void:
	var circle: ColorRect = canvas.get_node("UI/CircleFade")
	var tree := canvas.get_tree()
	await close(circle, func() -> Vector2: return Vector2(canvas.get_window().size) / 2.0, 3.0)
	if is_instance_valid(canvas) and canvas.is_inside_tree():
		tree.change_scene_to_file(scene_file)
