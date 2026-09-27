shader_type canvas_item;
render_mode unshaded;

uniform float viewport_aspect = 1.777778;
uniform float source_aspect = 1.777778;
uniform float flow_time = 0.0;
uniform float energy = 0.0;
uniform bool reduced_motion = false;

float cascade_mask(vec2 uv, float center_x, float half_width, float top, float bottom) {
	float across = exp(-pow((uv.x - center_x) / half_width, 4.0));
	return across * smoothstep(top, top + 0.018, uv.y)
		* (1.0 - smoothstep(bottom - 0.035, bottom, uv.y));
}

void fragment() {
	vec2 uv = UV;
	float horizontal_span = min(1.0, viewport_aspect / source_aspect);
	float vertical_span = min(1.0, source_aspect / viewport_aspect);
	float focal_x = mix(0.215, 0.5, smoothstep(0.75, 1.65, viewport_aspect));
	uv.x = (UV.x - 0.5) * horizontal_span + focal_x;
	uv.y = (UV.y - 0.5) * vertical_span + 0.5;
	// Broad island falls are fed by subtle water paths across the cheeks.
	float falling_water = cascade_mask(uv, 0.143, 0.020, 0.253, 0.454)
		+ cascade_mask(uv, 0.287, 0.012, 0.221, 0.351)
		+ cascade_mask(uv, 0.237, 0.010, 0.347, 0.468);
	// Wider eyelid curtains feed the catchment tiers; carved eyes stay still.
	float left_channel_x = mix(0.214, 0.212, smoothstep(0.181, 0.300, uv.y));
	float right_channel_x = mix(0.251, 0.253, smoothstep(0.192, 0.304, uv.y));
	float cheek_water = cascade_mask(uv, left_channel_x, 0.0065, 0.175, 0.316)
		+ cascade_mask(uv, right_channel_x, 0.0052, 0.185, 0.320);
	falling_water = clamp(falling_water + cheek_water * 0.7, 0.0, 1.0);
	float motion = reduced_motion ? 0.0 : 1.0;
	vec2 water_uv = uv;
	water_uv.x += sin(uv.y * 130.0 - flow_time * 3.0) * 0.00045 * falling_water * motion;
	water_uv.y += sin(uv.y * 170.0 - flow_time * 4.5) * 0.0011 * falling_water * motion;
	vec4 col = texture(TEXTURE, water_uv);
	// Keep the distant spray subdued instead of drawing luminous tear lines.
	col.rgb += vec3(0.012, 0.016, 0.018) * falling_water * motion
		* (0.5 + 0.5 * sin(uv.y * 195.0 - flow_time * 5.0));
	col.rgb = mix(col.rgb, col.rgb * vec3(0.50, 0.58, 0.72), energy * 0.45);
	COLOR = col;
}
