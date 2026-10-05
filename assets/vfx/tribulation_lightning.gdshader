shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float clock = 0.0;
uniform float strength = 0.0;
uniform float seed = 1.0;
float hash(float p) { return fract(sin(p * 127.1 + seed * 311.7) * 43758.5453); }
float zigzag(float y) {
	float cell = floor(y);
	return mix(hash(cell), hash(cell + 1.0), fract(y)) * 2.0 - 1.0;
}
void fragment() {
	float y = UV.y;
	float bend = zigzag(y * 22.0) * 0.20 + sin(y * 17.0 + clock * 0.65 + seed) * 0.045;
	float distance = abs(UV.x - 0.5 - bend * sin(y * 3.14159));
	float core = exp(-distance * distance * 18000.0);
	float sheath = exp(-distance * distance * 1700.0);
	float bloom = exp(-distance * distance * 110.0);
	float fade = smoothstep(0.0, 0.035, y) * (1.0 - smoothstep(0.92, 1.0, y));
	vec3 color = mix(vec3(0.32, 0.57, 1.0), vec3(1.0, 0.98, 0.87), min(1.0, core + sheath));
	COLOR = vec4(color, (core + sheath * 0.6 + bloom * 0.34) * fade * strength);
}
