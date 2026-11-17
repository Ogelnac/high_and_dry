shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_spacing : hint_range(0.25, 48.0, 0.05) = 1.5;
uniform float dot_radius : hint_range(0.5, 24.0, 0.05) = 2.0;
uniform float registration_offset : hint_range(0.0, 8.0, 0.25) = 2.0;
uniform float dot_softness : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool use_artwork_texture = false;
uniform vec4 artwork_region = vec4(0.0);

varying vec2 local_position;
varying vec2 original_position;
varying vec4 artwork_tint;

void vertex() {
	original_position = VERTEX;
	artwork_tint = COLOR;
	float padding = min(dot_radius, max(dot_spacing, 0.25) * 2.0) + max(registration_offset, 8.0) + 2.0;
	vec2 padding_direction = artwork_region.z > 0.0 && artwork_region.w > 0.0 ? sign(VERTEX) : UV * 2.0 - 1.0;
	VERTEX += padding_direction * padding;
	local_position = VERTEX;
}

float plate_coverage(vec2 point, vec2 rect_size, float ink, float aa, mat2 grid_rotation) {
	if (ink <= 0.0) {
		return 0.0;
	}
	float spacing = max(dot_spacing, 0.25);
	vec2 grid = plate_grid(point, spacing, grid_rotation);
	vec2 nearest = round(grid);
	float radius_limit = spacing * 0.5;
	float max_radius = min(dot_radius, radius_limit) * ink;
	int reach = int(ceil((max_radius + aa) / spacing + 0.5)) - 1;
	float plate_mask = 0.0;
	for (int y = -reach; y <= reach; y++) {
		for (int x = -reach; x <= reach; x++) {
			vec2 center = plate_center(nearest + vec2(float(x), float(y)), spacing, grid_rotation);
			float dot_distance = distance(point, center);
			if (dot_distance < max_radius + aa) {
				vec2 cell_min = center - spacing * 0.5;
				vec2 cell_max = center + spacing * 0.5;
				vec2 overlap = max(min(cell_max, rect_size) - max(cell_min, vec2(0.0)), vec2(0.0));
				float coverage = overlap.x * overlap.y / (spacing * spacing);
				float radius = max_radius * sqrt(coverage);
				float mask = dot_mask(dot_distance, radius, aa);
				plate_mask = max(plate_mask, mask * smoothstep(0.0, aa, radius));
			}
		}
	}
	return plate_mask;
}

float rect_coverage(vec2 point, vec2 rect_size, float pixel_width) {
	vec2 edge = min(point, rect_size - point);
	return smoothstep(-0.5 * pixel_width, 0.5 * pixel_width, min(edge.x, edge.y));
}

float artwork_alpha(vec2 uv, vec2 uv_pixel, float alpha, vec2 region_start, vec2 region_end) {
	vec2 edge = min(uv - region_start, region_end - uv);
	vec2 coverage = clamp(edge / max(uv_pixel, vec2(0.000001)) + 0.5, vec2(0.0), vec2(1.0));
	return alpha * coverage.x * coverage.y;
}

