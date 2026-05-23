shader_type canvas_item;

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float smin( float a, float b, float k )
{
    k *= 6.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - h*h*h*k*(1.0/6.0);
}

// -- function coefficients for N superpositions
uniform vec3 sc[1]; // -- how many things are we superpositioning with?
uniform vec2 dummy_pos;

// -------------
//uniform vec2 level_dims = vec2(10000.0);
uniform float lava_level;
uniform float t;

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

uniform vec4 top_color : source_color = vec4(1.0, 0.9, 0.2, 1.0); // Bright Yellow/White
uniform vec4 mid_color : source_color = vec4(1.0, 0.3, 0.0, 1.0); // Bright Orange
uniform vec4 bot_color : source_color = vec4(0.2, 0.0, 0.0, 1.0); // Deep Dark Red

uniform float speed = 2.0;
uniform float amplitude = 0.05;
uniform float frequency = 10.0;
//uniform float glow_thickness = 0.1;

void fragment() {
    vec2 p = vec2(world_position.x, -world_position.y);
    float noise = sin(p.x * 0.01 + TIME * 2.567) * 7.0;
    noise += sin(p.x * 0.026 - TIME * 1.26) * 4.0; 
    noise += sin(p.x * 0.057 + TIME * 3.123) * 2.0;
    
	float fn = 0.0;
	for (int i = 0; i < 1; i++)
	{
		fn -=  sc[i].x * sin((sc[i].y * p.x) - t);
	}
	
    float sdf = p.y + lava_level + fn + noise;

    float edge_w = fwidth(sdf);
    float alpha = smoothstep(edge_w, -edge_w, sdf);

    float glow_thickness = 55.0; 
    float glow_intensity = 0.8;
    float dist = max(sdf, 0.0); // Only glow ABOVE the surface
    float glow = glow_intensity / (1.0 + pow(dist / glow_thickness, 2.0));

    float color_mix = clamp((-p.y - lava_level) / 300.0, 0.0, 1.0);
	// -- hdr thresholds
    vec3 orange = vec3(2.5, 0.6, 0.1);
    vec3 red = vec3(1.5, 0.05, 0.01);
    vec3 base_color = mix(red, orange, color_mix);

    vec3 final_rgb = base_color * (alpha + glow);
    float final_alpha = clamp(alpha + glow, 0.0, 1.0);

    COLOR = vec4(final_rgb, final_alpha);
}