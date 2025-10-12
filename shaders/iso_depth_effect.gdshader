shader_type canvas_item;

uniform float depth_factor : hint_range(0.0, 1.0) = 0.5; // contrôlé depuis GDScript
uniform vec3 near_tint_color : hint_color = vec3(1.1, 1.05, 0.95);
uniform vec3 far_tint_color  : hint_color = vec3(0.8, 0.9, 1.1);
uniform float blur_strength = 0.0015;
uniform float contrast_boost = 0.15;
uniform float saturation_boost = 0.25;

// Conversion RGB ↔ HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y)/(6.0*d + e)), d/(q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0 + vec3(0,4,2),6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // --- BLUR SELON PROFONDEUR ---
    float blur = (1.0 - depth_factor) * blur_strength;
    vec4 blurred = (
        texture(TEXTURE, UV + vec2( blur,  blur)) +
        texture(TEXTURE, UV + vec2(-blur,  blur)) +
        texture(TEXTURE, UV + vec2( blur, -blur)) +
        texture(TEXTURE, UV + vec2(-blur, -blur))
    ) * 0.25;
    tex_color = mix(blurred, tex_color, depth_factor);

    // --- COLOR KEYING ---
    vec3 tint = mix(far_tint_color, near_tint_color, depth_factor);
    tex_color.rgb *= tint;

    // --- SATURATION ---
    vec3 hsv = rgb2hsv(tex_color.rgb);
    hsv.y += (depth_factor - 0.5) * saturation_boost * 2.0;
    hsv.y = clamp(hsv.y, 0.0, 1.0);
    tex_color.rgb = hsv2rgb(hsv);

    // --- ÉCLAIRCISSEMENT / ASSOMBRISSEMENT ---
    float light_factor = mix(0.8, 1.15, depth_factor);
    tex_color.rgb *= light_factor;

    // --- CONTRASTE SUPPLÉMENTAIRE ---
    tex_color.rgb = mix(tex_color.rgb, pow(tex_color.rgb, vec3(1.0 - contrast_boost * depth_factor)), 0.5);

    COLOR = tex_color;
}
