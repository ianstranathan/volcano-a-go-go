shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D noise_tex: repeat_enable;

// The progress of the burn (0.0 = fully visible, 1.0 = fully burned)
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
// Width of the glowing burn edge
uniform float burn_size : hint_range(0.0, 0.5) = 0.1;

// Colors for the burning edge
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.0, 1.0); // Orange/Red
uniform vec4 ash_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);  // Dark Grey/Char


void fragment() {
    // 1. Fetch textures
    vec4 main_tex = texture(TEXTURE, UV);
    float noise_val = texture(noise_tex, UV).r;

    // 2. Alpha cutoff mask: 1.0 where noise >= burn_amount, 0.0 where burned
    // step(a, b) returns 1.0 if b >= a, else 0.0
    float visible_mask = step(burn_amount, noise_val);

    // 3. Calculate glowing edge factor: 0.0 at hot edge, 1.0 at normal sprite
    // clamp keeps value between 0.0 and 1.0 to prevent color overflows
    float edge_factor = clamp((noise_val - burn_amount) / max(burn_size, 0.0001), 0.0, 1.0);

    // 4. Blend edge colors (Fire -> Ash -> Original Texture)
    vec3 edge_effect = mix(burn_color.rgb, ash_color.rgb, edge_factor);
    
    // Smoothly transition from the glowing edge back into the original texture
    vec3 final_rgb = mix(edge_effect, main_tex.rgb, edge_factor);

    // 5. Output final color combined with visible mask and original alpha
    COLOR = vec4(final_rgb, main_tex.a * visible_mask);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
