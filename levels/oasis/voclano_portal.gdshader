shader_type canvas_item;


uniform sampler2D noise_texture : repeat_enable;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.1;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;

uniform sampler2D screen_texture : hint_screen_texture;

mat2 rotate(float _angle){
    return mat2(vec2(cos(_angle), -sin(_angle)),
                vec2(sin(_angle), cos(_angle)));
}
float vec3_avg(vec3 v){
	return (v.x + v.y + v.z) / 3.0;
}
void fragment() {

    vec2 moving_uv = UV * wave_frequency;
    moving_uv.x += TIME * wave_speed * 0.5;
    moving_uv.y += TIME * wave_speed * 0.3; // slightly different speed for organic look

    //vec2 distortion = (noise.rg * 2.0 - 1.0) * distortion_strength;
	vec2 distortion = vec2(0.);
    
    distortion.x += sin(UV.y * 10.0 + TIME * wave_speed) * distortion_strength * 0.3;
    distortion.y += cos(UV.x * 10.0 + TIME * wave_speed) * distortion_strength * 0.3;

    vec4 final_color = texture(TEXTURE, UV + distortion);

	vec2 uv = 2. * UV - 1.;
	vec4 noise = texture(noise_texture, UV - rotate(0.1 * TIME) * vec2(3. * length(uv)));
	float r = length(uv) + 0.2 * noise.r;
	
	// -----
	float avg = vec3_avg(final_color.xyz);
	float mask = 1. - smoothstep(0.3, 0.3 + fwidth(avg), avg);
	//vec4 screen_sample = texture(screen_texture, UV + 0.025 * noise.r );
	COLOR.xyz = (mask * (1. - avg) * vec3(1., 0., 0.)) + vec3(0.2) * (1. - mask);
	
	
	// -- clear the bg grid
	
	COLOR.a = 1. - smoothstep(0.9, 0.9 + fwidth(r), r);
	//COLOR = noise;
}