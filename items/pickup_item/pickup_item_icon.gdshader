shader_type canvas_item;


uniform vec4 src_col: source_color;

// https://www.shadertoy.com/view/4stcWH
// https://www.shadertoy.com/view/XsdXRl
uniform float rotation_speed : hint_range(-2.0, 2.0) = 0.5;
uniform float sphere_scale : hint_range(0.1, 2.0) = 1.0;
uniform float decal_scale: hint_range(0.1, 1.) = 1.;
uniform float texture_repeat_x : hint_range(1.0, 20.0) = 4.0;

void vertex(){
	VERTEX.y += 30. * sin(4. * TIME);
}
void fragment() {
    vec2 uv = 2. * UV - 1.0;
	
	//float d = sqrt(uv.x*uv.x + uv.y*uv.y);
    //float cng = asin(d);
	//float lambda = atan(uv.x*sin(cng) , d*cos(cng));
	//float phi = asin(uv.y*sin(cng) / d);
	//vec2 duv = vec2(lambda * 2. / PI , phi * 2.0 / PI);
	//duv.x = duv.x*(1.0 - 0.5*abs(duv.y)*(abs(duv.y)));
	
    //vec4 tex_sample = texture(TEXTURE, UV);
    //float r = length(uv);
    //
	//// 
    //float mask_delta = fwidth(r);
    //float mask = 1.0 - smoothstep(0.95 - mask_delta, 0.95, r);
    //
    //// -- the derivative of the texture's red channel
    //float tex_r = tex_sample.r;
    //float tex_delta = fwidth(tex_r);
    //
    ////  2xfwidth transition around the 0.5 threshold
    //float icon_edge = smoothstep(0.5 - tex_delta, 0.5 + tex_delta, tex_r);
    //
    //// -- cleanly swap between the original texture (mix vs add)
    //vec4 final_color = mix(src_col, tex_sample, icon_edge);
    //
    //COLOR = final_color;
    //COLOR.a *= mask;
	//vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE.y;

    // ------------------------------------------------------------
    // 1. Convert UV coordinates to centered coordinates.
    //
    // UV is:
    //     (0, 0) = top-left
    //     (1, 1) = bottom-right
    //
    // Centering gives us:
    //     (-1, -1) ... (1, 1)
    // ------------------------------------------------------------

    vec2 centered_uv = UV * 2.0 - 1.0;
	
    // Correct for non-square sprites/viewports so the sphere
    // remains circular rather than becoming an ellipse.
    float aspect_ratio = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;

    centered_uv.x *= aspect_ratio;
	

    // Scale the sphere.
    vec2 sphere_position = centered_uv / sphere_scale;

    
    float radius_squared = dot(sphere_position, sphere_position);

   

    // ------------------------------------------------------------
    // 3. Reconstruct the Z coordinate of the sphere.
    // x² + y² + z² = 1  => z = sqrt(1 - x² - y²)
    // ------------------------------------------------------------

    float z = sqrt(1.0 - radius_squared);

    vec3 sphere_normal = vec3(
        sphere_position.x,
        sphere_position.y,
        z
    );

    // ------------------------------------------------------------
    // 4. Rotate the sphere around its Y axis.
    // ------------------------------------------------------------

    float rotation = TIME * rotation_speed;

    float sin_rotation = sin(rotation);
    float cos_rotation = cos(rotation);

    vec3 rotated_normal;

    rotated_normal.x =
        sphere_normal.x * cos_rotation -
        sphere_normal.z * sin_rotation;

    rotated_normal.y =
        -sphere_normal.y;

    rotated_normal.z =
        sphere_normal.x * sin_rotation +
        sphere_normal.z * cos_rotation;

    // ------------------------------------------------------------
    // 5. Convert the 3D point on the sphere into longitude
    //    and latitude.
    // ------------------------------------------------------------

    float longitude = atan(
        rotated_normal.x,
        rotated_normal.z
    );

    float latitude = asin(
        clamp(rotated_normal.y, -1.0, 1.0)
    );

    // ------------------------------------------------------------
    // 6. Convert longitude/latitude into texture UVs.
    // ------------------------------------------------------------

    vec2 texture_uv;

    texture_uv.x = longitude / (2.0 * PI) + 0.5;
    texture_uv.y = 0.5 - latitude / PI;
	
	texture_uv.x *= texture_repeat_x;
	texture_uv.x = fract(texture_uv.x);
	
	texture_uv = (texture_uv - 0.5) / decal_scale + 0.5;
	
    // ------------------------------------------------------------
    // 7. Sample the original texture.
    // ------------------------------------------------------------

    vec4 texture_color = texture(TEXTURE, texture_uv);
	
	float radius = length(sphere_position);

	float sphere_alpha = 1.0 - smoothstep(
	    0.98,
	    0.98 + fwidth(radius),
	    radius
	);

    COLOR = vec4(texture_color.xyz, sphere_alpha);
}
