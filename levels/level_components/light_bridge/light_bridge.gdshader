shader_type canvas_item;
render_mode blend_add, unshaded;

// Uniforms for customization
uniform vec4 core_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.0, 0.3, 0.6, 1.0);
uniform float speed : hint_range(-10.0, 10.0) = 3.0;
uniform float striation_density : hint_range(5.0, 100.0) = 40.0;
uniform float glow_intensity : hint_range(0.1, 5.0) = 1.5;

void fragment() {
    // UV.x maps horizontally across the bridge, UV.y maps vertically (top to bottom)
    vec2 uv = UV;

    // 1. Vertical core falloff (bright in the middle, fading out at top/bottom bounds)
    float center_distance = abs(uv.y - 0.5) * 2.0; // 0.0 at center, 1.0 at edges
    float core_glow = clamp(1.0 - center_distance, 0.0, 1.0);
    core_glow = pow(core_glow, 2.0); // Sharpen the core beam

    // 2. Lateral striations (magnetic lines moving horizontally)
    // We offset UV.x by TIME * speed to make the magnetic lines sweep across the screen
    float striations = sin((uv.x * striation_density) - (TIME * speed));
    // Remap sine wave from [-1, 1] to [0.2, 1.0] for varying intensity instead of complete black cuts
    striations = mix(0.2, 1.0, striations * 0.5 + 0.5);

    // Add a secondary high-frequency noise/ripple for energy turbulence
    float turbulence = sin(uv.x * 120.0 + TIME * 15.0) * 0.1 + 0.9;

    // 3. Combine colors and patterns
    vec4 final_color = mix(edge_color, core_color, core_glow);
    
    // Apply striations and overall glow multiplier
    float alpha = core_glow * striations * turbulence * glow_intensity;

    COLOR = final_color * alpha;
}