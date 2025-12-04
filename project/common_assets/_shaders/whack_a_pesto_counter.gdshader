shader_type canvas_item;

uniform int total_resources = 50;

uniform int red_resources;
uniform int orange_resources;
uniform int yellow_resources;
uniform int green_resources;
uniform int blue_resources;
uniform int pink_resources;
uniform int white_resources;
uniform int brown_resources;

uniform float wave_amp = 0.005;
uniform float wave_freq = 1.0;
uniform float wave_speed = 2.0;

const vec3 colours[9] = vec3[](
	vec3(0.6745, 0.1961, 0.1961),
	vec3(0.8745, 0.4431, 0.1490),
	vec3(0.9843, 0.9490, 0.2118),
	vec3(0.4157, 0.7412, 0.1882),
	vec3(0.3882, 0.6078, 1.0000),
	vec3(0.8431, 0.4824, 0.7294),
	vec3(1.0000, 1.0000, 1.0000),
	vec3(0.5608, 0.3373, 0.2314),
	vec3(0.0, 0.0, 0.0)
);

void fragment() {
	float total = max(float(total_resources), 1.0);
	float w[9];
	w[0] = float(red_resources) / total;
	w[1] = float(orange_resources) / total;
	w[2] = float(yellow_resources) / total;
	w[3] = float(green_resources) / total;
	w[4] = float(blue_resources) / total;
	w[5] = float(pink_resources) / total;
	w[6] = float(white_resources) / total;
	w[7] = float(brown_resources) / total;

	float sumw = 0.0;
	for (int i = 0; i < 8; i++) sumw += w[i];
	w[8] = max(1.0 - sumw, 0.0);

	vec3 seg_col[9];
	float seg_w[9];
	int seg_count = 0;
	for (int i = 0; i < 9; i++) {
		if (w[i] > 0.0) {
			seg_col[seg_count] = colours[i];
			seg_w[seg_count] = w[i];
			seg_count++;
		}
	}

	float x = clamp(UV.x, 0.0, 1.0);
	float running_total = 0.0;
	vec3 col = seg_col[seg_count - 1];
	bool picked = false;

	for (int i = 0; i < seg_count; i++) {
		float boundary = running_total + seg_w[i];
		if (i < seg_count - 1) {
			float offset = sin(UV.y * 6.2831853 * wave_freq + TIME * wave_speed + float(i) * 2.7182818) * wave_amp;
			boundary += offset;
		}
		if (!picked && x <= boundary) {
			col = seg_col[i];
			picked = true;
		}
		running_total += seg_w[i];
	}

	COLOR = vec4(col, 1.0);
}
