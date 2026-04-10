shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// Procedural cross/plus flare texture
// Based on tutorial: two perpendicular lines intersecting with center glow

uniform vec4 modulate : source_color = vec4(1.0, 0.6, 0.1, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	
	// Create horizontal line
	float h_line = 1.0 - smoothstep(0.0, 0.05, abs(uv.y));
	h_line *= step(abs(uv.x), 0.5);
	
	// Create vertical line
	float v_line = 1.0 - smoothstep(0.0, 0.05, abs(uv.x));
	v_line *= step(abs(uv.y), 0.5);
	
	// Combine lines
	float cross = max(h_line, v_line);
	
	// Add center glow
	float center_dist = length(uv);
	float center_glow = exp(-center_dist * 8.0);
	
	// Combine cross and center glow
	float alpha = max(cross * 0.7, center_glow);
	
	// Soft edge falloff
	alpha *= smoothstep(0.7, 0.3, center_dist);
	
	ALBEDO = modulate.rgb;
	ALPHA = alpha * modulate.a;
}
