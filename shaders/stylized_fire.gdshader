shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 core_color : source_color = vec4(1.0, 0.96, 0.55, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.42, 0.05, 1.0);
uniform vec4 edge_color : source_color = vec4(0.82, 0.10, 0.02, 1.0);
uniform vec2 scroll_speed = vec2(0.0, -3.2);
uniform float noise_scale : hint_range(1.0, 15.0) = 5.5;
uniform float distortion_power : hint_range(0.0, 0.5) = 0.16;
uniform float emission_energy : hint_range(1.0, 20.0) = 4.5;
uniform float wobble_strength : hint_range(0.0, 0.3) = 0.06;
uniform bool use_tail_fade = false;

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
	float n = noise(VERTEX.xz * 3.0 + vec2(0.0, TIME * abs(scroll_speed.y)));
	VERTEX += NORMAL * (n - 0.5) * wobble_strength;
}

void fragment() {
	// 1. Rolagem contínua e distorção UV
	vec2 scrolled_uv = UV * noise_scale + TIME * scroll_speed;
	float noise_val = fbm(scrolled_uv);
	vec2 distorted_uv = scrolled_uv + vec2(noise_val * distortion_power, 0.0);
	float fire_noise = fbm(distorted_uv + scrolled_uv * 0.5);
	
	// 2. Máscara opcional de cauda (afunila base e ponta no eixo Y)
	float tail_mask = use_tail_fade ? sin(UV.y * 3.14159265) : 1.0;
	float final_mask = fire_noise * tail_mask;
	
	// 3. Mapeamento em 3 faixas nítidas (Núcleo -> Meio -> Borda)
	vec3 col = edge_color.rgb;
	if (final_mask > 0.56) {
		col = core_color.rgb;
	} else if (final_mask > 0.34) {
		col = mid_color.rgb;
	}
	
	// Recorte duro para manter estética 3D-to-Pixel Art
	if (final_mask < 0.20) {
		discard;
	}
	
	ALBEDO = col;
	EMISSION = col * emission_energy * final_mask;
}