extends RichTextEffect
class_name MossTongueEffect

var bbcode = "moss_type"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var size: Vector2i = char_fx.env.get("size", Vector2i(28, 28))
	var idx := char_fx.relative_index + 131
	var glyph := char_fx.glyph_index
	var ts := TextServerManager.get_primary_interface()
	var font_rid := char_fx.font
	var glyph_size := ts.font_get_glyph_size(font_rid, size, glyph)

	var flip_h := _hash01(idx) < 0.5

	var xform := char_fx.transform

	if flip_h:
		xform = xform.scaled_local(Vector2(-1, 1))
		xform = xform.translated(Vector2(glyph_size.x/2.0, 0.0))
	else:
		xform = xform.scaled_local(Vector2(1, -1))
		xform = xform.translated(Vector2(0.0, -glyph_size.y/2.0))

	char_fx.transform = xform
	return true

func _hash01(x: int) -> float:
	var f := sin(float(x) * 12.9898) * 43758.5453
	return f - floor(f)
