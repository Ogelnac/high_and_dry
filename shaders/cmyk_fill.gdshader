shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wave_mask;

uniform vec4 fill_colour: source_color = vec4(1.0);
uniform float fill_height: hint_range(0.0, 1.0) = 0.5;
uniform float max_offset = 1.0;
uniform float min_offset = 0.0;
uniform float wave_freq = 10.0;
uniform float wave_band = 0.08;
uniform float wave_speed = 0.6;

varying float alpha;

vec3 colour_cbs_adjustment(vec3 colour, float contrast, float brightness, float saturation) {
	colour += brightness;
	colour = (colour - 0.5) * contrast + 0.5;
	float lum = dot(colour, vec3(0.299, 0.587, 0.114));
	colour = mix(vec3(lum), colour, saturation);
	return clamp(colour, 0.0, 1.0);
}

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

	float max_CMY_dot_radius = 0.75;
	float max_k_dot_radius = 1.0;

	float c_dot = halftone(TEXTURE, UV, radians(15.0), (1.0 - colour.r), max_CMY_dot_radius);
	float m_dot = halftone(TEXTURE, UV, radians(60.0), (1.0 - colour.g), max_CMY_dot_radius);
	float y_dot = halftone(TEXTURE, UV, radians(0.0), (1.0 - colour.b), max_CMY_dot_radius);
	float k_dot = halftone(TEXTURE, UV, radians(45.0), 1.0 - max(colour.r, max(colour.g, colour.b)), max_k_dot_radius);

	alpha = tex.a;

	vec2 wave_uv;
	wave_uv.x = fract(UV.x * wave_freq + TIME * fill_colour.r * wave_speed);
	wave_uv.y = clamp((UV.y - (edge - wave_band)) / max(wave_band, 1e-4), 0.0, 1.0);
	alpha *= texture(wave_mask, wave_uv).a;

	vec3 final_colour = vec3(c_dot, m_dot, y_dot);

	float contrast = 1.0;
	float brightness = 0.0;
	float saturation = 1.0;

	final_colour = colour_cbs_adjustment(final_colour, contrast, brightness, saturation);
	final_colour *= vec3(k_dot);

	COLOR = vec4(final_colour, alpha);
}
