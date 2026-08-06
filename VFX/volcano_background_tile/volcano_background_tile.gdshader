shader_type canvas_item;

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

uniform sampler2D noise_tex: repeat_enable;
uniform sampler2D normal_map: repeat_enable;
uniform sampler2D rock_tex: repeat_enable;
uniform sampler2D magma_tex: repeat_enable;
//uniform sampler2D rock_ambient_occl: repeat_enable;

mat2 rot( float angle){
	return mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle), cos(angle))
	);
}

vec2 rotated_UV(vec2 uv, mat2 rota){
	return rota* (uv - vec2(0.5)) + vec2(0.5);
}

const vec3 light_dir = vec3(0., 1., 0.);

uniform vec2 level_dims = vec2(4000, 4000);
void fragment() {
	vec2 _UV = world_position / level_dims;
	
	// -- rock and diffuse light
	vec3 normal = texture(normal_map, _UV).xyz;
	float diffuse_raw        = dot(normal,  light_dir); //normalize(light_pos)); 
	float diffuse_normalized = diffuse_raw * 0.5 + 0.5;
	float diffuse_clamped    = max( 0., diffuse_raw);
	float brightness         = mix(diffuse_clamped, diffuse_normalized, .1);
	
		//--------- making my own spatmap
	vec4 splat_map_from_noise_tex = texture(noise_tex, _UV);
	float pattern_mask = smoothstep(0.1 + 0.2 * _UV.y, 0.32, splat_map_from_noise_tex.r);
	float rock_mask = pattern_mask * smoothstep(0.55, 0.67, splat_map_from_noise_tex.r);
	pattern_mask *= (1. - rock_mask);
	float m = (1. - (pattern_mask + rock_mask));
	float magma_mask = 1. - (m * (1. - smoothstep(0.95, 1., m)));
	
	COLOR = vec4( vec3(magma_mask), 1.);
	
	//--------- rotating for pattern to look better
	vec2 uv = 2. * _UV - 1.;
	uv = rot(3.14 / 2.) * uv;
	uv *= 3.0;

	// -- bg patter
	vec3 bg_pattern_sample = texture(TEXTURE, uv).xyz;
	vec3 bg_pattern =  bg_pattern_sample * pattern_mask;

	// cel shading y/n  -----------------
	brightness = floor(brightness * 6.) / 6.;
	//
	vec3 rock_tex_sample = texture(rock_tex, 2. * _UV).xyz;
	vec3 bg_rock = rock_tex_sample * rock_mask;


	vec4 noise_sample = texture(noise_tex, _UV + vec2(0., 0.01 * TIME));
	vec4 magma_sample = texture(magma_tex, rotated_UV(_UV, rot(0.1 * TIME)) * noise_sample.r);

	vec3 bg_magma = magma_sample.xyz * (1. - (pattern_mask + rock_mask));

	float magma_glow = 1. / magma_mask;
	magma_glow *= 0.1;
	magma_glow = pow(magma_glow, 0.8);
	vec3 magma_glow_col = magma_glow * vec3(1.0, 0.5, 0.25);

	vec3 col = bg_pattern + bg_rock;
	vec3 out_col = col * brightness + 0.7 * bg_magma + magma_glow_col;

	out_col = 1.0 - exp( -out_col );
	COLOR = vec4( out_col, 1.);
}
//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
