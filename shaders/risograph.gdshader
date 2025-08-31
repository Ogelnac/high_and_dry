shader_type canvas_item;
render_mode unshaded;

uniform sampler2D source_tex : source_color;

uniform vec3  paper_colour : source_color = vec3(0.99, 0.98, 0.95);
uniform float ink_bleed_px = 0.8;
uniform float fray_amount_px = 0.5;
uniform float fray_scale_px  = 18.0;
uniform float fray_octaves   = 2.0;
uniform float edge_softness  = 1.0;

uniform vec2  r_offset_px = vec2( 0.01, -0.01);
uniform vec2  g_offset_px = vec2( 0.00,  0.00);
uniform vec2  b_offset_px = vec2( 0.00,  0.00);
uniform float r_rot_deg =  0.15;
uniform float g_rot_deg = -0.10;
uniform float b_rot_deg =  0.00;

uniform float black_grey_floor = 0.0;
uniform float black_dot_transition : hint_range(0.5,2.0) = 0.5;

vec2 rot2(vec2 p, float a){ float s=sin(a), c=cos(a); return vec2(c*p.x - s*p.y, s*p.x + c*p.y); }

vec2 misreg_uv(vec2 uv, float deg, vec2 offset_px, vec2 texel){
	vec2 centre = uv - 0.5;
	centre = rot2(centre, radians(deg));
	vec2 mis = uv + offset_px * texel;
	return centre + 0.5 + (mis - uv);
}

float vhash(vec2 p){
	p = fract(p*vec2(123.34, 456.21));
	p += dot(p, p+45.32);
	return fract(p.x*p.y);
}
float vnoise(vec2 p){
	vec2 i = floor(p), f = fract(p);
	float a = vhash(i);
	float b = vhash(i + vec2(1.0,0.0));
	float c = vhash(i + vec2(0.0,1.0));
	float d = vhash(i + vec2(1.0,1.0));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p, int oct){
	float s = 0.0, a = 0.6;
	for(int i=0;i<4;i++){
		if(i>=oct) break;
		s += vnoise(p)*a;
		p *= 2.0;
		a *= 0.5;
	}
	return s / (1.0 - pow(0.5, float(oct)));
}

vec2 alpha_grad(vec2 uv, vec2 texel){
	float tl = texture(source_tex, uv + vec2(-texel.x, -texel.y)).a;
	float  l = texture(source_tex, uv + vec2(-texel.x,  0.0)).a;
	float bl = texture(source_tex, uv + vec2(-texel.x,  texel.y)).a;
	float  t = texture(source_tex, uv + vec2( 0.0, -texel.y)).a;
	float  b = texture(source_tex, uv + vec2( 0.0,  texel.y)).a;
	float tr = texture(source_tex, uv + vec2( texel.x, -texel.y)).a;
	float  r = texture(source_tex, uv + vec2( texel.x,  0.0)).a;
	float br = texture(source_tex, uv + vec2( texel.x,  texel.y)).a;
	float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
	float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
	return vec2(gx, gy);
}

float bleed8(vec2 uv, vec2 texel, float radius_px){
	vec2 r = radius_px * texel;
	float a = texture(source_tex, uv).a;
	a = max(a, texture(source_tex, uv + vec2( r.x,  0.0)).a);
	a = max(a, texture(source_tex, uv + vec2(-r.x,  0.0)).a);
	a = max(a, texture(source_tex, uv + vec2( 0.0,  r.y)).a);
	a = max(a, texture(source_tex, uv + vec2( 0.0, -r.y)).a);
	a = max(a, texture(source_tex, uv + vec2( r.x,  r.y)).a);
	a = max(a, texture(source_tex, uv + vec2(-r.x,  r.y)).a);
	a = max(a, texture(source_tex, uv + vec2( r.x, -r.y)).a);
	a = max(a, texture(source_tex, uv + vec2(-r.x, -r.y)).a);
	return a;
}

void fragment(){
	vec2 tex_size  = vec2(textureSize(source_tex, 0));
	vec2 texel     = 1.0 / max(tex_size, vec2(1.0));

	vec2 uv_r = misreg_uv(UV, r_rot_deg, r_offset_px, texel);
	vec2 uv_g = misreg_uv(UV, g_rot_deg, g_offset_px, texel);
	vec2 uv_b = misreg_uv(UV, b_rot_deg, b_offset_px, texel);

	float r = texture(source_tex, uv_r).r;
	float g = texture(source_tex, uv_g).g;
	float b = texture(source_tex, uv_b).b;

	float a_src   = texture(source_tex, UV).a;
	float a_bleed = bleed8(UV, texel, ink_bleed_px);

	vec2  gxy   = alpha_grad(UV, texel);
	float glen  = length(gxy) + 1e-5;
	vec2  n_dir = gxy / glen;

	vec2  screen_px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float nval = fbm(screen_px / max(fray_scale_px, 1.0), int(clamp(fray_octaves,1.0,3.0)));
	float nibble_px = fray_amount_px * mix(0.5, 1.0, nval);

	float a_eroded = texture(source_tex, UV - n_dir * texel * nibble_px).a;

	float a_soft = smoothstep(0.0, 1.0, pow(max(a_src, 0.0), 1.0/edge_softness));
	float a = min(a_eroded, a_bleed) * a_soft;

	vec3 ink_rgb = vec3(r,g,b);
	ink_rgb = max(ink_rgb, vec3(black_grey_floor));

	vec3 final_rgb = mix(paper_colour, ink_rgb, a);

	float t = clamp((black_dot_transition - 0.5) / (2.0 - 0.5), 0.0, 1.0);
	final_rgb = mix(final_rgb, vec3(0.0), t);

	COLOR = vec4(final_rgb, a);
}
