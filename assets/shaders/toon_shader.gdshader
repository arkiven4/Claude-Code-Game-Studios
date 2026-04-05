shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float shadow_threshold : hint_range(0, 1) = 0.5;
uniform float shadow_softness : hint_range(0, 1) = 0.05;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_strength : hint_range(0, 1) = 0.2;
uniform float rim_softness : hint_range(0, 1) = 0.1;

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
}

void light() {
	// Standard Toon Diffuse
	float dot_product = dot(NORMAL, LIGHT);
	float diffuse_stepped = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, dot_product);
	
	// Mix Albedo with Shadow Color
	vec3 diffuse_color = mix(shadow_color.rgb * ALBEDO, ALBEDO, diffuse_stepped);
	
	// Rim Light (Stylized)
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_intensity = smoothstep(1.0 - rim_strength - rim_softness, 1.0 - rim_strength + rim_softness, rim_dot);
	// Only show rim light where the main light is hitting
	rim_intensity *= clamp(dot_product, 0.0, 1.0); 
	
	DIFFUSE_LIGHT += diffuse_color * LIGHT_COLOR * ATTENUATION;
	SPECULAR_LIGHT += rim_color.rgb * rim_intensity * LIGHT_COLOR * ATTENUATION;
}
