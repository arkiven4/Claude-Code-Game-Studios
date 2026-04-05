shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float feather : hint_range(0.0, 0.1) = 0.005;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float alpha = smoothstep(radius, radius - feather, dist);
    
    vec4 color = texture(TEXTURE, UV);
    COLOR = vec4(color.rgb, color.a * alpha);
}
