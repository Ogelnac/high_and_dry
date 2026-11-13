shader_type canvas_item;

uniform float dot_spacing : hint_range(0.25, 24.0, 0.05) = 0.65;
uniform float dot_radius : hint_range(0.0, 10.0, 0.05) = 0.5;
uniform float registration_offset : hint_range(0.0, 5.0, 0.25) = 1.0;
uniform float dot_softness : hint_range(0.0, 0.4, 0.01) = 0.12;
uniform float msdf_pixel_range = 16.0;

varying vec4 ink_colour;
varying vec2 local_position;
const mat2 ALIGNED_GRID = mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
const mat2 BLACK_GRID = mat2(vec2(0.70710678, 0.70710678), vec2(-0.70710678, 0.70710678));


void vertex() {
	local_position = VERTEX;
	ink_colour = COLOR;
}

float glyph_distance(sampler2D atlas, vec2 uv) {
	vec3 field = texture(atlas, uv).rgb;
	return max(min(field.r, field.g), min(max(field.r, field.g), field.b)) - 0.5;
}

float dot_coverage(sampler2D atlas, vec2 uv, vec2 uv_per_unit, float distance_scale, vec2 cell, vec2 offset, float ink, float aa, float spacing, float max_radius) {
	vec2 to_center = cell - local_position;
	float dot_distance = length(to_center + offset);
	if (dot_distance >= max_radius + aa) {
		return 0.0;
	}
	float center_distance = glyph_distance(atlas, uv + to_center * uv_per_unit) * distance_scale;
	float coverage = clamp(0.5 + center_distance / spacing, 0.0, 1.0);
	float radius = max_radius * ink * sqrt(ink * coverage);
	float dot_mask = 1.0 - smoothstep(radius - aa, radius + aa, dot_distance);
	return dot_mask * smoothstep(0.0, aa, radius);
}

float plate(sampler2D atlas, vec2 uv, vec2 uv_per_unit, float distance_scale, vec2 offset, float ink, float aa, float spacing, float max_radius, mat2 grid_rotation) {
	if (ink <= 0.0) {
		return 0.0;
	}
	vec2 cell = floor(transpose(grid_rotation) * (local_position - offset) / spacing) * spacing;
	float coverage = 0.0;
	int extra_ring = int(ceil((max_radius + aa) / spacing)) - 1;
	for (int y = -extra_ring; y <= 1 + extra_ring; y++) {
		for (int x = -extra_ring; x <= 1 + extra_ring; x++) {
			vec2 center = grid_rotation * (cell + vec2(float(x), float(y)) * spacing);
			coverage = max(coverage, dot_coverage(atlas, uv, uv_per_unit, distance_scale, center, offset, ink, aa, spacing, max_radius));
		}
	}
	return coverage;
}

void fragment() {
	vec2 dx = dFdx(local_position);
	vec2 dy = dFdy(local_position);
	vec2 local_step = sqrt(dx * dx + dy * dy);
	vec2 uv_dx = dFdx(UV);
	vec2 uv_dy = dFdy(UV);
	vec2 uv_per_unit = sqrt(uv_dx * uv_dx + uv_dy * uv_dy) / max(local_step, vec2(0.000001));
	float atlas_per_unit = max(uv_per_unit.x / TEXTURE_PIXEL_SIZE.x, uv_per_unit.y / TEXTURE_PIXEL_SIZE.y);
	float distance_scale = msdf_pixel_range / max(atlas_per_unit, 0.000001);
	float spacing = max(dot_spacing, 0.25);
	float max_radius = min(dot_radius, spacing * 2.0);
	float pixel_width = max(max(local_step.x, local_step.y), 0.000001);
	float aa = min(max(0.5 * pixel_width, spacing * dot_softness), spacing * 0.5);
	float unresolved = smoothstep(0.45, 1.15, pixel_width / spacing);
	float reach = max(max_radius + registration_offset + aa, 0.5 * pixel_width);
	float glyph = glyph_distance(TEXTURE, UV);
	if (glyph < -min(reach / distance_scale, 0.49)) {
		discard;
	}

	vec3 rgb = clamp(ink_colour.rgb, vec3(0.0), vec3(1.0));
	float value = max(rgb.r, max(rgb.g, rgb.b));
	vec3 cmy = (vec3(value) - rgb) / max(value, 0.00001);
	vec4 plates;
	plates.r = plate(TEXTURE, UV, uv_per_unit, distance_scale, vec2(-registration_offset, 0.0), cmy.r, aa, spacing, max_radius, ALIGNED_GRID);
	plates.g = plate(TEXTURE, UV, uv_per_unit, distance_scale, vec2(registration_offset, 0.0), cmy.g, aa, spacing, max_radius, ALIGNED_GRID);
	plates.b = plate(TEXTURE, UV, uv_per_unit, distance_scale, vec2(0.0, registration_offset), cmy.b, aa, spacing, max_radius, ALIGNED_GRID);
	plates.a = plate(TEXTURE, UV, uv_per_unit, distance_scale, vec2(0.0), 1.0 - value, aa, spacing, max_radius, BLACK_GRID);
	vec3 transmitted = (vec3(1.0) - plates.rgb) * (1.0 - plates.a);
	float clear_area = (1.0 - plates.r) * (1.0 - plates.g) * (1.0 - plates.b) * (1.0 - plates.a);
	float alpha = 1.0 - clear_area;
	vec3 premultiplied = transmitted - vec3(clear_area);
	float shape = smoothstep(-0.5 * pixel_width, 0.5 * pixel_width, glyph * distance_scale);
	premultiplied = mix(premultiplied, rgb * shape, unresolved);
	alpha = mix(alpha, shape, unresolved);
	COLOR = vec4(premultiplied / max(alpha, 0.00001), ink_colour.a * alpha);
}
