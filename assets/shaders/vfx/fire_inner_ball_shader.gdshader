shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 ball_color : source_color = vec4(1.0, 0.2, 0.1, 1.0);
uniform float fresnel_power = 4.0;

void fragment() {
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
    float alpha = 1.0 - fresnel; // Inverted fresnel for soft center
    
    ALBEDO = ball_color.rgb;
    ALPHA = alpha * ball_color.a;
}
