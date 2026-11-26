shader_type canvas_item;

#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform float dot_spacing : hint_range(0.25, 24.0, 0.05) = 1.5;
uniform float dot_radius : hint_range(0.0, 10.0, 0.05) = 2.0;
uniform float dot_softness : hint_range(0.0, 0.6, 0.01) = 0.5;
uniform float msdf_pixel_range = 16.0;
uniform bool use_alpha_mask = false;
uniform vec4 fill_colour : source_color = vec4(0.960784314, 0.901960784, 0.768627451, 1.0);

varying vec2 local_position;
varying float text_opacity;

void vertex() {
	local_position = VERTEX;
	text_opacity = COLOR.a;
}

float image_mask(vec2 uv, float alpha) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThanEqual(uv, vec2(1.0)))) {
		return 0.0;
	}
	return alpha > 0.0 ? 1.0 : 0.0;
}

float cutout_distance(vec2 delta, float radius, float spacing, float aa, float center_distance) {
	float cutout_radius = radius * (1.0 - smoothstep(0.0, spacing * 0.5, center_distance));
	float outside_cutout = length(delta) - cutout_radius;
	return mix(aa, outside_cutout, smoothstep(0.0, aa, cutout_radius));
}

void fragment() {
	float spacing = max(dot_spacing, 0.25);
	float radius = clamp(dot_radius, 0.0, spacing * 0.5);
	vec2 grid = plate_grid(local_position, spacing, BLACK_GRID);
	vec2 nearest = floor(grid + 0.5);
	radius = radius > 0.0 ? max(radius + dot_radius_offset(nearest, BLACK_GRID), 0.0) : 0.0;
	vec2 local_delta = plate_center(nearest, spacing, BLACK_GRID) - local_position;
	float pixel_width = max(length(dFdx(local_position)), length(dFdy(local_position)));
	float aa = clamp(max(pixel_width * 0.5, spacing * dot_softness), 0.000001, spacing * 0.6);

	float resolved = 1.0 - smoothstep(0.45, 1.15, pixel_width / spacing);
	vec2 local_dx = dFdx(local_position);
	vec2 local_dy = dFdy(local_position);
	float determinant = local_dx.x * local_dy.y - local_dx.y * local_dy.x;
	vec2 sample_uv = UV;
	if (abs(determinant) > 0.00000001) {
		vec2 screen_delta = vec2(
			local_delta.x * local_dy.y - local_delta.y * local_dy.x,
			local_dx.x * local_delta.y - local_dx.y * local_delta.x
		) / determinant;
		sample_uv += dFdx(UV) * screen_delta.x + dFdy(UV) * screen_delta.y;
	}

	if (use_alpha_mask) {
		float mask = image_mask(UV, texture(TEXTURE, UV).a);
		float probe_width = spacing * 0.5 / max(pixel_width, 0.000001);
		vec2 step_x = dFdx(UV) * probe_width;
		vec2 step_y = dFdy(UV) * probe_width;
		vec2 left = sample_uv - step_x;
		vec2 right = sample_uv + step_x;
		vec2 top = sample_uv - step_y;
		vec2 bottom = sample_uv + step_y;
		float interior = min(
			min(image_mask(left, texture(TEXTURE, left).a), image_mask(right, texture(TEXTURE, right).a)),
			min(image_mask(top, texture(TEXTURE, top).a), image_mask(bottom, texture(TEXTURE, bottom).a))
		);
		float center_mask = image_mask(sample_uv, texture(TEXTURE, sample_uv).a);
		float center_distance = interior * center_mask * spacing * 0.5;
		float edge_alpha = smoothstep(-aa, aa, cutout_distance(local_delta, radius, spacing, aa, center_distance));
		float alpha = mix(1.0, edge_alpha, resolved * smoothstep(0.0, aa, radius));
		COLOR = vec4(fill_colour.rgb, text_opacity * mask * alpha);
	} else {
		vec3 field = texture(TEXTURE, UV).rgb;
		float glyph = max(min(field.r, field.g), min(max(field.r, field.g), field.b)) - 0.5;
		vec2 atlas_step = fwidth(UV) / TEXTURE_PIXEL_SIZE;
		float screen_range = max(0.5 * msdf_pixel_range * dot(1.0 / max(atlas_step, vec2(0.000001)), vec2(1.0)), 1.0);

		float distance_inside = glyph * screen_range * pixel_width;
		vec3 center = texture(TEXTURE, sample_uv).rgb;
		float center_distance = (max(min(center.r, center.g), min(max(center.r, center.g), center.b)) - 0.5) * screen_range * pixel_width;
		float outside_cutout = cutout_distance(local_delta, radius, spacing, aa, center_distance);
		float eroded = min(distance_inside + radius * 0.55, outside_cutout);
		float dotted_alpha = smoothstep(-aa, aa, eroded);
		float plain_alpha = clamp(glyph * screen_range + 0.5, 0.0, 1.0);
		float alpha = mix(plain_alpha, dotted_alpha, resolved * smoothstep(0.0, aa, radius));
		COLOR = vec4(fill_colour.rgb, text_opacity * alpha);
	}
}
