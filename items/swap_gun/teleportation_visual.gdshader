shader_type canvas_item;


uniform vec4 color: source_color = vec4(1.0);
uniform float control: hint_range(0.0, 1.0, 0.1);
uniform sampler2D noise_tex: repeat_enable;


void fragment(){
	vec2 uv = 2. * UV - 1.;
	vec4 n_sample = texture(noise_tex, uv *  vec2(1., 0.01) - vec2(0., TIME));
	vec4 n_sample2 = texture(noise_tex, uv *  vec2(1., 0.05) - vec2(0., 1.34 * TIME));
	
	float d = length(uv);
	
	float outer = pow(d, 4.);
	outer += step(control, n_sample.x) * step(control + 0.2, n_sample2.x);
	COLOR = vec4(color.xyz * outer, (1. - control) * d * (1. - smoothstep(0.9, 0.95, d) ));
}