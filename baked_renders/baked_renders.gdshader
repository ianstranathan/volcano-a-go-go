shader_type canvas_item;


const vec3 g = vec3(0.92, 0.7, 0.2);
const float threshold = 0.1; 
float avg( vec3 col){
	return (col.x + col.y + col.y) / 3.;
}

void fragment() {
	vec4 s = texture(TEXTURE, UV);
	float color_distance = distance(s.rgb, g);
	float gold_mask = 1. - smoothstep(threshold, threshold + 0.1, color_distance);
	float mask = smoothstep(0.5, 0.5 + fwidth(avg(s.xyz)), avg(s.xyz));
	
	vec3 col = g * gold_mask + vec3(mask) * (1. - gold_mask);
	COLOR = vec4(col, 1.0);
}
