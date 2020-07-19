usingnamespace @import("../c.zig");

pub const DrawElementsIndirectCommand = packed struct {
    vertex_count: GLuint,
    instance_count: GLuint,
    first_index: GLuint,
    base_vertex: GLuint,
    base_instance: GLuint,
};
