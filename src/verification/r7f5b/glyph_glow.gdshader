// F5-B-F1 original local bloom: white-hot core, golden near halo, amber spill.
shader_type canvas_item;
render_mode unshaded;
uniform float strength = 4.5;
uniform float radius_px = 22.0;
uniform float dissolve = 0.0;
uniform bool dark_ink = false;
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
float grain(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
	float core=texture(TEXTURE,UV).a;
	float near_glow=0.0;
	float wide_glow=0.0;
	for(int i=0;i<12;i++) {
		float a=float(i)*0.5235988;
		vec2 dir=vec2(cos(a),sin(a))*TEXTURE_PIXEL_SIZE;
		near_glow+=texture(TEXTURE,UV+dir*3.0).a/12.0;
		wide_glow+=texture(TEXTURE,UV+dir*radius_px*0.30).a*0.040;
		wide_glow+=texture(TEXTURE,UV+dir*radius_px*0.62).a*0.028;
		wide_glow+=texture(TEXTURE,UV+dir*radius_px).a*0.015;
	}
	float n=grain(floor(UV*vec2(192.0,480.0)));
	float fade=dissolve<0.001 ? 1.0 : 1.0-smoothstep(n-0.16,n+0.16,dissolve);
	float bloom=clamp((near_glow*0.65+wide_glow)*strength,0.0,0.92);
	vec3 warm=mix(vec3(1.0,0.35,0.025),vec3(1.0,0.76,0.20),near_glow);
	vec3 center=dark_ink ? vec3(0.12,0.18,0.12) : vec3(1.0,0.985,0.79);
	COLOR=vec4(mix(warm,center,core),max(core,bloom)*fade)*vertex_tint;
}
