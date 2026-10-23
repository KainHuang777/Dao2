shader_type canvas_item;
render_mode unshaded;
uniform sampler2D art_texture : filter_linear, repeat_disable;
uniform vec2 image_size = vec2(64.0);
uniform vec2 pixel_scale = vec2(1.0);
uniform bool enabled = true;
varying vec4 tint;

// Transparent outside source bounds; never clamp edge pixels into a rectangular frame.
vec4 source_at(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) { return vec4(0.0); }
	return texture(art_texture, uv);
}

void vertex() {
	tint = COLOR;
	if (enabled) {
		vec2 pad = vec2(7.0) / pixel_scale;
		vec2 side = UV * 2.0 - 1.0;
		VERTEX += side * pad;
		UV += side * pad / image_size;
	}
}

void fragment() {
	vec4 original = source_at(UV);
	if (!enabled || original.a >= 0.999) {
		COLOR = original * tint;
	} else {
		vec2 px = 1.0 / (image_size * pixel_scale);
		float solid = step(0.75, original.a);
		float expanded = solid;
		// Square dilation matches the approved SVG feMorphology footprint.
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				expanded = max(expanded, step(0.75, source_at(UV + vec2(float(x), float(y)) * px * 1.15).a));
			}
		}
		float ring = max(0.0, expanded - solid) * 0.58;
		// Bounded Gaussian approximation, sigma=1.5 display pixels, down=1.8.
		float shadow = 0.0;
		float weights = 0.0;
		for (int y = -2; y <= 2; y++) {
			for (int x = -2; x <= 2; x++) {
				vec2 offset = vec2(float(x), float(y)) * 1.5;
				float w = exp(-dot(offset, offset) / 4.5);
				shadow += source_at(UV + (offset - vec2(0.0, 1.8)) * px).a * w;
				weights += w;
			}
		}
		shadow = shadow / weights * 0.24;
		float behind = ring + shadow * (1.0 - ring);
		vec3 behind_rgb = vec3(0.360784, 0.325490, 0.270588) * ring
			+ vec3(0.317647, 0.294118, 0.239216) * shadow * (1.0 - ring);
		float alpha = original.a + behind * (1.0 - original.a);
		vec3 rgb = original.rgb * original.a + behind_rgb * (1.0 - original.a);
		COLOR = vec4(rgb / max(alpha, 0.00001), alpha) * tint;
	}
}
