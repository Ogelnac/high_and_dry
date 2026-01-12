shader_type canvas_item;

uniform vec4 fill_colour: source_color = vec4(1.0);

uniform float thread1_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread2_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread3_slider: hint_range(0.0, 1.0, 0.01);

uniform vec4 region_rect = vec4(128.0, 0.0, 64.0, 128.0);

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;
uniform float mix_scale: hint_range(0.0, 1.0) = 0.0;

vec2 fix_aspect(sampler2D tex, vec2 uv) {
	ivec2 tex_size = textureSize(tex, 0);
	float aspect = float(tex_size.y) / float(tex_size.x);
	return uv * vec2(1.0, aspect);
}

float get_dynamic_dot_scale(sampler2D tex) {
	ivec2 tex_size = textureSize(tex, 0);
	vec2 pixel_size = 1.0 / vec2(tex_size);
	return 0.5 / pixel_size.x;
}

float halftone(sampler2D tex, vec2 uv, float angle, float ink_coverage, float dot_radius) {
	uv = fix_aspect(tex, uv);
	uv *= get_dynamic_dot_scale(tex);

	float cs = cos(angle);
	float sn = sin(angle);
	vec2 rotated_uv = vec2(
		uv.x * cs + uv.y * sn,
		uv.x * sn - uv.y * cs
	);

	vec2 grid = fract(rotated_uv) - 0.5;
	float dist = length(grid);

	float radius = dot_radius * ink_coverage;
	float edge = fract(dist);
	return smoothstep(radius - edge, radius + edge, dist);
}

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

	float max_CMY_dot_radius = 0.75;
	float max_k_dot_radius = 1.0;

	float c_dot = halftone(TEXTURE, UV, radians(15.0), (1.0 - colour.r), max_CMY_dot_radius);
	float m_dot = halftone(TEXTURE, UV, radians(60.0), (1.0 - colour.g), max_CMY_dot_radius);
	float y_dot = halftone(TEXTURE, UV, radians(0.0), (1.0 - colour.b), max_CMY_dot_radius);

	float k_ink = black_dot_transition - max(colour.r, max(colour.g, colour.b));
	float k_dot = halftone(TEXTURE, UV, radians(45.0), k_ink, max_k_dot_radius);

	vec3 cmyk_rgb = vec3(c_dot, m_dot, y_dot) * vec3(k_dot);
	float cmyk_a = base.a * alpha_effect;

	vec3 tex_rgb = base.rgb;
	float tex_a = base.a * alpha_effect;

	vec3 out_rgb = mix(cmyk_rgb, tex_rgb, mix_scale);
	float out_a = mix(cmyk_a, tex_a, mix_scale);

	float mask = thread_region_mask(UV, TEXTURE_PIXEL_SIZE);

	out_rgb *= mask;
	out_a *= mask;

	COLOR = vec4(out_rgb, out_a);
}
