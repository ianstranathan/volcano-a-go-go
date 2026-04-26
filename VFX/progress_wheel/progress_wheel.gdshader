shader_type canvas_item;

float ring( vec2 uv, float outer_rad, float thickness){
    float d = length(uv);
	float aa = fwidth(d);
    float outer_circ = smoothstep(outer_rad, outer_rad + aa, d);
    float inner_circ = smoothstep(outer_rad - thickness, (outer_rad - thickness) + aa, d);
    return (1. - outer_circ) * inner_circ;
}

const float pi = 3.14159;
const float tau = 2.0 * pi;
//const vec3 progress_col = vec3(1., 1., 0.); // gradient texture to sample into
const vec3 background_col = vec3(0.156); // rgb(40)
//uniform sampler2D color_gradient;
uniform float progress: hint_range(0.0, 1.0, 0.1);
uniform vec4 progress_start_col: source_color;//  vec3(1., 1., 0.) / .8;
uniform vec4 progress_end_col: source_color;

void fragment(){
	//float progress = (sin(TIME - pi/2.) + 1.) / 2.;
    vec2 uv = 2. * UV - 1.;
 	uv.y *= -1.;
    float angle = (atan(uv.y, uv.x) + pi) / tau; // [0.5, 1], [0.5, 0]
    angle = (1. - angle); // shifting to go clockwise, starts at -pi
    //col = texture(iChannel0, vec2(angle, length(uv))).xyz;
    float the_ring = ring(uv, 0.9, 0.5);
	float aa = fwidth(the_ring);
    float progress_mask = (1. - smoothstep(progress, progress + aa, angle));

    float background_mask = smoothstep(progress, progress + aa, angle);

    vec3 progress_col_plus_mask = progress_mask * mix(progress_start_col.xyz, progress_end_col.xyz, progress); //texture(color_gradient, vec2(progress)).xyz;
    vec3 background_col_plus_mask = background_mask * background_col;
    vec3 col = the_ring * (progress_col_plus_mask + background_col_plus_mask);
	//
	float alpha = progress_start_col.a * (1. - progress) + progress_end_col.a * progress;

	col += (0.3 * sin(25. * TIME) * progress_mask) * mix(0., 1., pow(1. - progress, 2.));
    COLOR = vec4(col, the_ring * alpha);
}