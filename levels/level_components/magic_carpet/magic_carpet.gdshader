shader_type canvas_item;

uniform vec4 carpet_color : source_color = vec4(0.55, 0.06, 0.08, 1.0);
uniform vec4 dark_color : source_color = vec4(0.20, 0.015, 0.025, 1.0);
uniform vec4 gold_color : source_color = vec4(1.0, 0.65, 0.16, 1.0);
uniform vec4 magic_color : source_color = vec4(0.15, 0.8, 1.0, 1.0);

uniform float float_amount = 0.025;
uniform float float_speed = 2.0;
uniform float glow = 0.25;


// ============================================================
// PSEUDO-3D CAMERA
// ============================================================
//
// The carpet lives on a flat XY plane:
//
//     X = left / right
//     Y = DEPTH
//
// Y goes INTO the screen.
//
// The important part is that all lines running along Y
// converge on `vanishing_point`.
//
// Move vanishing_point.x to look more from the side.
// Move vanishing_point.y to change how downward we're looking.
//
// perspective controls how aggressively the carpet
// shrinks toward the vanishing point.
// ============================================================

uniform vec2 vanishing_point = vec2(0.62, 0.18);

uniform float perspective = 1.35;

// Width of the carpet in its own plane.
uniform float carpet_width = 1.25;

// Depth of the carpet in its own plane.
uniform float carpet_depth = 0.72;


// ============================================================
// SDF
// ============================================================

float sd_box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0.0)))
        + min(max(d.x, d.y), 0.0);
}

float sd_circle(vec2 p, float r) {
    return length(p) - r;
}


// ============================================================
// PERSPECTIVE PROJECTION
// ============================================================
//
// This is the important bit.
//
// We use:
//
//     screen_y = VP.y + depth_scale * Y / (1 + P * Y)
//
// Therefore:
//
//     Y = q / (depth_scale - q * P)
//
// where q is the distance from the vanishing point.
//
// This guarantees that Y -> infinity approaches the
// vanishing point.
//
// X gets multiplied by the SAME perspective scale,
// so the carpet's sides converge correctly too.
// ============================================================

vec2 screen_to_carpet(vec2 screen_uv) {

    // Screen position relative to vanishing point.
    vec2 q = screen_uv - vanishing_point;


    // --------------------------------------------------------
    // Vertical perspective.
    //
    // `depth_scale` controls the angle of the carpet plane.
    //
    // Larger = more downward / more visible carpet.
    // --------------------------------------------------------

    float depth_scale = 0.6;


    // --------------------------------------------------------
    // Recover world-space depth.
    //
    // screen displacement:
    //
    //     q.y = depth_scale * Y / (1 + perspective * Y)
    //
    // inverse:
    //
    //     Y = q.y / (depth_scale - q.y * perspective)
    // --------------------------------------------------------

    float denominator =
        depth_scale
        - q.y * perspective;

    // Avoid division instability around the horizon.
    denominator = max(denominator, 0.001);

    float depth =
        q.y / denominator;


    // --------------------------------------------------------
    // Perspective scale.
    //
    // Farther away:
    //
    //     scale -> 0
    //
    // Nearer:
    //
    //     scale -> larger
    // --------------------------------------------------------

    float scale =
        1.0 + depth * perspective;

    scale = max(scale, 0.001);


    // --------------------------------------------------------
    // Recover X.
    //
    // The screen X coordinate is also affected by perspective.
    // --------------------------------------------------------

    float x =
        q.x * scale;


    // Convert into the carpet's local coordinates.
    x /= carpet_width;
    depth /= carpet_depth;


    return vec2(x, depth);
}


