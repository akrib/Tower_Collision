shader_type canvas_item;

// TEST SIMPLE : Ce shader colore progressivement en rouge
uniform float depth_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Récupérer la couleur originale
	vec4 original_color = texture(TEXTURE, UV);
	
	// Mélanger avec du rouge selon depth_factor
	// depth_factor = 0.0 → Tout rouge
	// depth_factor = 1.0 → Couleur originale
	vec3 red_tint = vec3(1.0, 0.0, 0.0);
	vec3 mixed_color = mix(red_tint, original_color.rgb, depth_factor);
	
	// Appliquer
	COLOR = vec4(mixed_color, original_color.a);
}