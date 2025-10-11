shader_type canvas_item;

uniform sampler2D noise_tex : source_color;
uniform float wave_speed = 0.3; // plus lent
uniform float wave_strength = 0.03; // plus doux
uniform vec2 wave_direction = vec2(1.0, 0.3);

void fragment() {
    vec2 uv = UV;

    // Effet de profondeur : scale selon Y (de 0.08 à 0.15)
    float t = uv.y;
    float scale = mix(0.08, 0.15, t);
    uv.y = (uv.y - 0.5) / scale + 0.5;

    // Déplacement plus lent
    uv += wave_direction * TIME * wave_speed * 0.1;

    // Bruit simplifié et plus fluide
    vec2 noise;
    #ifdef TEXTURE
    noise = texture(noise_tex, uv).rg;
    #else
    float n = sin((uv.x + uv.y + TIME * wave_speed) * 6.0); // fréquence réduite
    noise = vec2(n, n) * 0.5 + 0.5;
    #endif

    uv += (noise - 0.5) * wave_strength;

    COLOR = texture(TEXTURE, uv);
}
