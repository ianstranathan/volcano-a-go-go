shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec4 src_col: source_color;


void fragment() {
    vec2 uv = 2. * UV - 1.0;
    vec4 tex_sample = texture(TEXTURE, UV);
    float r = length(uv);
    
	// 
    float mask_delta = fwidth(r);
    float mask = 1.0 - smoothstep(0.95 - mask_delta, 0.95, r);
    
    // -- the derivative of the texture's red channel
    float tex_r = tex_sample.r;
    float tex_delta = fwidth(tex_r);
    
    //  2xfwidth transition around the 0.5 threshold
    float icon_edge = smoothstep(0.5 - tex_delta, 0.5 + tex_delta, tex_r);
    
    // -- cleanly swap between the original texture (mix vs add)
    vec4 final_color = mix(src_col, tex_sample, icon_edge);
    
    COLOR = final_color;
    COLOR.a *= mask;
}


