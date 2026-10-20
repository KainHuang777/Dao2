shader_type canvas_item;
render_mode unshaded;
uniform float bend = 0.0;
uniform float aspect = 1.7778;
void fragment() {
 vec2 p = UV - vec2(0.5);
 vec2 radial = p * vec2(aspect,1.0);
 vec2 uv = vec2(0.5) + p / (1.0 + bend * dot(radial,radial));
 // Overscan is in the source plate. Clamp final half-texel to avoid edge garbage.
 COLOR = texture(TEXTURE, clamp(uv, TEXTURE_PIXEL_SIZE, vec2(1.0)-TEXTURE_PIXEL_SIZE));
}
