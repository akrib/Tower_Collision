shader_type canvas_item;

uniform sampler2D noise_tex : source_color;
uniform float wave_speed = 0.3;
uniform float wave_strength = 0.03;
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.7; // 🔸 Contrôle de la transparence

void fragment() {
    vec2 uv = UV;

    // ========================================================
    // EFFET DE PROFONDEUR (SCALE Y)
    // ========================================================

    float t = uv.y;
    float scale = mix(0.001, 0.08, t);
    uv.y = (uv.y - 0.7) / scale + 0.0;

    // ========================================================
    // ONDULATIONS CIRCULAIRES DEPUIS L'EXTÉRIEUR
    // ========================================================

    vec2 center = vec2(2.5, 1.5);
    float distance_from_center = length(UV - center);
    float max_distance = length(vec2(0.5, 0.5));
    float normalized_distance = distance_from_center / max_distance;
    float wave_phase = normalized_distance * 5.0 - TIME * wave_speed * 2.0;
    float wave = sin(wave_phase) * wave_strength * 1.0;
    vec2 direction_to_center = normalize(center - UV);
    vec2 perpendicular = vec2(-direction_to_center.y, direction_to_center.x);
    uv += perpendicular * wave;

    // ========================================================
    // BRUIT ADDITIONNEL
    // ========================================================

    vec2 noise;
    #ifdef TEXTURE
    noise = texture(noise_tex, uv).rg;
    #else
    float n = sin((uv.x + uv.y + TIME * wave_speed) * 6.0);
    noise = vec2(n, n) * 0.5 + 0.5;
    #endif

    uv += (noise - 0.5) * wave_strength;

    // ========================================================
    // RENDU FINAL AVEC ASSOMBRISSEMENT DE PROFONDEUR
    // ========================================================

    vec4 color = texture(TEXTURE, uv);

    float depth_darkness = mix(0.4, 1.0, UV.y);
    color.rgb *= depth_darkness;

    // ========================================================
    // AJOUT DE TRANSPARENCE
    // ========================================================

    // Plus transparent vers le bas de la texture
    float alpha_gradient = mix(0.3, 0.5, UV.y);
    float alpha = alpha_strength * alpha_gradient;

    color.a *= alpha;

    COLOR = color;
}
