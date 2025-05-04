shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D overlay : source_color;
uniform vec2 overlay_pixel_size = vec2(2048, 2048);

uniform vec2 chroma_offset_c = vec2(0.0, 0.0);
uniform vec2 chroma_offset_m = vec2(0.0, 0.0);
uniform vec2 chroma_offset_y = vec2(0.0, 0.0);

vec3 remap(vec3 value, vec3 minVal, vec3 maxVal) {
	return (value - minVal) / (maxVal - minVal);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float c_shift = texture(SCREEN_TEXTURE, uv + chroma_offset_c / 200.0).g;
	float m_shift = texture(SCREEN_TEXTURE, uv + chroma_offset_m / 200.0).b;
	float y_shift = texture(SCREEN_TEXTURE, uv + chroma_offset_y / 200.0).r;

	vec3 chroma_mixed = vec3(y_shift, c_shift, m_shift);

	vec2 overlay_uv = fract(UV * overlay_pixel_size);
	vec3 overlay_sample = texture(overlay, overlay_uv).rgb;

	vec3 final_colour = remap(overlay_sample + chroma_mixed, vec3(0.0), vec3(1.0));

	COLOR = vec4(final_colour, 1.0);
}
