shader_type canvas_item;


uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float bottom_bias : hint_range(0.0, 1.0) = 0.6;
uniform vec2 uv_scale = vec2(10.0, 10.0);
uniform float edge_size : hint_range(0.0, 0.3) = 0.08;
uniform vec4 sand_color : source_color = vec4(0.85, 0.7, 0.45, 1.0);
uniform sampler2D noise_tex : hint_default_white, repeat_enable;
uniform sampler2D rock_tex;


float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void vertex(){
	VERTEX.y += sign(VERTEX.y) * step(0.,VERTEX.y) * 1000. * pow(dissolve_progress, 2.0);
}
void fragment()
{
    vec4 main_tex = texture(rock_tex, UV);
    float fine_noise = texture(noise_tex, UV * uv_scale).r;
    float particle_noise = hash(UV * 300.0);
    float combined_noise = mix(fine_noise, particle_noise, 0.3);
    float height_weight = mix(1.0, 1.0 - UV.y, bottom_bias);
    float pixel_dissolve_value = combined_noise * height_weight;
    float current_threshold = mix(-0.1, 1.1, dissolve_progress);
    float alpha_mask = step(pixel_dissolve_value, current_threshold);
    float visible_mask = 1.0 - alpha_mask;
    float edge_factor = clamp((pixel_dissolve_value - current_threshold) / max(edge_size, 0.0001), 0.0, 1.0);
    vec3 final_rgb = mix(sand_color.rgb, main_tex.rgb, edge_factor);
    COLOR = vec4(final_rgb, main_tex.a * visible_mask);
}