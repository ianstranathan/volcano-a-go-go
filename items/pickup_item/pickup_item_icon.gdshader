shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec4 src_col: source_color;

// https://www.shadertoy.com/view/4stcWH
// https://www.shadertoy.com/view/XsdXRl
void fragment() {
    vec2 uv = 2. * UV - 1.0;
	
	//float d = sqrt(uv.x*uv.x + uv.y*uv.y);
    //float cng = asin(d);
	//float lambda = atan(uv.x*sin(cng) , d*cos(cng));
	//float phi = asin(uv.y*sin(cng) / d);
	//vec2 duv = vec2(lambda * 2. / PI , phi * 2.0 / PI);
	//duv.x = duv.x*(1.0 - 0.5*abs(duv.y)*(abs(duv.y)));
	
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


