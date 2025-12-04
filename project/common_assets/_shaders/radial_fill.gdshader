shader_type canvas_item;

uniform float fill: hint_range(0.175, 1.0, 0.001) = 0.75;
uniform float start_angle_deg: hint_range(-360.0, 360.0, 0.1) = 0.0;
uniform bool clockwise = true;
uniform float outer_radius: hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float edge_softness: hint_range(0.0, 0.2, 0.0001) = 0.005;
uniform float angle_softness_deg: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;

uniform sampler2D overlay_tex: source_color;
uniform bool use_overlay = true;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float s = max(edge_softness, 0.000001);
	float rout = 1.0 - smoothstep(outer_radius - s, outer_radius, r);

	float two_pi = 6.28318530718;
	float a = atan(p.y, p.x) + radians(start_angle_deg);
	a = mod(a + two_pi, two_pi);
	float t = clockwise ? a : two_pi - a;
	float boundary = clamp(fill, 0.0, 1.0) * two_pi;
	float wedge = 1.0 - smoothstep(boundary, boundary + radians(angle_softness_deg), t);
	wedge *= step(0.00001, fill);

	vec4 base = COLOR;
	vec4 col = vec4(base.rgb, base.a * rout * wedge);

	if (use_overlay) {
		vec4 ov = texture(overlay_tex, UV);
		col.rgb = mix(col.rgb, ov.rgb, ov.a);
		col.a = max(col.a, ov.a);
	}

	COLOR = vec4(col.rgb, col.a - alpha);
}
