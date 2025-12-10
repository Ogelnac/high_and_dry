shader_type canvas_item;

uniform vec4 fill_colour: source_color = vec4(1.0);
uniform float thread1_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread2_slider: hint_range(0.0, 1.0, 0.01);
uniform float thread3_slider: hint_range(0.0, 1.0, 0.01);

uniform vec4 region_rect = vec4(128.0, 0.0, 64.0, 128.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * fill_colour;

	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel = UV * tex_size;
	vec2 uv_region = (pixel - region_rect.xy) / region_rect.zw;

	float mask = 0.0;

	if (uv_region.x < 1.0 / 3.0) {
		mask = step(uv_region.y, thread1_slider);
	} else if (uv_region.x < 2.0 / 3.0) {
		mask = step(uv_region.y, thread2_slider);
	} else {
		mask = step(uv_region.y, thread3_slider);
	}

	COLOR = tex * mask;
}
