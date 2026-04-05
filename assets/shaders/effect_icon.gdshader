/// effect_icon.gdshader
/// Renders a status effect icon with an animated border-wipe outline showing remaining duration.
/// Duration method: box/ring outline only — no bottom progress bar.
/// Target: Forward+ renderer (Godot 4.6)

shader_type spatial;
render_mode blend_mix, unshaded, depth_test_disabled;

uniform sampler2D icon_texture : source_color;
uniform bool use_texture = false;
uniform vec4 icon_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float duration_ratio : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	/// Billboard: strip rotation, keep world position.
	mat4 modified_modelview = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = modified_modelview;
}

void fragment() {
	/// Shared: clock-wipe angle from top-center, going clockwise.
	vec2 center = UV - 0.5;
	float angle = atan(center.y, center.x);
	float top_angle = angle - 3.14159265 * 0.5;
	if (top_angle < 0.0) top_angle += 6.2831853;
	float duration_angle = duration_ratio * 6.2831853;

	if (use_texture) {
		vec4 tex_color = texture(icon_texture, UV);
		if (tex_color.a < 0.1) {
			/// Transparent area around icon: draw circular ring outline.
			float dist = length(center);
			float border_width = 0.06;
			if (dist > 0.45 - border_width && dist < 0.48) {
				if (top_angle < duration_angle) {
					float glow = 1.0 - smoothstep(0.0, border_width, dist - (0.45 - border_width));
					ALBEDO = mix(vec3(0.1, 0.1, 0.15), vec3(1.0, 1.0, 1.0), glow);
					ALPHA = glow * 0.8;
				} else {
					ALBEDO = vec3(0.15, 0.15, 0.2);
					ALPHA = 0.3;
				}
			} else {
				ALBEDO = vec3(0.1, 0.1, 0.15);
				ALPHA = 0.6;
			}
		} else {
			ALBEDO = tex_color.rgb * icon_color.rgb;
			ALPHA = tex_color.a;
		}
	} else {
		/// Placeholder colored box: border-wipe outline on all four edges.
		float border = 0.08;
		float edge_x = min(UV.x, 1.0 - UV.x);
		float edge_y = min(UV.y, 1.0 - UV.y);
		float edge = min(edge_x, edge_y);

		if (edge < border) {
			if (top_angle < duration_angle) {
				/// Remaining duration: bright white border.
				ALBEDO = vec3(1.0, 1.0, 1.0);
				ALPHA = 0.95;
			} else {
				/// Elapsed: dim gray border.
				ALBEDO = vec3(0.2, 0.2, 0.25);
				ALPHA = 0.4;
			}
		} else {
			ALBEDO = icon_color.rgb;
			ALPHA = 0.85;
		}
	}
}
