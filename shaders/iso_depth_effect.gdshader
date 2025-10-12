shader_type canvas_item;

// Paramètre principal - contrôlé automatiquement
uniform float depth_factor : hint_range(0.0, 1.0) = 0.5;

// === TEINTES DE COULEUR ===
uniform vec3 near_tint_color : source_color = vec3(1.2, 1.1, 0.9);  // Chaud devant (jaune)
uniform vec3 far_tint_color : source_color = vec3(0.7, 0.8, 1.2);   // Froid derrière (bleu)

// === LUMINOSITÉ ET CONTRASTE ===
uniform float brightness_range : hint_range(0.0, 2.0) = 0.4;
uniform float contrast_strength : hint_range(0.0, 1.0) = 0.2;

// === SATURATION ===
uniform float saturation_range : hint_range(0.0, 1.0) = 0.3;

// === RIM LIGHTING (CONTOUR LUMINEUX) ===
uniform bool enable_rim_lighting = true;
uniform vec3 rim_color : source_color = vec3(0.3, 0.6, 1.0);  // Bleu clair
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.8;

// === AMBIENT OCCLUSION (OMBRAGE) ===
uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;

// Conversion RGB vers HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y)/(6.0*d + e)), d/(q.x + e), q.x);
}

// Conversion HSV vers RGB
vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

// Détection des bords pour le rim lighting
float edge_detection(sampler2D tex, vec2 uv, vec2 pixel_size) {
	// Échantillonner les pixels voisins
	float alpha_center = texture(tex, uv).a;
	float alpha_right = texture(tex, uv + vec2(pixel_size.x, 0.0)).a;
	float alpha_left = texture(tex, uv - vec2(pixel_size.x, 0.0)).a;
	float alpha_up = texture(tex, uv + vec2(0.0, pixel_size.y)).a;
	float alpha_down = texture(tex, uv - vec2(0.0, pixel_size.y)).a;

	// Si c'est un bord (alpha varie)
	float edge = 0.0;
	if (alpha_center > 0.5) {
		if (alpha_right < 0.5 || alpha_left < 0.5 || alpha_up < 0.5 || alpha_down < 0.5) {
			edge = 1.0;
		}
	}

	return edge;
}

void fragment() {
	// Récupérer la couleur de base
	vec4 tex_color = texture(TEXTURE, UV);

	// Si le pixel est transparent, ne rien faire
	if (tex_color.a > 0.01) {
		// === 1. TEINTE DE COULEUR (COLOR GRADING) ===
	vec3 tint = mix(far_tint_color, near_tint_color, depth_factor);
	tex_color.rgb *= tint;

	// === 2. LUMINOSITÉ SELON LA PROFONDEUR ===
	// Objets proches plus lumineux, lointains plus sombres
	float brightness = mix(1.0 - brightness_range, 1.0 + brightness_range, depth_factor);
	tex_color.rgb *= brightness;

	// === 3. CONTRASTE ===
	float contrast = 1.0 + (contrast_strength * (1.0 - depth_factor));
	tex_color.rgb = ((tex_color.rgb - 0.5) * contrast) + 0.5;

	// === 4. SATURATION ===
	vec3 hsv = rgb2hsv(tex_color.rgb);
	float saturation_mod = mix(-saturation_range, saturation_range, depth_factor);
	hsv.y = clamp(hsv.y + saturation_mod, 0.0, 1.0);
	tex_color.rgb = hsv2rgb(hsv);

	// === 5. AMBIENT OCCLUSION (OMBRAGE DANS LES CREUX) ===
	// Les objets lointains sont plus sombres dans les coins
	float ao = 1.0 - (ao_strength * (1.0 - depth_factor));
	// Approximation simple : assombrir selon la distance du centre
	float dist_from_center = length(UV - 0.5) * 2.0;
	tex_color.rgb *= mix(1.0, ao, dist_from_center * 0.3);

		// === 6. RIM LIGHTING (CONTOUR LUMINEUX) ===
		if (enable_rim_lighting) {
			vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
			float edge = edge_detection(TEXTURE, UV, pixel_size);

			if (edge > 0.5) {
				// Appliquer le rim lighting
				// Plus fort sur les objets proches
				float rim_strength = rim_intensity * depth_factor;
				tex_color.rgb = mix(tex_color.rgb, rim_color, rim_strength * edge);
			}
		}

		// Clamp final pour éviter les dépassements
		tex_color.rgb = clamp(tex_color.rgb, 0.0, 1.0);
	}

	COLOR = tex_color;
}