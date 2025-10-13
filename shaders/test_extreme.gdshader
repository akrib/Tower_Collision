
shader_type canvas_item;

// SHADER DE TEST ULTRA SIMPLE
// depth_factor = 0.0 → NOIR TOTAL
// depth_factor = 1.0 → BLANC TOTAL

uniform float depth_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Récupérer la couleur originale
	vec4 original = texture(TEXTURE, UV);
	
	// Si le pixel est transparent, ne rien faire
	if (original.a < 0.01) {
		COLOR = original;
		return;
	}
	
	// EFFET EXTRÊME : interpolation entre NOIR et BLANC
	// depth_factor = 0.0 → vec3(0, 0, 0) = NOIR
	// depth_factor = 1.0 → vec3(1, 1, 1) = BLANC
	vec3 result = mix(vec3(0.0), vec3(1.0), depth_factor);
	
	// Conserver l'alpha original
	COLOR = vec4(result, original.a);
}