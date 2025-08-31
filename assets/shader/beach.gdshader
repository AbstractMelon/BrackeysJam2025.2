shader_type spatial;

// Height-based color gradient parameters
uniform float water_level : hint_range(-10.0, 10.0) = 0.0;
uniform float sand_level : hint_range(-10.0, 20.0) = 2.0;
uniform float grass_level : hint_range(-10.0, 30.0) = 5.0;
uniform float rock_level : hint_range(-10.0, 250.0) = 110.0;

// Colors for different heights
uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform vec4 wet_sand_color : source_color = vec4(0.6, 0.4, 0.2, 1.0);
uniform vec4 dry_sand_color : source_color = vec4(0.9, 0.8, 0.6, 1.0);
uniform vec4 grass_color : source_color = vec4(0.3, 0.6, 0.2, 1.0);
uniform vec4 rock_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec4 snow_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);

// Transition smoothness
uniform float transition_smoothness : hint_range(0.1, 5.0) = 1.0;

// Noise for variation
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.3;

// Simple noise function
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

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Get world position height from vertex shader
    float height = world_position.y;

    // Add noise variation to height
    float height_noise = smooth_noise(world_position.xz * noise_scale) * noise_strength;
    height += height_noise;

    vec4 final_color;

    // Determine color based on height with smooth transitions
    if (height < water_level) {
        final_color = water_color;
    }
    else if (height < sand_level) {
        // Transition from water to wet sand
        float t = smoothstep(water_level, sand_level, height);
        t = pow(t, 1.0 / transition_smoothness);
        final_color = mix(water_color, wet_sand_color, t);
    }
    else if (height < grass_level) {
        // Transition from wet sand to dry sand to grass
        float mid_point = (sand_level + grass_level) * 0.5;
        if (height < mid_point) {
            float t = smoothstep(sand_level, mid_point, height);
            t = pow(t, 1.0 / transition_smoothness);
            final_color = mix(wet_sand_color, dry_sand_color, t);
        } else {
            float t = smoothstep(mid_point, grass_level, height);
            t = pow(t, 1.0 / transition_smoothness);
            final_color = mix(dry_sand_color, grass_color, t);
        }
    }
    else if (height < rock_level) {
        // Transition from grass to rock
        float t = smoothstep(grass_level, rock_level, height);
        t = pow(t, 1.0 / transition_smoothness);
        final_color = mix(grass_color, rock_color, t);
    }
    else {
        // High altitude - rock to snow
        float snow_start = rock_level + 5.0;
        if (height > snow_start) {
            float t = smoothstep(rock_level, snow_start, height);
            t = pow(t, 1.0 / transition_smoothness);
            final_color = mix(rock_color, snow_color, t);
        } else {
            final_color = rock_color;
        }
    }

    ALBEDO = final_color.rgb;

    // Adjust roughness based on material type
    if (height < water_level + 0.5) {
        ROUGHNESS = 0.1; // Wet areas are smoother
    } else if (height < grass_level) {
        ROUGHNESS = 0.8; // Sand is rough
    } else if (height < rock_level) {
        ROUGHNESS = 0.6; // Grass/vegetation
    } else {
        ROUGHNESS = 0.7; // Rock
    }

    METALLIC = 0.0;
}