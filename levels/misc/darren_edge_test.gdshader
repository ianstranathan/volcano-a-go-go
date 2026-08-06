shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D tex;
void fragment() {
	vec4 t_s = texture(tex, vec2(0.5, 0.5));
	COLOR = t_s;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
