shader_type canvas_item;

uniform sampler2D noise_tex: repeat_enable;

void vertex() {
	// Called for every vertex the material is visible on.
}

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

void fragment() {
	vec2 uv = 2. * UV - 1.;
	vec4 n = texture( noise_tex, UV );
	float a  = atan(uv.y, uv.x);
	float circ = sdCircle( uv, 0.8 + 0.1 * cos((4. * a + 0.1 * n.r) - TIME));
	float mm = smoothstep(0., 2. * fwidth(length(uv)), circ);
	COLOR = vec4( vec3(mm), (1. - mm));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
