shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// Procedural flash/flare texture - soft circle with glow
// Based on tutorial: single circle shape with transparent background

uniform vec4 modulate : source_color = vec4(1.0);

void fragment() {
	// Calculate UV distance from center (0.5, 0.5)
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 2.0; // Normalize to 0-1 range
	
	// Soft circle with smooth falloff
	float smoothness = 0.95;
	float circle = smoothstep(1.0, smoothness, dist);
	
	// Invert: center is white, edges are transparent
	float alpha = 1.0 - circle;
	
	// Apply glow falloff
	alpha = pow(alpha, 1.5);
	
	ALBEDO = modulate.rgb;
	ALPHA = alpha * modulate.a;
}
