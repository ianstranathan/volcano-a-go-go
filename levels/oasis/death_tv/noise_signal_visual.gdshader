shader_type canvas_item;

//uniform sampler2D screen_tex: hint_screen_texture;
uniform float scanlines_1 = 500.;
uniform float scanlines_2 = 25.;
uniform float scan_reduction = .1;

uniform float vinnette_alpla: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float vinnette_inner_radius = 0.;
uniform float vinnette_outer_radius = 1.;


float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}
vec2 crt(vec2 coord, float bend)
{
	// put in symmetrical coords
	coord = (coord - 0.5) * 2.0;

	coord *= 1.1;	

	// deform coords
	coord.x *= 1.0 + pow((abs(coord.y) / bend), 2.0);
	coord.y *= 1.0 + pow((abs(coord.x) / bend), 2.0);

	// transform back to 0.0 - 1.0 space
	coord  = (coord / 2.0) + 0.5;

	return coord;
}

void fragment() {
	vec2 uv_noise = UV * TIME;
	
	vec2 crtCoords = crt(UV, 3.2);
	//vec2 uv_scan1 = vec2(UV.x, UV.y + TIME);
	//vec2 uv_scan2 = vec2(UV.x, UV.y + TIME * .4);
	vec2 uv_scan1 = vec2(crtCoords.x, crtCoords.y + TIME);
	vec2 uv_scan2 = vec2(crtCoords.x, crtCoords.y + TIME * .4);
	
	// shadertoy has tiling textures. wouldn't be needed
	// if you set up your tex params properly
	if (crtCoords.x < 0.0 || crtCoords.x > 1.0 || crtCoords.y < 0.0 || crtCoords.y > 1.0)
		discard;
		
	vec4 screen = texture(TEXTURE, UV);
	
	float scanlines1 = sin(uv_scan1.y * scanlines_1) * scan_reduction - scan_reduction;
	float scanlines2 = sin(uv_scan2.y * scanlines_2) * scan_reduction - scan_reduction;
	
	vec4 noise = vec4(random(uv_noise), random(uv_noise), random(uv_noise), .2);
	
	float vinnette_x = abs(UV.r-.5)*2.0;
	float vinnette_y = abs(UV.g-.5)*2.0;
	float vinnette_q = 1.0-(1.0-sqrt(vinnette_x*vinnette_x+vinnette_y*vinnette_y)/vinnette_outer_radius)/(1.0-vinnette_inner_radius);
	screen += vec4(0, 0, 0, vinnette_q * vinnette_alpla);
	
	
	COLOR = screen * noise;
	
	COLOR.rgb += vec3(scanlines1);
	COLOR.rgb += vec3(scanlines2);
	
	COLOR.rgb *= vec3(5, 5, 5);
	COLOR.a = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
