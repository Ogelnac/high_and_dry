shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D overlay : source_color, repeat_enable, filter_linear_mipmap;

uniform vec2 overlay_pixel_size = vec2(2048, 2048);

uniform float registration_offset : hint_range(0.0, 8.0, 0.25) = 0.0;

uniform vec2 scroll_speed = vec2(0.0, 0.0);

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

	vec2 offset = registration_offset * SCREEN_PIXEL_SIZE;
	float red = texture(SCREEN_TEXTURE, uv + vec2(offset.x, 0.0)).r;
	float green = texture(SCREEN_TEXTURE, uv - vec2(offset.x, 0.0)).g;
	float blue = texture(SCREEN_TEXTURE, uv - vec2(0.0, offset.y)).b;

	vec3 chroma_mixed = vec3(red, green, blue);

	vec2 overlay_uv = (UV + (TIME * scroll_speed)) * overlay_pixel_size;
	vec3 overlay_sample = texture(overlay, overlay_uv).rgb;

	vec3 final_colour = remap(chroma_mixed + overlay_sample, vec3(0.0), vec3(1.0));
	final_colour = colour_cbs_adjustment(final_colour, 1.0, 0.0, 1.0);

	COLOR = vec4(final_colour, 1.0);
}
