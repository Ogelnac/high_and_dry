#include "res://project/common_assets/_shaders/cmyk_screen.gdshaderinc"

uniform vec2 atlas_frames = vec2(1.0);
uniform vec4 atlas_region = vec4(0.0);
uniform vec4 paper_color : source_color = vec4(0.96, 0.90, 0.77, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.23, 0.17, 0.26, 0.65);
uniform float ink_imperfection : hint_range(0.0, 0.3, 0.01) = 0.3;
uniform float black_ink_softness : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float black_dot_transition : hint_range(0.5, 2.0) = 0.5;

#ifdef ENTITY_DIFFRACTION
uniform sampler2D diffraction : source_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float diffraction_strength = 200.0;
uniform float diffraction_mix : hint_range(0.0, 1.0) = 0.45;
uniform float alpha_effect : hint_range(0.0, 1.0) = 1.0;
#endif

varying vec2 original_position;
varying vec2 padded_position;
varying vec4 tint;

void vertex() {
	original_position = VERTEX;
	tint = COLOR;
	VERTEX += sign(VERTEX) * 3.0;
	padded_position = VERTEX;
}

float frame_coverage(vec2 uv, vec2 frame_start, vec2 frame_end) {
	vec2 inside = step(frame_start, uv) * (1.0 - step(frame_end, uv));
	return inside.x * inside.y;
}

float black_ink(vec3 color) {
	return 1.0 - smoothstep(0.03, 0.12, max(color.r, max(color.g, color.b)));
}

