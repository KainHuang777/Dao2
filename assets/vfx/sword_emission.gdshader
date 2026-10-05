shader_type canvas_item;
render_mode unshaded;

uniform vec4 emission : source_color = vec4(0.65, 1.0, 0.86, 1.0);
uniform float clock = 0.0;
uniform float strength = 1.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 source = texture(TEXTURE, UV) * vertex_tint;
	vec2 pixel = TEXTURE_PIXEL_SIZE * 3.0;
	float edge = max(max(texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, pixel.y)).a,
		texture(TEXTURE, UV - vec2(0.0, pixel.y)).a));
	float sweep = pow(0.5 + 0.5 * sin(UV.x * 12.0 - clock * 2.0), 8.0);
	vec3 lit = source.rgb + emission.rgb * (0.28 + sweep * 0.45) * strength;
	COLOR = vec4(mix(emission.rgb, lit, source.a), max(source.a, edge * 0.48 * strength));
}
