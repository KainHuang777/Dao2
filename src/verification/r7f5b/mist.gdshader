// Original project shader. Explicit clock freezes with the preview.
shader_type canvas_item;
render_mode unshaded;
uniform float effect_time = 0.0;
uniform float direction = 1.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec2 uv=UV;
	uv.x += sin(UV.y*15.0+effect_time*0.55*direction)*0.003;
	COLOR = texture(TEXTURE,uv) * vertex_tint;
}
