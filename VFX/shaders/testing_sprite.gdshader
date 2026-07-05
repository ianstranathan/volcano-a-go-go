shader_type canvas_item;


//uniform sampler2D noise_tex;
//uniform int fadeType: hint_range(0, 3, 1);
uniform float t: hint_range(0.0, 1.0, 0.1);


void fragment()
{
    vec2 uv = 2. * UV - 1.;
	float r = length(uv);
	float _t = mix(0., 1.5, t * t);
	float mask = 1. - smoothstep( _t, _t + fwidth( r), r);
	COLOR = vec4( vec3( mask ), mask);
	//outcol =  texture(TEXTURE,uv) * s + (1. - s) * vec4(0,0,0,1);
    //COLOR = outcol;
}


