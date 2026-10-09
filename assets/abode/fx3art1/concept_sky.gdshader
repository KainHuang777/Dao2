shader_type canvas_item;
render_mode unshaded;
uniform float viewport_aspect = 1.777778;
uniform float source_aspect = 1.777778;
uniform float background_focal_x = 0.5;
uniform float flow_time = 0.0;
uniform float energy = 0.0;
uniform bool reduced_motion = false;
// Local source-plate patches: feather wider than the displacement, so the
// distant rocks bob without a rectangular seam or movement of the Buddha face.
float rock_patch(vec2 uv, vec2 centre, vec2 half_size) {
	vec2 d = abs(uv - centre) / half_size;
	return 1.0 - smoothstep(0.72, 1.0, max(d.x, d.y));
}
float mist(vec2 uv, vec2 origin, float seed, float time) {
	float phase = time * (0.055 + seed * 0.004) + seed * 0.271;
	float cycle = fract(phase);
	float variation = fract(sin((floor(phase) + seed * 7.13) * 12.9898) * 43758.5453);
	vec2 centre = origin + vec2((variation - 0.5) * 0.027 + sin(seed * 9.1 + time * 0.13) * 0.006, -cycle * 0.028);
	vec2 size = vec2(0.015 + cycle * 0.023, 0.010 + cycle * 0.012);
	vec2 p = (uv - centre) / size;
	float body = exp(-dot(p, p) * 2.1);
	float wisps = 0.72 + 0.28 * sin(uv.x * 490.0 + sin(uv.y * 260.0 + time * 0.2) * 2.0 + seed);
	return body * wisps * sin(cycle * 3.141593);
}
void fragment() {
	vec2 uv = vec2((UV.x - 0.5) * min(1.0, viewport_aspect / source_aspect) + background_focal_x,
		(UV.y - 0.5) * min(1.0, source_aspect / viewport_aspect) + 0.5);
	uv = clamp(uv, vec2(0.0001), vec2(0.9999));
	vec2 sample_uv = uv;
	float left_x = mix(0.577, 0.566, smoothstep(0.26, 0.54, uv.y));
	float falls = (1.0 - smoothstep(0.004, 0.011, abs(uv.x - left_x)))
		* smoothstep(0.255, 0.30, uv.y) * (1.0 - smoothstep(0.54, 0.59, uv.y));
	falls += (1.0 - smoothstep(0.005, 0.012, abs(uv.x - 0.689)))
		* smoothstep(0.205, 0.245, uv.y) * (1.0 - smoothstep(0.60, 0.66, uv.y));
	float haze = 0.0;
	if (!reduced_motion) {
		// Different long periods, approximately 2–4 source pixels; only the selected debris.
		float drift = rock_patch(uv, vec2(0.455, 0.241), vec2(0.009, 0.026)) * sin(flow_time * 0.25) * 0.0020;
		drift += rock_patch(uv, vec2(0.474, 0.326), vec2(0.019, 0.065)) * sin(flow_time * 0.19 + 1.9) * 0.0026;
		drift += rock_patch(uv, vec2(0.518, 0.294), vec2(0.008, 0.026)) * sin(flow_time * 0.22 + 4.1) * 0.0018;
		drift += rock_patch(uv, vec2(0.522, 0.401), vec2(0.009, 0.026)) * sin(flow_time * 0.17 + 2.8) * 0.0022;
		drift += rock_patch(uv, vec2(0.494, 0.458), vec2(0.007, 0.025)) * sin(flow_time * 0.21 + 5.2) * 0.0018;
		sample_uv.y -= drift;
		sample_uv.x += sin(uv.y * 175.0 - flow_time * 3.4) * 0.0014 * falls;
		sample_uv.y += sin(uv.y * 235.0 - flow_time * 5.5) * 0.0021 * falls;
		// Fixed varied phases create irregular billowing; presentation never consumes rule RNG.
		for (int i = 0; i < 3; i++) {
			haze += mist(uv, vec2(0.565, 0.575), float(i + 1), flow_time);
			haze += mist(uv, vec2(0.693, 0.644), float(i + 4), flow_time);
		}
	}
	vec4 col = texture(TEXTURE, clamp(sample_uv, vec2(0.0001), vec2(0.9999)));
	float streak = (0.5 + 0.5 * sin(uv.y * 290.0 - flow_time * 6.0 + uv.x * 370.0)) * falls;
	if (!reduced_motion) col.rgb += vec3(0.055, 0.065, 0.075) * streak;
	col.rgb = mix(col.rgb, vec3(0.95, 0.88, 0.77), clamp(haze * 0.28, 0.0, 0.32));
	col.rgb = mix(col.rgb, col.rgb * vec3(0.50, 0.58, 0.72), energy * 0.45);
	COLOR = col;
}
