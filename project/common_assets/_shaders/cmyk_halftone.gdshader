shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_softness: hint_range(0.0, 0.6, 0.01) = 0.5;
uniform float registration_offset: hint_range(0.0, 8.0, 0.25) = 0.0;

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	vec3 colour = COLOR.rgb;

	float black_ink = black_dot_transition - max(colour.r, max(colour.g, colour.b));
	vec2 point = UV / pixel_size;
	float spacing = 1.5;
	vec3 cmyk_rgb = cmyk_texture_color(point, spacing, colour, black_ink, registration_offset, dot_softness);
	float cmyk_a = COLOR.a * alpha_effect;

	COLOR = vec4(cmyk_rgb, cmyk_a);
}
