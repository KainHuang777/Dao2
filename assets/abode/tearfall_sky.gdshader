shader_type canvas_item;
render_mode unshaded;

uniform float viewport_aspect = 1.777778;
uniform float source_aspect = 1.777778;
uniform float background_focal_x = 0.5;
uniform float flow_time = 0.0;
uniform float energy = 0.0;
uniform bool reduced_motion = false;

// Bounded cascade mask: early exit if outside range to completely eliminate pow(x, 4.0) overflows and NaNs
float cascade_mask(vec2 uv, float center_x, float half_width, float top, float bottom) {
	float dx = abs(uv.x - center_x);
	if (dx > half_width * 3.0 || uv.y < top - 0.015 || uv.y > bottom + 0.015) {
		return 0.0;
	}
	float norm_x = dx / half_width;
	float across = exp(-norm_x * norm_x * norm_x * norm_x);
	return across * smoothstep(top, top + 0.018, uv.y)
		* (1.0 - smoothstep(bottom - 0.035, bottom, uv.y));
}

void fragment() {
	vec2 uv = UV;
	float horizontal_span = min(1.0, viewport_aspect / source_aspect);
	float vertical_span = min(1.0, source_aspect / viewport_aspect);
	uv.x = (UV.x - 0.5) * horizontal_span + background_focal_x;
	uv.y = (UV.y - 0.5) * vertical_span + 0.5;
	uv = clamp(uv, vec2(0.0001), vec2(0.9999));

	if (reduced_motion) {
		vec4 base_col = texture(TEXTURE, uv);
		if (energy > 0.001) {
			base_col.rgb = mix(base_col.rgb, base_col.rgb * vec3(0.50, 0.58, 0.72), energy * 0.45);
		}
		COLOR = base_col;
	} else {
		// Broad island falls are fed by subtle water paths across the cheeks
		float falling_water = cascade_mask(uv, 0.303, 0.020, 0.253, 0.454)
			+ cascade_mask(uv, 0.447, 0.012, 0.221, 0.351)
			+ cascade_mask(uv, 0.397, 0.010, 0.347, 0.468);

		// Wider eyelid curtains feed the catchment tiers; carved eyes stay still
		float left_channel_x = mix(0.374, 0.372, smoothstep(0.181, 0.300, uv.y));
		float right_channel_x = mix(0.411, 0.413, smoothstep(0.192, 0.304, uv.y));
		float cheek_water = cascade_mask(uv, left_channel_x, 0.0065, 0.175, 0.316)
			+ cascade_mask(uv, right_channel_x, 0.0052, 0.185, 0.320);

		falling_water = clamp(falling_water + cheek_water * 0.7, 0.0, 1.0);

		vec2 water_uv = uv;
		if (falling_water > 0.0005) {
			// Gentle and smooth displacement without high-frequency aliasing
			water_uv.x += sin(uv.y * 45.0 - flow_time * 2.5) * 0.00035 * falling_water;
			water_uv.y += sin(uv.y * 60.0 - flow_time * 3.5) * 0.00085 * falling_water;
			water_uv = clamp(water_uv, vec2(0.0001), vec2(0.9999));
		}

		vec4 col = texture(TEXTURE, water_uv);

		if (falling_water > 0.0005) {
			// Subtle waterfall shimmer
			col.rgb += vec3(0.010, 0.014, 0.016) * falling_water
				* (0.5 + 0.5 * sin(uv.y * 50.0 - flow_time * 4.0));
		}

		if (energy > 0.001) {
			col.rgb = mix(col.rgb, col.rgb * vec3(0.50, 0.58, 0.72), energy * 0.45);
		}

		COLOR = col;
	}
}
