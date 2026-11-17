shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float base_radius : hint_range(0.1, 0.9) = 0.65;
uniform float start_thickness : hint_range(0.001, 0.1) = 0.014;
uniform float end_thickness : hint_range(0.0005, 0.05) = 0.0015;
uniform float spin_amount = 3.5;
uniform float flare_intensity = 3.2;
uniform float chromatic_aberration : hint_range(0.0, 0.15) = 0.065;
uniform float noise_amount : hint_range(0.0, 0.05) = 0.005;

// Parâmetros de Vidro / Bolha Translúcida
uniform float glass_refraction : hint_range(0.0, 0.15) = 0.045;
uniform float rim_glass_reflection : hint_range(0.0, 2.0) = 0.75;
uniform vec3 core_color : source_color = vec3(0.95, 0.98, 1.0);

varying float life_progress;
varying float seed_val;

void vertex() {
    seed_val = INSTANCE_CUSTOM.x;
    life_progress = INSTANCE_CUSTOM.y;
}

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

float get_hit_channel(float r, float angle, float spin, float radius_offset, float thickness, float n_val) {
    float target_r = base_radius + radius_offset + (n_val - 0.5) * noise_amount;
    float dist = abs(r - target_r);
    
    // 1. Fio fino e nítido da borda externa
    float ring = smoothstep(thickness, 0.0, dist);
    
    // 2. Halo externo apertado
    float tight_glow = exp(-dist * 110.0) * 0.4;
    
    // 3. Reflexo especular de vidro colado na curva interna da borda (Fresnel acentuado)
    float normalized_r = clamp(r / target_r, 0.0, 1.0);
    float inside_mask = step(r, target_r);
    // Expoente 10 concentra o brilho apenas nos últimos 15% da borda, mantendo o miolo transparente
    float glass_rim = pow(normalized_r, 10.0) * inside_mask;
    
    // 4. Flares direcionais girando
    float wave1 = pow(max(0.0, cos(angle + spin)), 8.0);
    float wave2 = pow(max(0.0, cos(angle - spin * 0.85 + 3.14)), 14.0) * 0.4;
    float wave_total = wave1 + wave2;
    
    // O flare acende tanto o fio externo quanto a curva interna de vidro (sem criar mancha no meio)
    float hotspot = (exp(-dist * 75.0) + glass_rim * 0.85) * wave_total * flare_intensity;
    
    // Reflexo base contínuo da casca de vidro
    float base_glass = glass_rim * rim_glass_reflection;
    
    return (ring * 0.75) + tight_glow + base_glass + hotspot;
}

void fragment() {
    vec2 uv = (UV - 0.5) * 2.0;
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    
    float current_thickness = mix(start_thickness, end_thickness, life_progress);
    float ease_life = 1.0 - pow(1.0 - life_progress, 2.5);
    float spin = (ease_life * spin_amount) + (seed_val * 6.2831);
    
    vec2 noise_coord = vec2(cos(angle), sin(angle)) * 3.5 + vec2(seed_val * 15.0 + life_progress * 2.0);
    float n_val = noise(noise_coord) * 0.7 + noise(noise_coord * 2.2) * 0.3;
    
    float ca = chromatic_aberration * (0.6 + 0.8 * life_progress);
    
    float red   = get_hit_channel(r, angle + ca, spin, -0.005, current_thickness, n_val);
    float green = get_hit_channel(r, angle, spin, 0.0, current_thickness, n_val);
    float blue  = get_hit_channel(r, angle - ca, spin, 0.005, current_thickness, n_val);
    
    vec3 flare_light = vec3(red, green, blue) * core_color;
    
    // --- REFRAÇÃO DE LENTE ESFÉRICA ---
    float sphere_mask = 1.0 - smoothstep(base_radius - 0.015, base_radius + 0.01, r);
    // Distorção mais forte perto das bordas da esfera (comportamento real de lente)
    float lens_curve = pow(clamp(r / base_radius, 0.0, 1.0), 3.0);
    vec2 refraction_offset = normalize(uv + 0.0001) * lens_curve * glass_refraction * sphere_mask * COLOR.a;
    
    vec3 bg_color;
    bg_color.r = texture(screen_texture, SCREEN_UV - refraction_offset * 1.2).r;
    bg_color.g = texture(screen_texture, SCREEN_UV - refraction_offset).g;
    bg_color.b = texture(screen_texture, SCREEN_UV - refraction_offset * 0.8).b;
    
    float edge_mask = 1.0 - smoothstep(0.88, 1.0, r);
    
    // Soma a luz especular do vidro por cima do fundo refratado
    vec3 final_rgb = bg_color + (flare_light * edge_mask * COLOR.rgb * COLOR.a);
    
    // Transparência cristalina: o centro só aparece onde há refração ou brilho de borda
    float rim_alpha = pow(clamp(r / base_radius, 0.0, 1.0), 4.0) * sphere_mask;
    float light_alpha = clamp(max(flare_light.r, max(flare_light.g, flare_light.b)), 0.0, 1.0);
    float total_alpha = clamp((rim_alpha * 0.5 + light_alpha) * COLOR.a, 0.0, 1.0) * edge_mask;
    
    COLOR = vec4(final_rgb, total_alpha);
}
