shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float alpha : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);

    if (dist <= radius) {
        COLOR = vec4(color.rgb, color.a * alpha);
    } else {
        COLOR = vec4(0.0);
    }
}