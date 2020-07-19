#version 460 core

layout (location = 0) in float vertex;

uniform mat4 projection;
uniform mat4 view;

layout (std430, binding = 0) buffer COLOUR_BLOCK {
    vec4 in_colours[];
};

out vec4 colour;
out vec2 height_x;
out flat uint noise;

const uint lod5_scale = 2048; 

void main() {
    const uint row = gl_VertexID / lod5_scale;
    const uint col = gl_VertexID % lod5_scale;
    const mat4 model = mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(col, vertex, row, 1.0)
    );
    gl_Position = projection * view * model * vec4(0.0, 0.0, 0.0, 1.0);
    height_x = vec2(vertex, col);
    if (vertex <= 36.0) {
        colour = vec4(0.15, 0.15, 0.44, 1.0);
        noise = 0;
    } else if (vertex <= 39.0) {
        colour = in_colours[3];
        noise = 0;
    } else if (vertex <= 60.0) {
        colour = vec4(0.15, 0.45, 0.15, 1.0);
        noise = 2;
    } else if (vertex <= 64.0) {
        colour = vec4(0.15, 0.75, 0.15, 1.0);
        noise = 0;
    } else if (vertex <= 72.0) {
        colour = vec4(0.5, 0.5, 0.5, 1.0);
        noise = 0;
    } else if (vertex <= 80.0) {
        colour = vec4(0.77, 0.77, 0.77, 1.0);
        noise = 0;
    } else {
        colour = vec4(1.0, 1.0, 1.0, 1.0);
        noise = 0;
    }
}