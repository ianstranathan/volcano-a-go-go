shader_type canvas_item;

//void vertex() {
	//VERTEX *= 2.0;
//}

uniform int skin_tone_type:hint_enum("One", "Two", "Three", "Four", "Five");
const vec3[5] skin_tones = { vec3(0.553, 0.333, 0.141),
							vec3(0.776, 0.525, 0.259),
							vec3(0.878, 0.675, 0.412),
							vec3(0.945, 0.761, 0.490),
							vec3(1.0, 0.859, 0.675)};

uniform vec4 turban_color: source_color;
void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    float red_threshold = step(0.4, tex_color.r); 
    float green_is_low = step(0.1, tex_color.r - tex_color.g);
    float blue_is_present = step(0.05, tex_color.b - tex_color.g);

    float mask = red_threshold * green_is_low * blue_is_present;
	
	vec3 col = tex_color.xyz * (skin_tones[skin_tone_type] * (1. - mask) + turban_color.xyz * mask);
    COLOR = vec4(col, tex_color.a);
}


