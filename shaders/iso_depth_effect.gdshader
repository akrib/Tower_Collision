shader_type canvas_item;

// Paramètre principal - contrôlé automatiquement
uniform float depth_factor : hint_range(0.0, 1.0) = 0.5;

// === TEINTES DE COULEUR (TRÈS SUBTILES) ===
uniform vec3 near_tint_color : source_color = vec3(1.05, 1.03, 1.0);  // Légèrement plus clair devant
uniform vec3 far_tint_color : source_color = vec3(0.90, 0.92, 0.95);   // Légèrement plus sombre derrière

// === LUMINOSITÉ ET CONTRASTE (RÉDUITS) ===
uniform float brightness_range : hint_range(0.0, 2.0) = 0.15;  // Réduit de 0.4 à 0.15
uniform float contrast_strength : hint_range(0.0, 1.0) = 0.08;  // Réduit de 0.2 à 0.08

// === SATURATION (TRÈS SUBTILE) ===
uniform float saturation_range : hint_range(0.0, 1.0) = 0.10;  // Réduit de 0.3 à 0.10

// === RIM LIGHTING (CONTOUR LUMINEUX) - DÉSACTIVÉ PAR DÉFAUT ===
uniform bool enable_rim_lighting = false;
uniform vec3 rim_color : source_color = vec3(0.3, 0.6, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.3;  // Réduit de 0.8 à 0.3

// === AMBIENT OCCLUSION (OMBRAGE) - TRÈS RÉDUIT ===
uniform float ao_strength : hint_range(0.0, 1.0) = 0.10;  // Réduit de 0.3 à 0.10

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
	float alpha_center = texture(tex, uv).a;
	float alpha_right = texture(tex, uv + vec2(pixel_size.x, 0.0)).a;
	float alpha_left = texture(tex, uv - vec2(pixel_size.x, 0.0)).a;
	float alpha_up = texture(tex, uv + vec2(0.0, pixel_size.y)).a;
	float alpha_down = texture(tex, uv - vec2(0.0, pixel_size.y)).a;

	float edge = 0.0;
	if (alpha_center > 0.5) {
		if (alpha_right < 0.5 || alpha_left < 0.5 || alpha_up < 0.5 || alpha_down < 0.5) {
			edge = 1.0;
		}
	}

	return edge;
}

// Fonction de lissage pour des transitions plus douces
float smooth_depth(float d) {
	// Utilise smoothstep pour adoucir la courbe
	return smoothstep(0.0, 1.0, d);
}

void fragment() {
	// Récupérer la couleur de base
	vec4 tex_color = texture(TEXTURE, UV);

	// Si le pixel est transparent, ne rien faire
	if (tex_color.a > 0.01) {
		// Appliquer un lissage sur le depth_factor pour des transitions plus douces
		float smooth_depth_factor = smooth_depth(depth_factor);

		// === 1. TEINTE DE COULEUR SUBTILE ===
		vec3 tint = mix(far_tint_color, near_tint_color, smooth_depth_factor);
		tex_color.rgb *= tint;

		// === 2. LUMINOSITÉ SUBTILE ===
		float brightness = mix(1.0 - brightness_range, 1.0 + brightness_range, smooth_depth_factor);
		tex_color.rgb *= brightness;

		// === 3. CONTRASTE MINIMAL ===
		float contrast = 1.0 + (contrast_strength * (1.0 - smooth_depth_factor));
		tex_color.rgb = ((tex_color.rgb - 0.5) * contrast) + 0.5;

		// === 4. SATURATION SUBTILE ===
		vec3 hsv = rgb2hsv(tex_color.rgb);
		float saturation_mod = mix(-saturation_range, saturation_range, smooth_depth_factor);
		hsv.y = clamp(hsv.y + saturation_mod, 0.0, 1.0);
		tex_color.rgb = hsv2rgb(hsv);

		// === 5. AMBIENT OCCLUSION TRÈS LÉGER ===
		float ao = 1.0 - (ao_strength * (1.0 - smooth_depth_factor));
		float dist_from_center = length(UV - 0.5) * 2.0;
		tex_color.rgb *= mix(1.0, ao, dist_from_center * 0.2);  // Réduit de 0.3 à 0.2

		// === 6. RIM LIGHTING (OPTIONNEL) ===
		if (enable_rim_lighting) {
			vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
			float edge = edge_detection(TEXTURE, UV, pixel_size);

			if (edge > 0.5) {
				float rim_strength = rim_intensity * smooth_depth_factor;
				tex_color.rgb = mix(tex_color.rgb, rim_color, rim_strength * edge);
			}
		}

		// Clamp final
		tex_color.rgb = clamp(tex_color.rgb, 0.0, 1.0);
	}

	COLOR = tex_color;
}