void fragment() {
	vec2 local_dx = dFdx(local_position);
	vec2 local_dy = dFdy(local_position);
	vec2 local_step = sqrt(local_dx * local_dx + local_dy * local_dy);
	float spacing = max(dot_spacing, 0.25);
	vec2 point = local_position;
	float pixel_width = max(max(local_step.x, local_step.y), 0.000001);
	float aa = min(max(0.5 * pixel_width, spacing * dot_softness), spacing * 0.6);
	float unresolved = smoothstep(0.45, 1.15, pixel_width / spacing);
	vec2 original_dx = dFdx(original_position);
	vec2 original_dy = dFdy(original_position);
	vec2 uv_dx = dFdx(UV);
	vec2 uv_dy = dFdy(UV);
	vec2 rect_size = sqrt((original_dx * original_dx + original_dy * original_dy)
		/ max(uv_dx * uv_dx + uv_dy * uv_dy, vec2(1e-16)));

	vec4 tint = use_artwork_texture ? artwork_tint : COLOR;
	vec3 rgb = clamp(tint.rgb, vec3(0.0), vec3(1.0));
	vec2 cyan_point = plate_position(point, CYAN_SHIFT, registration_offset);
	vec2 magenta_point = plate_position(point, MAGENTA_SHIFT, registration_offset);
	vec2 yellow_point = plate_position(point, YELLOW_SHIFT, registration_offset);
	vec2 black_point = plate_position(point, BLACK_SHIFT, registration_offset);
	vec4 result;
	if (use_artwork_texture) {
		float determinant = original_dx.x * original_dy.y - original_dx.y * original_dy.x;
		mat2 local_to_uv = mat2(0.0);
		if (abs(determinant) > 0.00000001) {
			local_to_uv = mat2(uv_dx, uv_dy) * mat2(vec2(original_dy.y, -original_dx.y), vec2(-original_dy.x, original_dx.x)) / determinant;
		}
		vec2 cyan_uv = UV + local_to_uv * (cyan_point - original_position);
		vec2 magenta_uv = UV + local_to_uv * (magenta_point - original_position);
		vec2 yellow_uv = UV + local_to_uv * (yellow_point - original_position);
		vec2 black_uv = UV + local_to_uv * (black_point - original_position);
		vec2 region_start = artwork_region.xy * TEXTURE_PIXEL_SIZE;
		vec2 region_end = vec2(1.0);
		if (artwork_region.z > 0.0 && artwork_region.w > 0.0) {
			region_end = region_start + artwork_region.zw * TEXTURE_PIXEL_SIZE;
		}
		vec2 half_texel = 0.5 * TEXTURE_PIXEL_SIZE;
		vec2 sample_min = region_start + half_texel;
		vec2 sample_max = region_end - half_texel;
		vec2 sample_dx = local_to_uv * local_dx;
		vec2 sample_dy = local_to_uv * local_dy;
		vec2 uv_pixel = abs(sample_dx) + abs(sample_dy);
		vec4 cyan_sample = textureGrad(TEXTURE, clamp(cyan_uv, sample_min, sample_max), sample_dx, sample_dy);
		vec4 magenta_sample = textureGrad(TEXTURE, clamp(magenta_uv, sample_min, sample_max), sample_dx, sample_dy);
		vec4 yellow_sample = textureGrad(TEXTURE, clamp(yellow_uv, sample_min, sample_max), sample_dx, sample_dy);
		vec4 black_sample = textureGrad(TEXTURE, clamp(black_uv, sample_min, sample_max), sample_dx, sample_dy);
		float black_tone = cmyk_ink(black_sample.rgb * rgb).a;
		float black_shape = artwork_alpha(black_uv, uv_pixel, black_sample.a, region_start, region_end);
		float interior = 1.0;
		if (black_tone > 0.75) {
			for (int axis = 0; axis < 2; axis++) {
				vec2 step_uv = local_to_uv[axis] * spacing;
				for (int direction = -1; direction <= 1; direction += 2) {
					vec2 neighbor_uv = black_uv + step_uv * float(direction);
					vec4 neighbor = textureGrad(TEXTURE, clamp(neighbor_uv, sample_min, sample_max), sample_dx, sample_dy);
					float neighbor_ink = cmyk_ink(neighbor.rgb * rgb).a * artwork_alpha(neighbor_uv, uv_pixel, neighbor.a, region_start, region_end);
					interior = min(interior, smoothstep(0.25, 0.9, neighbor_ink / black_tone));
				}
			}
		}
		vec4 artwork_ink = vec4(
			cmyk_ink(cyan_sample.rgb * rgb).r * artwork_alpha(cyan_uv, uv_pixel, cyan_sample.a, region_start, region_end),
			cmyk_ink(magenta_sample.rgb * rgb).g * artwork_alpha(magenta_uv, uv_pixel, magenta_sample.a, region_start, region_end),
			cmyk_ink(yellow_sample.rgb * rgb).b * artwork_alpha(yellow_uv, uv_pixel, yellow_sample.a, region_start, region_end),
			black_tone * black_shape
		);
		float black_dots = 1.0 - texture_plate(black_point, spacing, BLACK_GRID, 0.75 * artwork_ink.a, 0.0);
		vec4 screened = vec4(
			1.0 - texture_plate(cyan_point, spacing, CYAN_GRID, 0.75 * artwork_ink.r, dot_softness),
			1.0 - texture_plate(magenta_point, spacing, MAGENTA_GRID, 0.75 * artwork_ink.g, dot_softness),
			1.0 - texture_plate(yellow_point, spacing, YELLOW_GRID, 0.75 * artwork_ink.b, dot_softness),
			mix(black_dots, black_plate_coverage(black_point, spacing, black_tone, black_dots, black_shape), interior)
		);
		result = cmyk_composite(mix(screened, artwork_ink, unresolved * black_shape));
	} else {
		rect_size = mix(rect_size, original_position / max(UV, vec2(0.000001)), greaterThan(UV, vec2(0.5)));
		vec4 ink = cmyk_ink(rgb);
		vec4 plates;
		plates.r = plate_coverage(cyan_point, rect_size, ink.r, aa, CYAN_GRID);
		plates.g = plate_coverage(magenta_point, rect_size, ink.g, aa, MAGENTA_GRID);
		plates.b = plate_coverage(yellow_point, rect_size, ink.b, aa, YELLOW_GRID);
		plates.a = plate_coverage(black_point, rect_size, ink.a, aa, BLACK_GRID);
		vec4 shapes;
		shapes.r = rect_coverage(cyan_point, rect_size, pixel_width);
		shapes.g = rect_coverage(magenta_point, rect_size, pixel_width);
		shapes.b = rect_coverage(yellow_point, rect_size, pixel_width);
		shapes.a = rect_coverage(black_point, rect_size, pixel_width);
		vec2 edge = min(black_point, rect_size - black_point);
		float interior = smoothstep(0.0, spacing, min(edge.x, edge.y));
		plates.a = mix(plates.a, black_plate_coverage(black_point, spacing, ink.a, plates.a, shapes.a), interior);
		result = mix(cmyk_composite(plates), cmyk_unresolved(rgb, ink, shapes), unresolved * shapes.a);
	}
	COLOR = vec4(result.rgb / max(result.a, 0.00001), tint.a * result.a);
}
