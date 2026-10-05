shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec4 tint : source_color = vec4(0.3, 1.0, 0.85, 1.0);
void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE * 2.0;
	float glow = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float weight = exp(-float(x * x + y * y) * 0.5);
			glow += texture(TEXTURE, UV + vec2(float(x), float(y)) * p).a * weight;
		}
	}
	COLOR = vec4(tint.rgb, glow / 6.1689 * tint.a);
}
