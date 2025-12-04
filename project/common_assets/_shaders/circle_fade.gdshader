shader_type canvas_item;

uniform float transition_value : hint_range(0.0, 1.0);
uniform vec2 transition_location;
uniform vec2 colorrect_size;

void fragment() {
    vec2 uv_position = UV * colorrect_size;
    vec2 center = transition_location;

    float max_radius = max(
        length(vec2(center.x, center.y)),
        max(
            length(vec2(colorrect_size.x - center.x, center.y)),
            length(vec2(center.x, colorrect_size.y - center.y))
        )
    );

    float current_radius = max_radius * (1.0 - transition_value);
    float dist = length(uv_position - center);

    if (dist <= current_radius) {
        discard;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    }
}
