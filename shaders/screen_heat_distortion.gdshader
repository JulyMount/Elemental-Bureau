shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 0.02) = 0.0032;
uniform float wave_speed : hint_range(1.0, 10.0) = 4.2;
uniform float wave_frequency : hint_range(5.0, 40.0) = 22.0;
uniform vec4 edge_warm_tint : source_color = vec4(1.0, 0.42, 0.06, 0.14);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered);
	
	// Máscara de vinheta: mantém o centro da tela nítido e aplica o calor mais nas bordas
	float edge_mask = smoothstep(0.18, 0.68, dist) * intensity;
	
	// Ondulação térmica ascendente
	float wave_x = sin(uv.y * wave_frequency + TIME * wave_speed) * cos(uv.x * wave_frequency * 0.7 - TIME * wave_speed * 0.8);
	float wave_y = cos(uv.x * wave_frequency + TIME * wave_speed * 1.1);
	
	vec2 offset = vec2(wave_x, wave_y) * distortion_strength * edge_mask;
	vec4 screen_col = texture(screen_texture, clamp(uv + offset, vec2(0.0), vec2(1.0)));
	
	// Brilho laranja suave apenas nas extremidades da tela
	vec3 final_rgb = mix(screen_col.rgb, screen_col.rgb + edge_warm_tint.rgb, edge_mask * edge_warm_tint.a);
	COLOR = vec4(final_rgb, 1.0);
}