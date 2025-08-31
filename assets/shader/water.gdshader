shader_type spatial;

render_mode depth_draw_opaque, depth_test_disabled, vertex_lighting, ambient_light_disabled, shadows_disabled, fog_disabled;
// Water shader parameters
uniform float wave_height : hint_range(0.0, 100) = 0.02;
uniform float wave_frequency : hint_range(1.0, 10.0) = 4.0;
uniform float wave_speed : hint_range(0.0, 1.0) = 1.0;
uniform vec4 water_color : source_color = vec4(0.2, 0.6, 0.8, 0.7);
uniform vec4 deep_color : source_color = vec4(0.1, 0.3, 0.6, 0.9);
uniform float transparency : hint_range(0.0, 1.0) = 0.7;
uniform float foam_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;

// Noise function for waves
float noise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

float smooth_noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fractal_noise(vec2 pos) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * smooth_noise(pos * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

varying vec3 world_position;

void vertex() {
    world_position = VERTEX;
    vec2 uv = UV;
    float time = TIME * wave_speed;
    
    // Create wave displacement
    float wave1 = sin(uv.x * wave_frequency + time) * wave_height;
    float wave2 = sin(uv.y * wave_frequency * 1.3 + time * 1.1) * wave_height * 0.7;
    float wave3 = fractal_noise(uv * 3.0 + vec2(time * 0.5, time * 0.3)) * wave_height * 0.5;
    
    VERTEX.y += wave1 + wave2 + wave3;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * wave_speed;
    
    // Create wave pattern for color variation
    float wave_pattern = sin(uv.x * wave_frequency + time) + sin(uv.y * wave_frequency * 1.3 + time * 1.1);
    wave_pattern = wave_pattern * 0.5 + 0.5; // Normalize to 0-1
    
    // Create foam pattern
    float foam = fractal_noise(uv * 8.0 + time * 2.0) * foam_intensity;
    foam = smoothstep(0.3, 0.7, foam);
    
    // Mix colors based on wave pattern
    vec4 final_color = mix(deep_color, water_color, wave_pattern);
    
    // Add foam
    final_color = mix(final_color, vec4(1.0, 1.0, 1.0, 0.8), foam * 0.3);
    
    ALBEDO = final_color.rgb;
    ALPHA = transparency;
    
    // Add some roughness variation
    ROUGHNESS = 0.1 + foam * 0.3;
    METALLIC = 0.0;
}