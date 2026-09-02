shader_type canvas_item;
render_mode blend_premul_alpha;
void vertex() {
	// Called for every vertex the material is visible on.
}
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}
uniform sampler2D bg_tex: repeat_enable;
//void fragment() {
	//vec2 uv = 2.0 * UV - 1.0;
    //float dist = 1.0 / length((10. + 2. * sin(4. * TIME)) * uv);
    //dist = pow(dist, 0.8);
//
    //vec3 glow_color = dist * vec3(1.0, 0.5, 0.25);
    //glow_color = 1.0 - exp(-glow_color);
//
    //float glow_alpha = clamp(length(glow_color), 0.0, 1.0);
//
    //vec4 bg_sample = texture(bg_tex, UV);
    //vec4 minimap_mask = texture(TEXTURE, UV);
//
    //vec3 base = bg_sample.rgb * 0.75;
    //base *= 1.0 - minimap_mask.r;
    //base += minimap_mask.rgb;
//
    //COLOR.rgb = glow_color * glow_alpha
              //+ base * (1.0 - glow_alpha);
    //COLOR.a = 1.0;
//}
void fragment() {
    vec2 uv = 2.0 * UV - 1.0;
    float intensity = 1.0 / length(
        (15.0 + 2.0 * sin(4.0 * TIME)) * uv
    );
    intensity = pow(intensity, 0.8);
    vec3 glow = intensity * vec3(1.0, 0.5, 0.25);
    glow = 1.0 - exp(-glow);
    vec4 bg_sample = texture(bg_tex, UV);
    vec4 minimap_mask = texture(TEXTURE, UV);
    vec3 base = bg_sample.rgb * 0.75;
    base *= 1.0 - minimap_mask.r;
    base += minimap_mask.rgb;
    float glow_alpha = clamp(intensity, 0.0, 1.0);
    vec3 col = glow + base * (1.0 - glow_alpha);
    COLOR = vec4(col, 1.);
}
//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
