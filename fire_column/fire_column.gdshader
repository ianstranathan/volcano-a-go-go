shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable;
const vec3 inner_col = vec3(1., 0.96, 0.47);
const vec3 outer_col = vec3(1., 0.75, 0.3);

uniform vec2 sprite_size = vec2(1000.);

varying vec2 world_position;

//void vertex() {
   	//world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
//}

void fragment() {
    //vec2 uv = world_position / sprite_size;
	vec2 uv = 2. * UV - 1.;
	uv *= vec2(2., 12.);

    // -- cylinder projection
    vec2 sample_uv = uv;
	float v = 5.0;
    sample_uv.x = asin(clamp(uv.x, -0.999, 0.999)) + v * TIME;

	sample_uv.y *= 2.;
	//
    sample_uv *= 0.05; //

    vec2 distortion_uv = sample_uv * 2.5 + vec2(0.0, v * TIME * 0.1);
    float noise_distortion = texture(noise_tex, distortion_uv).r;

    float distortion_strength = 0.25; // Cranked up for more noticeable warbling
    float diagonal_domain = sample_uv.x + sample_uv.y + (noise_distortion * distortion_strength);


    float repeating_space = fract(2.0 * diagonal_domain);
    float smooth_pattern = 2.0 * (abs(repeating_space - 0.5));

    float target_line_edge = 0.5;
    float stripe_delta = fwidth(smooth_pattern);
    float diagonal_mask = smoothstep(target_line_edge + stripe_delta, target_line_edge, smooth_pattern);

    float border_domain = abs(uv.x) + (1.5 * noise_distortion - 0.5) * distortion_strength;

    float border_delta = fwidth(border_domain);
    float silhouette_mask = smoothstep(1.0 + border_delta, 1.0, border_domain);

    vec3 final_color =  (inner_col * diagonal_mask + outer_col * (1. - diagonal_mask));
    float final_alpha = silhouette_mask;

    COLOR = vec4(final_color, final_alpha);
	//COLOR = vec4(world_position / 1000.0,0,1);
}