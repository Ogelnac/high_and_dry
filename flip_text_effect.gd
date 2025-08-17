extends RichTextEffect
class_name FlipTextEffect

var bbcode = "flip"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.transform = char_fx.transform.rotated_local(PI)
	char_fx.transform.origin -= Vector2(-8.0, 8.0)
	return true
