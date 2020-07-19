#version 460 core

in vec4 colour;
in vec2 height_x;
in flat uint noise;

out vec4 out_colour;

float rand(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    // const float r = rand(height_x);
    // if (noise == 1) {
    //     out_colour = vec4(colour.rgb - (r * 0.1), colour.a);
    // } else if (noise == 2) {
    //     out_colour = vec4(colour.rgb - (r * 0.2), colour.a);
    // } else {
    //     out_colour = colour;
    // }
    out_colour = colour;
}