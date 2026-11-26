shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_softness: hint_range(0.0, 0.6, 0.01) = 0.5;
uniform float registration_offset: hint_range(0.0, 8.0, 0.25) = 0.0;

uniform sampler2D wave_mask;
uniform float black_dot_transition: hint_range(0.5, 2.0) = 1.0;

uniform vec4 fill_colour: source_color = vec4(1.0);
uniform float fill_height: hint_range(0.0, 1.0) = 0.1;
uniform float max_offset = 0.14;
uniform float min_offset = 0.84;
uniform float wave_freq = 4.0;
uniform float wave_band = 0.05;
uniform float wave_speed = 0.4;

varying float alpha;

void fragment() {
	float lo = min(min_offset, max_offset);
	float hi = max(min_offset, max_offset);
	float edge = lo + clamp(1.0 - fill_height, 0.0, 1.0) * max(hi - lo, 1e-5);

	if (UV.y > edge) alpha = 0.0;

	ivec2 tex_size = textureSize(TEXTURE, 0);
	vec2 pixel_size = 1.0 / vec2(tex_size);
	vec2 subpixel_padding = pixel_size * 1.0;
	vec2 padded_uv = clamp(UV, subpixel_padding, vec2(1.0) - subpixel_padding);

	vec4 tex = texture(TEXTURE, padded_uv);
	vec3 colour = tex.rgb * fill_colour.rgb;

	vec2 point = UV / pixel_size;
	float spacing = 1.5;
	vec3 halftone_rgb = cmyk_paper_color(cmyk_screen_color(point, spacing, colour, registration_offset, dot_softness)) * cmyk_scene_fade(black_dot_transition);

	alpha = tex.a;

	vec2 wave_uv;
	wave_uv.x = fract(UV.x * wave_freq + TIME * fill_colour.r * wave_speed);
	wave_uv.y = clamp((UV.y - (edge - wave_band)) / max(wave_band, 1e-4), 0.0, 1.0);
	alpha *= texture(wave_mask, wave_uv).a;

	COLOR = vec4(halftone_rgb, alpha);
}
