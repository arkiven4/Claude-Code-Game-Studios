shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform sampler2D noise_tex : repeat_enable;
uniform sampler2D mask_tex : source_color;
uniform vec4 base_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec2 speed = vec2(0.0, -3.0);
uniform vec2 tiling = vec2(1.0, 1.0);

void fragment() {
    vec2 scrolling_uv = (UV * tiling) + (TIME * speed);
    float noise = texture(noise_tex, scrolling_uv).r;
    float mask = texture(mask_tex, UV).r;
    
    ALBEDO = base_color.rgb * COLOR.rgb;
    ALPHA = noise * mask * base_color.a * COLOR.a;
}
