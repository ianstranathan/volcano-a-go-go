shader_type canvas_item;

uniform sampler2D pillar_tex: repeat_enable;

void vertex() {
	// Called for every vertex the material is visible on.
}

const float scale = 0.25;
const vec2 sprite_scale = vec2(1);
const vec2 res = vec2(100.);
const vec2 sprite_res = sprite_scale * res;

uniform vec2 coll_extents;

// little utility fn to scale texture, @300, 100, it looks like 5 is good
//float fn(){
	//return mix(2., 7., (coll_extents.x - 300.) / 300.0);
//}

void fragment() {
	vec2 uv = 2. * UV - 1.;
	
	float ar = sprite_res.x / sprite_res.y;
	
	vec2 sample_uv = 2. * UV - 1.;
	sample_uv.y = asin(sample_uv.y) - TIME;
	sample_uv.x *= sprite_res.x/sprite_res.y;
	sample_uv *= 0.05;
	vec4 tex_s = texture(pillar_tex, 5. * sample_uv);
	
	float fb = (1. - length(vec2(0., uv.y * uv.y)));
	float y_gt_0 = step(0., uv.y);
	float fake_bake = fb * y_gt_0;
	COLOR = vec4(tex_s.xyz * fake_bake + tex_s.xyz * (1. - fake_bake) * (1. - y_gt_0), 1.);
}
