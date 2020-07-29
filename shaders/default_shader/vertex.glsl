#version 460 core

layout (location = 0) in vec3 offset;

uniform mat4 projection;
uniform mat4 view;

layout (std430, binding = 0) buffer HEIGHT_BLOCK {
    float lod[7][12][8][8][6];
    float local[4][64][64][6];
};

layout (std430, binding = 1) buffer COLOUR_BLOCK {
    vec4 in_colours[];
};

out vec4 colour;

const float height_scale = 1.0;
const float size_multiplier = 0.01;

void main() {
    if (offset.z > 0.24) {
        // LOD terrain
        const uint lod_num = gl_InstanceID / 12;
        const uint ch = gl_InstanceID % 12;
        const uint chv = gl_VertexID % 384;
        const uint r = chv / 48;
        const uint rv = chv % 48;
        const uint c = rv / 6;
        const uint v = rv % 6;

        const float height = lod[lod_num][ch][r][c][v];

        const float x_off = (v == 2 || v == 3 || v == 5) ? 1.0 : 0.0;
        const float z_off = (v == 1 || v == 2 || v == 5) ? 1.0 : 0.0;
        const float x = offset.x + (float(c) * offset.z) + (x_off * offset.z);
        const float z = offset.y + (float(r) * offset.z) + (z_off * offset.z);
        const mat4 model = mat4(
            vec4(1.0, 0.0, 0.0, 0.0),
            vec4(0.0, 1.0, 0.0, 0.0),
            vec4(0.0, 0.0, 1.0, 0.0),
            vec4(x, height, z, 1.0)
        );

        gl_Position = projection * view * model * vec4(0.0, 0.0, 0.0, 1.0);

        if (height <= (36.0 * height_scale)) {
            colour = vec4(0.15, 0.15, 0.44, 1.0);
        } else if (height <= (39.0 * height_scale)) {
            colour = in_colours[3];
        } else if (height <= (60.0 * height_scale)) {
            colour = vec4(0.15, 0.45, 0.15, 1.0);
        } else if (height <= (64.0 * height_scale)) {
            colour = vec4(0.15, 0.75, 0.15, 1.0);
        } else if (height <= (72.0 * height_scale)) {
            colour = vec4(0.5, 0.5, 0.5, 1.0);
        } else if (height <= (80.0 * height_scale)) {
            colour = vec4(0.77, 0.77, 0.77, 1.0);
        } else {
            colour = vec4(1.0, 1.0, 1.0, 1.0);
        }
        // if (offset.z > 15.0) {
        //     colour = vec4(1.0, 0.0, 0.0, 1.0);
        // } else if (offset.z > 7.0) {
        //     colour = vec4(0.0, 1.0, 0.0, 1.0);
        // } else if (offset.z > 3.0) {
        //     colour = vec4(0.0, 0.0, 1.0, 1.0);
        // } else if (offset.z > 1.1) {
        //     colour = vec4(1.0, 0.0, 0.0, 1.0);
        // } else if (offset.z > 0.9) {
        //     colour = vec4(0.0, 1.0, 0.0, 1.0);
        // } else if (offset.z > 0.4) {
        //     colour = vec4(0.0, 0.0, 1.0, 1.0);
        // } else {
        //     colour = vec4(1.0, 0.0, 0.0, 1.0);
        // }
    } else {
        // Local terrain
        const uint chv = gl_VertexID % 24576;
        const uint r = chv / 384;
        const uint rv = chv % 384;
        const uint c = rv / 6;
        const uint v = rv % 6;

        const float height = local[gl_InstanceID][r][c][v];

        const float x_off = (v == 2 || v == 3 || v == 5) ? 1.0 : 0.0;
        const float z_off = (v == 1 || v == 2 || v == 5) ? 1.0 : 0.0;
        const float x = offset.x + (float(c) * offset.z) + (x_off * offset.z);
        const float z = offset.y + (float(r) * offset.z) + (z_off * offset.z);
        const mat4 model = mat4(
            vec4(1.0, 0.0, 0.0, 0.0),
            vec4(0.0, 1.0, 0.0, 0.0),
            vec4(0.0, 0.0, 1.0, 0.0),
            vec4(x, height, z, 1.0)
        );

        gl_Position = projection * view * model * vec4(0.0, 0.0, 0.0, 1.0);

        if (height <= (36.0 * height_scale)) {
            colour = vec4(0.15, 0.15, 0.44, 1.0);
        } else if (height <= (39.0 * height_scale)) {
            colour = in_colours[3];
        } else if (height <= (60.0 * height_scale)) {
            colour = vec4(0.15, 0.45, 0.15, 1.0);
        } else if (height <= (64.0 * height_scale)) {
            colour = vec4(0.15, 0.75, 0.15, 1.0);
        } else if (height <= (72.0 * height_scale)) {
            colour = vec4(0.5, 0.5, 0.5, 1.0);
        } else if (height <= (80.0 * height_scale)) {
            colour = vec4(0.77, 0.77, 0.77, 1.0);
        } else {
            colour = vec4(1.0, 1.0, 1.0, 1.0);
        }
    }
}