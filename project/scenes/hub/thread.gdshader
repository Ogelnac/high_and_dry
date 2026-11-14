shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float registration_offset: hint_range(0.0, 8.0, 0.25) = 0.0;

uniform vec4 fill_colour: source_color = vec4(1.0);

uniform float thread1_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread2_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread3_slider: hint_range(0.0, 1.0, 0.01);

uniform vec4 region_rect = vec4(128.0, 0.0, 64.0, 128.0);

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;

float thread_region_mask(vec2 uv, vec2 tex_pix_size) {
	vec2 tex_size = 1.0 / tex_pix_size;
	vec2 pixel = uv * tex_size;
	vec2 uv_region = (pixel - region_rect.xy) / region_rect.zw;

	float mask = 0.0;

	if (uv_region.x < 1.0 / 3.0) {
		mask = step(uv_region.y, thread1_slider);
	} else if (uv_region.x < 2.0 / 3.0) {
		mask = step(uv_region.y, thread2_slider);
	} else {
		mask = step(uv_region.y, thread3_slider);
	}

	return mask;
}

void fragment() {
	ivec2 tex_size = textureSize(TEXTURE, 0);
	vec2 pixel_size = 1.0 / vec2(tex_size);
	vec2 subpixel_padding = pixel_size * 1.0;
	vec2 padded_uv = clamp(UV, subpixel_padding, vec2(1.0) - subpixel_padding);

	vec4 tex = texture(TEXTURE, padded_uv);

	vec4 base = tex * fill_colour * COLOR;
	vec3 colour = base.rgb;

	float black_ink = black_dot_transition - max(colour.r, max(colour.g, colour.b));
	vec3 cmyk_rgb = cmyk_texture_color(UV / pixel_size, 2.0, colour, black_ink, registration_offset);
	float cmyk_a = base.a * alpha_effect;

	float mask = thread_region_mask(UV, TEXTURE_PIXEL_SIZE);

	COLOR = vec4(cmyk_rgb * mask, cmyk_a * mask);
}
