shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// Procedural spark particle texture
// Based on tutorial: small bright dot with soft falloff

uniform vec4 modulate : source_color = vec4(1.0, 0.3, 0.1, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 2.0;
	
	// Small bright core
	float core = exp(-dist * 10.0);
	
	// Soft outer glow
	float glow = exp(-dist * 4.0) * 0.5;
	
	float alpha = max(core, glow);
	
	ALBEDO = modulate.rgb;
	ALPHA = alpha * modulate.a;
}
