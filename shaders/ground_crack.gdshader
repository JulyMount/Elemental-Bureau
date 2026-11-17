shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 crack_core : source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform vec4 crack_glow : source_color = vec4(0.95, 0.30, 0.05, 1.0);
uniform float crack_density : hint_range(2.0, 20.0) = 8.0;
uniform float crack_width : hint_range(0.02, 0.35) = 0.14;
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Voronoi simples para gerar veios de rachadura orgânicos
float voronoi_cracks(vec2 x) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	float md1 = 8.0;
	float md2 = 8.0;
	
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md1) {
				md2 = md1;
				md1 = d;
			} else if (d < md2) {
				md2 = d;
			}
		}
	}
	return sqrt(md2) - sqrt(md1);
}

void fragment() {
	// Converte UV para coordenadas radiais (-1 a 1)
	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered);
	
	// Máscara circular com anel externo
	float circle_mask = 1.0 - smoothstep(0.75, 1.0, dist);
	float ring_edge = smoothstep(0.65, 0.85, dist) * (1.0 - smoothstep(0.85, 1.0, dist));
	
	float v = voronoi_cracks(centered * crack_density);
	float crack_mask = 1.0 - smoothstep(0.0, crack_width, v);
	
	float intensity = clamp(crack_mask + ring_edge * 0.85, 0.0, 1.0) * circle_mask;
	if (intensity < 0.15) {
		discard;
	}
	
	ALBEDO = mix(crack_glow.rgb, crack_core.rgb, crack_mask);
	ALPHA = intensity * fade_alpha;
}