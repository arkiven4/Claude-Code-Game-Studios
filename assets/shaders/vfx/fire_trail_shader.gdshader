shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D trail_tex : repeat_enable;
uniform vec2 speed = vec2(1.0, 0.0);
uniform vec2 scale = vec2(1.0, 1.0);

void fragment() {
    vec2 moving_uv = (UV * scale) + vec2(TIME * speed.x, TIME * speed.y);
    vec4 tex = texture(trail_tex, moving_uv);
    
    // Trail3D script sets vertex colors for the gradient
    ALBEDO = COLOR.rgb;
    ALPHA = tex.r * COLOR.a;
}
