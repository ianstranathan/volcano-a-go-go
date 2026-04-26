shader_type canvas_item;

uniform sampler2D noise_tex: repeat_enable;
uniform sampler2D color_gradient_tex;
void vertex() {
	// Called for every vertex the material is visible on.
}



float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);

    float b = sqrt(r*r-d*d);  // can delay this sqrt by rewriting the comparison
    return ((p.y-b)*d > p.x*b) ? length(p-vec2(0.0,b))*sign(d)
                               : length(p-vec2(-d,0.0))-r;
}

void fragment() {
	vec2 uv = 2. * UV - 1.;
	
	uv.x *= 0.67;
//	uv.x += UV.y * UV.y;
	vec2 n_uv = vec2(0.1 * uv.x, uv.y);
	
	float t = 0.45 * TIME;
	vec4 noise_sample = texture( noise_tex, UV * vec2(0.1, 1.) + (120. * n_uv.x * n_uv.x) - t);
	
	noise_sample = 2. * noise_sample * noise_sample;
	float mask_noise = mix(0.01, 0.42, uv.y) * noise_sample.r;
	float mask = 1. - sdVesica(uv, 0.25 + 0.1 * noise_sample.r, 1. + 0.1 * mask_noise);
	float fw = fwidth(mask); // -- the change in distance between adjacent pixels
	
	
	mask = smoothstep(-fw, fw, mask);
	vec3 col = texture(color_gradient_tex, vec2(2. * (1. - UV.y) * 
	                   noise_sample.r * noise_sample.r)).xyz * mask * noise_sample.r;
	COLOR = vec4( col, mask);;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
