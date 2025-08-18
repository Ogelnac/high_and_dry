extends RichTextEffect
class_name MossTongueEffect

var bbcode = "moss_type"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var seed := int(char_fx.env.get("seed", 0))
	var intensity := float(char_fx.env.get("intensity", 1.0))
	var wobble := float(char_fx.env.get("wobble", 1.0))

	var idx := char_fx.relative_index + seed * 131

	var a := _hash01(idx) * 2.0 - 1.0
	var angle := a * 0.9 * intensity
	char_fx.transform = char_fx.transform.rotated_local(angle)

	var t := char_fx.elapsed_time
	var ox := (_hash01(idx + 17) - 0.5) * 8.0 * intensity + sin(t * 2.1 + float(idx)) * 3.0 * wobble
	var oy := (_hash01(idx + 29) - 0.5) * 6.0 * intensity + cos(t * 1.8 + float(idx)) * 2.0 * wobble
	char_fx.transform.origin += Vector2(ox, oy)

	var s := 1.0 + (_hash01(idx + 53) - 0.5) * 0.5 * intensity
	char_fx.transform = char_fx.transform.scaled_local(Vector2(s, s))

	var alpha := 0.85 + _hash01(idx + 71) * 0.15
	char_fx.color.a *= alpha
	return true

func _hash01(x: int) -> float:
	var f := sin(float(x) * 12.9898) * 43758.5453
	return f - floor(f)
