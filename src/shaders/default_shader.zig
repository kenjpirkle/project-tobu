const std = @import("std");
const warn = std.debug.warn;
const Shader = @import("shader.zig").Shader;
const ShaderSource = @import("shader.zig").ShaderSource;
const Colour = @import("../gl/colour.zig").Colour;
const DrawArraysIndirectCommand = @import("../gl/draw_arrays_indirect_command.zig").DrawArraysIndirectCommand;
const DrawElementsIndirectCommand = @import("../gl/draw_elements_indirect_command.zig").DrawElementsIndirectCommand;
const MapBuffer = @import("../map_buffer.zig").MapBuffer;
const zglm = @import("../zglm/zglm.zig");
const constants = @import("../game_constants.zig");
usingnamespace @import("../c.zig");

const BufferType = struct {
    pub const VertexBuffer: u32 = 0;
    pub const IndexBuffer: u32 = 1;
    pub const ColourBuffer: u32 = 2;
    pub const DrawCommandBuffer: u32 = 3;
};

const buffer_count = 4;

const ShaderLocation = struct {
    pub const Vertex: u32 = 0;
    pub const ColourIndex: u32 = 1;
};

pub const DefaultShader = struct {
    const Self = @This();

    const shaders = [_]ShaderSource{
        .{
            .shader_type = GL_VERTEX_SHADER,
            .source = "shaders/default_shader/vertex.glsl",
        },
        .{
            .shader_type = GL_FRAGMENT_SHADER,
            .source = "shaders/default_shader/fragment.glsl",
        },
    };

    shader: Shader = undefined,
    vertex_array_object: GLuint = undefined,
    vertex_buffer_objects: [buffer_count]GLuint = undefined,
    projection_location: GLint = undefined,
    view_location: GLint = undefined,
    vertex_buffer: MapBuffer(f32, constants.lod5_scale * constants.lod5_scale) = undefined,
    index_buffer: MapBuffer(GLuint, (constants.lod5_scale - 1) * (constants.lod5_scale - 1) * 6) = undefined,
    colour_buffer: MapBuffer(Colour, 256) = undefined,
    draw_command_buffer: MapBuffer(DrawElementsIndirectCommand, 16) = undefined,

    pub fn init(self: *Self) !void {
        self.shader = try Shader.init(shaders[0..]);

        glUseProgram(self.shader.program);
        glCreateVertexArrays(1, &self.vertex_array_object);
        glBindVertexArray(self.vertex_array_object);
        glCreateBuffers(buffer_count, &self.vertex_buffer_objects[0]);

        // VERTEX_BUFFER
        self.vertex_buffer.init(self.vertex_buffer_objects[BufferType.VertexBuffer], GL_ARRAY_BUFFER);
        // vertex attribute
        glVertexAttribPointer(ShaderLocation.Vertex, 1, GL_FLOAT, GL_FALSE, @sizeOf(f32), @intToPtr(?*c_void, 0));
        glEnableVertexAttribArray(ShaderLocation.Vertex);

        // INDEX_BUFFER
        self.index_buffer.init(self.vertex_buffer_objects[BufferType.IndexBuffer], GL_ELEMENT_ARRAY_BUFFER);

        // COLOUR BUFFER
        self.colour_buffer.init(self.vertex_buffer_objects[BufferType.ColourBuffer], GL_SHADER_STORAGE_BUFFER);
        self.colour_buffer.append(&[_]Colour{
            // Stone
            .{
                .red = 46.0 / 255.0,
                .green = 42.0 / 255.0,
                .blue = 42.0 / 255.0,
                .alpha = 1.00,
            },
            // Dirt
            .{
                .red = 49.0 / 255.0,
                .green = 38.0 / 255.0,
                .blue = 15.0 / 255.0,
                .alpha = 1.00,
            },
            // Grass
            .{
                .red = 7.0 / 255.0,
                .green = 75.0 / 255.0,
                .blue = 18.0 / 255.0,
                .alpha = 1.00,
            },
            // Sand
            .{
                .red = 189.0 / 255.0,
                .green = 178.0 / 255.0,
                .blue = 120.0 / 255.0,
                .alpha = 1.00,
            },
        });
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, self.vertex_buffer_objects[BufferType.ColourBuffer]);

        // DRAW COMMAND BUFFER
        self.draw_command_buffer.init(self.vertex_buffer_objects[BufferType.DrawCommandBuffer], GL_DRAW_INDIRECT_BUFFER);

        self.projection_location = try self.shader.getUniformLocation("projection");
        self.view_location = try self.shader.getUniformLocation("view");
    }

    pub fn setView(self: *Self, view_matrix: zglm.Mat4) void {
        glProgramUniformMatrix4fv(self.shader.program, self.view_location, 1, GL_FALSE, @ptrCast([*c]const f32, @alignCast(4, &view_matrix.c0)));
    }

    pub fn setProjection(self: *Self, projection_matrix: zglm.Mat4) void {
        glProgramUniformMatrix4fv(self.shader.program, self.projection_location, 1, GL_FALSE, @ptrCast([*c]const f32, @alignCast(4, &projection_matrix.c0)));
    }
};
