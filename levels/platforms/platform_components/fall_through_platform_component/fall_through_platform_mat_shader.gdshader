shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}
uniform vec4 src_col: source_color;

void fragment() {
	COLOR = src_col;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
