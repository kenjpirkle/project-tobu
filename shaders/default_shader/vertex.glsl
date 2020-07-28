#version 460 core

layout (location = 0) in float vertex;
layout (location = 1) in vec3 offset;

uniform mat4 projection;
uniform mat4 view;

layout (std430, binding = 0) buffer COLOUR_BLOCK {
    vec4 in_colours[];
};

out vec4 colour;

const uint vertices_per_row = 48;
const float height_scale = 1.0;

const float size_multiplier = 0.01;

void main() {
    const uint chunk = gl_VertexID % 384;
    const uint row = chunk / vertices_per_row;
    const uint row_vertex =  chunk % vertices_per_row;
    const uint quad = row_vertex / 6;
    const uint quad_offset = row_vertex % 6;

    const float x_off = (quad_offset == 2 || quad_offset == 3 || quad_offset == 5) ? 1.0 : 0.0;
    const float z_off = (quad_offset == 1 || quad_offset == 2 || quad_offset == 5) ? 1.0 : 0.0;
    const float x = offset.x + (float(quad) * offset.z) + (x_off * offset.z);
    const float z = offset.y + (float(row) * offset.z) + (z_off * offset.z);
    const mat4 model = mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(x, vertex, z, 1.0)
    );

    gl_Position = projection * view * model * vec4(0.0, 0.0, 0.0, 1.0);

    if (vertex <= (36.0 * height_scale)) {
        colour = vec4(0.15, 0.15, 0.44, 1.0);
    } else if (vertex <= (39.0 * height_scale)) {
        colour = in_colours[3];
    } else if (vertex <= (60.0 * height_scale)) {
        colour = vec4(0.15, 0.45, 0.15, 1.0);
    } else if (vertex <= (64.0 * height_scale)) {
        colour = vec4(0.15, 0.75, 0.15, 1.0);
    } else if (vertex <= (72.0 * height_scale)) {
        colour = vec4(0.5, 0.5, 0.5, 1.0);
    } else if (vertex <= (80.0 * height_scale)) {
        colour = vec4(0.77, 0.77, 0.77, 1.0);
    } else {
        colour = vec4(1.0, 1.0, 1.0, 1.0);
    }
}