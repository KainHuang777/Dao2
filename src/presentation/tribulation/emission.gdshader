shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float strength = 1.0;
void fragment() {
 float a=0.0;
 for(int x=-2;x<=2;x++) {
  for(int y=-2;y<=2;y++) {
   a += texture(TEXTURE, UV + vec2(float(x),float(y))*TEXTURE_PIXEL_SIZE*5.0).a / 25.0;
  }
 }
 COLOR = vec4(0.28,0.65,1.0,a*strength);
}
