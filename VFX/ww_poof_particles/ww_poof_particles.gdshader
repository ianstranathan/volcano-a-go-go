shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

//float between( float gt, float lt, float axis)
//{
	//return step(gt, axis) * (1. - step(lt, axis));
//}
uniform int cell_index:hint_enum("Zero", "One", "Two");
void fragment() {
	vec2 tex1_UV = (UV + vec2(float(cell_index), 1.)) / 3.0;
	vec4 tex1 = texture(TEXTURE, tex1_UV);
	COLOR = tex1;
}
