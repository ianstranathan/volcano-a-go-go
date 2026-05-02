shader_type canvas_item;

uniform float using = 0.;

void vertex() {
	VERTEX += using * vec2( sign(VERTEX.x), sign(VERTEX.y)) * 1. * sin(20. * TIME);
}

float sdVesica(vec2 p, float w, float h)
{
    float d = 0.5*(w*w-h*h)/h;
    p = abs(p);
    vec3 c = (w*p.y<d*(p.x-w)) ? vec3(0.0,w,0.0) : vec3(-d,0.0,d+h);
    return length(p-c.yx) - c.z;
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

uniform sampler2D noise_tex: repeat_enable;

void fragment() {
	vec2 uv = 2. * UV - 1.;
	float sdf = sdSegment( uv, vec2(0.0, 0.4), vec2(0.0, -0.4));
	float d = length(uv);
	float f = fwidth(d);
	float capsule_mask = smoothstep(0.5, 0.5 + f, sdf);

	// noise
	vec4 noise_sample = texture(noise_tex, UV - vec2(0., TIME));
	vec4 noise_sample2 = texture(noise_tex, 0.5 * UV - vec2(0., 1.273 * TIME));
	// ---
	float noise_disp = clamp(2. * noise_sample.r * noise_sample2.r, 0., 1.);
	float flame_sdf = sdVesica(uv.yx - vec2(0.0, 0.), 0.4 + 0.2 * noise_disp,  0.2);
	//float flame_mask = smoothstep(0.0, 0. + f, flame_sdf);

    // Dampen the glow
	float dist = 1. / clamp(flame_sdf, 0.01, 1.);
    dist *= 0.2;
    dist = pow(dist, 0.8);
	// ---------------------------------
	// bending capsule mask
	float mask = (1. - capsule_mask) * step(0.4 - 0.5 * uv.x * uv.x, -uv.y);
	float flame_mask = using * dist * (1. - mask);
	vec3 col = flame_mask * vec3(1.0, 0.5, 0.25) + (1. - abs(uv.x)) * mask * vec3(0.1, 0.2, 1.);
	//vec3 col = vec3(dist);
	//col *= (1. - capsule_mask) * step(0., -uv.y)
	col = 1.0 - exp( -col );
	COLOR = vec4(col, mask + (1. - mask) * pow(flame_mask, 4.));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
