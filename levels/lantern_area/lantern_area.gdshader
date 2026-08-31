shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D noise_tex: repeat_enable;
uniform vec2 dim = vec2(1.);
uniform float lantern_radius = 0.4;
uniform vec2 lantern_pos; 
void fragment() {
	vec2 uv = 2. * UV - 1.;
	float ar = (dim.x / dim.y);
	uv.x *= ar;
	uv.y *= -1.;
	//vec2 p = lantern_pos;
	//p.x *= ar;
	vec2 _lantern_pos = lantern_pos;
	_lantern_pos.x *= ar;
	vec2 p = uv - _lantern_pos;
	float r = length(p);
	
	// noise to add some visual variety to the lantern rad
	vec4 noise_sample = texture(noise_tex, UV - 0.1 * TIME);
	float start = 0.1 * noise_sample.r + lantern_radius;
	float mask = smoothstep(start, start + fwidth(r), r);
	
	COLOR = vec4(vec3(0.2), mask);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
