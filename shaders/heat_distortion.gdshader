shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 heat_tint : source_color = vec4(1.0, 0.55, 0.12, 0.28);
uniform float wave_speed : hint_range(1.0, 10.0) = 4.5;
uniform float wave_frequency : hint_range(2.0, 20.0) = 9.0;
uniform float distortion_amp : hint_range(0.0, 0.25) = 0.09;

void vertex() {
	// Ondulação térmica ascendente nos vértices do halo
	float wave = sin(VERTEX.y * wave_frequency - TIME * wave_speed) * cos(VERTEX.x * wave_frequency + TIME * wave_speed * 0.8);
	VERTEX += NORMAL * wave * distortion_amp;
}

void fragment() {
	// Efeito Fresnel para aparecer apenas nas bordas da silhueta (sem cobrir o rosto/corpo do player)
	float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.2);
	float pulse = 0.75 + 0.25 * sin(TIME * wave_speed * 1.5 + UV.y * 12.0);
	
	ALBEDO = heat_tint.rgb;
	EMISSION = heat_tint.rgb * 2.2;
	ALPHA = clamp(fresnel * heat_tint.a * pulse, 0.0, 0.55);
}