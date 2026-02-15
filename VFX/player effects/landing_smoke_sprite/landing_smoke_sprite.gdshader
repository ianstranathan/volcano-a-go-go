shader_type canvas_item;

uniform int horizontal_frames = 21; // Set these in the Inspector
uniform int vertical_frames = 1;
uniform sampler2D noise_tex: repeat_enable;
uniform float t: hint_range(0.0, 1.0, 0.1);
void fragment() {
	// This "zooms in" the UV to a 0.0 - 1.0 range for the current frame
	vec2 uv = 2. * fract(UV * vec2(float(horizontal_frames), float(vertical_frames))) - 1.;

	vec4 noise_sample_1 = texture(noise_tex, 0.121 * uv - vec2(0.056 * TIME, -0.131 * TIME));
	vec4 noise_sample_2 = texture(noise_tex, 0.257 * uv + vec2(0.113 * TIME, 0.087 * TIME));
	float n = noise_sample_1.r * noise_sample_2.r;
	float _t = t * t;
	float mask = smoothstep(_t, _t + fwidth(n), n);
	
	float a = 1. - (t * t);
	COLOR *= mask * a;
}
