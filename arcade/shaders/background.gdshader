shader_type canvas_item;

uniform float darkness = 0.8;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    color.rgb *= darkness;
    COLOR = color;
}
