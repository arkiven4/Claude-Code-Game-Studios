shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 fire_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform sampler2D noise_tex : repeat_enable;
uniform sampler2D mask_gradient_tex : repeat_enable;
uniform vec2 speed = vec2(0.0, 1.0);
uniform float emission_strength = 2.0;

void fragment() {
    vec2 moving_uv = UV + TIME * speed;
    float noise = texture(noise_tex, moving_uv).r;
    float mask = texture(mask_gradient_tex, UV).r;
    
    float alpha = clamp(noise - mask, 0.0, 1.0);
    
    ALBEDO = fire_color.rgb;
    ALPHA = alpha * fire_color.a;
}
