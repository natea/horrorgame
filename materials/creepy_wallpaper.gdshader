shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.4, 0.35, 0.3);
uniform vec3 pattern_color : source_color = vec3(0.3, 0.25, 0.2);
uniform vec3 blood_color : source_color = vec3(0.4, 0.05, 0.02);
uniform float pattern_scale : hint_range(1.0, 20.0) = 8.0;
uniform float chip_amount : hint_range(0.0, 1.0) = 0.3;
uniform float blood_amount : hint_range(0.0, 1.0) = 0.15;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.9;

// Hash function for randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * pattern_scale;
    
    // Victorian damask-like pattern
    float pattern = 0.0;
    vec2 grid = fract(uv) - 0.5;
    float diamond = 1.0 - (abs(grid.x) + abs(grid.y)) * 2.0;
    pattern = smoothstep(0.0, 0.3, diamond);
    
    // Add some swirl detail
    float swirl = sin(uv.x * 3.14159 * 2.0) * sin(uv.y * 3.14159 * 2.0);
    pattern = mix(pattern, swirl * 0.5 + 0.5, 0.3);
    
    // Base wallpaper color with pattern
    vec3 color = mix(base_color, pattern_color, pattern * 0.5);
    
    // Chipped/peeling areas
    float chip_noise = fbm(uv * 2.0);
    float chips = smoothstep(1.0 - chip_amount, 1.0 - chip_amount + 0.1, chip_noise);
    vec3 chip_color = vec3(0.6, 0.55, 0.5); // Exposed wall underneath
    color = mix(color, chip_color, chips);
    
    // Random blood stains
    float blood_noise = fbm(uv * 0.5 + vec2(42.0, 17.0));
    float drip_noise = fbm(vec2(uv.x * 3.0, uv.y * 0.3) + vec2(13.0, 7.0));
    float blood = smoothstep(1.0 - blood_amount, 1.0 - blood_amount + 0.05, blood_noise);
    blood += smoothstep(0.85, 0.9, drip_noise) * 0.5; // Drip patterns
    blood = clamp(blood, 0.0, 1.0);
    
    // Darken blood in some areas for dried look
    vec3 final_blood = mix(blood_color, blood_color * 0.3, fbm(uv * 4.0));
    color = mix(color, final_blood, blood);
    
    // Age/dirt overlay
    float dirt = fbm(uv * 1.5) * 0.15;
    color = color - vec3(dirt);
    
    ALBEDO = color;
    ROUGHNESS = roughness_val;
    METALLIC = 0.0;
}