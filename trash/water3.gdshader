shader_type canvas_item;

uniform float time;
uniform vec2 boat_pos;
uniform float wake_radius = 0.1;
uniform float wake_strength = 0.02;

void fragment() {
    vec2 uv = UV;

    // Déformation sinusoïdale de l’eau
    uv.y += sin(uv.x * 10.0 + time * 2.0) * 0.01;

    // Effet de sillage circulaire autour du bateau
    float dist = distance(uv, boat_pos);
    if (dist < wake_radius) {
        uv.y += cos(dist * 20.0 - time * 5.0) * wake_strength * (1.0 - dist / wake_radius);
    }

    COLOR = texture(TEXTURE, uv);
}
