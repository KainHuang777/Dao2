// Original project shader, F5-B. Local alpha mask, no screen reads or TIME.
shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.6;
uniform float radius_px = 10.0;
uniform float effect_time = 0.0;
uniform float dissolve = 0.0;
uniform bool glyph = false;
uniform bool dark_ink = false;
uniform vec4 tint : source_color = vec4(0.55, 0.94, 0.80, 1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
float noise(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233))) * 43758.5453); }
void fragment() {
	vec2 d = TEXTURE_PIXEL_SIZE * radius_px;
	float blur = texture(TEXTURE,UV).a * 0.16;
	for(int i=0;i<8;i++) {
		float a = float(i) * 0.785398;
		vec2 dir = vec2(cos(a),sin(a));
		blur += texture(TEXTURE,UV+dir*d*0.45).a * 0.065;
		blur += texture(TEXTURE,UV+dir*d).a * 0.04;
	}
	float alpha = texture(TEXTURE,UV).a;
	float grain = noise(floor(UV*vec2(128.0,256.0)));
	float fade = 1.0-smoothstep(grain-0.13,grain+0.13,dissolve);
	if(dissolve<0.001) { fade=1.0; }
	vec3 core = mix(tint.rgb,vec3(0.99,0.94,0.78),glyph?0.95:0.0);
	if(glyph && dark_ink) { core=vec3(0.07,0.20,0.19); }
	float ink = glyph ? alpha*(0.84+0.16*grain) : alpha*0.18;
	COLOR = vec4(mix(tint.rgb,core,alpha), (ink+blur*strength)*fade) * vertex_tint;
}
