shader_type canvas_item;

// Set these in the Inspector
uniform int total_frames = 12;
uniform float animation_speed = 6.0; // Frames per second

varying float v_anim_offset;

void vertex() {
    // Grab the 'x' component we stored in GDScript and pass it along
    v_anim_offset = INSTANCE_CUSTOM.x;
}

void fragment() {
    // 1. Get the horizontal size of a single frame (1.0 / 12 = 0.0833)
    float frame_width = 1.0 / float(total_frames);

    // 2. Calculate the current frame index using the offset passed from vertex()
	float offset_time = TIME * animation_speed + (v_anim_offset * float(total_frames));
    // float current_frame = floor(mod(TIME * animation_speed + random_offset, float(total_frames)));
	float current_frame = floor(mod(offset_time, float(total_frames)));
    // 3. Shift the UV coordinates horizontally to grab the correct frame slice
    vec2 frame_uv = UV;
    frame_uv.x = (UV.x / float(total_frames)) + (current_frame * frame_width);

    // 4. Output the pixel from your spritesheet
    COLOR = texture(TEXTURE, frame_uv);
}
