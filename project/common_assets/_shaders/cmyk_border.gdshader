shader_type canvas_item;

uniform float dot_spacing : hint_range(0.25, 48.0, 0.05) = 12.0;
uniform float dot_radius : hint_range(0.5, 24.0, 0.05) = 11.75;
uniform float registration_offset : hint_range(0.0, 8.0, 0.25) = 2.0;
uniform float dot_softness : hint_range(0.0, 0.4, 0.01) = 0.12;

varying vec2 local_position;
varying vec2 weighted_rect_size;
const mat2 ALIGNED_GRID = mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
const mat2 BLACK_GRID = mat2(vec2(0.70710678, 0.70710678), vec2(-0.70710678, 0.70710678));

void vertex() {
	weighted_rect_size = VERTEX * UV;
	float padding = min(dot_radius, max(dot_spacing, 0.25) * 2.0) + registration_offset + 2.0;
	VERTEX += (UV * 2.0 - 1.0) * padding;
	local_position = VERTEX;
}

float plate_coverage(vec2 point, vec2 rect_size, vec2 offset, float ink, float aa, mat2 grid_rotation) {
	if (ink <= 0.0) {
		return 0.0;
	}
	float spacing = max(dot_spacing, 0.25);
	vec2 grid = transpose(grid_rotation) * (point - offset) / spacing;
	vec2 nearest = round(grid);
	float max_radius = min(dot_radius, spacing * 2.0) * ink * sqrt(ink);
	int reach = int(ceil((max_radius + aa) / spacing + 0.5)) - 1;
	float plate_mask = 0.0;
	for (int y = -reach; y <= reach; y++) {
		for (int x = -reach; x <= reach; x++) {
			vec2 center = grid_rotation * ((nearest + vec2(float(x), float(y))) * spacing);
			float dot_distance = distance(point, center + offset);
			if (dot_distance < max_radius + aa) {
				vec2 cell_min = center - spacing * 0.5;
				vec2 cell_max = center + spacing * 0.5;
				vec2 overlap = max(min(cell_max, rect_size) - max(cell_min, vec2(0.0)), vec2(0.0));
				float coverage = overlap.x * overlap.y / (spacing * spacing);
				float radius = max_radius * sqrt(coverage);
				float dot_mask = 1.0 - smoothstep(radius - aa, radius + aa, dot_distance);
				plate_mask = max(plate_mask, dot_mask * smoothstep(0.0, aa, radius));
			}
		}
	}
	return plate_mask;
}

void fragment() {
	vec2 local_dx = dFdx(local_position);
	vec2 local_dy = dFdy(local_position);
	vec2 local_step = sqrt(local_dx * local_dx + local_dy * local_dy);
	float spacing = max(dot_spacing, 0.25);
	vec2 point = local_position;
	float pixel_width = max(max(local_step.x, local_step.y), 0.000001);
	float aa = min(max(0.5 * pixel_width, spacing * dot_softness), spacing * 0.5);
	float unresolved = smoothstep(0.45, 1.15, pixel_width / spacing);
	vec2 rect_size = mix(vec2(1e10), weighted_rect_size / max(UV, vec2(0.00000001)), greaterThan(UV, vec2(0.00000001)));

	vec3 rgb = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
	float value = max(rgb.r, max(rgb.g, rgb.b));
	vec3 cmy = (vec3(value) - rgb) / max(value, 0.00001);
	float cyan = plate_coverage(point, rect_size, vec2(-registration_offset, 0.0), cmy.r, aa, ALIGNED_GRID);
	float magenta = plate_coverage(point, rect_size, vec2(registration_offset, 0.0), cmy.g, aa, ALIGNED_GRID);
	float yellow = plate_coverage(point, rect_size, vec2(0.0, registration_offset), cmy.b, aa, ALIGNED_GRID);
	float black = plate_coverage(point, rect_size, vec2(0.0), 1.0 - value, aa, BLACK_GRID);

	vec3 paper_mix = (vec3(1.0) - vec3(cyan, magenta, yellow)) * (1.0 - black);
	float clear_area = (1.0 - cyan) * (1.0 - magenta) * (1.0 - yellow) * (1.0 - black);

	float alpha = 1.0 - clear_area;
	vec3 premultiplied = paper_mix - vec3(clear_area);
	vec2 edge = min(point, rect_size - point);
	float shape = smoothstep(-0.5 * pixel_width, 0.5 * pixel_width, min(edge.x, edge.y));
	premultiplied = mix(premultiplied, rgb * shape, unresolved);
	alpha = mix(alpha, shape, unresolved);
	COLOR = vec4(premultiplied / max(alpha, 0.00001), COLOR.a * alpha);
}
