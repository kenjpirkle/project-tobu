#version 460 core

layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec4 colour;

const vec4 colours[] = {
    // Stone
    vec4(46.0 / 255.0, 42.0 / 255.0, 42.0 / 255.0, 1.0),
    // Dirt
    vec4(49.0 / 255.0, 38.0 / 255.0, 15.0 / 255.0, 1.0),
    // Grass
    vec4(7.0 / 255.0, 75.0 / 255.0, 18.0 / 255.0, 1.0),
    // Sand
    vec4(189.0 / 255.0, 178.0 / 255.0, 120.0 / 255.0, 1.0)
};

void main()
{
	gl_Position = projection * view * model * vec4(position, 1.0);
    const uint face = gl_VertexID / 6;
    if (face == 0) {
        colour = vec4(1.0, 0.0, 0.0, 1.0);
    } else if (face == 1) {
        colour = vec4(0.0, 1.0, 0.0, 1.0);
    } else if (face == 2) {
        colour = vec4(0.0, 0.0, 1.0, 1.0);
    } else if (face == 3) {
        colour = vec4(1.0, 1.0, 0.0, 1.0);
    } else if (face == 4) {
        colour = vec4(1.0, 0.0, 1.0, 1.0);
    } else if (face == 5) {
        colour = vec4(0.0, 1.0, 1.0, 1.0);
    } else {
        colour = vec4(0.0, 0.0, 0.0, 1.0);
    }
}