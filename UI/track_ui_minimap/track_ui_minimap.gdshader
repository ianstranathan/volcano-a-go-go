shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

//vec3 grey_scale(vec3 col){
	//return vec3((col.x + col.y + col.z) / 3.);
//}

uniform vec2 positions[4];
uniform vec3 player_cols[4];

uniform vec2 level_dims;

// this is just trial and error for the given uv scale
//
const vec3 volcano_uv_bounds = vec3(0.825, // max length of side of volcano
								   -0.425, // volcanco floow in uv space
									0.4);  // volcano top in uv space

void fragment() {
	vec2 uv = 2. * UV - 1.;
	uv.y *= -1.;
	vec2 zoomed_uv = 0.6 * (UV - vec2(0.5)) + vec2(0.5);
	vec4 tex_sample = texture(TEXTURE, zoomed_uv);
	float tex_delta = fwidth(tex_sample.x);

	float mask = 0.0;
	float mask_alpha = 0.0;
	vec3 col = tex_sample.xyz + 0.35;
	for( int i = 0; i < positions.length(); i++)
	{
		vec2 pos = positions[i];

		float x = volcano_uv_bounds.x * pos.x / (level_dims.x / 2.);
		float y = mix(volcano_uv_bounds.y, volcano_uv_bounds.z, (pos.y / level_dims.y));



		// add to total color

		float m = smoothstep(0., 2. * fwidth(length(uv)), sdCircle(uv - vec2(x,y), 0.015));
		// cut out black mask from total color
		col *= m;
		// set color
		col += (1. - m) * player_cols[i];
		mask_alpha += (1. - m);
	}
	float alpha = 1. - smoothstep(0.4, 0.4 + tex_delta, tex_sample.x);
	alpha += mask_alpha;
	COLOR = vec4(col, alpha);
}
