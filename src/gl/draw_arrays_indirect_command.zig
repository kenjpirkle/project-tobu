usingnamespace @import("../c.zig");

pub const DrawArraysIndirectCommand = packed struct {
    vertex_count: GLuint,
    instance_count: GLuint,
    first_vertex: GLuint,
    base_instance: GLuint,
};
