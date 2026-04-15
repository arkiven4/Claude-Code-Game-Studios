shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform sampler2D main_tex : source_color;
uniform vec4 base_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);

void fragment() {
    vec4 tex = texture(main_tex, UV);
    ALBEDO = base_color.rgb * COLOR.rgb;
    ALPHA = tex.r * base_color.a * COLOR.a;
}
