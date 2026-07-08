shader_type canvas_item;

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float smin( float a, float b, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec2 coll_extents;
void fragment() {
	vec2 uv = 2. * UV - 1.;
	//vec2 res = 1. / SCREEN_PIXEL_SIZE;
	//float AR =  res.x / res.y;
	float AR = coll_extents.x / coll_extents.y;
	float box = sdBox(uv, vec2(0.5));
	vec2 circ_uv = uv;
	circ_uv.x *= AR;
	
	float x =  0.5 * ( cos(TIME) );
	float y =  0.5 * ( sin(TIME) );
	vec2 player_pos = vec2( AR * x, y);
	float player = sdCircle(circ_uv - player_pos, 0.1);
	float d = smin(box, player, 0.1);
	float mask = smoothstep(0., 2. * fwidth(d), d);
	vec3 col = vec3(mask);
	COLOR = vec4(col, 1. - mask);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
