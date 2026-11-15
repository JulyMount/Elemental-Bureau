shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float pixel_size : hint_range(1.0, 16.0) = 3.0;
uniform float color_levels : hint_range(2.0, 64.0) = 24.0;
uniform float outline_threshold : hint_range(0.01, 1.0) = 0.18;
uniform vec4 outline_color : source_color = vec4(0.06, 0.04, 0.08, 1.0);

vec3 quantize_color(vec3 col, float levels) {
	return floor(col * levels + 0.5) / levels;
}

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 grid_uv = floor(FRAGCOORD.xy / pixel_size) * pixel_size;
	vec2 snapped_uv = (grid_uv + pixel_size * 0.5) / screen_size;

	vec3 center_col = texture(screen_texture, snapped_uv).rgb;

	vec2 texel = pixel_size / screen_size;
	vec3 col_right = texture(screen_texture, snapped_uv + vec2(texel.x, 0.0)).rgb;
	vec3 col_down  = texture(screen_texture, snapped_uv + vec2(0.0, texel.y)).rgb;

	float edge_diff = length(center_col - col_right) + length(center_col - col_down);
	float edge_mask = step(outline_threshold, edge_diff);

	vec3 quantized = quantize_color(center_col, color_levels);
	vec3 final_rgb = mix(quantized, outline_color.rgb, edge_mask * 0.75);

	COLOR = vec4(final_rgb, 1.0);
}