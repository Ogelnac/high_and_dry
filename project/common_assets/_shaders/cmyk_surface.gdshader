shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float registration_offset: hint_range(0.0, 8.0, 0.25) = 0.0;
uniform float dot_softness: hint_range(0.0, 0.6, 0.01) = 0.5;

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;
uniform bool continuous_tile_grid = false;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 point = continuous_tile_grid ? world_position : UV / TEXTURE_PIXEL_SIZE;
	float spacing = 1.5;
	float pixel_width = max(length(dFdx(point)), length(dFdy(point)));
	float softness = clamp(max(dot_softness, 0.5 * pixel_width / spacing), 0.000001, 0.6);
	vec3 colour = COLOR.rgb;

	vec3 cmyk_rgb = cmyk_paper_color(cmyk_screen_color(point, spacing, colour, registration_offset, softness)) * cmyk_scene_fade(black_dot_transition);
	float cmyk_a = COLOR.a * alpha_effect;

	COLOR = vec4(cmyk_rgb, cmyk_a);
}
