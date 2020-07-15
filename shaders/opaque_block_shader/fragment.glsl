#version 460 core

#extension GL_ARB_bindless_texture : require

in vec4 colour;

out vec4 out_colour;

float rand(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    const float r = rand(gl_FragCoord.xy) * 0.015;
    out_colour = vec4(colour.rgb - r * 1.25, colour.a);
}