shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float registration_offset: hint_range(0.0, 8.0, 0.25) = 0.0;

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;

uniform sampler2D diffraction: source_color;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float diffraction_strength = 1.0;

void fragment() {
	ivec2 tex_size = textureSize(TEXTURE, 0);
	vec2 pixel_size = 1.0 / vec2(tex_size);
	vec2 subpixel_padding = pixel_size * 1.0;
	vec2 padded_uv = clamp(UV, subpixel_padding, vec2(1.0) - subpixel_padding);

	vec4 tex = texture(TEXTURE, padded_uv);

	float out_a = COLOR.a * alpha_effect;

	vec2 centred_uv = UV - vec2(0.32);

	vec3 diff = texture(diffraction, UV).rgb;

	vec2 direction = centred_uv;
	vec2 screen_offset = direction * -diff.r * SCREEN_PIXEL_SIZE * diffraction_strength;

	vec3 screen_sample = texture(SCREEN_TEXTURE, SCREEN_UV + screen_offset).rgb;

	vec3 combine = mix(tex.rgb, screen_sample, 0.25);

	float black_ink = black_dot_transition - max(combine.r, max(combine.g, combine.b));
	vec3 halftone_rgb = cmyk_texture_color(UV / pixel_size, 2.0, combine, black_ink, registration_offset);
	COLOR = vec4(halftone_rgb, out_a);
}