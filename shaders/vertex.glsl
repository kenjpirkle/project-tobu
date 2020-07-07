#version 460 core

#extension GL_ARB_bindless_texture : require

layout (location = 0) in vec4 instance_transform;
layout (location = 1) in float instance_depth;
layout (location = 2) in uint in_character;
layout (location = 3) in uvec4 colour_indices;

layout (std430, binding = 0) buffer COLOUR_BLOCK {
    vec4 in_colours[];
};

uniform float window_height;
uniform vec2 res_multi;
uniform vec4 texture_transforms[128];

out vec4 colour;
out vec2 tex_coords;
out flat uint is_text;

const uvec2 vertices[4] = {
    uvec2(0, 0),
    uvec2(0, 1),
    uvec2(1, 0),
    uvec2(1, 1)
};

void main() {
    if (in_character == 0) {
        is_text = 0;
    } else if (in_character == 1) {
        is_text = 1;
    } else {
        is_text = 2;
    }

    const float x = (instance_transform.x + (instance_transform.z * vertices[gl_VertexID].x)) * res_multi.x - 1.0;
    const float y = (window_height - instance_transform.y - (instance_transform.w * vertices[gl_VertexID].y)) * res_multi.y - 1.0;
    gl_Position = vec4(x, y, instance_depth, 1);
    colour = in_colours[colour_indices[gl_VertexID]];
    const vec4 c = texture_transforms[in_character];
    tex_coords.x = (c.x + (c.z * vertices[gl_VertexID].x));
    tex_coords.y = (c.y + (c.w * vertices[gl_VertexID].y));
}