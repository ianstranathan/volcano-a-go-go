shader_type canvas_item;

uniform sampler2D splatmap: repeat_enable;
uniform sampler2D tex1: repeat_enable;
uniform sampler2D tex2: repeat_enable;
uniform sampler2D tex3: repeat_enable;

uniform sampler2D noise_tex: repeat_enable;

const float tex1_res = 1.3;
const float tex2_res = 2.5;
const float tex3_res = 3.1;


mat2 rot(float angle){
	return mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
}

void fragment() {
	vec2 uv = 2. * UV - 1.;
//	float x = (uv.x);
//	float func = (x * x - 0.5);
//	float parab = smoothstep(0.0, 1., length(uv - vec2(uv.x, func)));
	
	vec4 splatmapcolor = texture(splatmap, rot(0.005 * TIME) * 
										  (UV - vec2(0.5)) + vec2(0.5) - vec2(0., 0.01 * TIME)
								);
	
	vec4 noise_sample = texture(noise_tex, UV - 0.005 * vec2(0., TIME)
							   );
	
	// just turing UV.y upside down and adding some noise
	float heat_uv_disp = ((1. - UV.y) - 0.5) * 1.5 * noise_sample.r;
	vec2 heat_uv = UV * heat_uv_disp - vec2(0., 0.01 * TIME);
	
	
	vec3 col_1 = texture(tex3, rot(3.14 / 8.) * (heat_uv)
	 * tex1_res + noise_sample.r).rgb * splatmapcolor.r;
	vec3 col_2 = texture(tex1, heat_uv * tex2_res).rgb * splatmapcolor.g;
	vec3 col_3 = texture(tex1, heat_uv * tex3_res).rgb * splatmapcolor.b;
	
	
	vec3 col = col_1 + col_2 + col_3;
	COLOR = vec4(col, 0.7);
}
