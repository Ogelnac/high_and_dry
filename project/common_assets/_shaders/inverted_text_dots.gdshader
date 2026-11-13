shader_type canvas_item;

uniform float dot_spacing : hint_range(0.25, 24.0, 0.05) = 2.0;
uniform float dot_radius : hint_range(0.0, 10.0, 0.05) = 0.55;
uniform float dot_softness : hint_range(0.0, 0.4, 0.01) = 0.15;
uniform float msdf_pixel_range = 16.0;

varying vec2 local_position;
varying float text_opacity;

void vertex() {
	local_position = VERTEX;
	text_opacity = COLOR.a;
}

void fragment() {
	vec3 field = texture(TEXTURE, UV).rgb;
	float glyph = max(min(field.r, field.g), min(max(field.r, field.g), field.b)) - 0.5;
	vec2 atlas_step = fwidth(UV) / TEXTURE_PIXEL_SIZE;
	float screen_range = max(0.5 * msdf_pixel_range * dot(1.0 / max(atlas_step, vec2(0.000001)), vec2(1.0)), 1.0);

	float spacing = max(dot_spacing, 0.25);
	float radius = clamp(dot_radius, 0.0, spacing * 0.5);
	vec2 grid = vec2(local_position.x + local_position.y, local_position.y - local_position.x) * 0.70710678;
	vec2 cell = fract(grid / spacing + 0.5) - 0.5;
	float pixel_width = max(length(dFdx(local_position)), length(dFdy(local_position)));
	float aa = clamp(max(pixel_width * 0.5, spacing * dot_softness), 0.000001, spacing * 0.5);
	float distance_inside = glyph * screen_range * pixel_width;
	float resolved = 1.0 - smoothstep(0.45, 1.15, pixel_width / spacing);
	vec2 grid_delta = -cell * spacing;
	vec2 local_delta = vec2(grid_delta.x - grid_delta.y, grid_delta.x + grid_delta.y) * 0.70710678;
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
	vec3 center = texture(TEXTURE, sample_uv).rgb;
	float center_distance = (max(min(center.r, center.g), min(max(center.r, center.g), center.b)) - 0.5) * screen_range * pixel_width;
	float cutout_radius = radius * (1.0 - smoothstep(0.0, spacing * 0.5, center_distance));
	float outside_cutout = length(cell) * spacing - cutout_radius;
	outside_cutout = mix(aa, outside_cutout, smoothstep(0.0, aa, cutout_radius));
	float eroded = min(distance_inside + radius * 0.55, outside_cutout);
	float dotted_alpha = smoothstep(-aa, aa, eroded);
	float plain_alpha = clamp(glyph * screen_range + 0.5, 0.0, 1.0);
	float alpha = mix(plain_alpha, dotted_alpha, resolved * smoothstep(0.0, aa, radius));
	COLOR = vec4(vec3(1.0), text_opacity * alpha);
}
