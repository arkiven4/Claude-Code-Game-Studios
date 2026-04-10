shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// Procedural shockwave ring texture
// Based on tutorial: ring/donut shape with transparent center

uniform vec4 modulate : source_color = vec4(1.0, 0.8, 0.3, 0.3);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 2.0;
	
	// Create ring: difference between two circles
	float outer_radius = 0.9;
	float inner_radius = 0.6;
	
	float outer_circle = 1.0 - smoothstep(outer_radius - 0.05, outer_radius, dist);
	float inner_circle = 1.0 - smoothstep(inner_radius - 0.05, inner_radius, dist);
	
	// Ring = outer - inner
	float ring = outer_circle - inner_circle;
	
	// Soft edge
	ring = smoothstep(0.0, 1.0, ring);
	
	// Edge glow effect
	float edge_dist = min(abs(dist - outer_radius), abs(dist - inner_radius));
	float edge_glow = exp(-edge_dist * 20.0) * 0.5;
	
	float alpha = ring + edge_glow;
	
	ALBEDO = modulate.rgb;
	ALPHA = alpha * modulate.a;
}
