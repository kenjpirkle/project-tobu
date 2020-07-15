const std = @import("std");
const warn = std.debug.warn;
const Shader = @import("shader.zig").Shader;
const ShaderSource = @import("shader.zig").ShaderSource;
const Colour = @import("../gl/colour.zig").Colour;
const DrawArraysIndirectCommand = @import("../gl/draw_arrays_indirect_command.zig").DrawArraysIndirectCommand;
const BlockType = @import("../block_type.zig").BlockType;
const Chunk = @import("../chunk.zig").Chunk;
const MapBuffer = @import("../map_buffer.zig").MapBuffer;
const zglm = @import("../zglm/zglm.zig");
usingnamespace @import("../c.zig");

const BufferType = struct {
    pub const BlockBuffer: u32 = 0;
    pub const ColourBuffer: u32 = 1;
    pub const DrawCommandBuffer: u32 = 2;
    pub const TextureHandleBuffer: u32 = 3;
};

const ShaderLocation = struct {
    pub const Block: u32 = 0;
    pub const ColourIndex: u32 = 1;
};

pub const OpaqueBlockShader = struct {
    const Self = @This();

    const shaders = [_]ShaderSource{
        .{
            .shader_type = GL_VERTEX_SHADER,
            .source = "shaders/opaque_block_shader/vertex.glsl",
        },
        .{
            .shader_type = GL_FRAGMENT_SHADER,
            .source = "shaders/opaque_block_shader/fragment.glsl",
        },
    };

    shader: Shader = undefined,
    vertex_array_object: GLuint = undefined,
    vertex_buffer_objects: [3]GLuint = undefined,
    projection_location: GLint = undefined,
    view_location: GLint = undefined,
    blocks: MapBuffer(BlockType, 128) = undefined,
    colours: MapBuffer(Colour, 128) = undefined,
    draw_commands: MapBuffer(DrawArraysIndirectCommand, 64) = undefined,

    pub fn init(self: *Self) !void {
        self.shader = try Shader.init(shaders[0..]);

        glUseProgram(self.shader.program);
        glCreateVertexArrays(1, &self.vertex_array_object);
        glBindVertexArray(self.vertex_array_object);
        glCreateBuffers(3, &self.vertex_buffer_objects[0]);

        // BLOCK BUFFER
        self.blocks.init(self.vertex_buffer_objects[BufferType.BlockBuffer], GL_ARRAY_BUFFER);
        self.blocks.append(&[_]BlockType{
            BlockType.Dirt,
            BlockType.Grass,
            BlockType.Sand,
            BlockType.Stone,
            BlockType.Dirt,
            BlockType.Grass,
            BlockType.Sand,
            BlockType.Stone,
            BlockType.Dirt,
            BlockType.Grass,
            BlockType.Sand,
            BlockType.Stone,
            BlockType.Dirt,
            BlockType.Grass,
            BlockType.Sand,
            BlockType.Stone,
        });
        // BlockType attribute
        glVertexAttribIPointer(ShaderLocation.Block, 1, GL_UNSIGNED_BYTE, 1, @intToPtr(?*GLvoid, 0));
        // ColourIndex attribute
        // glVertexAttribIPointer(ShaderLocation.ColourIndex, 1, GL_UNSIGNED_BYTE, 2, @intToPtr(?*GLvoid, 1));

        // COLOUR BUFFER
        self.colours.init(self.vertex_buffer_objects[BufferType.ColourBuffer], GL_SHADER_STORAGE_BUFFER);
        self.colours.append(&[_]Colour{
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
        self.draw_commands.init(self.vertex_buffer_objects[BufferType.DrawCommandBuffer], GL_DRAW_INDIRECT_BUFFER);
        self.draw_commands.append(&[_]DrawArraysIndirectCommand{
            .{
                .vertex_count = 24,
                .instance_count = 16,
                .first_vertex = 0,
                .base_instance = 0,
            },
        });

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
