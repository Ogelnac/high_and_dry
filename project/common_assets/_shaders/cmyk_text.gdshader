shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_spacing : hint_range(0.25, 24.0, 0.05) = 1.5;
uniform float dot_radius : hint_range(0.0, 10.0, 0.05) = 2.0;
uniform float registration_offset : hint_range(0.0, 5.0, 0.25) = 0.0;
uniform float dot_softness : hint_range(0.0, 0.6, 0.01) = 0.5;
uniform float msdf_pixel_range = 16.0;

varying vec4 ink_colour;
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
	ink_colour = COLOR;
}

float glyph_distance(vec3 field) {
	return max(min(field.r, field.g), min(max(field.r, field.g), field.b)) - 0.5;
}

float dot_coverage(float center_distance, float dot_distance, float ink, float aa, float spacing, float max_radius) {
	float coverage = clamp(0.5 + center_distance / spacing, 0.0, 1.0);
	float radius = max_radius * ink * sqrt(coverage);
	float mask = dot_mask(dot_distance, radius, aa);
	return mask * smoothstep(0.0, aa, radius);
}

float glyph_coverage(vec3 field, float distance_scale, float pixel_width) {
	return smoothstep(-0.5 * pixel_width, 0.5 * pixel_width, glyph_distance(field) * distance_scale);
}

void fragment() {
	vec2 dx = dFdx(local_position);
	vec2 dy = dFdy(local_position);
	vec2 local_step = sqrt(dx * dx + dy * dy);
	vec2 uv_dx = dFdx(UV);
	vec2 uv_dy = dFdy(UV);
	float determinant = dx.x * dy.y - dy.x * dx.y;
	mat2 local_to_uv = mat2(0.0);
	if (abs(determinant) > 0.00000001) {
		local_to_uv = mat2(uv_dx, uv_dy) * mat2(vec2(dy.y, -dx.y), vec2(-dy.x, dx.x)) / determinant;
	}
	float atlas_per_unit = max(length(local_to_uv[0] / TEXTURE_PIXEL_SIZE), length(local_to_uv[1] / TEXTURE_PIXEL_SIZE));
	float distance_scale = msdf_pixel_range / max(atlas_per_unit, 0.000001);
	float spacing = max(dot_spacing, 0.25);
	float max_radius = min(dot_radius, spacing * 2.0);
	float pixel_width = max(max(local_step.x, local_step.y), 0.000001);
	float aa = min(max(0.5 * pixel_width, spacing * dot_softness), spacing * 0.6);
	float unresolved = smoothstep(0.45, 1.15, pixel_width / spacing);
	float reach = max(max_radius + registration_offset + aa, 0.5 * pixel_width);
	float glyph = glyph_distance(texture(TEXTURE, UV).rgb);
	if (glyph < -min(reach / distance_scale, 0.49)) {
		discard;
	}

	vec3 rgb = clamp(ink_colour.rgb, vec3(0.0), vec3(1.0));
	vec4 ink = cmyk_ink(rgb);
	vec2 cyan_point = plate_position(local_position, CYAN_SHIFT, registration_offset);
	vec2 magenta_point = plate_position(local_position, MAGENTA_SHIFT, registration_offset);
	vec2 yellow_point = plate_position(local_position, YELLOW_SHIFT, registration_offset);
	vec2 black_point = plate_position(local_position, BLACK_SHIFT, registration_offset);
	vec2 points[4] = { cyan_point, magenta_point, yellow_point, black_point };
	mat2 rotations[4] = { CYAN_GRID, MAGENTA_GRID, YELLOW_GRID, BLACK_GRID };
	vec4 plates = vec4(0.0);
	for (int channel = 0; channel < 4; channel++) {
		float ink_amount = ink[channel];
		if (ink_amount <= 0.0) {
			continue;
		}
		float plate_radius = min(max_radius, spacing * 0.5);
		vec2 point = points[channel];
		mat2 grid_rotation = rotations[channel];
		float coverage = 0.0;
		vec2 cell = floor(plate_grid(point, spacing, grid_rotation));
		int extra_ring = int(ceil((plate_radius + aa) / spacing)) - 1;
		for (int y = -extra_ring; y <= 1 + extra_ring; y++) {
			for (int x = -extra_ring; x <= 1 + extra_ring; x++) {
				vec2 center = plate_center(cell + vec2(float(x), float(y)), spacing, grid_rotation);
				float dot_distance = distance(center, point);
				if (dot_distance < plate_radius + aa) {
					vec2 center_uv = UV + local_to_uv * (center - local_position);
					float center_distance = glyph_distance(texture(TEXTURE, center_uv).rgb) * distance_scale;
					coverage = max(coverage, dot_coverage(center_distance, dot_distance, ink_amount, aa, spacing, plate_radius));
				}
			}
		}
		plates[channel] = coverage;
	}
	vec4 shapes;
	shapes.r = glyph_coverage(texture(TEXTURE, UV + local_to_uv * (cyan_point - local_position)).rgb, distance_scale, pixel_width);
	shapes.g = glyph_coverage(texture(TEXTURE, UV + local_to_uv * (magenta_point - local_position)).rgb, distance_scale, pixel_width);
	shapes.b = glyph_coverage(texture(TEXTURE, UV + local_to_uv * (yellow_point - local_position)).rgb, distance_scale, pixel_width);
	shapes.a = glyph_coverage(texture(TEXTURE, UV + local_to_uv * (black_point - local_position)).rgb, distance_scale, pixel_width);
	float interior = smoothstep(0.0, spacing, glyph * distance_scale);
	plates.a = mix(plates.a, black_plate_coverage(black_point, spacing, ink.a, plates.a, shapes.a), interior);
	vec4 result = mix(cmyk_composite(plates), cmyk_unresolved(rgb, ink, shapes), unresolved * shapes.a);
	COLOR = vec4(result.rgb / max(result.a, 0.00001), ink_colour.a * result.a);
}
