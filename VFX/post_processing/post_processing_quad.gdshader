shader_type canvas_item;

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_tex : repeat_enable;

uniform vec2 camera_world_pos;
uniform float lava_level;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float heat_range : hint_range(0.0, 1000.0) = 600.0;
uniform float t;

uniform vec3 sc[1];

void fragment() {
    vec2 uv = SCREEN_UV * 2.0 - 1.0;
	vec2 dims = 1.0 / SCREEN_PIXEL_SIZE;
    uv.x *= dims.x / dims.y;
    vec2 world_pos = world_position + uv;

    vec2 p = vec2(world_position.x, -world_position.y);
    //float world_freq = 0.001;
    //float world_amp = 100.0;
    //float fn = world_amp * sin(world_freq * p.x - (speed * TIME));

	float fn = 0.0;
	for (int i = 0; i < 1; i++)
	{
		fn -=  sc[i].x * sin((sc[i].y * p.x) - t);
	}
    float surface = p.y + lava_level + fn;
    float heat_mask = clamp(1.0 - (surface / heat_range), 0.0, 1.0);
    heat_mask = pow(heat_mask, 2.0);

    vec4 noise = texture(noise_tex, 0.001 * world_pos + vec2(0., 0.1 * TIME));
    vec2 distortion = vec2(0.5 * noise.r, 0.5 * noise.r) * distortion_strength * heat_mask;
    vec4 scene_color = textureLod(screen_texture, SCREEN_UV + distortion, 0.0);
    vec3 heat_tint = vec3(1.0, 0.4, 0.0);
    scene_color.rgb = mix(scene_color.rgb, heat_tint, heat_mask * 0.15);

    COLOR = scene_color;
	//COLOR = vec4(vec3(noise.r), heat_mask);
}

//uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
//
//void fragment() {
    //vec2 uv = SCREEN_UV * 2.0 - 1.0;
	//vec2 dims = 1.0 / SCREEN_PIXEL_SIZE;
    //uv.x *= dims.x / dims.y;
//
    //COLOR = textureLod(screen_texture, SCREEN_UV, 0.0) + vec4(0., 0., 0.5, 0.8);
//}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
