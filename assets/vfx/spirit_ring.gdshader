shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tint : source_color = vec4(0.4, 1.0, 0.78, 1.0);
uniform float clock = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x);
	float ring = abs(r - 0.70);
	float core = exp(-ring * ring * 6000.0);
	float halo = exp(-ring * ring * 130.0);
	float orbit = pow(0.5 + 0.5 * cos(angle * 3.0 - clock * 1.4), 12.0);
	float inner = exp(-pow(r - 0.56, 2.0) * 2500.0);
	float flecks = pow(0.5 + 0.5 * cos(angle * 36.0 + clock * 0.3), 16.0);
	float mask = (core * (0.45 + orbit) + halo * 0.45 + inner * flecks * 0.4) * strength;
	COLOR = vec4(mix(tint.rgb, vec3(1.0, 0.98, 0.85), core * 0.55), mask * tint.a);
}