void fragment() {

    // ========================================================
    // SCREEN -> CARPET PLANE
    // ========================================================

    vec2 uv = screen_to_carpet(1.5 *(UV - vec2(0.5)) + vec2(0.5));


    // ========================================================
    // FLYING / WAVING CARPET
    //
    // This is now operating entirely in carpet coordinates.
    //
    // uv.y is actual DEPTH.
    // ========================================================

    float wave =
        sin(
            uv.x * 6.2831
            + TIME * float_speed
        ) * float_amount;

    uv.y +=
        wave
        * sin(uv.x * 3.14159);


    // Centered carpet coordinates.
    vec2 p = uv;

    p.x *= 1.25;


    // ========================================================
    // MAIN CARPET BODY
    // ========================================================

    float body =
        sd_box(
            p,
            vec2(0.43, 0.20)
        );

    float taper =
        abs(p.x) * 0.10;

    body -= taper;


    // ========================================================
    // CURLED CORNERS
    // ========================================================

    vec2 left_curl_pos =
        vec2(-0.43, -0.015);

    vec2 right_curl_pos =
        vec2(0.43, -0.015);

    float left_curl =
        sd_circle(
            p - left_curl_pos,
            0.075
        );

    float right_curl =
        sd_circle(
            p - right_curl_pos,
            0.075
        );

    float shape =
        min(
            body,
            min(left_curl, right_curl)
        );


    // ========================================================
    // TRANSPARENCY
    // ========================================================

    float alpha =
        1.0 - smoothstep(
            0.0,
            0.008,
            shape
        );

    if (alpha <= 0.0) {
        discard;
    }


    // ========================================================
    // BASE FABRIC
    // ========================================================

    vec3 color =
        carpet_color.rgb;


    // ========================================================
    // INNER PANEL
    // ========================================================

    float inner =
        1.0 - smoothstep(
            0.0,
            0.012,
            sd_box(
                p,
                vec2(0.36, 0.135)
            )
        );

    color =
        mix(
            color,
            dark_color.rgb,
            inner * 0.45
        );


    // ========================================================
    // GOLD BORDER
    // ========================================================

    float outer_border =
        1.0 - smoothstep(
            0.0,
            0.012,
            abs(
                sd_box(
                    p,
                    vec2(0.405, 0.175)
                )
            )
        );

    float inner_border =
        1.0 - smoothstep(
            0.0,
            0.012,
            abs(
                sd_box(
                    p,
                    vec2(0.365, 0.135)
                )
            )
        );

    float border =
        clamp(
            outer_border - inner_border,
            0.0,
            1.0
        );

    color =
        mix(
            color,
            gold_color.rgb,
            border
        );


    // ========================================================
    // CENTER DIAMOND
    // ========================================================

    vec2 motif = p;

    float diamond =
        abs(motif.x)
        + abs(motif.y * 1.8);

    float diamond_line =
        1.0 - smoothstep(
            0.0,
            0.012,
            abs(diamond - 0.14)
        );

    float center_diamond =
        1.0 - smoothstep(
            0.0,
            0.012,
            abs(
                abs(motif.x)
                + abs(motif.y * 1.8)
                - 0.07
            )
        );

    color =
        mix(
            color,
            gold_color.rgb,
            diamond_line * 0.8
        );

    color =
        mix(
            color,
            magic_color.rgb,
            center_diamond * 0.7
        );


    // ========================================================
    // DECORATIVE DOTS
    // ========================================================

    float dots = 0.0;

    for (int i = 0; i < 5; i++) {

        float x =
            float(i - 2) * 0.13;

        float d =
            sd_circle(
                p - vec2(x, 0.0),
                0.012
            );

        dots =
            max(
                dots,
                1.0 - smoothstep(
                    0.0,
                    0.006,
                    d
                )
            );
    }

    color =
        mix(
            color,
            gold_color.rgb,
            dots
        );


    // ========================================================
    // MAGICAL GLOW
    // ========================================================

    float pulse =
        0.5
        + 0.5 * sin(TIME * 3.0);

    float magic_glow =
        pulse * glow;

    color +=
        magic_color.rgb
        * magic_glow
        * inner;


    // ========================================================
    // CYAN EDGE
    // ========================================================

    float edge =
        1.0 - smoothstep(
            0.0,
            0.018,
            abs(shape)
        );

    color +=
        magic_color.rgb
        * edge
        * 0.35;


    COLOR =
        vec4(color, alpha);
}

