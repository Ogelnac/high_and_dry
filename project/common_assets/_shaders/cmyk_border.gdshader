shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_spacing : hint_range(0.25, 48.0, 0.05) = 1.5;
uniform float dot_radius : hint_range(0.5, 24.0, 0.05) = 2.0;
uniform float registration_offset : hint_range(0.0, 8.0, 0.25) = 2.0;
uniform float dot_softness : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool use_artwork_texture = false;
uniform vec4 artwork_region = vec4(0.0);
instance uniform bool centered_artwork = false;

varying vec2 local_position;
varying vec2 original_position;
varying vec4 artwork_tint;

void vertex() {
	original_position = VERTEX;
	artwork_tint = COLOR;
	float padding = min(dot_radius, max(dot_spacing, 0.25) * 2.0) + max(registration_offset, 8.0) + 2.0;
	bool centered = centered_artwork || (artwork_region.z > 0.0 && artwork_region.w > 0.0);
	vec2 padding_direction = centered ? sign(VERTEX) : UV * 2.0 - 1.0;
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
	int reach = int(ceil((max_radius + DOT_RADIUS_JITTER + aa) / spacing + 0.5)) - 1;
	float plate_mask = 0.0;
	for (int y = -reach; y <= reach; y++) {
		for (int x = -reach; x <= reach; x++) {
			vec2 cell = nearest + vec2(float(x), float(y));
			vec2 center = plate_center(cell, spacing, grid_rotation);
			float dot_distance = distance(point, center);
			if (dot_distance < max_radius + DOT_RADIUS_JITTER + aa) {
				vec2 cell_min = center - spacing * 0.5;
				vec2 cell_max = center + spacing * 0.5;
				vec2 overlap = max(min(cell_max, rect_size) - max(cell_min, vec2(0.0)), vec2(0.0));
				float coverage = overlap.x * overlap.y / (spacing * spacing);
				float radius = max_radius * sqrt(coverage);
				radius = radius > 0.0 ? max(radius + dot_radius_offset(cell, grid_rotation), 0.0) : 0.0;
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
		vec2 artwork_uv = UV + local_to_uv * (point - original_position);
		vec4 sampling_region = all(greaterThan(abs(REGION_RECT.zw), vec2(0.0))) ? REGION_RECT : vec4(0.0, 0.0, 1.0, 1.0);
		if (artwork_region.z > 0.0 && artwork_region.w > 0.0) {
			sampling_region = artwork_region * TEXTURE_PIXEL_SIZE.xyxy;
		}
		vec2 region_start = min(sampling_region.xy, sampling_region.xy + sampling_region.zw);
		vec2 region_end = max(sampling_region.xy, sampling_region.xy + sampling_region.zw);
		vec2 half_texel = 0.5 * TEXTURE_PIXEL_SIZE;
		vec2 sample_min = region_start + half_texel;
		vec2 sample_max = region_end - half_texel;
		vec2 sample_dx = local_to_uv * local_dx;
		vec2 sample_dy = local_to_uv * local_dy;
		vec2 uv_pixel = abs(sample_dx) + abs(sample_dy);
		vec4 artwork = textureGrad(TEXTURE, clamp(artwork_uv, sample_min, sample_max), sample_dx, sample_dy);
		float shape = artwork_alpha(artwork_uv, uv_pixel, artwork.a, region_start, region_end);
		vec3 artwork_rgb = artwork.rgb * rgb;
		vec3 screened = cmyk_screen_color(point, spacing, artwork_rgb, registration_offset, dot_softness);
		result = vec4(mix(screened, artwork_rgb, unresolved) * shape, shape);
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
		vec3 screened = cmyk_screen_color(point, spacing, rgb, registration_offset, dot_softness);
		result = mix(result, vec4(mix(screened, rgb, unresolved), 1.0), interior * shapes.a);
	}
	COLOR = vec4(cmyk_paper_color(result.rgb / max(result.a, 0.00001)), tint.a * result.a);
}
