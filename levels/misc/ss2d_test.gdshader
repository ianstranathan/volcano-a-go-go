shader_type canvas_item;

// The maximum supported vertices for our dynamic SDF (change if your shapes are more complex)
const int MAX_VERTICES = 32;

uniform vec2 polygon_points[MAX_VERTICES];
uniform int point_count = 0;

uniform vec2 marker_local_pos;
uniform float dist_scale = 100.0;
uniform float burn_softness : hint_range(0.01, 1.0) = 0.2;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// Helper function to find the shortest distance from a pixel (p) to a line segment (a to b)
float distance_to_segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	vec2 ap = p - a;
	float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
	return length(ap - ab * t);
}

void fragment() {
	// 1. Calculate the raw distance to the closest polygon edge
	float min_dist_to_edge = 99999.0;
	
	if (point_count > 1) {
		for (int i = 0; i < point_count; i++) {
			vec2 pt_a = polygon_points[i];
			// Connect the last point back to the first point to close the loop
			vec2 pt_b = polygon_points[(i + 1) % point_count];
			
			float dist = distance_to_segment(local_pos, pt_a, pt_b);
			min_dist_to_edge = min(min_dist_to_edge, dist);
		}
	} else {
		min_dist_to_edge = 0.0;
	}

	// 2. Calculate the fade multiplier based on our origin marker
	float dist_from_marker = distance(local_pos, marker_local_pos);
	float radial_fade = clamp(dist_from_marker / dist_scale, 0.0, 1.0);

	// 3. Combine: We fade to black based on *both* how close we are to the edge 
	// and how far we've spread from the marker.
	float combined_sdf = mix(min_dist_to_edge, (1.0 - radial_fade) * 50.0, 0.5);

	// 4. Smoothstep the final burn mask
	float burn_mask = 1. - smoothstep(0.0, burn_softness * 100.0, combined_sdf);

	vec4 tex_color = texture(TEXTURE, UV);
	vec3 final_color = mix(vec3(0.0), tex_color.rgb, burn_mask);

	COLOR = vec4(final_color, tex_color.a);
}