shader_type spatial;
render_mode blend_mix, unshaded, depth_test_disabled;

uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 full_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec4 empty_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

void vertex() {
	// Manual Billboard logic
	// Get the model-view matrix and zero out the rotation part
	mat4 modified_modelview = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], 
		INV_VIEW_MATRIX[1], 
		INV_VIEW_MATRIX[2], 
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = modified_modelview;
}

void fragment() {
	if (UV.x <= health_ratio) {
		vec3 hp_color;
		if (health_ratio > 0.5) {
			hp_color = mix(mid_color.rgb, full_color.rgb, (health_ratio - 0.5) * 2.0);
		} else {
			hp_color = mix(empty_color.rgb, mid_color.rgb, health_ratio * 2.0);
		}
		ALBEDO = hp_color;
		ALPHA = 1.0;
	} else {
		ALBEDO = bg_color.rgb;
		ALPHA = bg_color.a;
	}
}
