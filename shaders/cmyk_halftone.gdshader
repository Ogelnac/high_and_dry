shader_type canvas_item;

uniform float black_dot_transition: hint_range(0.5, 2.0) = 0.5;
uniform float alpha_effect: hint_range(0.0, 1.0) = 1.0;

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

	float alpha = COLOR.a;

	vec3 final_colour = vec3(c_dot, m_dot, y_dot);

	final_colour *= vec3(k_dot);
    COLOR = vec4(final_colour, alpha * alpha_effect);
}