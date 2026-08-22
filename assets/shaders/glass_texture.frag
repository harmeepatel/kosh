#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution; // Screen resolution
uniform float uTime;      // (Optional) for animation
uniform vec4 uColor1;     // Background color 1 (e.g., warm)
uniform vec4 uColor2;     // Background color 2 (e.g., cool)

out vec4 fragColor;

// --- Helper Functions ---

// Simple 2D randomness
vec2 random(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Generate cellular (Voronoi-like) info. Returns (distance_to_center, closest_point_uv)
vec4 cellular_layer(vec2 st, float scale) {
    vec2 p = st * scale;
    vec2 f_st = fract(p);
    vec2 i_st = floor(p);

    float m_dist = 1.0;  // minimum distance
    vec2 m_point;        // nearest point
    vec2 m_diff;

    // Grid search for nearest point
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random(i_st + neighbor);

            // Jitter the point slightly
            point = 0.5 + 0.5 * sin(point * 6.2831);

            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);

            if (dist < m_dist) {
                m_dist = dist;
                m_point = point;
                m_diff = diff;
            }
        }
    }
    // Return distance, and cell info for normal calculation
    return vec4(m_dist, i_st + neighbor + point, m_diff);
}

// Combine multi-level cellular structures to make complex facets
float complex_cellular(vec2 st) {
    vec4 l1 = cellular_layer(st, 3.5); // Large facets
    vec4 l2 = cellular_layer(st, 12.0); // Medium texture
    vec4 l3 = cellular_layer(st, 25.0); // Fine granularity

    // Multi-sampling and blending
    float res = 0.0;
    res += l1.x * 0.45;
    res += l2.x * 0.35;
    res += l3.x * 0.20;

    // Soften the pattern to make it organic
    return 1.0 - smoothstep(0.0, 1.3, res);
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution.xy;

    // --- Generate Structured Facets ---
    // Multi-sample the complex pattern to find a 'normal' for each facet
    float st0 = complex_cellular(uv);
    float st1 = complex_cellular(uv + vec2(0.005, 0.0));
    float st2 = complex_cellular(uv + vec2(0.0, 0.005));

    // Facet normal calculation
    float dx = (st1 - st0) * 1.5;
    float dy = (st2 - st0) * 1.5;
    vec2 normal = vec2(dx, dy);

    // --- Apply Distortion (Refraction) ---
    // The structured pattern distorts how the background is sampled
    float strength = 0.12; // Control refraction intensity
    vec2 distorted_uv = uv + normal * strength;

    // --- Background Colors & Gradient (Matching Image) ---
    // Distorted colors: Warm amber to Cool navy
    vec4 bgColor1 = uColor1; // (Passed from Dart)
    vec4 bgColor2 = uColor2; // (Passed from Dart)

    // Blend the gradient *using distorted UV*
    vec4 refractColor = mix(bgColor1, bgColor2, distorted_uv.y);

    // --- Layering the Structured Look ---
    // Apply a light highlight pattern directly from the facets
    float highlight = pow(dx * dx + dy * dy, 2.0);
    vec4 finalHighlight = vec4(1.0) * pow(highlight, 1.5) * 0.4; // Shiny edges

    // Combine refraction and highlight, with a soft overlay of the facet structure
    fragColor = refractColor + finalHighlight + vec4(st0) * 0.05;
}
