uniform vec4 paper_color : source_color = vec4(0.960784314, 0.901960784, 0.768627451, 1.0);

vec3 cmyk_paper_color(vec3 rgb) {
	float white = min(rgb.r, min(rgb.g, rgb.b));
	return rgb - (vec3(1.0) - paper_color.rgb) * white;
}

const mat2 CYAN_GRID = mat2(vec2(0.96592583, 0.25881905), vec2(-0.25881905, 0.96592583));
const mat2 MAGENTA_GRID = mat2(vec2(0.5, 0.86602540), vec2(-0.86602540, 0.5));
const mat2 YELLOW_GRID = mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
const mat2 BLACK_GRID = mat2(vec2(0.70710678, 0.70710678), vec2(-0.70710678, 0.70710678));

const vec2 CYAN_SHIFT = vec2(-1.0, 0.0);
const vec2 MAGENTA_SHIFT = vec2(1.0, 0.0);
const vec2 YELLOW_SHIFT = vec2(0.0, 1.0);
const vec2 BLACK_SHIFT = vec2(0.0);

float ink_variation(vec2 point) {
	return sin(point.x * 1.1 + point.y * 0.63) * sin(point.y * 1.31 - point.x * 0.47);
}

float cmyk_scene_fade(float transition) {
	return 1.0 - clamp((transition - 0.5) / 1.5, 0.0, 1.0);
}

vec2 plate_position(vec2 point, vec2 shift, float registration) {
	return point - shift * registration;
}

vec2 plate_grid(vec2 point, float spacing, mat2 rotation) {
	return transpose(rotation) * point / spacing - 0.5;
}

vec2 plate_center(vec2 cell, float spacing, mat2 rotation) {
	return rotation * ((cell + 0.5) * spacing);
}

const float DOT_RADIUS_JITTER = 0.1;

float dot_radius_offset(vec2 cell, mat2 rotation) {
	vec2 seed = cell + rotation[0] * 31.7;
	float random_value = fract(sin(dot(seed, vec2(127.1, 311.7))) * 43758.5453);
	return (2.0 * random_value - 1.0) * DOT_RADIUS_JITTER;
}

float dot_mask(float distance_to_center, float radius, float softness) {
	return 1.0 - smoothstep(radius - softness, radius + softness, distance_to_center);
}

vec4 cmyk_ink(vec3 rgb) {
	rgb = clamp(rgb, vec3(0.0), vec3(1.0));
	float value = max(rgb.r, max(rgb.g, rgb.b));
	vec3 chromatic = (vec3(value) - rgb) / max(value, 0.00001);
	return vec4(chromatic, 1.0 - value);
}

float tone_matched_plate(vec2 point, float spacing, mat2 rotation, float ink, float softness) {
	vec2 grid = plate_grid(point, spacing, rotation);
	vec2 cell = floor(grid + 0.5);
	float radius = clamp(length(grid - cell) - dot_radius_offset(cell, rotation) / spacing, 0.0, sqrt(0.5));
	float angle = acos(0.5 / max(radius, 0.5));
	float area = radius <= 0.5 ? PI * radius * radius
		: (PI - 4.0 * angle) * radius * radius + 2.0 * sqrt(max(radius * radius - 0.25, 0.0));
	float mask = 1.0 - smoothstep(ink - softness, ink + softness, area);
	float coverage = mix(ink, mask, min(1.0, min(ink, 1.0 - ink) / softness));
	return 1.0 - coverage;
}

float black_plate_coverage(vec2 point, float spacing, float ink, float dots, float shape) {
	float solidifying = smoothstep(0.75, 1.0, ink);
	float merged = (1.0 - tone_matched_plate(point, spacing, BLACK_GRID, ink, 0.08)) * shape;
	return mix(dots, merged, solidifying);
}

vec3 cmyk_screen_color(vec2 point, float spacing, vec3 rgb, float registration, float softness) {
	vec4 ink = cmyk_ink(rgb);
	softness = max(softness, 0.000001);
	float cyan = tone_matched_plate(plate_position(point, CYAN_SHIFT, registration), spacing, CYAN_GRID, ink.r, softness);
	float magenta = tone_matched_plate(plate_position(point, MAGENTA_SHIFT, registration), spacing, MAGENTA_GRID, ink.g, softness);
	float yellow = tone_matched_plate(plate_position(point, YELLOW_SHIFT, registration), spacing, YELLOW_GRID, ink.b, softness);
	float black = tone_matched_plate(point, spacing, BLACK_GRID, ink.a, softness);
	return vec3(cyan, magenta, yellow) * black;
}

vec4 cmyk_composite(vec4 plates) {
	vec3 transmitted = (vec3(1.0) - plates.rgb) * (1.0 - plates.a);
	float clear_area = transmitted.r * (1.0 - plates.g) * (1.0 - plates.b);
	return vec4(transmitted - vec3(clear_area), 1.0 - clear_area);
}

vec4 cmyk_unresolved(vec3 rgb, vec4 ink, vec4 shapes) {
	float shared_shape = min(min(shapes.r, shapes.g), min(shapes.b, shapes.a));
	float remaining = 1.0 - shared_shape;
	vec4 shifted = cmyk_composite(ink * (shapes - shared_shape) / max(remaining, 0.000001));
	return vec4(rgb, 1.0) * shared_shape + shifted * remaining;
}
