shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

mat2 rotate(float _angle){
    return mat2(vec2(cos(_angle), -sin(_angle)),
                vec2(sin(_angle), cos(_angle)));
}

uniform sampler2D chain_tex: repeat_enable, filter_nearest;

void fragment() {
	vec2 uv = UV;
	uv.x -= TIME;
	uv.y += 0.25 * sin(1. * uv.x - 30. * TIME);
	COLOR = texture(chain_tex, rotate(PI/2.) * uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
