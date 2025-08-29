shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D overlay : source_color;
uniform sampler2D paper_overlay : source_color;

uniform vec2 overlay_pixel_size = vec2(2048, 2048);

uniform vec2 chroma_offset_c = vec2(0.0, 0.0);
uniform vec2 chroma_offset_m = vec2(0.0, 0.0);
uniform vec2 chroma_offset_y = vec2(0.0, 0.0);

vec3 colour_cbs_adjustment(vec3 colour, float contrast, float brightness, float saturation) {
	colour += brightness;
	colour = (colour - 0.5) * contrast + 0.5;
	float lum = dot(colour, vec3(0.299, 0.587, 0.114));
	colour = mix(vec3(lum), colour, saturation);
	return clamp(colour, 0.0, 1.0);
}

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
	vec3 paper_sample = texture(paper_overlay, overlay_uv).rgb;
	vec3 combined_filter = mix(overlay_sample, paper_sample, 0.2);

	vec3 final_colour = remap(chroma_mixed + combined_filter, vec3(0.0), vec3(1.0));
	final_colour = colour_cbs_adjustment(final_colour, 1.1, 0.0, 1.5);

	COLOR = vec4(final_colour, 1.0);
}
