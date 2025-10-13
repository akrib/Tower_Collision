shader_type canvas_item;

uniform sampler2D noise_tex : source_color;
uniform float wave_speed = 0.3;
uniform float wave_strength = 0.03;

void fragment() {
    vec2 uv = UV;

    // ========================================================
    // EFFET DE PROFONDEUR (SCALE Y)
    // ========================================================

    float t = uv.y;
    float scale = mix(0.08, 0.15, t);
    uv.y = (uv.y - 0.5) / scale + 0.5;

    // ========================================================
    // ONDULATIONS CIRCULAIRES DEPUIS L'EXTÉRIEUR
    // ========================================================

    // Centre de l'image
    vec2 center = vec2(2.5, 1.5);

    // Distance du centre (0.0 au centre, augmente vers les bords)
    float distance_from_center = length(UV - center);

    // Distance maximale (du centre au coin)
    float max_distance = length(vec2(0.5, 0.5));

    // Normaliser la distance (0.0 au centre, 1.0 aux coins)
    float normalized_distance = distance_from_center / max_distance;

    // Créer des vagues circulaires qui partent des bords vers le centre
    // Plus on est loin du centre, plus la phase est avancée
    float wave_phase = normalized_distance * 5.0 - TIME * wave_speed * 2.0;

    // Calcul de l'ondulation
    float wave = sin(wave_phase) * wave_strength * 1.0;

    // Direction vers le centre
    vec2 direction_to_center = normalize(center - UV);

    // Appliquer l'ondulation perpendiculaire à la direction
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

    // Assombrir selon Y pour effet de profondeur
    float depth_darkness = mix(0.4, 1.0, UV.y);

    color.rgb *= depth_darkness;

    COLOR = color;
}