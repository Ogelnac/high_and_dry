shader_type canvas_item;

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;
uniform float mix_scale: hint_range(0.0, 1.0) = 0.0;

uniform sampler2D diffraction: source_color;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float diffraction_strength = 1.0;

vec2 fix_aspect(sampler2D tex, vec2 uv) {
	ivec2 tex_size = textureSize (tex, 0);
	vec2 screen_size = vec2(1.0, (1.0 / float(tex_size.x)) /(1.0 / float(tex_size.y)));
	return uv * screen_size;
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

void fragment() {
	ivec2 tex_size = textureSize(TEXTURE, 0);
	vec2 pixel_size = 1.0 / vec2(tex_size);
	vec2 subpixel_padding = pixel_size * 1.0;
	vec2 padded_uv = clamp(UV, subpixel_padding, vec2(1.0) - subpixel_padding);

	vec4 tex = texture(TEXTURE, padded_uv);

	vec3 colour = COLOR.rgb;

	float max_CMY_dot_radius = 0.75;
	float max_k_dot_radius = 1.0;

	float c_dot = halftone(TEXTURE, UV, radians(15.0), (1.0 - colour.r), max_CMY_dot_radius);
	float m_dot = halftone(TEXTURE, UV, radians(60.0), (1.0 - colour.g), max_CMY_dot_radius);
	float y_dot = halftone(TEXTURE, UV, radians(0.0), (1.0 - colour.b), max_CMY_dot_radius);

	float k_dot = halftone(TEXTURE, UV, radians(45.0), black_dot_transition - max(colour.r, max(colour.g, colour.b)), max_k_dot_radius);

	vec3 cmyk_rgb = vec3(c_dot, m_dot, y_dot) * vec3(k_dot);
	float cmyk_a = COLOR.a * alpha_effect;

	vec3 tex_rgb = tex.rgb * COLOR.rgb;
	float tex_a = tex.a * COLOR.a * alpha_effect;

	vec3 out_rgb = mix(cmyk_rgb, tex_rgb, mix_scale);
	float out_a = mix(cmyk_a, tex_a, mix_scale);

	vec2 centred_uv = UV - vec2(0.32);

	vec3 diff = texture(diffraction, UV).rgb;

	vec2 direction = centred_uv;
	vec2 screen_offset = direction * -diff.r * SCREEN_PIXEL_SIZE * diffraction_strength;

	vec3 screen_sample = texture(SCREEN_TEXTURE, SCREEN_UV + screen_offset).rgb;

	vec3 combine = mix(tex.rgb, screen_sample, 0.25);

	COLOR = vec4(combine, out_a);
}