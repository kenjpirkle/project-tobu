#version 460 core

#extension GL_ARB_bindless_texture : require

layout (location = 0) in uint block_type;

uniform mat4 projection;
uniform mat4 view;

layout (std430, binding = 0) buffer COLOUR_BLOCK {
    vec4 in_colours[];
};

out vec4 colour;

const vec3 vertices[] = {
    // front face quad
    { -0.5,  0.5,  0.5 }, // top left
    {  0.5,  0.5,  0.5 }, // top right
    {  0.5, -0.5,  0.5 }, // bottom right
    { -0.5, -0.5,  0.5 }, // bottom left

    // back face quad
    { -0.5,  0.5, -0.5 }, // top left
    {  0.5,  0.5, -0.5 }, // top right
    {  0.5, -0.5, -0.5 }, // bottom right
    { -0.5, -0.5, -0.5 }, // bottom left

    // left face quad
    { -0.5,  0.5, -0.5 }, // top left
    { -0.5,  0.5,  0.5 }, // top right
    { -0.5, -0.5,  0.5 }, // bottom right
    { -0.5, -0.5, -0.5 }, // bottom left
    
    // right face quad
    { 0.5,  0.5,  0.5 }, // top left
    { 0.5,  0.5, -0.5 }, // top right
    { 0.5, -0.5, -0.5 }, // bottom right
    { 0.5, -0.5,  0.5 }, // bottom left

    // top face quad
    { -0.5,  0.5, -0.5 }, // top left
    {  0.5,  0.5, -0.5 }, // top right
    {  0.5,  0.5,  0.5 }, // bottom right
    { -0.5,  0.5,  0.5 }, // bottom left

    // bottom face quad
    { -0.5, -0.5,  0.5 }, // top left
    {  0.5, -0.5,  0.5 }, // top right
    {  0.5, -0.5, -0.5 }, // bottom right
    { -0.5, -0.5, -0.5 }  // bottom left
};

void main() {
    const uint x_ind = gl_InstanceID % 16;
    const uint z_ind = gl_InstanceID / 16;

    const float x = vertices[gl_VertexID].x + x_ind;
    const float y = vertices[gl_VertexID].y;
    const float z = vertices[gl_VertexID].z + z_ind - 10;

    gl_Position = projection * view * vec4(x, y, z, 1.0);
    colour = in_colours[gl_InstanceID % 3];
}