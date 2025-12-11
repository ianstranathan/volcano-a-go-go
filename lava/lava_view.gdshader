shader_type canvas_item;

const float lava_level = -0.5;
const float blur = 0.05;
const vec3 lava_top_col = vec3(1.0, 0.5, 0.25);
const vec3 lava_body_col = vec3(1., 0.1, 0.2);

uniform float _t;
//uniform vec2 resolution;

void fragment() {
	vec2 uv = 2. * UV - 1.;
	uv.y *= -1.0;
	
	float _time = _t > 0.? _t : TIME;
	vec2 resolution = 1. / SCREEN_PIXEL_SIZE;
	uv.x *= resolution.x / resolution.y;


	// the top of the wave
	float func = 0.3 * sin(0.2 * uv.x - _time);
	//float func = -0.2;
	func += lava_level; // domain disp of lava to be chosen baseline
	vec2 func_rel_pos = uv - vec2(uv.x, func);
	//float lava_bubbles = 1. - smoothstep(0., 0.2, uv.y - shift);// change the function to include the lava bubbles
	float dist_field = length(func_rel_pos);

	float dist = 1.0 / dist_field;
	dist *= 0.1;
	dist = pow(dist, 0.8);
	//dist += dist * prod * (1. - step(0.2, abs(uv.y - func)));// add the lava bubbles to the dist func
	vec3 col = mix(lava_body_col, lava_top_col, dist) * dist;
	col = 1.0 - exp( -col );
	vec4 top_lava_layer = vec4(col, dist * dist);
	
	// Lava body
	float body_mask = 1. - smoothstep(func - 0.01, func, uv.y);
	float gradient_from_bottom = smoothstep(-1., func, uv.y);
	
	vec4 lava_body = vec4( mix(lava_top_col, lava_body_col, gradient_from_bottom * body_mask), body_mask);
	
	COLOR = lava_body + top_lava_layer;
}