void fragment() {
	vec2 dx = dFdx(original_position);
	vec2 dy = dFdy(original_position);
	mat2 local_to_uv = mat2(dFdx(UV), dFdy(UV)) * inverse(mat2(dx, dy));
	vec2 frame_size = 1.0 / atlas_frames;
	vec2 frame_center_uv = UV - local_to_uv * original_position;
	vec2 frame_start = clamp(floor(frame_center_uv * atlas_frames), vec2(0.0), atlas_frames - 1.0) * frame_size;
	vec2 frame_end = frame_start + frame_size;
	if (atlas_region.z > 0.0 && atlas_region.w > 0.0) {
		frame_start = atlas_region.xy * TEXTURE_PIXEL_SIZE;
		frame_end = frame_start + atlas_region.zw * TEXTURE_PIXEL_SIZE;
	}
	vec2 half_texel = TEXTURE_PIXEL_SIZE * 0.5;
	vec2 artwork_uv = UV + local_to_uv * (padded_position - original_position);
	vec4 artwork = texture(TEXTURE, clamp(artwork_uv, frame_start + half_texel, frame_end - half_texel));
	artwork.a *= frame_coverage(artwork_uv, frame_start, frame_end);

	float paper = artwork.a;
	float shadow = 0.0;
	float edge_wobble = 0.32 * sin(dot(padded_position, vec2(0.85, 0.55)))
		+ 0.18 * sin(dot(padded_position, vec2(-0.65, 1.15)) + 1.7);
	float paper_radius = 0.85 + edge_wobble;
	vec2 shadow_uv = artwork_uv - local_to_uv * vec2(1.0, 2.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 offset = local_to_uv * vec2(float(x), float(y));
			vec2 paper_uv = artwork_uv + offset * paper_radius;
			vec2 sample_uv = shadow_uv + offset * 0.85;
			paper = max(paper, texture(TEXTURE, clamp(paper_uv, frame_start + half_texel, frame_end - half_texel)).a * frame_coverage(paper_uv, frame_start, frame_end));
			shadow = max(shadow, texture(TEXTURE, clamp(sample_uv, frame_start + half_texel, frame_end - half_texel)).a * frame_coverage(sample_uv, frame_start, frame_end));
		}
	}

	float paper_alpha = paper * paper_color.a * (1.0 - artwork.a);
	float shadow_alpha = shadow * shadow_color.a * (1.0 - artwork.a - paper_alpha);
	float alpha = artwork.a + paper_alpha + shadow_alpha;
	float variation = ink_variation(padded_position);
	vec3 printed = artwork.rgb;
	float ink_value = max(printed.r, max(printed.g, printed.b));
	float color_ink = smoothstep(0.08, 0.35, ink_value);
	vec2 ink_uv = artwork_uv + local_to_uv * (vec2(1.0, -0.65) * ink_imperfection * (0.75 + 0.25 * variation));
	ivec2 texture_size = textureSize(TEXTURE, 0);
	vec2 lower = floor(ink_uv * vec2(texture_size) - 0.5) + 0.5;
	vec2 blend = fract(ink_uv * vec2(texture_size) - 0.5);
	vec3 shifted_color = printed;
	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			vec2 tap = vec2(float(x), float(y));
			vec2 tap_uv = (lower + tap) / vec2(texture_size);
			vec4 ink = texture(TEXTURE, clamp(tap_uv, frame_start + half_texel, frame_end - half_texel));
			vec2 weight = mix(1.0 - blend, blend, tap);
			float ink_mask = ink.a * frame_coverage(tap_uv, frame_start, frame_end);
			shifted_color += (ink.rgb - printed) * (weight.x * weight.y * ink_mask);
		}
	}
	printed = mix(printed, shifted_color, color_ink);
	printed = mix(printed, paper_color.rgb, ink_imperfection * 0.25 * color_ink * (0.5 + 0.5 * variation));
	vec2 black_texel = artwork_uv / TEXTURE_PIXEL_SIZE - 0.5;
	vec2 black_lower = floor(black_texel) + 0.5;
	vec2 black_blend = fract(black_texel);
	float soft_black = 0.0;
	vec3 nearby_color = vec3(0.0);
	float nearby_weight = 0.0;
	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			vec2 tap = vec2(float(x), float(y));
			vec2 tap_uv = (black_lower + tap) * TEXTURE_PIXEL_SIZE;
			vec4 ink = texture(TEXTURE, clamp(tap_uv, frame_start + half_texel, frame_end - half_texel));
			vec2 weight = mix(1.0 - black_blend, black_blend, tap);
			float coverage = weight.x * weight.y * ink.a * frame_coverage(tap_uv, frame_start, frame_end);
			float black = black_ink(ink.rgb);
			soft_black += coverage * black;
			nearby_color += ink.rgb * coverage * (1.0 - black);
			nearby_weight += coverage * (1.0 - black);
		}
	}
	float original_black = black_ink(artwork.rgb);
	vec3 color_under_black = nearby_weight > 0.00001 ? nearby_color / nearby_weight : paper_color.rgb;
	vec3 softened_print = mix(printed, color_under_black, original_black) * (1.0 - soft_black);
	printed = mix(printed, softened_print, black_ink_softness);
#ifdef ENTITY_DIFFRACTION
	vec2 diffraction_uv = clamp(artwork_uv, frame_start + half_texel, frame_end - half_texel);
	float distortion = texture(diffraction, diffraction_uv).r;
	vec2 direction = artwork_uv - (frame_start + frame_end) * 0.5;
	vec2 screen_offset = -direction * distortion * SCREEN_PIXEL_SIZE * diffraction_strength;
	vec3 refracted = texture(SCREEN_TEXTURE, clamp(SCREEN_UV + screen_offset, vec2(0.0), vec2(1.0))).rgb;
	printed = mix(printed, refracted, diffraction_mix * (1.0 - original_black));
	artwork.a *= alpha_effect;
	alpha = artwork.a + paper_alpha + shadow_alpha;
#endif
	vec3 color = printed * artwork.a + paper_color.rgb * paper_alpha + shadow_color.rgb * shadow_alpha;
	COLOR = vec4(color / max(alpha, 0.00001) * tint.rgb * cmyk_scene_fade(black_dot_transition), alpha * tint.a);
}
