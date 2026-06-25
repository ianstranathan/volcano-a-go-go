shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}
uniform vec4 src_col: source_color;
void fragment() {
	vec2 uv = 2. * UV - 1.;
	uv.x -= 0.1 * TIME;
	uv *= 0.2;
	float x = abs(uv.y) + uv.x;
	float mask = 2. * abs(fract(x) - 0.5);
	mask = smoothstep(0.6, 0.65, mask);
	vec3 col = src_col.xyz * mask;
	//float a = (0.3 * mask) * (1. - hit_modulation) + mask * hit_modulation;
	COLOR = vec4(col, mask * src_col.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
