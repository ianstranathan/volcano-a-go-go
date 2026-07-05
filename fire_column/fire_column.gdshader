shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable;
//uniform vec2 chunk_dims;
const vec3 inner_col = vec3(1., 0.96, 0.47);
const vec3 outer_col = vec3(1., 0.75, 0.3);
const vec2 sprite_scale = vec2(1.06);//, 0.16);
const vec2 res = vec2(128.0);
const vec2 sprite_res = sprite_scale * res;

uniform vec2 texture_size = vec2(512.0, 512.0); // Size of noise file, NOT the chunk
varying vec2 world_position;
void vertex() {
    // 1. Calculate absolute position for seamless noise mapping
   	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    //world_position = mod(raw_world, texture_size);
}

void fragment() {
	// -- perfect if UV instead of world position
    vec2 uv = 2.0 * (world_position) - 1.0;
	uv *= 0.001;
    uv.x *= 1.3; // so you can see boundary
	
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
}
