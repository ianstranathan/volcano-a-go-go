shader_type canvas_item;

uniform sampler2D noise_tex: repeat_enable;
uniform float fuzziness : hint_range(0.0, 0.1) = 0.03;
uniform float speed = 1.0;

void vertex() {
	VERTEX += vec2(sign(VERTEX.x), sign(VERTEX.y)) * 5. * sin(4. * TIME);
}

void fragment() {
	vec2 moving_uv = UV + vec2(TIME * speed * 0.1);
	vec4 noise_sample = texture(noise_tex, moving_uv);
	// --
	vec2 distorted_uv = UV + (noise_sample.xy - 0.5) * fuzziness;
	vec4 col = texture(TEXTURE, distorted_uv);
	COLOR = col;
	COLOR += 0.2 * COLOR.a;
	COLOR.a *= 2. * (UV.y * UV.y);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
