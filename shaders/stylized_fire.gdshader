shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.45, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.42, 0.05, 1.0);
uniform vec4 edge_color : source_color = vec4(0.82, 0.10, 0.02, 1.0);
uniform float speed : hint_range(0.5, 8.0) = 3.2;
uniform float noise_scale : hint_range(1.0, 15.0) = 5.5;
uniform float wobble_strength : hint_range(0.0, 0.3) = 0.08;

// Ruído procedural leve (não exige textura externa)
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * noise(p);
		p *= 2.05;
		amp *= 0.5;
	}
	return v;
}

void vertex() {
	// Ondulação sutil na malha para dar vida à chama
	float n = noise(VERTEX.xz * 3.0 + vec2(0.0, TIME * speed));
	VERTEX += NORMAL * (n - 0.5) * wobble_strength;
}

void fragment() {
	vec2 uv = UV * noise_scale;
	uv.y -= TIME * speed;
	
	float n = fbm(uv + vec2(fbm(uv * 1.4 - TIME * 1.2)));
	
	// Faixas de cor nítidas estilo Pixel Art
	vec3 col = edge_color.rgb;
	if (n > 0.62) {
		col = core_color.rgb;
	} else if (n > 0.38) {
		col = mid_color.rgb;
	}
	
	// Recorte duro nas bordas para evitar aspecto borrado no filtro pixelado
	if (n < 0.22) {
		discard;
	}
	
	ALBEDO = col;
}