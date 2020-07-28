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
    pub const OffsetBuffer: u32 = 1;
    pub const ColourBuffer: u32 = 2;
    pub const DrawCommandBuffer: u32 = 3;
};

const buffer_count = 4;

const ShaderLocation = struct {
    pub const Vertex: u32 = 0;
    pub const Offset: u32 = 1;
    pub const ColourIndex: u32 = 2;
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
    vertex_buffer: MapBuffer(f32, 130560) = undefined,
    offset_buffer: MapBuffer(zglm.Vec3, 88) = undefined,
    colour_buffer: MapBuffer(Colour, 256) = undefined,
    draw_command_buffer: MapBuffer(DrawArraysIndirectCommand, 88) = undefined,

    pub fn init(self: *Self) !void {
        self.shader = try Shader.init(shaders[0..]);

        glUseProgram(self.shader.program);
        glCreateVertexArrays(1, &self.vertex_array_object);
        glBindVertexArray(self.vertex_array_object);
        glCreateBuffers(buffer_count, &self.vertex_buffer_objects[0]);

        // VERTEX BUFFER
        self.vertex_buffer.init(self.vertex_buffer_objects[BufferType.VertexBuffer], GL_ARRAY_BUFFER);
        // vertex attribute
        glVertexAttribPointer(ShaderLocation.Vertex, 1, GL_FLOAT, GL_FALSE, @sizeOf(f32), @intToPtr(?*c_void, 0));
        glEnableVertexAttribArray(ShaderLocation.Vertex);

        // OFFSET BUFFER
        self.offset_buffer.init(self.vertex_buffer_objects[BufferType.OffsetBuffer], GL_ARRAY_BUFFER);
        glVertexAttribPointer(ShaderLocation.Offset, 3, GL_FLOAT, GL_FALSE, @sizeOf(zglm.Vec3), @intToPtr(?*GLvoid, 0));
        glEnableVertexAttribArray(ShaderLocation.Offset);
        glVertexAttribDivisor(ShaderLocation.Offset, 1);
        self.offset_buffer.append(&[_]zglm.Vec3{
            // 128 chunks
            .{ .x = 0.0, .y = 0.0, .z = 16.0 },
            .{ .x = 128.0, .y = 0.0, .z = 16.0 },
            .{ .x = 256.0, .y = 0.0, .z = 16.0 },
            .{ .x = 384.0, .y = 0.0, .z = 16.0 },
            .{ .x = 0.0, .y = 384.0, .z = 16.0 },
            .{ .x = 128.0, .y = 384.0, .z = 16.0 },
            .{ .x = 256.0, .y = 384.0, .z = 16.0 },
            .{ .x = 384.0, .y = 384.0, .z = 16.0 },
            .{ .x = 0.0, .y = 128.0, .z = 16.0 },
            .{ .x = 0.0, .y = 256.0, .z = 16.0 },
            .{ .x = 384.0, .y = 128.0, .z = 16.0 },
            .{ .x = 384.0, .y = 256.0, .z = 16.0 },
            // 64 chunks
            .{ .x = 128.0, .y = 128.0, .z = 8.0 },
            .{ .x = 192.0, .y = 128.0, .z = 8.0 },
            .{ .x = 256.0, .y = 128.0, .z = 8.0 },
            .{ .x = 320.0, .y = 128.0, .z = 8.0 },
            .{ .x = 128.0, .y = 320.0, .z = 8.0 },
            .{ .x = 192.0, .y = 320.0, .z = 8.0 },
            .{ .x = 256.0, .y = 320.0, .z = 8.0 },
            .{ .x = 320.0, .y = 320.0, .z = 8.0 },
            .{ .x = 128.0, .y = 192.0, .z = 8.0 },
            .{ .x = 128.0, .y = 256.0, .z = 8.0 },
            .{ .x = 320.0, .y = 192.0, .z = 8.0 },
            .{ .x = 320.0, .y = 256.0, .z = 8.0 },
            // 32 chunks
            .{ .x = 192.0, .y = 192.0, .z = 4.0 },
            .{ .x = 224.0, .y = 192.0, .z = 4.0 },
            .{ .x = 256.0, .y = 192.0, .z = 4.0 },
            .{ .x = 288.0, .y = 192.0, .z = 4.0 },
            .{ .x = 192.0, .y = 288.0, .z = 4.0 },
            .{ .x = 224.0, .y = 288.0, .z = 4.0 },
            .{ .x = 256.0, .y = 288.0, .z = 4.0 },
            .{ .x = 288.0, .y = 288.0, .z = 4.0 },
            .{ .x = 192.0, .y = 224.0, .z = 4.0 },
            .{ .x = 192.0, .y = 256.0, .z = 4.0 },
            .{ .x = 288.0, .y = 224.0, .z = 4.0 },
            .{ .x = 288.0, .y = 256.0, .z = 4.0 },
            // 16 chunks
            .{ .x = 224.0, .y = 224.0, .z = 2.0 },
            .{ .x = 240.0, .y = 224.0, .z = 2.0 },
            .{ .x = 256.0, .y = 224.0, .z = 2.0 },
            .{ .x = 272.0, .y = 224.0, .z = 2.0 },
            .{ .x = 224.0, .y = 272.0, .z = 2.0 },
            .{ .x = 240.0, .y = 272.0, .z = 2.0 },
            .{ .x = 256.0, .y = 272.0, .z = 2.0 },
            .{ .x = 272.0, .y = 272.0, .z = 2.0 },
            .{ .x = 224.0, .y = 240.0, .z = 2.0 },
            .{ .x = 224.0, .y = 256.0, .z = 2.0 },
            .{ .x = 272.0, .y = 240.0, .z = 2.0 },
            .{ .x = 272.0, .y = 256.0, .z = 2.0 },
            // 8 chunks
            .{ .x = 240.0, .y = 240.0, .z = 1.0 },
            .{ .x = 248.0, .y = 240.0, .z = 1.0 },
            .{ .x = 256.0, .y = 240.0, .z = 1.0 },
            .{ .x = 264.0, .y = 240.0, .z = 1.0 },
            .{ .x = 240.0, .y = 264.0, .z = 1.0 },
            .{ .x = 248.0, .y = 264.0, .z = 1.0 },
            .{ .x = 256.0, .y = 264.0, .z = 1.0 },
            .{ .x = 264.0, .y = 264.0, .z = 1.0 },
            .{ .x = 240.0, .y = 248.0, .z = 1.0 },
            .{ .x = 240.0, .y = 256.0, .z = 1.0 },
            .{ .x = 264.0, .y = 248.0, .z = 1.0 },
            .{ .x = 264.0, .y = 256.0, .z = 1.0 },
            // 4 chunks
            .{ .x = 248.0, .y = 248.0, .z = 0.5 },
            .{ .x = 252.0, .y = 248.0, .z = 0.5 },
            .{ .x = 256.0, .y = 248.0, .z = 0.5 },
            .{ .x = 260.0, .y = 248.0, .z = 0.5 },
            .{ .x = 248.0, .y = 260.0, .z = 0.5 },
            .{ .x = 252.0, .y = 260.0, .z = 0.5 },
            .{ .x = 256.0, .y = 260.0, .z = 0.5 },
            .{ .x = 260.0, .y = 260.0, .z = 0.5 },
            .{ .x = 248.0, .y = 252.0, .z = 0.5 },
            .{ .x = 248.0, .y = 256.0, .z = 0.5 },
            .{ .x = 260.0, .y = 252.0, .z = 0.5 },
            .{ .x = 260.0, .y = 256.0, .z = 0.5 },
            // 2 chunks
            .{ .x = 252.0, .y = 252.0, .z = 0.25 },
            .{ .x = 254.0, .y = 252.0, .z = 0.25 },
            .{ .x = 256.0, .y = 252.0, .z = 0.25 },
            .{ .x = 258.0, .y = 252.0, .z = 0.25 },
            .{ .x = 252.0, .y = 258.0, .z = 0.25 },
            .{ .x = 254.0, .y = 258.0, .z = 0.25 },
            .{ .x = 256.0, .y = 258.0, .z = 0.25 },
            .{ .x = 258.0, .y = 258.0, .z = 0.25 },
            .{ .x = 252.0, .y = 254.0, .z = 0.25 },
            .{ .x = 252.0, .y = 256.0, .z = 0.25 },
            .{ .x = 258.0, .y = 254.0, .z = 0.25 },
            .{ .x = 258.0, .y = 256.0, .z = 0.25 },
            // 1 chunks
            .{ .x = 254.0, .y = 254.0, .z = 0.015625 },
            .{ .x = 255.0, .y = 254.0, .z = 0.015625 },
            .{ .x = 254.0, .y = 255.0, .z = 0.015625 },
            .{ .x = 255.0, .y = 255.0, .z = 0.015625 },
        });

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
